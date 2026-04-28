class Env {
  static Future<void> init() async {
    // No longer using dotenv. API keys are passed via --dart-define
  }

  static const String googleMapsApiKey = String.fromEnvironment('MAPS_API_KEY', defaultValue: '');
  static const String geminiApiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
}
