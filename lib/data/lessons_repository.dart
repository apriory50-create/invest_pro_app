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
import 'lessons_part10.dart';
import 'lessons_part11.dart';
import 'lessons_part12.dart';
import 'lessons_part13.dart';
import 'lessons_part14.dart';
import 'lessons_part15.dart';
import 'lessons_part16.dart';
import 'lessons_part17.dart';
import 'lessons_part18.dart';
import 'lessons_part19.dart';
import 'lessons_part20.dart';
import 'lessons_part21.dart';
import 'lessons_part22.dart';
import 'lessons_part23.dart';
import 'lessons_part24.dart';
import 'lessons_part25.dart';
import 'lessons_part26.dart';
import 'lessons_part27.dart';
import 'lessons_part28.dart';
import 'lessons_part29.dart';
import 'lessons_part30.dart';
import 'lessons_part31.dart';
import 'lessons_part32.dart';

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
        ...lessonsPart10,
        ...lessonsPart11,
        ...lessonsPart12,
        ...lessonsPart13,
        ...lessonsPart14,
        ...lessonsPart15,
        ...lessonsPart16,
        ...lessonsPart17,
        ...lessonsPart18,
        ...lessonsPart19,
        ...lessonsPart20,
        ...lessonsPart21,
        ...lessonsPart22,
        ...lessonsPart23,
        ...lessonsPart24,
        ...lessonsPart25,
        ...lessonsPart26,
        ...lessonsPart27,
        ...lessonsPart28,
        ...lessonsPart29,
        ...lessonsPart30,
        ...lessonsPart31,
        ...lessonsPart32,
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
