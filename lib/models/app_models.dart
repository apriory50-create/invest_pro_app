class Lesson {
  final int id;
  final String module;
  final String title;
  final String content;
  final String example;
  final String quizQuestion;
  final List<String> quizOptions;
  final int correctIndex;
  final String quizExplanation;

  const Lesson({
    required this.id,
    required this.module,
    required this.title,
    required this.content,
    required this.example,
    required this.quizQuestion,
    required this.quizOptions,
    required this.correctIndex,
    required this.quizExplanation,
  });
}

class GlossaryTerm {
  final String term;
  final String definition;
  final String example;

  const GlossaryTerm({
    required this.term,
    required this.definition,
    required this.example,
  });
}

class SimAsset {
  final String ticker;
  final String name;
  final String type;
  final String sector;
  double price;
  final double yieldPercent;

  SimAsset({
    required this.ticker,
    required this.name,
    required this.type,
    required this.sector,
    required this.price,
    required this.yieldPercent,
  });
}

class SimScenario {
  final int id;
  final String title;
  final String category;
  final String newsText;
  final Map<String, double> sectorImpacts;
  final String rightAction;
  final String mistakeAnalysis;

  const SimScenario({
    required this.id,
    required this.title,
    required this.category,
    required this.newsText,
    required this.sectorImpacts,
    required this.rightAction,
    required this.mistakeAnalysis,
  });
}

class PortfolioItem {
  final String id;
  final String ticker;
  final String name;
  final String type;
  final String sector;
  final double quantity;
  final double avgPrice;
  final String date;
  final String emotionNote;

  PortfolioItem({
    required this.id,
    required this.ticker,
    required this.name,
    required this.type,
    required this.sector,
    required this.quantity,
    required this.avgPrice,
    required this.date,
    this.emotionNote = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'ticker': ticker,
        'name': name,
        'type': type,
        'sector': sector,
        'quantity': quantity,
        'avgPrice': avgPrice,
        'date': date,
        'emotionNote': emotionNote,
      };

  factory PortfolioItem.fromJson(Map<String, dynamic> j) => PortfolioItem(
        id: j['id']?.toString() ?? '',
        ticker: j['ticker']?.toString() ?? '',
        name: j['name']?.toString() ?? '',
        type: j['type']?.toString() ?? 'Акция',
        sector: j['sector']?.toString() ?? 'Другое',
        quantity: (j['quantity'] as num?)?.toDouble() ?? 0.0,
        avgPrice: (j['avgPrice'] as num?)?.toDouble() ?? 0.0,
        date: j['date']?.toString() ?? '',
        emotionNote: j['emotionNote']?.toString() ?? '',
      );
}

class NewsChannel {
  final String id;
  final String name;
  final String url;
  final bool enabled;

  NewsChannel({
    required this.id,
    required this.name,
    required this.url,
    this.enabled = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'url': url,
        'enabled': enabled,
      };

  factory NewsChannel.fromJson(Map<String, dynamic> j) => NewsChannel(
        id: j['id']?.toString() ?? '',
        name: j['name']?.toString() ?? '',
        url: j['url']?.toString() ?? '',
        enabled: j['enabled'] == true,
      );
}

class NewsArticle {
  final String title;
  final String description;
  final String source;
  final String date;

  NewsArticle({
    required this.title,
    required this.description,
    required this.source,
    required this.date,
  });
}

class AiConfig {
  final String provider;
  final String baseUrl;
  final String apiKey;
  final String model;

  AiConfig({
    this.provider = 'OpenAI',
    this.baseUrl = 'https://api.openai.com/v1/chat/completions',
    this.apiKey = '',
    this.model = 'gpt-4o-mini',
  });

  Map<String, dynamic> toJson() => {
        'provider': provider,
        'baseUrl': baseUrl,
        'apiKey': apiKey,
        'model': model,
      };

  factory AiConfig.fromJson(Map<String, dynamic> j) => AiConfig(
        provider: j['provider']?.toString() ?? 'OpenAI',
        baseUrl: j['baseUrl']?.toString() ?? 'https://api.openai.com/v1/chat/completions',
        apiKey: j['apiKey']?.toString() ?? '',
        model: j['model']?.toString() ?? 'gpt-4o-mini',
      );
}
