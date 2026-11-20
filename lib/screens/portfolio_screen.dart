import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/app_models.dart';
import '../services/ai_service.dart';
import '../services/storage_service.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  List<PortfolioItem> _items = [];
  bool _askingAi = false;
  String _aiAdvice = '';

  final _types = ['Акция', 'Облигация', 'Фонд', 'Валюта', 'Металлы'];
  final _sectors = ['Финансы', 'Нефть и газ', 'IT', 'Ритейл', 'Госдолг', 'Другое'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await StorageService.getPortfolio();
    if (!mounted) return;
    setState(() => _items = list);
  }

  double get _totalSum =>
      _items.fold(0.0, (sum, e) => sum + (e.quantity * e.avgPrice));

  Map<String, double> get _typeShares {
    final map = <String, double>{};
    for (final e in _items) {
      map[e.type] = (map[e.type] ?? 0) + (e.quantity * e.avgPrice);
    }
    return map;
  }

  Future<void> _addDialog() async {
    final tickerCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '1');
    final priceCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    String type = _types.first;
    String sector = _sectors.first;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: const Text('Добавить бумагу'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: tickerCtrl, decoration: const InputDecoration(labelText: 'Тикер (например, SBER)')),
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Название (например, Сбербанк)')),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: type,
                  decoration: const InputDecoration(labelText: 'Тип актива'),
                  items: _types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (v) => setDlg(() => type = v ?? type),
                ),
                DropdownButtonFormField<String>(
                  value: sector,
                  decoration: const InputDecoration(labelText: 'Отрасль'),
                  items: _sectors.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (v) => setDlg(() => sector = v ?? sector),
                ),
                TextField(controller: qtyCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Количество')),
                TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Средняя цена (₽)')),
                TextField(controller: noteCtrl, decoration: const InputDecoration(labelText: 'Дневник: почему купил?')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Сохранить')),
          ],
        ),
      ),
    );

    if (ok == true && tickerCtrl.text.trim().isNotEmpty) {
      final qty = double.tryParse(qtyCtrl.text.replaceAll(',', '.')) ?? 0;
      final price = double.tryParse(priceCtrl.text.replaceAll(',', '.')) ?? 0;
      final now = DateTime.now();
      final dateStr = '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year}';
      final item = PortfolioItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        ticker: tickerCtrl.text.trim().toUpperCase(),
        name: nameCtrl.text.trim().isEmpty ? tickerCtrl.text.trim().toUpperCase() : nameCtrl.text.trim(),
        type: type,
        sector: sector,
        quantity: qty,
        avgPrice: price,
        date: dateStr,
        emotionNote: noteCtrl.text.trim(),
      );
      setState(() => _items.add(item));
      await StorageService.savePortfolio(_items);
    }
  }

  Future<void> _deleteItem(String id) async {
    setState(() => _items.removeWhere((e) => e.id == id));
    await StorageService.savePortfolio(_items);
  }

  Future<void> _askAi() async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Сначала добавьте хотя бы одну бумагу')),
      );
      return;
    }
    setState(() {
      _askingAi = true;
      _aiAdvice = 'Анализирую ваш портфель...';
    });
    final lines = _items.map((e) {
      final sum = (e.quantity * e.avgPrice).toStringAsFixed(0);
      final note = e.emotionNote.isNotEmpty ? ' (причина покупки: ${e.emotionNote})' : '';
      return '- ${e.ticker} (${e.name}), ${e.type}, отрасль: ${e.sector}, ${e.quantity} шт. на $sum ₽$note';
    }).join('\n');

    final prompt =
        'Разбери мой реальный портфель на сумму ${_totalSum.toStringAsFixed(0)} ₽:\n$lines\n\n'
        'Объясни простым языком для новичка:\n'
        '1. Есть ли перекосы по типам активов и отраслям?\n'
        '2. Какие главные риски ты видишь?\n'
        '3. Что стоит держать, а где нужна ребалансировка?';

    final res = await AiService.ask(prompt);
    if (!mounted) return;
    setState(() {
      _askingAi = false;
      _aiAdvice = res;
    });
  }

  @override
  Widget build(BuildContext context) {
    final total = _totalSum;
    final shares = _typeShares;

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Реальный портфель', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              FilledButton.icon(onPressed: _addDialog, icon: const Icon(Icons.add), label: const Text('Добавить')),
            ],
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Оценка портфеля: ${total.toStringAsFixed(0)} ₽',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (shares.isEmpty)
                    const Text('Портфель пуст. Нажмите «Добавить», чтобы внести первую бумагу.')
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: shares.entries.map((e) {
                        final pct = total > 0 ? (e.value / total * 100).toStringAsFixed(1) : '0';
                        return Chip(label: Text('${e.key}: $pct%'));
                      }).toList(),
                    ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonalIcon(
                      onPressed: _askingAi ? null : _askAi,
                      icon: const Icon(Icons.psychology),
                      label: Text(_askingAi ? 'ИИ думает...' : 'Посоветоваться с ИИ'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_aiAdvice.isNotEmpty) ...[
            const SizedBox(height: 10),
            Card(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Совет ИИ-инвестора', style: TextStyle(fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.share, size: 20),
                          onPressed: () => Share.share('Разбор моего портфеля от ИИ:\n\n$_aiAdvice'),
                        ),
                      ],
                    ),
                    Text(_aiAdvice),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          ..._items.map((item) {
            final sum = (item.quantity * item.avgPrice).toStringAsFixed(0);
            return Card(
              child: ListTile(
                title: Text('${item.ticker} — ${item.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${item.type} • ${item.sector} • ${item.quantity} шт. × ${item.avgPrice} ₽ = $sum ₽'),
                    if (item.emotionNote.isNotEmpty)
                      Text('Дневник (${item.date}): ${item.emotionNote}',
                          style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12)),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _deleteItem(item.id),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
