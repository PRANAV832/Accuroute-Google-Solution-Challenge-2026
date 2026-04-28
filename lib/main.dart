import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'utils/env.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models/shipment.dart';
import 'screens/splash_screen.dart';
import 'screens/role_select_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/driver_login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/shipment_detail_screen.dart';
import 'screens/add_shipment_screen.dart';
import 'utils/app_theme.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: AppTheme.background,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  runApp(const AcuRouteApp());
}

/// Root application widget
class AcuRouteApp extends StatelessWidget {
  const AcuRouteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,

      // ── Routes ────────────────────────────────────────────────
      initialRoute: AppConstants.splashRoute,
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case AppConstants.splashRoute:
            return _fadeRoute(const SplashScreen());

          case AppConstants.roleSelectRoute:
            return _fadeRoute(const RoleSelectScreen());

          case AppConstants.loginRoute:
            return _fadeRoute(const LoginScreen());

          case AppConstants.signupRoute:
            return _fadeRoute(const SignupScreen());

          case AppConstants.driverLoginRoute:
            return _fadeRoute(const DriverLoginScreen());

          case AppConstants.dashboardRoute:
            return _fadeRoute(const DashboardScreen());

          case AppConstants.shipmentDetailRoute:
            final shipment = settings.arguments as Shipment;
            return _slideRoute(ShipmentDetailScreen(shipment: shipment));

          case AppConstants.addShipmentRoute:
            return _slideRoute(const AddShipmentScreen());

          default:
            return _fadeRoute(const SplashScreen());
        }
      },
    );
  }

  /// Fade transition for major navigations (splash → login → dashboard)
  PageRouteBuilder _fadeRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: AppConstants.transitionDuration,
    );
  }

  /// Slide-up transition for detail screens
  PageRouteBuilder _slideRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final tween = Tween(begin: const Offset(0, 0.05), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeOut));
        return SlideTransition(
          position: animation.drive(tween),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      transitionDuration: AppConstants.transitionDuration,
    );
  }
}
