import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:shop/models/apriori_state_manager.dart';
import 'package:shop/route/route_constants.dart';
import 'package:shop/route/router.dart' as router;
import 'package:shop/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    usePathUrlStrategy();
  }
  await AprioriStateManager.instance.init();
  runApp(const MyApp());
}

class IOSBouncingScrollBehavior extends MaterialScrollBehavior {
  const IOSBouncingScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
  }

  @override
  Widget buildOverscrollIndicator(
      BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AprioriMart - Universitas Gunadarma',
      theme: AppTheme.lightTheme(context),
      themeMode: ThemeMode.light,
      scrollBehavior: const IOSBouncingScrollBehavior(),
      onGenerateRoute: router.generateRoute,
      initialRoute: onbordingScreenRoute,
    );
  }
}
