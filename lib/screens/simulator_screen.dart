import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../data/scenarios_repository.dart';

class _SimPosition {
  final String ticker;
  int quantity;
  double avgBuyPrice;

  _SimPosition({
    required this.ticker,
    required this.quantity,
    required this.avgBuyPrice,
  });

  _SimPosition copy() => _SimPosition(
        ticker: ticker,
        quantity: quantity,
        avgBuyPrice: avgBuyPrice,
      );
}

class _TurnTrade {
  final String ticker;
  final String assetName;
  final String sector;
  final bool isBuy;
  final int quantity;
  final double price;

  const _TurnTrade({
    required this.ticker,
    required this.assetName,
    required this.sector,
    required this.isBuy,
    required this.quantity,
    required this.price,
  });
}

class _SimSnapshot {
  final int scenarioIndex;
  final double cash;
  final Map<String, _SimPosition> positions;
  final Map<String, double> prices;

  _SimSnapshot({
    required this.scenarioIndex,
    required this.cash,
    required this.positions,
    required this.prices,
  });
}

class SimulatorScreen extends StatefulWidget {
  const SimulatorScreen({super.key});

  @override
  State<SimulatorScreen> createState() => _SimulatorScreenState();
}

class _SimulatorScreenState extends State<SimulatorScreen> {
  static const double _initialCash = 100000.0;

  late List<SimScenario> _scenarios;
  late List<SimAsset> _assets;

  int _scenarioIndex = 0;
  double _cash = _initialCash;
  Map<String, _SimPosition> _positions = {};

  final List<_SimSnapshot> _history = [];
  final List<_TurnTrade> _currentTurnTrades = [];

  String _selectedTicker = 'SBER';
  int _tradeQty = 1;

  bool _turnResolved = false;
  List<String> _evaluationNotes = [];
  Map<String, double> _lastPriceChanges = {};

  @override
  void initState() {
    super.initState();
    _scenarios = ScenariosRepository.allScenarios;
    _initDefaultState();
  }

  void _initDefaultState() {
    _assets = [
      SimAsset(ticker: 'SBER', name: 'Сбербанк', type: 'Акция', sector: 'Банки', price: 300.0, yieldPercent: 11.0),
      SimAsset(ticker: 'LKOH', name: 'Лукойл', type: 'Акция', sector: 'Нефть и газ', price: 7200.0, yieldPercent: 13.0),
      SimAsset(ticker: 'YDEX', name: 'Яндекс', type: 'Акция', sector: 'IT', price: 4000.0, yieldPercent: 2.0),
      SimAsset(ticker: 'X5', name: 'X5 Group', type: 'Акция', sector: 'Ритейл', price: 2800.0, yieldPercent: 8.0),
      SimAsset(ticker: 'CHMF', name: 'Северсталь', type: 'Акция', sector: 'Металлургия', price: 1500.0, yieldPercent: 12.0),
      SimAsset(ticker: 'OFZ', name: 'ОФЗ 26238', type: 'Облигация', sector: 'Облигации', price: 1000.0, yieldPercent: 14.0),
      SimAsset(ticker: 'GLD', name: 'Золото БПИФ', type: 'Фонд', sector: 'Золото', price: 100.0, yieldPercent: 0.0),
      SimAsset(ticker: 'LQDT', name: 'Денежный рынок', type: 'Фонд', sector: 'Денежный рынок', price: 100.0, yieldPercent: 18.0),
    ];
    _scenarioIndex = 0;
    _cash = _initialCash;
    _positions = {};
    _history.clear();
    _currentTurnTrades.clear();
    _selectedTicker = _assets.first.ticker;
    _tradeQty = 1;
    _turnResolved = false;
    _evaluationNotes = [];
    _lastPriceChanges = {};
  }

  SimAsset _assetByTicker(String ticker) {
    return _assets.firstWhere((a) => a.ticker == ticker, orElse: () => _assets.first);
  }

  double get _portfolioAssetsValue {
    double sum = 0.0;
    for (final pos in _positions.values) {
      sum += pos.quantity * _assetByTicker(pos.ticker).price;
    }
    return sum;
  }

  double get _totalCapital => _cash + _portfolioAssetsValue;

  _SimSnapshot _createSnapshot() {
    final posCopy = <String, _SimPosition>{};
    _positions.forEach((k, v) => posCopy[k] = v.copy());
    final priceCopy = <String, double>{};
    for (final a in _assets) {
      priceCopy[a.ticker] = a.price;
    }
    return _SimSnapshot(
      scenarioIndex: _scenarioIndex,
      cash: _cash,
      positions: posCopy,
      prices: priceCopy,
    );
  }

  void _rewindOneStep() {
    if (_history.isEmpty) return;
    final prev = _history.removeLast();
    setState(() {
      _scenarioIndex = prev.scenarioIndex;
      _cash = prev.cash;
      _positions = prev.positions;
      for (final a in _assets) {
        if (prev.prices.containsKey(a.ticker)) {
          a.price = prev.prices[a.ticker]!;
        }
      }
      _currentTurnTrades.clear();
      _turnResolved = false;
      _evaluationNotes = [];
      _lastPriceChanges = {};
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Перемотка назад: возврат к ходу ${_scenarioIndex + 1}')),
    );
  }

  Future<void> _confirmReset() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Обнулить портфель?'),
        content: const Text(
          'Все текущие позиции, история ходов и результаты будут сброшены к стартовым 100 000 ₽ и 1-му сценарию.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Обнулить'),
          ),
        ],
      ),
    );
    if (ok == true) {
      setState(() {
        _initDefaultState();
      });
    }
  }

  void _executeTrade(bool isBuy) {
    if (_turnResolved) return;
    final asset = _assetByTicker(_selectedTicker);
    if (_tradeQty <= 0) return;

    if (isBuy) {
      final cost = asset.price * _tradeQty;
      if (cost > _cash + 0.01) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Недостаточно свободных денег для покупки')),
        );
        return;
      }
      setState(() {
        _cash -= cost;
        final existing = _positions[asset.ticker];
        if (existing == null) {
          _positions[asset.ticker] = _SimPosition(
            ticker: asset.ticker,
            quantity: _tradeQty,
            avgBuyPrice: asset.price,
          );
        } else {
          final totalCost = existing.avgBuyPrice * existing.quantity + cost;
          existing.quantity += _tradeQty;
          existing.avgBuyPrice = totalCost / existing.quantity;
        }
        _currentTurnTrades.add(_TurnTrade(
          ticker: asset.ticker,
          assetName: asset.name,
          sector: asset.sector,
          isBuy: true,
          quantity: _tradeQty,
          price: asset.price,
        ));
      });
    } else {
      final existing = _positions[asset.ticker];
      if (existing == null || existing.quantity < _tradeQty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('У вас нет такого количества бумаг для продажи')),
        );
        return;
      }
      setState(() {
        final revenue = asset.price * _tradeQty;
        _cash += revenue;
        existing.quantity -= _tradeQty;
        if (existing.quantity <= 0) {
          _positions.remove(asset.ticker);
        }
        _currentTurnTrades.add(_TurnTrade(
          ticker: asset.ticker,
          assetName: asset.name,
          sector: asset.sector,
          isBuy: false,
          quantity: _tradeQty,
          price: asset.price,
        ));
      });
    }
  }

  double _impactForAsset(SimAsset asset, Map<String, double> impacts) {
    if (impacts.containsKey(asset.sector)) {
      return impacts[asset.sector]!;
    }
    final secLower = asset.sector.toLowerCase();
    for (final entry in impacts.entries) {
      final keyLower = entry.key.toLowerCase();
      if (keyLower == secLower ||
          secLower.contains(keyLower) ||
          keyLower.contains(secLower)) {
        return entry.value;
      }
      if ((keyLower.contains('акц') || keyLower.contains('рынок') || keyLower.contains('все')) &&
          asset.type == 'Акция') {
        return entry.value;
      }
      if (keyLower.contains('офз') && asset.ticker == 'OFZ') {
        return entry.value;
      }
      if (keyLower.contains('золот') && asset.ticker == 'GLD') {
        return entry.value;
      }
    }
    return 0.0;
  }

  void _resolveTurn() {
    if (_scenarios.isEmpty || _turnResolved) return;
    final scenario = _scenarios[_scenarioIndex];

    // Сохраняем состояние ДО реакции рынка, чтобы «Назад» возвращал к этому ходу
    _history.add(_createSnapshot());

    final changes = <String, double>{};
    for (final asset in _assets) {
      final pct = _impactForAsset(asset, scenario.sectorImpacts);
      changes[asset.ticker] = pct;
      if (pct != 0.0) {
        asset.price = (asset.price * (1 + pct / 100.0)).clamp(1.0, 1000000.0);
      }
    }

    final notes = <String>[];
    if (_currentTurnTrades.isEmpty) {
      notes.add(
        '🟡 Вы выбрали тактику «Держать / Без сделок». Отсутствие паники часто спасает от убытков на рыночном шуме, но сверьтесь ниже, не упустили ли вы возможность докупить сильный актив или защитить портфель.',
      );
    } else {
      for (final t in _currentTurnTrades) {
        final pct = changes[t.ticker] ?? 0.0;
        final pctStr = '${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(1)}%';
        if (t.isBuy) {
          if (pct > 0.5) {
            notes.add(
              '✅ Отличная покупка ${t.assetName} (${t.quantity} шт.): сектор «${t.sector}» выиграл от новости ($pctStr). Вы точно определили бенефициара!',
            );
          } else if (pct < -0.5) {
            notes.add(
              '❌ Ошибка входа в ${t.assetName} (${t.quantity} шт.): новость ударила по сектору «${t.sector}» ($pctStr). Покупать против негативного импульса лучше позже, когда падение остановится.',
            );
          } else {
            notes.add(
              'ℹ️ Нейтральная покупка ${t.assetName} (${t.quantity} шт.): новость почти не задела сектор «${t.sector}» ($pctStr). Спокойная диверсификация.',
            );
          }
        } else {
          if (pct < -0.5) {
            notes.add(
              '✅ Грамотная продажа ${t.assetName} (${t.quantity} шт.): вы вовремя сократили риск перед падением сектора «${t.sector}» ($pctStr).',
            );
          } else if (pct > 0.5) {
            notes.add(
              '❌ Поспешная продажа ${t.assetName} (${t.quantity} шт.): сектор «${t.sector}» вырос на этой новости ($pctStr). Вы зафиксировали выход слишком рано.',
            );
          } else {
            notes.add(
              'ℹ️ Нейтральная продажа ${t.assetName} (${t.quantity} шт.): сектор «${t.sector}» остался стабилен ($pctStr). Вы высвободили кэш.',
            );
          }
        }
      }
    }

    setState(() {
      _lastPriceChanges = changes;
      _evaluationNotes = notes;
      _turnResolved = true;
    });
  }

  void _nextScenario() {
    setState(() {
      if (_scenarioIndex < _scenarios.length - 1) {
        _scenarioIndex++;
      } else {
        _scenarioIndex = 0;
      }
      _currentTurnTrades.clear();
      _turnResolved = false;
      _evaluationNotes = [];
      _lastPriceChanges = {};
    });
  }

  String _fmt(double value) => '${value.toStringAsFixed(0)} ₽';

  @override
  Widget build(BuildContext context) {
    if (_scenarios.isEmpty) {
      return const Center(child: Text('Сценарии не загружены'));
    }

    final scenario = _scenarios[_scenarioIndex];
    final totalProfit = _totalCapital - _initialCash;
    final totalProfitPct = (totalProfit / _initialCash) * 100.0;
    final selectedAsset = _assetByTicker(_selectedTicker);
    final ownedSelectedQty = _positions[_selectedTicker]?.quantity ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text('Симулятор • Ход ${_scenarioIndex + 1}/${_scenarios.length}'),
        actions: [
          IconButton(
            tooltip: 'Перемотать назад',
            onPressed: _history.isEmpty ? null : _rewindOneStep,
            icon: const Icon(Icons.history),
          ),
          IconButton(
            tooltip: 'Обнулить портфель',
            onPressed: _confirmReset,
            icon: const Icon(Icons.restart_alt),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // 1. Сводка капитала
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _metricCol('Капитал', _fmt(_totalCapital), Colors.blue),
                  _metricCol('Свободно', _fmt(_cash), Colors.teal),
                  _metricCol(
                    'Результат',
                    '${totalProfit >= 0 ? '+' : ''}${_fmt(totalProfit)} (${totalProfitPct >= 0 ? '+' : ''}${totalProfitPct.toStringAsFixed(1)}%)',
                    totalProfit >= 0 ? Colors.green : Colors.red,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // 2. Таблица портфеля
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📊 Ваш портфель',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (_positions.isEmpty)
                    const Text(
                      'Портфель пока пуст. Купите бумаги ниже в ответ на новость или держите кэш.',
                      style: TextStyle(color: Colors.grey),
                    )
                  else
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columnSpacing: 16,
                        headingRowHeight: 36,
                        dataRowMinHeight: 36,
                        dataRowMaxHeight: 44,
                        columns: const [
                          DataColumn(label: Text('Бумага')),
                          DataColumn(label: Text('Кол-во'), numeric: true),
                          DataColumn(label: Text('Покупка'), numeric: true),
                          DataColumn(label: Text('Сейчас'), numeric: true),
                          DataColumn(label: Text('Стоимость'), numeric: true),
                          DataColumn(label: Text('Прибыль / Убыток'), numeric: true),
                        ],
                        rows: _positions.values.map((pos) {
                          final asset = _assetByTicker(pos.ticker);
                          final value = pos.quantity * asset.price;
                          final pnl = (asset.price - pos.avgBuyPrice) * pos.quantity;
                          final pnlPct = pos.avgBuyPrice > 0
                              ? ((asset.price - pos.avgBuyPrice) / pos.avgBuyPrice) * 100.0
                              : 0.0;
                          final color = pnl >= 0 ? Colors.green : Colors.red;

                          return DataRow(cells: [
                            DataCell(Text('${asset.ticker} (${asset.name})')),
                            DataCell(Text('${pos.quantity}')),
                            DataCell(Text(_fmt(pos.avgBuyPrice))),
                            DataCell(Text(_fmt(asset.price))),
                            DataCell(Text(_fmt(value))),
                            DataCell(Text(
                              '${pnl >= 0 ? '+' : ''}${_fmt(pnl)} (${pnlPct >= 0 ? '+' : ''}${pnlPct.toStringAsFixed(1)}%)',
                              style: TextStyle(color: color, fontWeight: FontWeight.bold),
                            )),
                          ]);
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // 3. Новость из сценария
          Card(
            color: Colors.indigo.withOpacity(0.08),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Chip(
                        label: Text(scenario.category, style: const TextStyle(fontSize: 12)),
                        visualDensity: VisualDensity.compact,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          scenario.title,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(scenario.newsText, style: const TextStyle(fontSize: 15, height: 1.4)),
                  const SizedBox(height: 10),
                  const Text(
                    '❓ Что делаем в ответ на эту новость?',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // 4. Панель выбора действий (покупка / продажа)
          if (!_turnResolved)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<String>(
                      value: _selectedTicker,
                      decoration: const InputDecoration(
                        labelText: 'Выберите бумагу',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: _assets.map((a) {
                        final qty = _positions[a.ticker]?.quantity ?? 0;
                        return DropdownMenuItem(
                          value: a.ticker,
                          child: Text(
                            '${a.ticker} • ${a.name} (${a.sector}) — ${_fmt(a.price)}${qty > 0 ? ' [есть: $qty]' : ''}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _selectedTicker = v);
                      },
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Text('Кол-во: '),
                        IconButton(
                          onPressed: _tradeQty > 1 ? () => setState(() => _tradeQty--) : null,
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                        Text('$_tradeQty', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        IconButton(
                          onPressed: () => setState(() => _tradeQty++),
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                        const Spacer(),
                        Text(
                          'Сумма: ${_fmt(selectedAsset.price * _tradeQty)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _executeTrade(true),
                            icon: const Icon(Icons.shopping_cart),
                            label: const Text('Купить'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: ownedSelectedQty > 0 ? () => _executeTrade(false) : null,
                            icon: const Icon(Icons.sell),
                            label: const Text('Продать'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_currentTurnTrades.isNotEmpty) ...[
                      const Divider(height: 20),
                      const Text('Сделки на этом ходу:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      ..._currentTurnTrades.map((t) => Text(
                            '• ${t.isBuy ? 'Куплено' : 'Продано'}: ${t.assetName} × ${t.quantity} по ${_fmt(t.price)}',
                            style: TextStyle(color: t.isBuy ? Colors.green[800] : Colors.red[800]),
                          )),
                    ],
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _resolveTurn,
                        icon: const Icon(Icons.check_circle),
                        label: Text(
                          _currentTurnTrades.isEmpty
                              ? 'Держать без сделок → Узнать реакцию рынка'
                              : 'Применить решение → Узнать реакцию рынка',
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // 5. Подробная оценка действий и разбор ошибок
          if (_turnResolved)
            Card(
              color: Colors.amber.withOpacity(0.10),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📋 Оценка ваших действий',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ..._evaluationNotes.map((note) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(note, style: const TextStyle(fontSize: 14, height: 1.35)),
                        )),
                    const Divider(height: 20),
                    const Text(
                      '📈 Реакция бумаг на новость:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _assets.map((a) {
                        final pct = _lastPriceChanges[a.ticker] ?? 0.0;
                        final col = pct > 0
                            ? Colors.green
                            : (pct < 0 ? Colors.red : Colors.grey);
                        return Chip(
                          visualDensity: VisualDensity.compact,
                          label: Text(
                            '${a.ticker}: ${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(1)}%',
                            style: TextStyle(color: col, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        );
                      }).toList(),
                    ),
                    const Divider(height: 20),
                    const Text(
                      '🟢 Как действует Профи:',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                    const SizedBox(height: 4),
                    Text(scenario.rightAction, style: const TextStyle(fontSize: 14, height: 1.4)),
                    const SizedBox(height: 10),
                    const Text(
                      '🔴 Разбор частых ошибок:',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                    ),
                    const SizedBox(height: 4),
                    Text(scenario.mistakeAnalysis, style: const TextStyle(fontSize: 14, height: 1.4)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _rewindOneStep,
                            icon: const Icon(Icons.replay),
                            label: const Text('Переиграть ход'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _nextScenario,
                            icon: const Icon(Icons.arrow_forward),
                            label: const Text('Следующая новость'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _metricCol(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}
