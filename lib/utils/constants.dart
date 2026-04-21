/// App-wide constants
class AppConstants {
  // ─── App Info ──────────────────────────────────────────────────
  static const String appName = 'AcuRoute';
  static const String appTagline = 'Smart Supply Chain Intelligence';
  static const String appVersion = '1.0.0';

  // ─── Route Names ───────────────────────────────────────────────
  static const String splashRoute = '/';
  static const String loginRoute = '/login';
  static const String signupRoute = '/signup';
  static const String dashboardRoute = '/dashboard';
  static const String shipmentDetailRoute = '/shipment-detail';
  static const String addShipmentRoute = '/add-shipment';

  // ─── Animation Durations ───────────────────────────────────────
  static const Duration splashDuration = Duration(milliseconds: 2500);
  static const Duration fadeInDuration = Duration(milliseconds: 800);
  static const Duration transitionDuration = Duration(milliseconds: 350);
}
