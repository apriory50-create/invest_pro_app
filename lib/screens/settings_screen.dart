import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../models/app_models.dart';
import '../services/ai_service.dart';
import '../services/storage_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _urlCtrl = TextEditingController();
  final _keyCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final List<String> _providers = ['OpenAI', 'DeepSeek', 'OpenRouter', 'Gemini', 'Claude', 'Свой API'];

  String _provider = 'OpenAI';
  bool _beginner = true;
  bool _hideKey = true;
  bool _testing = false;
  String _testMsg = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    _keyCtrl.dispose();
    _modelCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final cfg = await StorageService.getAiConfig();
    final beg = await StorageService.getBeginnerMode();
    if (!mounted) return;
    setState(() {
      _provider = _providers.contains(cfg.provider) ? cfg.provider : 'OpenAI';
      _urlCtrl.text = cfg.baseUrl;
      _keyCtrl.text = cfg.apiKey;
      _modelCtrl.text = cfg.model;
      _beginner = beg;
    });
  }

  void _applyPreset(String p) {
    setState(() {
      _provider = p;
      if (p == 'OpenAI') {
        _urlCtrl.text = 'https://api.openai.com/v1/chat/completions';
        _modelCtrl.text = 'gpt-4o-mini';
      } else if (p == 'DeepSeek') {
        _urlCtrl.text = 'https://api.deepseek.com/chat/completions';
        _modelCtrl.text = 'deepseek-chat';
      } else if (p == 'OpenRouter') {
        _urlCtrl.text = 'https://openrouter.ai/api/v1/chat/completions';
        _modelCtrl.text = 'openai/gpt-4o-mini';
      } else if (p == 'Gemini') {
        _urlCtrl.text = 'https://generativelanguage.googleapis.com';
        _modelCtrl.text = 'gemini-1.5-flash';
      } else if (p == 'Claude') {
        _urlCtrl.text = 'https://api.anthropic.com/v1/messages';
        _modelCtrl.text = 'claude-3-5-haiku-latest';
      }
    });
  }

  Future<void> _saveAi() async {
    await StorageService.saveAiConfig(AiConfig(
      provider: _provider,
      baseUrl: _urlCtrl.text.trim(),
      apiKey: _keyCtrl.text.trim(),
      model: _modelCtrl.text.trim(),
    ));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Настройки ИИ сохранены')),
    );
  }

  Future<void> _testAi() async {
    await _saveAi();
    setState(() {
      _testing = true;
      _testMsg = 'Проверяю связь...';
    });
    final res = await AiService.testConnection();
    if (!mounted) return;
    setState(() {
      _testing = false;
      _testMsg = res;
    });
  }

  Future<void> _exportData() async {
    final jsonStr = await StorageService.exportAllData();
    await Clipboard.setData(ClipboardData(text: jsonStr));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Резервная копия скопирована в буфер обмена')),
    );
  }

  Future<void> _importDialog() async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Загрузить резервную копию'),
        content: TextField(
          controller: ctrl,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Вставьте сюда сохраненный JSON-текст',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Загрузить')),
        ],
      ),
    );
    if (ok == true && ctrl.text.trim().isNotEmpty) {
      final success = await StorageService.importAllData(ctrl.text.trim());
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success ? 'Данные восстановлены!' : 'Ошибка: неверный формат данных')),
      );
    }
    ctrl.dispose();
  }

  Future<void> _shareProgress() async {
    final done = await StorageService.getCompletedLessons();
    final portfolio = await StorageService.getPortfolio();
    await Share.share(
      'Я изучаю инвестиции в приложении «Инвестор: с 0 до Профи»!\n'
      'Пройдено уроков: ${done.length}\n'
      'Бумаг в реальном портфеле: ${portfolio.length}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Настройки', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Card(
          child: SwitchListTile(
            title: const Text('Режим «Новичок»'),
            subtitle: const Text('Показывать простые подсказки к терминам и кнопкам'),
            value: _beginner,
            onChanged: (v) async {
              setState(() => _beginner = v);
              await StorageService.setBeginnerMode(v);
            },
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Подключение ИИ-инвестора', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _provider,
                  decoration: const InputDecoration(labelText: 'Провайдер ИИ', border: OutlineInputBorder()),
                  items: _providers.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                  onChanged: (v) => v != null ? _applyPreset(v) : null,
                ),
                const SizedBox(height: 10),
                if (_provider != 'Gemini' && _provider != 'Claude')
                  TextField(
                    controller: _urlCtrl,
                    decoration: const InputDecoration(labelText: 'Base URL (адрес API)', border: OutlineInputBorder()),
                  ),
                if (_provider != 'Gemini' && _provider != 'Claude') const SizedBox(height: 10),
                TextField(
                  controller: _modelCtrl,
                  decoration: const InputDecoration(labelText: 'Название модели', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _keyCtrl,
                  obscureText: _hideKey,
                  decoration: InputDecoration(
                    labelText: 'API-ключ',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_hideKey ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _hideKey = !_hideKey),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: FilledButton(onPressed: _saveAi, child: const Text('Сохранить'))),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _testing ? null : _testAi,
                        child: Text(_testing ? 'Проверка...' : 'Проверить'),
                      ),
                    ),
                  ],
                ),
                if (_testMsg.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(_testMsg, style: const TextStyle(fontSize: 13)),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Данные и прогресс', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.upload),
                  title: const Text('Выгрузить резервную копию (JSON)'),
                  onTap: _exportData,
                ),
                ListTile(
                  leading: const Icon(Icons.download),
                  title: const Text('Загрузить резервную копию (JSON)'),
                  onTap: _importDialog,
                ),
                ListTile(
                  leading: const Icon(Icons.share),
                  title: const Text('Поделиться прогрессом'),
                  onTap: _shareProgress,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
