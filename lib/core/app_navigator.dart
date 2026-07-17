import 'package:flutter/material.dart';

class AppNavigator {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static NavigatorState? get navigator => navigatorKey.currentState;
  static BuildContext? get context => navigatorKey.currentContext;

  static Future<void> handleNotificationData(Map<String, dynamic> data) async {
    // Untuk tahap ini dibuat aman dulu agar app.dart dan FCM tidak error.
    // Nanti kalau notifikasi customer sudah dipakai, routing bisa ditambahkan di sini.
    debugPrint('Notification data: $data');
  }

  static void pop<T extends Object?>([T? result]) {
    navigator?.pop(result);
  }
}
