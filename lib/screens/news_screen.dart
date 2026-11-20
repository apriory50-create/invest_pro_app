import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/app_models.dart';
import '../services/ai_service.dart';
import '../services/news_service.dart';
import '../services/storage_service.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  List<NewsArticle> _allNews = [];
  List<NewsArticle> _portfolioNews = [];
  List<NewsChannel> _channels = [];
  List<String> _stopWords = [];
  List<PortfolioItem> _portfolio = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    final ch = await StorageService.getChannels();
    final sw = await StorageService.getStopWords();
    final pf = await StorageService.getPortfolio();
    final all = await NewsService.fetchAllNews(ch, sw);
    final pfNews = NewsService.filterForPortfolio(all, pf);
    if (!mounted) return;
    setState(() {
      _channels = ch;
      _stopWords = sw;
      _portfolio = pf;
      _allNews = all;
      _portfolioNews = pfNews;
      _loading = false;
    });
  }

  Future<void> _channelsDialog() async {
    final nameCtrl = TextEditingController();
    final urlCtrl = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: const Text('Каналы новостей (RSS)'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ..._channels.map((c) => CheckboxListTile(
                        dense: true,
                        title: Text(c.name),
                        subtitle: Text(c.url, maxLines: 1, overflow: TextOverflow.ellipsis),
                        value: c.enabled,
                        secondary: IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20),
                          onPressed: () {
                            setDlg(() => _channels.removeWhere((x) => x.id == c.id));
                          },
                        ),
                        onChanged: (v) {
                          setDlg(() {
                            final idx = _channels.indexWhere((x) => x.id == c.id);
                            if (idx >= 0) {
                              _channels[idx] = NewsChannel(
                                id: c.id,
                                name: c.name,
                                url: c.url,
                                enabled: v ?? true,
                              );
                            }
                          });
                        },
                      )),
                  const Divider(),
                  TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Название канала')),
                  TextField(controller: urlCtrl, decoration: const InputDecoration(labelText: 'RSS-ссылка (https://...)')),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton(
                      onPressed: () {
                        if (nameCtrl.text.trim().isNotEmpty && urlCtrl.text.trim().isNotEmpty) {
                          setDlg(() {
                            _channels.add(NewsChannel(
                              id: DateTime.now().millisecondsSinceEpoch.toString(),
                              name: nameCtrl.text.trim(),
                              url: urlCtrl.text.trim(),
                            ));
                            nameCtrl.clear();
                            urlCtrl.clear();
                          });
                        }
                      },
                      child: const Text('Добавить канал'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () async {
                await StorageService.saveChannels(_channels);
                if (ctx.mounted) Navigator.pop(ctx);
                _refresh();
              },
              child: const Text('Готово'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _stopWordsDialog() async {
    final ctrl = TextEditingController(text: _stopWords.join(', '));
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Фильтр лишнего (стоп-слова)'),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Через запятую: реклама, промокод, скидка',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Сохранить')),
        ],
      ),
    );
    if (ok == true) {
      final words = ctrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      await StorageService.saveStopWords(words);
      _refresh();
    }
    ctrl.dispose();
  }

  Future<void> _analyzeNews(NewsArticle article) async {
    final tickers = _portfolio.isEmpty
        ? 'портфель пока пуст'
        : _portfolio.map((e) => '${e.ticker} (${e.name}, ${e.type})').join(', ');

    final prompt =
        'Разбери новость простым языком для новичка:\n'
        'Заголовок: ${article.title}\n'
        'Текст: ${article.description}\n'
        'Мой реальный портфель: $tickers.\n\n'
        'Объясни:\n'
        '1. Это важная новость или рыночный шум?\n'
        '2. Как она влияет на рынок и на мой портфель?\n'
        '3. Стоит ли что-то делать прямо сейчас или лучше просто наблюдать?';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => FutureBuilder<String>(
        future: AiService.ask(prompt),
        builder: (ctx, snap) {
          final text = snap.connectionState == ConnectionState.waiting
              ? 'ИИ-инвестор анализирует новость...'
              : (snap.data ?? 'Нет ответа от ИИ');
          return Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Разбор новости от ИИ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      if (snap.connectionState == ConnectionState.done)
                        IconButton(
                          icon: const Icon(Icons.share),
                          onPressed: () => Share.share('${article.title}\n\nРазбор ИИ:\n$text'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (snap.connectionState == ConnectionState.waiting)
                    const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
                  else
                    Text(text, style: const TextStyle(fontSize: 15)),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildList(List<NewsArticle> list, String emptyText) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(emptyText, textAlign: TextAlign.center),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: list.length,
        itemBuilder: (ctx, i) {
          final n = list[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${n.source} • ${n.date}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  const SizedBox(height: 4),
                  Text(n.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  if (n.description.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(n.description, style: const TextStyle(fontSize: 13)),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () => Share.share('${n.title}\n${n.description}'),
                        icon: const Icon(Icons.share, size: 18),
                        label: const Text('Поделиться'),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: () => _analyzeNews(n),
                        icon: const Icon(Icons.psychology, size: 18),
                        label: const Text('Разбор ИИ'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
            child: Row(
              children: [
                const Expanded(child: Text('Умные новости', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
                IconButton(tooltip: 'Фильтр спама', icon: const Icon(Icons.filter_alt_outlined), onPressed: _stopWordsDialog),
                IconButton(tooltip: 'Каналы RSS', icon: const Icon(Icons.rss_feed), onPressed: _channelsDialog),
                IconButton(tooltip: 'Обновить', icon: const Icon(Icons.refresh), onPressed: _refresh),
              ],
            ),
          ),
          const TabBar(
            tabs: [
              Tab(text: 'Общерыночные'),
              Tab(text: 'По портфелю'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildList(_allNews, 'Нет новостей. Нажмите «Обновить» или добавьте RSS-каналы.'),
                _buildList(_portfolioNews, 'Новостей по бумагам из вашего портфеля пока не найдено.\nДобавьте бумаги во вкладке «Портфель».'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
