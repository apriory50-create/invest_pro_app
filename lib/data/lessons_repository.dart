import '../models/app_models.dart';
import 'lessons_part1.dart';
import 'lessons_part2.dart';
import 'lessons_part3.dart';
import 'lessons_part4.dart';
import 'lessons_part5.dart';
import 'lessons_part6.dart';
import 'lessons_part7.dart';
import 'lessons_part8.dart';
import 'lessons_part9.dart';

class LessonsRepository {
  static List<Lesson> get allLessons => [
        ...lessonsPart1,
        ...lessonsPart2,
        ...lessonsPart3,
        ...lessonsPart4,
        ...lessonsPart5,
        ...lessonsPart6,
        ...lessonsPart7,
        ...lessonsPart8,
        ...lessonsPart9,
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

