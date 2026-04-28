import 'dart:convert';
import 'dart:io';

/// Standard Google polyline decoder
List<List<double>> decodePolyline(String encoded) {
  List<List<double>> polyline = [];
  int index = 0, len = encoded.length;
  int lat = 0, lng = 0;

  while (index < len) {
    int b, shift = 0, result = 0;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
    lat += dlat;

    shift = 0;
    result = 0;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
    lng += dlng;

    polyline.add([lat / 1E5, lng / 1E5]);
  }
  return polyline;
}

void main() async {
  final mapsKey = 'AIzaSyDFpoLnghMnogO7M56V4Y93QPUsyhwQyik';

  try {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json'
      '?origin=${Uri.encodeComponent("Mumbai")}'
      '&destination=${Uri.encodeComponent("Hyderabad")}'
      '&departure_time=now'
      '&key=$mapsKey'
    );
    final request = await HttpClient().getUrl(url);
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    final data = jsonDecode(body);
    
    print('Status: ${data['status']}');
    
    if (data['status'] == 'OK') {
      final route = data['routes'][0];
      final leg = route['legs'][0];
      print('Distance: ${leg['distance']['text']}');
      print('Duration: ${leg['duration']['text']}');
      
      // Check overview_polyline
      final overviewPolyline = route['overview_polyline']['points'];
      print('\nOverview polyline length: ${overviewPolyline.length} chars');
      print('First 100 chars: ${overviewPolyline.substring(0, overviewPolyline.length > 100 ? 100 : overviewPolyline.length)}');
      
      // Decode it
      final decoded = decodePolyline(overviewPolyline);
      print('\nDecoded ${decoded.length} points');
      print('First 3 points: ${decoded.take(3).toList()}');
      print('Last 3 points: ${decoded.skip(decoded.length - 3).toList()}');
      
      // Also check individual steps for their polylines
      final steps = leg['steps'] as List;
      print('\nNumber of steps: ${steps.length}');
      
      int totalStepPoints = 0;
      for (var step in steps) {
        final stepPolyline = step['polyline']['points'];
        final stepDecoded = decodePolyline(stepPolyline);
        totalStepPoints += stepDecoded.length;
      }
      print('Total points from all steps: $totalStepPoints');
    }
  } catch (e) {
    print('Error: $e');
  }
}
