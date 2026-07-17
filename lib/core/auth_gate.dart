import 'package:flutter/material.dart';

import '../screens/login_screen.dart';
import 'auth_storage.dart';

class AuthGate {
  static Future<bool> ensureLogin(BuildContext context) async {
    final token = await AuthStorage.token();

    if (token != null && token.isNotEmpty) {
      return true;
    }

    if (!context.mounted) {
      return false;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(returnToHome: true),
      ),
    );

    return result == true;
  }

  static Future<bool> isLoggedIn() async {
    final token = await AuthStorage.token();
    return token != null && token.isNotEmpty;
  }
}
