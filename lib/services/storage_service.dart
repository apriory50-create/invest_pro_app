import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_models.dart';

class StorageService {
  static const _kLessons = 'completed_lessons';
  static const _kPortfolio = 'portfolio_items';
  static const _kChannels = 'news_channels';
  static const _kStopWords = 'news_stopwords';
  static const _kAiConfig = 'ai_config';
  static const _kBeginner = 'is_beginner_mode';
  static const _kSimState = 'sim_state';

  static List<NewsChannel> get defaultChannels => [
        NewsChannel(id: '1', name: 'РБК Финансы', url: 'https://rssexport.rbc.ru/rbcnews/news/30/full.rss'),
        NewsChannel(id: '2', name: 'Интерфакс', url: 'https://www.interfax.ru/rss.asp'),
        NewsChannel(id: '3', name: 'Коммерсантъ Экономика', url: 'https://www.kommersant.ru/RSS/section-economics.xml'),
      ];

  static Future<Set<int>> getCompletedLessons() async {
    final p = await SharedPreferences.getInstance();
    final list = p.getStringList(_kLessons) ?? [];
    return list.map((e) => int.tryParse(e) ?? -1).where((e) => e >= 0).toSet();
  }

  static Future<void> toggleLesson(int id) async {
    final p = await SharedPreferences.getInstance();
    final set = await getCompletedLessons();
    if (set.contains(id)) {
      set.remove(id);
    } else {
      set.add(id);
    }
    await p.setStringList(_kLessons, set.map((e) => e.toString()).toList());
  }

  static Future<List<PortfolioItem>> getPortfolio() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_kPortfolio);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => PortfolioItem.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  static Future<void> savePortfolio(List<PortfolioItem> items) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kPortfolio, jsonEncode(items.map((e) => e.toJson()).toList()));
  }

  static Future<List<NewsChannel>> getChannels() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_kChannels);
    if (raw == null || raw.isEmpty) return defaultChannels;
    final list = jsonDecode(raw) as List;
    return list.map((e) => NewsChannel.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  static Future<void> saveChannels(List<NewsChannel> channels) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kChannels, jsonEncode(channels.map((e) => e.toJson()).toList()));
  }

  static Future<List<String>> getStopWords() async {
    final p = await SharedPreferences.getInstance();
    return p.getStringList(_kStopWords) ?? ['реклама', 'промокод', 'розыгрыш', 'скидка'];
  }

  static Future<void> saveStopWords(List<String> words) async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList(_kStopWords, words);
  }

  static Future<AiConfig> getAiConfig() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_kAiConfig);
    if (raw == null || raw.isEmpty) return AiConfig();
    return AiConfig.fromJson(Map<String, dynamic>.from(jsonDecode(raw)));
  }

  static Future<void> saveAiConfig(AiConfig config) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kAiConfig, jsonEncode(config.toJson()));
  }

  static Future<bool> getBeginnerMode() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_kBeginner) ?? true;
  }

  static Future<void> setBeginnerMode(bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kBeginner, value);
  }

  static Future getSimState() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_kSimState);
    if (raw == null || raw.isEmpty) return {};
    return Map<String, dynamic>.from(jsonDecode(raw));
  }

  static Future<void> saveSimState(Map state) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kSimState, jsonEncode(state));
  }

  static Future<String> exportAllData() async {
    final data = {
      'lessons': (await getCompletedLessons()).toList(),
      'portfolio': (await getPortfolio()).map((e) => e.toJson()).toList(),
      'channels': (await getChannels()).map((e) => e.toJson()).toList(),
      'stopWords': await getStopWords(),
      'aiConfig': (await getAiConfig()).toJson(),
      'beginnerMode': await getBeginnerMode(),
      'simState': await getSimState(),
    };
    return jsonEncode(data);
  }

  static Future<bool> importAllData(String jsonStr) async {
    try {
      final map = Map<String, dynamic>.from(jsonDecode(jsonStr));
      final p = await SharedPreferences.getInstance();
      if (map['lessons'] is List) {
        final list = (map['lessons'] as List).map((e) => e.toString()).toList();
        await p.setStringList(_kLessons, list);
      }
      if (map['portfolio'] is List) {
        await p.setString(_kPortfolio, jsonEncode(map['portfolio']));
      }
      if (map['channels'] is List) {
        await p.setString(_kChannels, jsonEncode(map['channels']));
      }
      if (map['stopWords'] is List) {
        final words = (map['stopWords'] as List).map((e) => e.toString()).toList();
        await p.setStringList(_kStopWords, words);
      }
      if (map['aiConfig'] is Map) {
        await p.setString(_kAiConfig, jsonEncode(map['aiConfig']));
      }
      if (map['beginnerMode'] is bool) {
        await p.setBool(_kBeginner, map['beginnerMode']);
      }
      if (map['simState'] is Map) {
        await p.setString(_kSimState, jsonEncode(map['simState']));
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}
