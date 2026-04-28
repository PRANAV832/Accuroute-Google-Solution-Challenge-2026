import 'dart:convert';
import 'dart:io';

void main() async {
  final mapsKey = 'AIzaSyDFpoLnghMnogO7M56V4Y93QPUsyhwQyik';
  final geminiKey = 'AIzaSyDB7W1f4pSHctsIDmEgZsTywx8Wg3-gFz8';

  // Test Google Maps
  try {
    final mapsUrl = Uri.parse('https://maps.googleapis.com/maps/api/geocode/json?address=New+York&key=$mapsKey');
    final mapsRequest = await HttpClient().getUrl(mapsUrl);
    final mapsResponse = await mapsRequest.close();
    final mapsBody = await mapsResponse.transform(utf8.decoder).join();
    final mapsData = jsonDecode(mapsBody);
    print('Google Maps API Status: ${mapsData['status']}');
    if (mapsData['status'] == 'REQUEST_DENIED') {
        print('Google Maps API Message: ${mapsData['error_message']}');
    }
  } catch (e) {
    print('Google Maps API Error: $e');
  }

  // Test Gemini
  try {
    final geminiUrl = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models?key=$geminiKey');
    final geminiRequest = await HttpClient().getUrl(geminiUrl);
    final geminiResponse = await geminiRequest.close();
    final geminiBody = await geminiResponse.transform(utf8.decoder).join();
    final geminiData = jsonDecode(geminiBody);
    if (geminiData['error'] != null) {
      print('Gemini API Error: ${geminiData['error']['message']}');
      print('Gemini API Error Status: ${geminiData['error']['status']}');
    } else {
      print('Gemini API Status: OK');
      print('Found ${geminiData['models'].length} models.');
    }
  } catch (e) {
    print('Gemini API Error: $e');
  }
}
