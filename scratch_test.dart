import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print('--- Testing APIs ---');
  final envFile = File('.env');
  if (!envFile.existsSync()) {
    print('Error: .env file not found');
    return;
  }

  final lines = envFile.readAsLinesSync();
  String mapsKey = '';
  String geminiKey = '';

  for (var line in lines) {
    if (line.startsWith('GOOGLE_MAPS_API_KEY=')) {
      mapsKey = line.substring('GOOGLE_MAPS_API_KEY='.length).trim();
    }
    if (line.startsWith('GEMINI_API_KEY=')) {
      geminiKey = line.substring('GEMINI_API_KEY='.length).trim();
    }
  }

  if (mapsKey.isEmpty || mapsKey == 'YOUR_GOOGLE_MAPS_API_KEY') {
    print('FAIL: Google Maps API key is missing or default.');
  } else {
    // Test Maps API
    final String url = 'https://maps.googleapis.com/maps/api/directions/json'
          '?origin=Mumbai'
          '&destination=Pune'
          '&key=$mapsKey';
    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['status'] == 'OK') {
          print('SUCCESS: Google Maps API is working! (Route: Mumbai -> Pune, Distance: ${data['routes'][0]['legs'][0]['distance']['text']})');
        } else {
          print('FAIL: Google Maps API returned status: ${data['status']} - ${data['error_message']}');
        }
      } else {
        print('FAIL: Google Maps API HTTP Error ${res.statusCode}');
      }
    } catch (e) {
      print('FAIL: Google Maps API Exception: $e');
    }
  }

  if (geminiKey.isEmpty || geminiKey == 'YOUR_GEMINI_API_KEY') {
    print('FAIL: Gemini API key is missing or default.');
  } else {
    // Test Gemini API
    final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$geminiKey');
    try {
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "contents": [{"parts": [{"text": "Say hello world"}]}]
        }),
      );
      if (res.statusCode == 200) {
         final data = json.decode(res.body);
         print('SUCCESS: Gemini API is working! (Response: ${data['candidates'][0]['content']['parts'][0]['text'].replaceAll('\n', '')})');
      } else {
         print('FAIL: Gemini API returned ' + res.statusCode.toString() + ' - ' + res.body);
      }
    } catch (e) {
      print('FAIL: Gemini API Exception: $e');
    }
  }
}
