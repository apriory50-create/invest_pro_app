import '../models/app_models.dart';
import 'scenarios_part1.dart';
import 'scenarios_part2.dart';

class ScenariosRepository {
  static List<SimScenario> get allScenarios => [
        ...scenariosPart1,
        ...scenariosPart2,
      ];
}
