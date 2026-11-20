import '../models/app_models.dart';
import 'scenarios_part1.dart';
import 'scenarios_part2.dart';
import 'scenarios_part3.dart';
import 'scenarios_part4.dart';
import 'scenarios_part5.dart';
import 'scenarios_part6.dart';
import 'scenarios_part7.dart';
import 'scenarios_part8.dart';
import 'scenarios_part9.dart';
import 'scenarios_part10.dart';

class ScenariosRepository {
  static List<SimScenario> get allScenarios => [
        ...scenariosPart1,
        ...scenariosPart2,
        ...scenariosPart3,
        ...scenariosPart4,
        ...scenariosPart5,
        ...scenariosPart6,
        ...scenariosPart7,
        ...scenariosPart8,
        ...scenariosPart9,
        ...scenariosPart10,
      ];
}
