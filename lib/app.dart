import 'package:flutter/material.dart';

import 'core/app_navigator.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

class MiMartUserApp extends StatelessWidget {
  const MiMartUserApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: AppNavigator.navigatorKey,
      title: 'MI MART',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const SplashScreen(),
    );
  }
}