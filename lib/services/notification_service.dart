// lib/services/notification_service.dart
// خدمة الإشعارات — Firebase Cloud Messaging

import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import '../firebase_options.dart';

// ─── Background handler (خارج أي class) ──────────────────────────
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService._showLocalNotification(message);
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'coupons_channel',       // channel id
    'كوبونات جديدة',          // channel name
    description: 'إشعارات الكوبونات والعروض الجديدة',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );

  // ─── Initialization ───────────────────────────────────────────
  static Future<void> initialize() async {
    // 1. Local notifications setup
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _localNotifications.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // 2. Create Android channel
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // 3. Firebase Messaging permissions
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    // 4. Get & save token
    try {
      final token = await messaging.getToken();
      debugPrint('📱 FCM Token: $token');
      // TODO: أرسل الـ token للـ backend هنا لتسجيل الجهاز
      // await sendTokenToBackend(token);
    } catch (e) {
      debugPrint('❌ Error getting FCM token: $e');
    }

    // 5. Background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 6. Foreground handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('📬 Foreground notification: ${message.notification?.title}');
      _showLocalNotification(message);
    });

    // 7. Notification opened app (from background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('🔔 Opened from notification: ${message.data}');
      _handleNotificationData(message.data);
    });

    // 8. Check if app opened from terminated state
    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationData(initialMessage.data);
    }
  }

  // ─── Show local notification ──────────────────────────────────
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final androidDetails = AndroidNotificationDetails(
      _channel.id,
      _channel.name,
      channelDescription: _channel.description,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      styleInformation: BigTextStyleInformation(
        notification.body ?? '',
        summaryText: 'كوبوني',
      ),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      ),
      payload: jsonEncode(message.data),
    );
  }

  // ─── Handle notification tap ──────────────────────────────────
  static void _onNotificationTap(NotificationResponse response) {
    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!);
        _handleNotificationData(data);
      } catch (_) {}
    }
  }

  // ─── Navigate based on notification data ──────────────────────
  static void _handleNotificationData(Map<String, dynamic> data) {
    // يمكن إضافة navigation logic هنا
    // مثال: لو في data['coupon_id'] → انقل لصفحة الكوبون
    final couponId = data['coupon_id'];
    if (couponId != null) {
      debugPrint('Navigate to coupon: $couponId');
    }
  }

  // ─── Subscribe to topic ───────────────────────────────────────
  static Future<void> subscribeToTopic(String topic) async {
    await FirebaseMessaging.instance.subscribeToTopic(topic);
    debugPrint('✅ Subscribed to topic: $topic');
  }

  static Future<void> unsubscribeFromTopic(String topic) async {
    await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
    debugPrint('❌ Unsubscribed from topic: $topic');
  }

  // ─── Get FCM token ───────────────────────────────────────────
  static Future<String?> getToken() async {
    return await FirebaseMessaging.instance.getToken();
  }
}