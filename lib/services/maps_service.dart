import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import '../utils/env.dart';

class RouteData {
  final List<LatLng> polylinePoints;
  final String eta;
  final String distance;
  final LatLng startLocation;
  final LatLng endLocation;

  /// Duration in seconds (from API `duration.value`)
  final int durationSeconds;

  /// Duration in traffic — seconds (from API `duration_in_traffic.value`).
  /// Falls back to [durationSeconds] if traffic data is unavailable.
  final int durationInTrafficSeconds;

  /// Human-readable traffic-aware ETA text, e.g. "5 hours 32 mins"
  final String durationInTrafficText;

  RouteData({
    required this.polylinePoints,
    required this.eta,
    required this.distance,
    required this.startLocation,
    required this.endLocation,
    required this.durationSeconds,
    required this.durationInTrafficSeconds,
    required this.durationInTrafficText,
  });
}

class MapsService {
  static final MapsService _instance = MapsService._internal();
  factory MapsService() => _instance;
  MapsService._internal();

  String get _apiKey => Env.googleMapsApiKey;

  // ── Route cache ────────────────────────────────────────────────
  // Key: "origin|destination|alternatives|avoid" → RouteData
  final Map<String, RouteData> _routeCache = {};

  /// Clear the entire route cache.
  void clearCache() => _routeCache.clear();

  /// Invalidate cache for a specific origin-destination pair.
  void invalidateRoute(String origin, String destination) {
    _routeCache.removeWhere((key, _) => key.startsWith('$origin|$destination'));
  }

  // ── Primary route fetch ────────────────────────────────────────
  /// Fetch a route between [origin] and [destination].
  ///
  /// When [alternatives] is true and a roadblock is detected, the API
  /// will return alternate routes and we pick the second one if available.
  ///
  /// Includes `departure_time=now` to get real-time traffic-aware ETA.
  Future<RouteData?> getRoute(
    String origin,
    String destination, {
    bool alternatives = false,
    bool useCache = true,
  }) async {
    return _fetchRoute(
      origin: origin,
      destination: destination,
      alternatives: alternatives,
      avoid: null,
      useCache: useCache,
    );
  }

  // ── Alternate route (for roadblock scenarios) ──────────────────
  /// Fetch an alternate route that avoids highways and tolls.
  /// Used when roadblock simulation is active.
  Future<RouteData?> getAlternateRoute(
    String origin,
    String destination,
  ) async {
    return _fetchRoute(
      origin: origin,
      destination: destination,
      alternatives: true,
      avoid: 'highways|tolls',
      useCache: true,
    );
  }

  // ── Internal route fetcher ─────────────────────────────────────
  Future<RouteData?> _fetchRoute({
    required String origin,
    required String destination,
    required bool alternatives,
    required String? avoid,
    required bool useCache,
  }) async {
    if (_apiKey.isEmpty || _apiKey == 'YOUR_GOOGLE_MAPS_API_KEY') {
      print('Google Maps API Key is missing or invalid.');
      return null;
    }

    // ── Check cache ──────────────────────────────────────────
    final cacheKey = '$origin|$destination|$alternatives|${avoid ?? "none"}';
    if (useCache && _routeCache.containsKey(cacheKey)) {
      return _routeCache[cacheKey];
    }

    try {
      final StringBuffer urlBuffer = StringBuffer(
        'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=${Uri.encodeComponent(origin)}'
        '&destination=${Uri.encodeComponent(destination)}'
        '&alternatives=$alternatives'
        '&departure_time=now'
        '&key=$_apiKey',
      );

      if (avoid != null && avoid.isNotEmpty) {
        urlBuffer.write('&avoid=${Uri.encodeComponent(avoid)}');
      }

      final response = await http.get(Uri.parse(urlBuffer.toString()));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['status'] == 'OK') {
          // If alternatives requested, try the second route; else first
          int routeIndex = (alternatives && (data['routes'] as List).length > 1) ? 1 : 0;
          final route = data['routes'][routeIndex];

          final leg = route['legs'][0];

          final String distanceText = leg['distance']['text'];
          final String durationText = leg['duration']['text'];
          final int durationValue = leg['duration']['value'] as int;

          // ── Traffic-aware duration ────────────────────────
          final trafficDuration = leg['duration_in_traffic'];
          final int trafficSeconds = trafficDuration != null
              ? (trafficDuration['value'] as int)
              : durationValue;
          final String trafficText = trafficDuration != null
              ? (trafficDuration['text'] as String)
              : durationText;

          final startLoc = leg['start_location'];
          final endLoc = leg['end_location'];

          // Use overview_polyline for the route path
          final String encodedPolyline = route['overview_polyline']['points'];
          final polylinePoints = _decodePolylineSafe(encodedPolyline);
              
          print('Route decoded: ${polylinePoints.length} points | '
              'First: ${polylinePoints.first.latitude},${polylinePoints.first.longitude} | '
              'Last: ${polylinePoints.last.latitude},${polylinePoints.last.longitude}');

          final routeData = RouteData(
            polylinePoints: polylinePoints,
            eta: durationText,
            distance: distanceText,
            startLocation: LatLng(startLoc['lat'], startLoc['lng']),
            endLocation: LatLng(endLoc['lat'], endLoc['lng']),
            durationSeconds: durationValue,
            durationInTrafficSeconds: trafficSeconds,
            durationInTrafficText: trafficText,
          );

          // ── Store in cache ─────────────────────────────────
          _routeCache[cacheKey] = routeData;

          return routeData;
        } else {
          print('Directions API error status: ${data['status']}');
        }
      } else {
        print('Directions API HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching route: $e');
    }
    return null;
  }

  // ── Web-Safe Polyline Decoder ──────────────────────────────────
  // Replaces bitwise shifts with multiplication to avoid 32-bit overflow on Flutter Web JS
  List<LatLng> _decodePolylineSafe(String encoded) {
    List<LatLng> polyline = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        // Use math multiplication instead of bitwise <<
        result += (b & 0x1f) * (1 << shift);
        shift += 5;
      } while (b >= 0x20);
      
      // Use math division instead of >>, and arithmetic -x - 1 instead of ~
      int dlat = ((result & 1) != 0 ? -(result ~/ 2) - 1 : (result ~/ 2));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result += (b & 0x1f) * (1 << shift);
        shift += 5;
      } while (b >= 0x20);
      
      int dlng = ((result & 1) != 0 ? -(result ~/ 2) - 1 : (result ~/ 2));
      lng += dlng;

      polyline.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return polyline;
  }
}
