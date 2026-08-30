import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'theme/app_theme.dart';
import 'screens/onboarding_screen.dart';
import 'screens/register_screen.dart';
import 'screens/login_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/home_shell.dart';
import 'screens/profile_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/search_screen.dart';
import 'screens/plan_ride_screen.dart';
import 'screens/lobby_screen.dart';
import 'screens/live_ride_screen.dart';
import 'screens/paused_ride_screen.dart';
import 'screens/capture_memory_screen.dart';
import 'screens/ride_summary_screen.dart';
import 'screens/ride_detail_screen.dart';
import 'screens/crew_ride_invite_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Loads .env into memory. Safe to call even with placeholder values —
  // it only parses the file; nothing in this UI-only build reads the
  // values yet (see lib/config/env_config.dart for the typed getters).
  await dotenv.load(fileName: '.env');
  runApp(const RutaApp());
}

/// Route names centralized here so screens never hardcode raw strings.
/// Matches the 13-screen flow from the UI/UX design pass.
class AppRoutes {
  static const onboarding = '/';
  static const register = '/register';
  static const login = '/login';
  static const forgotPassword = '/forgot-password';
  static const feed = '/feed';
  static const garage = '/garage';
  static const crew = '/crew';
  static const profile = '/profile';
  static const settings = '/settings';
  static const search = '/search';
  static const planRide = '/plan-ride';
  static const lobby = '/lobby';
  static const liveRide = '/live-ride';
  static const pausedRide = '/paused-ride';
  static const captureMemory = '/capture-memory';
  static const rideSummary = '/ride-summary';
  static const rideDetail = '/ride-detail';
  static const notifications = '/notifications';
  static const crewRideInvite = '/crew-ride-invite';
}

class RutaApp extends StatelessWidget {
  const RutaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RUTA',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.themeData,
      initialRoute: AppRoutes.onboarding,
      routes: {
        AppRoutes.onboarding: (_) => const OnboardingScreen(),
        AppRoutes.register: (_) => const RegisterScreen(),
        AppRoutes.login: (_) => const LoginScreen(),
        AppRoutes.forgotPassword: (_) => const ForgotPasswordScreen(),
        AppRoutes.feed: (_) => const HomeShell(initialIndex: 0),
        AppRoutes.garage: (_) => const HomeShell(initialIndex: 1),
        AppRoutes.crew: (_) => const HomeShell(initialIndex: 2),
        AppRoutes.profile: (_) => const ProfileScreen(),
        AppRoutes.settings: (_) => const SettingsScreen(),
        AppRoutes.search: (_) => const SearchScreen(),
        AppRoutes.planRide: (_) => const PlanRideScreen(),
        AppRoutes.lobby: (_) => const LobbyScreen(),
        AppRoutes.liveRide: (_) => const LiveRideScreen(),
        AppRoutes.pausedRide: (_) => const PausedRideScreen(),
        AppRoutes.captureMemory: (_) => const CaptureMemoryScreen(),
        AppRoutes.rideSummary: (_) => const RideSummaryScreen(),
        AppRoutes.rideDetail: (_) => const RideDetailScreen(),
        AppRoutes.notifications: (_) => const HomeShell(initialIndex: 3),
        AppRoutes.crewRideInvite: (_) => const CrewRideInviteScreen(),
      },
    );
  }
}
