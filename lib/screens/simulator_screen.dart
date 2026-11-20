import 'dart:math';
import 'package:flutter/material.dart';
import '../data/scenarios_repository.dart';
import '../models/app_models.dart';
import '../services/storage_service.dart';

class SimulatorScreen extends StatefulWidget {
  const SimulatorScreen({super.key});

  @override
  State<SimulatorScreen> createState() => _SimulatorScreenState();
}

class _SimulatorScreenState extends State<SimulatorScreen> {
  double _cash = 100000;
  int _month = 1;
  int _scenarioIdx = 0;
  double _lastIncome = 0;
  SimScenario? _currentScenario;
  String _feedback = 'Сформируйте стартовый портфель и нажмите «Следующий месяц».';

  late List<SimAsset> _market;
  final Map<String, int> _holdings = {};

  @override
  void initState() {
    super.initState();
    _market = _defaultMarket();
    _loadState();
  }

  List<SimAsset> _defaultMarket() => [
        SimAsset(ticker: 'OFZ-26', name: 'ОФЗ (гособлигация)', type: 'Облигация', sector: 'Госдолг', price: 950, yieldPercent: 15),
        SimAsset(ticker: 'SBER', name: 'Крупный банк', type: 'Акция', sector: 'Финансы', price: 280, yieldPercent: 12),
        SimAsset(ticker: 'LKOH', name: 'Нефтяной гигант', type: 'Акция', sector: 'Нефть и газ', price: 7000, yieldPercent: 14),
        SimAsset(ticker: 'YDEX', name: 'IT-лидер', type: 'Акция', sector: 'IT', price: 3800, yieldPercent: 2),
        SimAsset(ticker: 'X5', name: 'Продуктовая сеть', type: 'Акция', sector: 'Ритейл', price: 2900, yieldPercent: 10),
        SimAsset(ticker: 'GLDR', name: 'Золото и металлы', type: 'Металлы', sector: 'Металлы', price: 1500, yieldPercent: 0),
        SimAsset(ticker: 'TMOS', name: 'Фонд всего рынка', type: 'Фонд', sector: 'Фонды', price: 100, yieldPercent: 8),
      ];

  Future<void> _loadState() async {
    final s = await StorageService.getSimState();
    if (s.isEmpty || !mounted) return;
    setState(() {
      _cash = (s['cash'] as num?)?.toDouble() ?? 100000;
      _month = (s['month'] as num?)?.toInt() ?? 1;
      _scenarioIdx = (s['scenarioIdx'] as num?)?.toInt() ?? 0;
      if (s['holdings'] is Map) {
        _holdings.clear();
        (s['holdings'] as Map).forEach((k, v) {
          _holdings[k.toString()] = (v as num).toInt();
        });
      }
      if (s['prices'] is Map) {
        final pm = s['prices'] as Map;
        for (final a in _market) {
          if (pm[a.ticker] != null) {
            a.price = (pm[a.ticker] as num).toDouble();
          }
        }
      }
    });
  }

  Future<void> _saveState() async {
    await StorageService.saveSimState({
      'cash': _cash,
      'month': _month,
      'scenarioIdx': _scenarioIdx,
      'holdings': _holdings,
      'prices': {for (final a in _market) a.ticker: a.price},
    });
  }

  double get _assetsValue => _market.fold(
      0.0, (sum, a) => sum + ((_holdings[a.ticker] ?? 0) * a.price));

  double get _totalCapital => _cash + _assetsValue;

  void _buy(SimAsset a) {
    if (_cash < a.price) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Недостаточно свободных денег')),
      );
      return;
    }
    setState(() {
      _cash -= a.price;
      _holdings[a.ticker] = (_holdings[a.ticker] ?? 0) + 1;
    });
    _saveState();
  }

  void _sell(SimAsset a) {
    final qty = _holdings[a.ticker] ?? 0;
    if (qty <= 0) return;
    setState(() {
      _cash += a.price;
      _holdings[a.ticker] = qty - 1;
    });
    _saveState();
  }

  void _nextMonth() {
    final scenarios = ScenariosRepository.allScenarios;
    final sc = scenarios[_scenarioIdx % scenarios.length];
    final rnd = Random();
    double income = 0;

    setState(() {
      _month++;
      _scenarioIdx++;
      _currentScenario = sc;

      for (final a in _market) {
        final qty = _holdings[a.ticker] ?? 0;
        if (qty > 0 && a.yieldPercent > 0) {
          income += (qty * a.price) * (a.yieldPercent / 100 / 12);
        }
        final impact = sc.sectorImpacts[a.sector] ?? 0.0;
        final noise = (rnd.nextDouble() - 0.5) * 0.02;
        a.price = max(10, a.price * (1 + impact + noise));
      }

      _cash += income;
      _lastIncome = income;
      _feedback = _evaluatePortfolio();
    });
    _saveState();
  }

  String _evaluatePortfolio() {
    final total = _totalCapital;
    if (_assetsValue == 0) {
      return 'Вы держите 100% в наличных — инфляция постепенно обесценивает деньги. Попробуйте купить ОФЗ или фонд рынка.';
    }
    final ownedCount = _holdings.values.where((v) => v > 0).length;
    final cashShare = _cash / total;
    if (ownedCount == 1) {
      return 'Риск: все вложения в одной бумаге! Добавьте активы из других отраслей и облигации для защиты.';
    }
    if (cashShare < 0.05) {
      return 'У вас почти не осталось свободного кэша — при просадке рынка будет не на что докупить бумаги со скидкой.';
    }
    return 'Хороший баланс: активы распределены по $ownedCount бумагам, есть запас кэша (${(cashShare * 100).toStringAsFixed(0)}%).';
  }

  Future<void> _reset() async {
    setState(() {
      _cash = 100000;
      _month = 1;
      _scenarioIdx = 0;
      _lastIncome = 0;
      _currentScenario = null;
      _holdings.clear();
      _market = _defaultMarket();
      _feedback = 'Симулятор сброшен. Сформируйте новый портфель.';
    });
    await _saveState();
  }

  @override
  Widget build(BuildContext context) {
    final total = _totalCapital;
    final profit = total - 100000;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Симулятор • Месяц $_month', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            IconButton(tooltip: 'Сбросить', icon: const Icon(Icons.restart_alt), onPressed: _reset),
          ],
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Капитал: ${total.toStringAsFixed(0)} ₽ (${profit >= 0 ? '+' : ''}${profit.toStringAsFixed(0)} ₽)',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: profit >= 0 ? Colors.green : Colors.red)),
                const SizedBox(height: 4),
                Text('Свободные деньги: ${_cash.toStringAsFixed(0)} ₽ • Бумаги: ${_assetsValue.toStringAsFixed(0)} ₽'),
                if (_lastIncome > 0)
                  Text('Купоны и дивиденды за месяц: +${_lastIncome.toStringAsFixed(0)} ₽',
                      style: const TextStyle(fontSize: 12, color: Colors.green)),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _nextMonth,
                    icon: const Icon(Icons.fast_forward),
                    label: const Text('Следующий месяц (перемотать время)'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          color: Colors.amber.withOpacity(0.12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text('Оценка портфеля: $_feedback', style: const TextStyle(fontSize: 13)),
          ),
        ),
        if (_currentScenario != null) ...[
          const SizedBox(height: 8),
          Card(
            color: Colors.blue.withOpacity(0.08),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Событие (${_currentScenario!.category}): ${_currentScenario!.title}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(_currentScenario!.newsText),
                  const Divider(height: 16),
                  Text('Как правильно: ${_currentScenario!.rightAction}',
                      style: const TextStyle(fontSize: 13, color: Colors.green, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('Разбор ошибки: ${_currentScenario!.mistakeAnalysis}',
                      style: const TextStyle(fontSize: 13, color: Colors.redAccent)),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        const Text('Рынок ценных бумаг', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        ..._market.map((a) {
          final qty = _holdings[a.ticker] ?? 0;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text('${a.ticker} — ${a.name}', style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('${a.type} • ${a.sector} • Цена: ${a.price.toStringAsFixed(0)} ₽ • В портфеле: $qty шт.'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                    onPressed: qty > 0 ? () => _sell(a) : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                    onPressed: () => _buy(a),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
