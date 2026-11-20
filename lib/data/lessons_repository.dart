import '../models/app_models.dart';
import 'lessons_part1.dart';
import 'lessons_part2.dart';
import 'lessons_part3.dart';
import 'lessons_part4.dart';
import 'lessons_part5.dart';

class LessonsRepository {
  static List<Lesson> get allLessons => [
        ...lessonsPart1,
        ...lessonsPart2,
        ...lessonsPart3,
        ...lessonsPart4,
        ...lessonsPart5,
      ];

  static List<String> get modules {
    final seen = <String>{};
    final result = <String>[];
    for (final l in allLessons) {
      if (seen.add(l.moduleTitle)) {
        result.add(l.moduleTitle);
      }
    }
    return result;
  }
}
