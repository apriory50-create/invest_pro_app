import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/app_models.dart';
import 'storage_service.dart';

class AiService {
  static const String _defaultSystem =
      'Ты опытный финансовый наставник для новичка. Объясняй простым, живым языком без сложного жаргона, опирайся на факты, указывай риски и давай понятные пошаговые выводы.';

  static Future<String> ask(String prompt, {String? systemPrompt}) async {
    final config = await StorageService.getAiConfig();
    if (config.apiKey.trim().isEmpty) {
      return 'Ошибка: не указан API-ключ. Перейдите во вкладку «Настройки» и добавьте ключ.';
    }

    final sys = systemPrompt ?? _defaultSystem;
    try {
      if (config.provider == 'Gemini') {
        return await _callGemini(config, sys, prompt);
      } else if (config.provider == 'Claude') {
        return await _callClaude(config, sys, prompt);
      } else {
        return await _callOpenAiCompatible(config, sys, prompt);
      }
    } catch (e) {
      return 'Ошибка соединения с ИИ: $e';
    }
  }

  static Future<String> _callOpenAiCompatible(
      AiConfig config, String sys, String prompt) async {
    final uri = Uri.parse(config.baseUrl.trim());
    final res = await http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${config.apiKey.trim()}',
          },
          body: jsonEncode({
            'model': config.model.trim(),
            'messages': [
              {'role': 'system', 'content': sys},
              {'role': 'user', 'content': prompt},
            ],
            'temperature': 0.5,
          }),
        )
        .timeout(const Duration(seconds: 45));

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = jsonDecode(utf8.decode(res.bodyBytes));
      return data['choices'][0]['message']['content'].toString().trim();
    }
    return 'Ошибка API (${res.statusCode}): ${utf8.decode(res.bodyBytes)}';
  }

  static Future<String> _callGemini(
      AiConfig config, String sys, String prompt) async {
    final model = config.model.trim().isEmpty ? 'gemini-1.5-flash' : config.model.trim();
    final url =
        'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=${config.apiKey.trim()}';
    final res = await http
        .post(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [
              {
                'parts': [
                  {'text': '$sys\n\n$prompt'}
                ]
              }
            ]
          }),
        )
        .timeout(const Duration(seconds: 45));

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = jsonDecode(utf8.decode(res.bodyBytes));
      return data['candidates'][0]['content']['parts'][0]['text'].toString().trim();
    }
    return 'Ошибка Gemini (${res.statusCode}): ${utf8.decode(res.bodyBytes)}';
  }

  static Future<String> _callClaude(
      AiConfig config, String sys, String prompt) async {
    final uri = Uri.parse('https://api.anthropic.com/v1/messages');
    final res = await http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'x-api-key': config.apiKey.trim(),
            'anthropic-version': '2023-06-01',
          },
          body: jsonEncode({
            'model': config.model.trim(),
            'max_tokens': 1200,
            'system': sys,
            'messages': [
              {'role': 'user', 'content': prompt},
            ],
          }),
        )
        .timeout(const Duration(seconds: 45));

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = jsonDecode(utf8.decode(res.bodyBytes));
      return data['content'][0]['text'].toString().trim();
    }
    return 'Ошибка Claude (${res.statusCode}): ${utf8.decode(res.bodyBytes)}';
  }

  static Future<String> testConnection() async {
    return ask('Ответь одним коротким предложением: «Связь с ИИ-наставником успешно настроена!»');
  }
}
