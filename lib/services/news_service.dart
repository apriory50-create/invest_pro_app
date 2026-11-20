import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/app_models.dart';

class NewsService {
  static Future<List<NewsArticle>> fetchAllNews(
    List<NewsChannel> channels,
    List<String> stopWords,
  ) async {
    final List<NewsArticle> result = [];
    final lowerStops = stopWords
        .map((w) => w.trim().toLowerCase())
        .where((w) => w.isNotEmpty)
        .toList();

    for (final ch in channels) {
      if (!ch.enabled || ch.url.trim().isEmpty) continue;
      try {
        final res = await http
            .get(Uri.parse(ch.url.trim()))
            .timeout(const Duration(seconds: 15));
        if (res.statusCode >= 200 && res.statusCode < 300) {
          final xml = utf8.decode(res.bodyBytes, allowMalformed: true);
          final items = _parseRss(xml, ch.name);
          for (final item in items) {
            final full = '${item.title} ${item.description}'.toLowerCase();
            final isSpam = lowerStops.any((w) => full.contains(w));
            if (!isSpam) result.add(item);
          }
        }
      } catch (_) {}
    }
    return result;
  }

  static List<NewsArticle> filterForPortfolio(
    List<NewsArticle> articles,
    List<PortfolioItem> portfolio,
  ) {
    if (portfolio.isEmpty) return [];
    final keywords = <String>{};
    for (final p in portfolio) {
      if (p.ticker.trim().length >= 2) keywords.add(p.ticker.trim().toLowerCase());
      if (p.name.trim().length >= 3) keywords.add(p.name.trim().toLowerCase());
      if (p.sector.trim().length >= 3 && p.sector != 'Другое') {
        keywords.add(p.sector.trim().toLowerCase());
      }
    }
    return articles.where((a) {
      final text = '${a.title} ${a.description}'.toLowerCase();
      return keywords.any((k) => text.contains(k));
    }).toList();
  }

  static List<NewsArticle> _parseRss(String xml, String source) {
    final List<NewsArticle> list = [];
    final itemReg = RegExp(r'<item[^>]*>([\s\S]*?)<\/item>', caseSensitive: false);
    final matches = itemReg.allMatches(xml);

    for (final m in matches.take(20)) {
      final block = m.group(1) ?? '';
      final title = _clean(_extract(block, 'title'));
      final desc = _clean(_extract(block, 'description'));
      final date = _clean(_extract(block, 'pubDate'));
      if (title.isNotEmpty) {
        list.add(NewsArticle(
          title: title,
          description: desc.length > 260 ? '${desc.substring(0, 260)}...' : desc,
          source: source,
          date: date,
        ));
      }
    }
    return list;
  }

  static String _extract(String block, String tag) {
    final reg = RegExp('<$tag[^>]*>([\\s\\S]*?)<\\/$tag>', caseSensitive: false);
    return reg.firstMatch(block)?.group(1) ?? '';
  }

  static String _clean(String raw) {
    var s = raw.replaceAll(RegExp(r'<!\[CDATA\[|\]\]>'), '');
    s = s.replaceAll(RegExp(r'<[^>]*>'), ' ');
    s = s
        .replaceAll('&quot;', '"')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&nbsp;', ' ');
    return s.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
