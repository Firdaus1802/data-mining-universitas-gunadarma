import 'package:flutter/cupertino.dart';
import 'package:shop/entry_point.dart';

import 'screen_export.dart';

Route<dynamic> generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case onbordingScreenRoute:
      return CupertinoPageRoute(
        settings: settings,
        builder: (context) => const OnBordingScreen(),
      );
    case logInScreenRoute:
      return CupertinoPageRoute(
        settings: settings,
        builder: (context) => const LoginScreen(),
      );
    case signUpScreenRoute:
      return CupertinoPageRoute(
        settings: settings,
        builder: (context) => const SignUpScreen(),
      );
    case passwordRecoveryScreenRoute:
      return CupertinoPageRoute(
        settings: settings,
        builder: (context) => const PasswordRecoveryScreen(),
      );
    case otpScreenRoute:
    case signUpVerificationScreenRoute:
      return CupertinoPageRoute(
        settings: settings,
        builder: (context) {
          final args = settings.arguments as Map<String, dynamic>? ?? {};
          return EmailVerificationScreen(
            email: args['email'] as String? ?? 'user@gunadarma.ac.id',
            expectedOtp: args['expectedOtp'] as String? ?? '',
            userName: args['userName'] as String?,
          );
        },
      );
    case homeScreenRoute:
      return CupertinoPageRoute(
        settings: settings,
        builder: (context) => const HomeScreen(),
      );
    case discoverScreenRoute:
      return CupertinoPageRoute(
        settings: settings,
        builder: (context) => const DiscoverScreen(),
      );
    case searchScreenRoute:
      return CupertinoPageRoute(
        settings: settings,
        builder: (context) => const SearchScreen(),
      );
    case entryPointScreenRoute:
      return CupertinoPageRoute(
        settings: settings,
        builder: (context) => const EntryPoint(),
      );
    case profileScreenRoute:
      return CupertinoPageRoute(
        settings: settings,
        builder: (context) => const ProfileScreen(),
      );
    case aprioriDashboardScreenRoute:
      return CupertinoPageRoute(
        settings: settings,
        builder: (context) => const AprioriDashboardScreen(),
      );
    default:
      return CupertinoPageRoute(
        settings: settings,
        builder: (context) => const OnBordingScreen(),
      );
  }
}
