import '../models/shipment.dart';

/// Result data class from a simulation run
class SimulationResult {
  final String adjustedEta;
  final String optimizedEta;
  final RiskLevel riskLevel;
  final bool shouldFetchAlternateRoute;
  final int totalDelayMinutes;

  const SimulationResult({
    required this.adjustedEta,
    required this.optimizedEta,
    required this.riskLevel,
    required this.shouldFetchAlternateRoute,
    required this.totalDelayMinutes,
  });
}

/// Simulation engine for disruption scenarios.
///
/// Accepts simulation toggles and a base ETA, then computes:
/// - Adjusted ETA with penalty minutes
/// - Risk level based on active condition count
/// - Whether an alternate route should be fetched
class SimulationService {
  static final SimulationService _instance = SimulationService._internal();
  factory SimulationService() => _instance;
  SimulationService._internal();

  // ── Penalty constants (minutes) ────────────────────────────────
  static const int trafficPenalty = 30;
  static const int rainPenalty = 20;
  static const int roadblockPenalty = 40;

  /// Run the simulation with the given conditions.
  ///
  /// [baseEtaText] — the original ETA string, e.g. "5h 30m" or "3 hours 12 mins"
  /// [baseEtaSeconds] — optional raw seconds from the Directions API for precision
  /// [trafficOn], [rainOn], [roadblockOn] — active disruption toggles
  SimulationResult run({
    required String baseEtaText,
    int? baseEtaSeconds,
    required bool trafficOn,
    required bool rainOn,
    required bool roadblockOn,
  }) {
    final bool isDisrupted = trafficOn || rainOn || roadblockOn;

    if (!isDisrupted) {
      return SimulationResult(
        adjustedEta: baseEtaText,
        optimizedEta: baseEtaText,
        riskLevel: RiskLevel.low,
        shouldFetchAlternateRoute: false,
        totalDelayMinutes: 0,
      );
    }

    // ── Calculate total delay ──────────────────────────────────
    int delayMinutes = 0;
    if (trafficOn) delayMinutes += trafficPenalty;
    if (rainOn) delayMinutes += rainPenalty;
    if (roadblockOn) delayMinutes += roadblockPenalty;

    // ── Calculate risk level ──────────────────────────────────
    int activeConditions = 0;
    if (trafficOn) activeConditions++;
    if (rainOn) activeConditions++;
    if (roadblockOn) activeConditions++;

    final RiskLevel risk;
    if (activeConditions >= 2) {
      risk = RiskLevel.high;
    } else {
      risk = RiskLevel.medium;
    }

    // ── Compute adjusted ETAs ─────────────────────────────────
    String adjustedEta;
    String optimizedEta;

    if (baseEtaSeconds != null && baseEtaSeconds > 0) {
      // Use precise seconds-based calculation
      final adjustedSeconds = baseEtaSeconds + (delayMinutes * 60);
      final optimizedSeconds = baseEtaSeconds + ((delayMinutes * 0.5).round() * 60);
      adjustedEta = _formatSeconds(adjustedSeconds);
      optimizedEta = _formatSeconds(optimizedSeconds);
    } else {
      // Fallback to text parsing
      adjustedEta = _addMinutesToEtaText(baseEtaText, delayMinutes);
      optimizedEta = _addMinutesToEtaText(baseEtaText, (delayMinutes * 0.5).round());
    }

    return SimulationResult(
      adjustedEta: adjustedEta,
      optimizedEta: optimizedEta,
      riskLevel: risk,
      shouldFetchAlternateRoute: roadblockOn,
      totalDelayMinutes: delayMinutes,
    );
  }

  /// Format total seconds into a human-friendly "Xh Ym" string.
  String _formatSeconds(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    if (h > 0) {
      return '${h}h ${m}m';
    }
    return '${m}m';
  }

  /// Parse an ETA text like "5h 30m" or "3 hours 12 mins" and add minutes.
  String _addMinutesToEtaText(String eta, int minutes) {
    // Try "Xh Ym" pattern
    final hMatch = RegExp(r'(\d+)\s*h').firstMatch(eta);
    final mMatch = RegExp(r'(\d+)\s*m').firstMatch(eta);

    // Try "X hours Y mins" pattern
    final hoursMatch = RegExp(r'(\d+)\s*hour').firstMatch(eta);
    final minsMatch = RegExp(r'(\d+)\s*min').firstMatch(eta);

    int h = 0;
    int m = 0;

    if (hMatch != null) {
      h = int.parse(hMatch.group(1)!);
    } else if (hoursMatch != null) {
      h = int.parse(hoursMatch.group(1)!);
    }

    if (mMatch != null) {
      m = int.parse(mMatch.group(1)!);
    } else if (minsMatch != null) {
      m = int.parse(minsMatch.group(1)!);
    }

    m += minutes;
    h += m ~/ 60;
    m = m % 60;
    return '${h}h ${m}m';
  }
}
