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
