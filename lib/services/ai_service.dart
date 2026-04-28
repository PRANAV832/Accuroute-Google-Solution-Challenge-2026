import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/shipment.dart';
import '../utils/env.dart';

class AiService {
  static final AiService _instance = AiService._internal();
  factory AiService() => _instance;
  AiService._internal();

  String get _apiKey => Env.geminiApiKey;

  Future<String> _callGemini(String prompt) async {
    if (_apiKey.isEmpty || _apiKey == 'YOUR_GEMINI_API_KEY') {
      return "Gemini API key is missing. Please configure it in .env file.";
    }

    final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$_apiKey');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "contents": [
            {
              "parts": [
                {"text": prompt}
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final candidates = data['candidates'] as List;
        if (candidates.isNotEmpty) {
          final content = candidates[0]['content']['parts'][0]['text'];
          return content.toString().trim();
        }
      } else {
        print("Gemini API Error: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print("Gemini API Exception: $e");
    }
    return "Failed to fetch AI insights. Please try again later.";
  }

  /// Get AI insight for a disrupted shipment.
  ///
  /// Optional [delayMinutes], [activeConditions], and [actualEta] enrich the
  /// prompt with real dynamic data when available.
  Future<String> getAIInsight(
    String source,
    String destination,
    RiskLevel risk, {
    int? delayMinutes,
    List<String>? activeConditions,
    String? actualEta,
  }) async {
    if (risk == RiskLevel.low) {
      return "All conditions nominal on this route. No disruptions detected. "
             "Current ETA is within expected range. Continue on planned route.";
    }

    // Build a context-rich prompt using dynamic data when available
    final conditionsText = (activeConditions != null && activeConditions.isNotEmpty)
        ? activeConditions.join(', ')
        : 'traffic and bad weather';
    final delayText = delayMinutes != null
        ? 'Estimated delay is approximately $delayMinutes minutes. '
        : '';
    final etaText = actualEta != null
        ? 'Current ETA is $actualEta. '
        : '';

    final prompt = "You are a logistics AI assistant. "
        "A shipment from $source to $destination has been marked as ${risk.name.toUpperCase()} RISK due to $conditionsText. "
        "$delayText$etaText"
        "Explain the delay concisely (under 40 words) and suggest using an alternative route.";

    return await _callGemini(prompt);
  }

  /// General chatbot function with shipment context
  Future<String> chatWithBot(String message, Shipment shipment, RiskLevel currentRisk) async {
    final prompt = "You are a helpful logistics AI assistant inside the AcuRoute app. "
        "The current user is tracking a shipment from ${shipment.source} to ${shipment.destination}. "
        "The current risk level is ${currentRisk.name}. "
        "If they ask for nearby petrol pumps, hotels, or mechanics, provide a realistic mock list based on the route. "
        "User question: $message\n"
        "Provide a concise and helpful response.";

    return await _callGemini(prompt);
  }
}
