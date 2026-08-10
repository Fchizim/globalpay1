import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class PushNotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  static const _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'Used for transaction alerts',
    importance: Importance.high,
    playSound: true, // uses the default system notification sound
  );

  static Future<void> initialize() async {
    print('🔵 [1] initialize() started');

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    print('🔵 [2] Push permission status: ${settings.authorizationStatus}');

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _localNotifications.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );
    print('🔵 [3] Local notifications initialized');

    await _localNotifications
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
    print('🔵 [4] Android channel created (no-op on iOS)');

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    print('🔵 [5] Foreground presentation options set');

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification != null) {
        _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _channel.id,
              _channel.name,
              channelDescription: _channel.description,
              importance: Importance.high,
              priority: Priority.high,
              playSound: true,
            ),
            iOS: const DarwinNotificationDetails(
              presentSound: true,
            ),
          ),
        );
      }
    });
    print('🔵 [6] onMessage listener attached');

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleMessageTap(message);
    });
    print('🔵 [7] onMessageOpenedApp listener attached');

    // ── getInitialMessage() can hang indefinitely on iOS if the APNs
    // device token hasn't resolved internally yet. Wrap it in a timeout
    // so a slow/stuck APNs registration never blocks app startup.
    RemoteMessage? initialMessage;
    try {
      initialMessage = await _messaging.getInitialMessage().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print('🔵 [8-TIMEOUT] getInitialMessage() timed out after 5s, continuing anyway');
          return null;
        },
      );
      print('🔵 [8] getInitialMessage done: $initialMessage');
    } catch (e) {
      print('🔵 [8-ERROR] getInitialMessage threw: $e');
    }

    if (initialMessage != null) {
      _handleMessageTap(initialMessage);
    }

    print('🔵 [9] initialize() FINISHED');
  }

  static void _handleMessageTap(RemoteMessage message) {
    print('Notification tapped, data: ${message.data}');
  }

  /// Call this after login to get the token and send it to your backend.
  /// On iOS, the APNs device token can take a few seconds to arrive after
  /// permission is granted — FirebaseMessaging.getToken() will throw
  /// [firebase_messaging/apns-token-not-set] if called too early. This
  /// waits (with retries) for the APNs token to be ready first.
  static Future<String?> getToken() async {
    if (!kIsWeb && (Platform.isIOS || Platform.isMacOS)) {
      String? apnsToken = await _messaging.getAPNSToken();
      int attempts = 0;
      while (apnsToken == null && attempts < 10) {
        await Future.delayed(const Duration(milliseconds: 500));
        apnsToken = await _messaging.getAPNSToken();
        attempts++;
      }
      if (apnsToken == null) {
        print('⚠️ APNS token still not available after waiting — FCM token fetch will likely fail');
      }
    }

    try {
      return await _messaging.getToken();
    } catch (e) {
      print('Could not get FCM token: $e');
      return null;
    }
  }
}