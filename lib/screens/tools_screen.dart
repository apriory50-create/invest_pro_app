import 'dart:math';
import 'package:flutter/material.dart';
import '../models/app_models.dart';

class ToolsScreen extends StatefulWidget {
  const ToolsScreen({super.key});

  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen> {
  String _search = '';
  final List<bool> _checks = [false, false, false, false, false];

  final _startCtrl = TextEditingController(text: '100000');
  final _monthCtrl = TextEditingController(text: '10000');
  final _rateCtrl = TextEditingController(text: '15');
  final _yearsCtrl = TextEditingController(text: '10');

  static const List<GlossaryTerm> _terms = [
    GlossaryTerm(term: 'Акция', definition: 'Доля в бизнесе компании. Вы становитесь совладельцем.', example: 'Купили акцию магазина — получаете часть его прибыли в виде дивидендов.'),
    GlossaryTerm(term: 'Облигация', definition: 'Долговая расписка. Вы даете деньги в долг компании или государству под процент.', example: 'ОФЗ — вы заняли государству 1000 ₽ и получаете купоны 2 раза в год.'),
    GlossaryTerm(term: 'Дивиденды', definition: 'Часть чистой прибыли, которую компания раздает акционерам.', example: 'Компания заработала 100 ₽ на акцию и решила выплатить 50 ₽ владельцам.'),
    GlossaryTerm(term: 'НКД', definition: 'Накопленный купонный доход по облигации за дни с последней выплаты.', example: 'Если продать облигацию в середине срока, покупатель вернет вам НКД за ваши дни.'),
    GlossaryTerm(term: 'Дивидендный гэп', definition: 'Падение цены акции на размер дивиденда на следующий день после отсечки.', example: 'Акция стоила 100 ₽, дивиденд 10 ₽ — на утро цена откроется около 90 ₽.'),
    GlossaryTerm(term: 'Ликвидность', definition: 'Насколько быстро бумагу можно продать по рыночной цене.', example: 'Акции крупных банков продаются за секунду, а редкие облигации — часами.'),
    GlossaryTerm(term: 'Волатильность', definition: 'Сила колебания цены вверх и вниз за короткий срок.', example: 'У акций цена может скакать на 5% в день, у коротких ОФЗ — на 0.1%.'),
    GlossaryTerm(term: 'Диверсификация', definition: 'Распределение денег по разным активам и отраслям для снижения риска.', example: 'Не класть все деньги в одну компанию, а купить акции, облигации и фонды.'),
    GlossaryTerm(term: 'P/E', definition: 'За сколько лет компания окупит свою текущую цену текущей прибылью.', example: 'P/E = 5 означает, что бизнес стоит 5 своих годовых прибылей (дешево).'),
    GlossaryTerm(term: 'Дюрация', definition: 'Срок возврата вложений в облигацию. Чем она выше, тем сильнее цена реагирует на ставку ЦБ.', example: 'При росте ставки ЦБ длинные ОФЗ падают сильнее коротких.'),
    GlossaryTerm(term: 'Оферта', definition: 'Право или обязанность погасить облигацию досрочно в указанную дату.', example: 'Перед офертой эмитент может снизить купон до 0.1% — нужно следить за датой.'),
    GlossaryTerm(term: 'БПИФ / ETF', definition: 'Готовая корзина из десятков ценных бумаг в одной покупке.', example: 'Купили 1 пай фонда на индекс Мосбиржи — и сразу владеете 40 компаниями.'),
  ];

  static const List<String> _filters = [
    '1. Я понимаю, как компания зарабатывает деньги и откуда берет прибыль.',
    '2. У компании нет критических долгов, и ее выручка не падает из года в год.',
    '3. Я покупаю не на эмоциях («все берут»), а по понятной цене и цели.',
    '4. Эта бумага не займет больше 10–15% от моего портфеля.',
    '5. Я знаю, что буду делать, если завтра цена упадет на 20%.',
  ];

  @override
  void dispose() {
    _startCtrl.dispose();
    _monthCtrl.dispose();
    _rateCtrl.dispose();
    _yearsCtrl.dispose();
    super.dispose();
  }

  Widget _buildGlossary() {
    final q = _search.trim().toLowerCase();
    final list = _terms.where((t) {
      return t.term.toLowerCase().contains(q) || t.definition.toLowerCase().contains(q);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Поиск термина (например, НКД или гэп)...',
              border: OutlineInputBorder(),
            ),
            onChanged: (v) => setState(() => _search = v),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: list.length,
            itemBuilder: (ctx, i) {
              final t = list[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.term, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(t.definition),
                      const SizedBox(height: 4),
                      Text('Пример: ${t.example}', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildChecklist() {
    final passed = _checks.where((c) => c).length;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('5 фильтров перед покупкой', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        const Text('Отметьте пункты перед сделкой, чтобы не купить плохую бумагу на эмоциях.'),
        const SizedBox(height: 12),
        ...List.generate(_filters.length, (i) {
          return Card(
            child: CheckboxListTile(
              title: Text(_filters[i]),
              value: _checks[i],
              onChanged: (v) => setState(() => _checks[i] = v ?? false),
            ),
          );
        }),
        const SizedBox(height: 12),
        Card(
          color: passed == 5 ? Colors.green.withOpacity(0.15) : Colors.orange.withOpacity(0.15),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Text(
              passed == 5
                  ? 'Отлично! Все 5 фильтров пройдены — решение взвешенное.'
                  : 'Пройдено $passed из 5. Не торопитесь с покупкой, пока не проверите все пункты.',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => setState(() {
            for (var i = 0; i < _checks.length; i++) {
              _checks[i] = false;
            }
          }),
          child: const Text('Сбросить чек-лист'),
        ),
      ],
    );
  }

  Widget _buildCalculator() {
    final start = double.tryParse(_startCtrl.text.replaceAll(',', '.')) ?? 0;
    final month = double.tryParse(_monthCtrl.text.replaceAll(',', '.')) ?? 0;
    final rate = (double.tryParse(_rateCtrl.text.replaceAll(',', '.')) ?? 0) / 100;
    final years = int.tryParse(_yearsCtrl.text) ?? 0;

    final months = years * 12;
    final rMonth = rate / 12;
    double total = start;
    if (months > 0) {
      if (rMonth > 0) {
        final factor = pow(1 + rMonth, months).toDouble();
        total = start * factor + month * ((factor - 1) / rMonth);
      } else {
        total = start + month * months;
      }
    }
    final invested = start + month * months;
    final profit = total - invested;
    final passiveMonth = (total * rate) / 12;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Калькулятор сложного процента', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        TextField(controller: _startCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Стартовая сумма (₽)', border: OutlineInputBorder()), onChanged: (_) => setState(() {})),
        const SizedBox(height: 10),
        TextField(controller: _monthCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Пополнение в месяц (₽)', border: OutlineInputBorder()), onChanged: (_) => setState(() {})),
        const SizedBox(height: 10),
        TextField(controller: _rateCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Ожидаемая доходность (% годовых)', border: OutlineInputBorder()), onChanged: (_) => setState(() {})),
        const SizedBox(height: 10),
        TextField(controller: _yearsCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Срок (лет)', border: OutlineInputBorder()), onChanged: (_) => setState(() {})),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Итоговый капитал: ${total.toStringAsFixed(0)} ₽', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text('Вложено своих денег: ${invested.toStringAsFixed(0)} ₽'),
                Text('Заработано процентами: ${profit.toStringAsFixed(0)} ₽'),
                const Divider(height: 20),
                Text('Пассивный доход в месяц: ~${passiveMonth.toStringAsFixed(0)} ₽', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Инструменты инвестора'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Словарь'),
              Tab(text: '5 фильтров'),
              Tab(text: 'Калькулятор'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildGlossary(),
            _buildChecklist(),
            _buildCalculator(),
          ],
        ),
      ),
    );
  }
}
