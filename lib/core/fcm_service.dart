import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'app_config.dart';
import 'api_client.dart';
import 'auth_storage.dart';

class FcmService {
  static bool _ready = false;
  static final FirebaseMessaging _fm = FirebaseMessaging.instance;

  static Future<void> initialize() async {
    if (_ready) return;
    _ready = true;
    try {
      await _fm.requestPermission();
    } catch (_) {}
  }

  static Future<void> init() async => initialize();
  static Future<void> setup() async => initialize();
  static Future<void> configure() async => initialize();

  static Future<void> requestPermission() async {
    try {
      await _fm.requestPermission();
    } catch (e) {
      debugPrint('FCM permission error: $e');
    }
  }

  static Future<String?> getToken() async {
    try {
      return await _fm.getToken();
    } catch (e) {
      debugPrint('FCM getToken error: $e');
      return null;
    }
  }

  static Future<void> syncTokenToBackend() async {
    final token = await getToken();
    if (token == null || token.isEmpty) return;

    try {
      await ApiClient.post('save_fcm_token.php', body: {
        'fcm_token': token,
        'platform': Platform.isAndroid ? 'android' : (Platform.isIOS ? 'ios' : 'other'),
        'device_name': '',
        'app_version': '',
      });
    } catch (e) {
      debugPrint('FCM sync error: $e');
    }
  }

  static Future<void> saveTokenAfterLogin() async => syncTokenToBackend();

  static Future<void> saveTokenToServer() async => syncTokenToBackend();

  static Future<void> registerDeviceToken() async => syncTokenToBackend();

  static Future<void> revokeTokenAfterLogout() async {
    final token = await getToken();
    if (token == null || token.isEmpty) return;
    try {
      await ApiClient.post('revoke_fcm_token.php', body: {'fcm_token': token});
    } catch (e) {
      debugPrint('FCM revoke error: $e');
    }
  }

  static Future<void> deleteTokenAfterLogout() async => revokeTokenAfterLogout();

  static Future<void> removeTokenFromBackend() async => revokeTokenAfterLogout();

  static Future<void> handleInitialMessage() async {
    // minimal: left for future enhancement
  }

  static Future<void> setupInteractedMessage() async {
    // minimal: left for future enhancement
  }

  static Future<void> onLoginSuccess() async {
    await syncTokenToBackend();
  }

  static Future<void> onLogout() async {
    await revokeTokenAfterLogout();
  }

  static bool get isReady => _ready;
}
