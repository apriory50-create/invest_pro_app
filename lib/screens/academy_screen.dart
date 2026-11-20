import 'package:flutter/material.dart';
import '../data/lessons_repository.dart';
import '../models/app_models.dart';
import '../services/storage_service.dart';
import 'tools_screen.dart';

class AcademyScreen extends StatefulWidget {
  const AcademyScreen({super.key});

  @override
  State<AcademyScreen> createState() => _AcademyScreenState();
}

class _AcademyScreenState extends State<AcademyScreen> {
  Set<int> _completed = {};
  String _selectedModule = 'Все';
  String _search = '';
  bool _beginner = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final done = await StorageService.getCompletedLessons();
    final beg = await StorageService.getBeginnerMode();
    if (!mounted) return;
    setState(() {
      _completed = done;
      _beginner = beg;
    });
  }

  Future<void> _openLesson(Lesson lesson) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _LessonDetailScreen(
          lesson: lesson,
          isCompleted: _completed.contains(lesson.id),
        ),
      ),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final all = LessonsRepository.allLessons;
    final modules = ['Все', ...LessonsRepository.modules];
    final q = _search.trim().toLowerCase();

    final filtered = all.where((l) {
      final matchMod = _selectedModule == 'Все' || l.moduleTitle == _selectedModule;
      final matchQ = q.isEmpty ||
          l.title.toLowerCase().contains(q) ||
          l.content.toLowerCase().contains(q) ||
          l.category.toLowerCase().contains(q);
      return matchMod && matchQ;
    }).toList();

    final progress = all.isEmpty ? 0.0 : _completed.length / all.length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 6),
          child: Row(
            children: [
              const Expanded(
                child: Text('Академия', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              ),
              FilledButton.tonalIcon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ToolsScreen()),
                ),
                icon: const Icon(Icons.build_outlined, size: 18),
                label: const Text('Инструменты'),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LinearProgressIndicator(value: progress, minHeight: 8, borderRadius: BorderRadius.circular(4)),
              const SizedBox(height: 4),
              Text(
                'Пройдено ${_completed.length} из ${all.length} уроков (${(progress * 100).toStringAsFixed(0)}%)',
                style: const TextStyle(fontSize: 12),
              ),
              if (_beginner)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text(
                    'Подсказка: читайте уроки по порядку и проходите тест в конце каждого урока.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
          child: TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Поиск по урокам и категориям...',
              isDense: true,
              border: OutlineInputBorder(),
            ),
            onChanged: (v) => setState(() => _search = v),
          ),
        ),
        SizedBox(
          height: 40,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: modules.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (ctx, i) {
              final m = modules[i];
              return ChoiceChip(
                label: Text(m),
                selected: _selectedModule == m,
                onSelected: (_) => setState(() => _selectedModule = m),
              );
            },
          ),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
            itemCount: filtered.length,
            itemBuilder: (ctx, i) {
              final l = filtered[i];
              final done = _completed.contains(l.id);
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(
                    done ? Icons.check_circle : Icons.menu_book_outlined,
                    color: done ? Colors.green : null,
                  ),
                  title: Text(l.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('${l.category} • ~${l.readingTimeMinutes} мин', style: const TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _openLesson(l),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _LessonDetailScreen extends StatefulWidget {
  final Lesson lesson;
  final bool isCompleted;

  const _LessonDetailScreen({required this.lesson, required this.isCompleted});

  @override
  State<_LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<_LessonDetailScreen> {
  late bool _done;
  int? _selectedOption;

  @override
  void initState() {
    super.initState();
    _done = widget.isCompleted;
  }

  Future<void> _toggleDone() async {
    await StorageService.toggleLesson(widget.lesson.id);
    if (!mounted) return;
    setState(() => _done = !_done);
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.lesson;
    final answered = _selectedOption != null;
    final isCorrect = _selectedOption == l.correctOptionIndex;

    return Scaffold(
      appBar: AppBar(title: Text(l.moduleTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          children: [
            Text(l.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('${l.category} • Время чтения: ~${l.readingTimeMinutes} мин',
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 14),
            Text(l.content.trim(), style: const TextStyle(fontSize: 15, height: 1.5)),
            const SizedBox(height: 16),
            if (l.keyRules.isNotEmpty)
              Card(
                color: Colors.blue.withOpacity(0.08),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Главные правила урока:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 8),
                      ...l.keyRules.map((r) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text('• $r', style: const TextStyle(fontSize: 14)),
                          )),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            const Text('Проверка понимания:', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(l.question, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            ...List.generate(l.options.length, (i) {
              return Card(
                child: RadioListTile<int>(
                  value: i,
                  groupValue: _selectedOption,
                  title: Text(l.options[i]),
                  onChanged: (v) => setState(() => _selectedOption = v),
                ),
              );
            }),
            if (answered) ...[
              const SizedBox(height: 8),
              Card(
                color: isCorrect ? Colors.green.withOpacity(0.15) : Colors.red.withOpacity(0.15),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    isCorrect ? 'Верно! ${l.explanation}' : 'Не совсем. ${l.explanation}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _toggleDone,
                icon: Icon(_done ? Icons.check_circle : Icons.done),
                label: Text(_done ? 'Урок пройден (нажмите для отмены)' : 'Отметить урок как пройденный'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

