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
    try {
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
    } catch (e) {
      debugPrint('❌ Error initializing local notifications: $e');
    }

    // 2. Create Android channel
    try {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);
    } catch (e) {
      debugPrint('❌ Error creating Android notification channel: $e');
    }

    // 3. Firebase Messaging permissions
    FirebaseMessaging? messaging;
    try {
      messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
    } catch (e) {
      debugPrint('❌ Error requesting Firebase Messaging permissions: $e');
    }

    // 4. Get & save token
    if (messaging != null) {
      try {
        final token = await messaging.getToken();
        debugPrint('📱 FCM Token: $token');
      } catch (e) {
        debugPrint('❌ Error getting FCM token: $e');
      }
    }

    // 5. Background handler
    try {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    } catch (e) {
      debugPrint('❌ Error setting background message handler: $e');
    }

    // 6. Foreground handler
    try {
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('📬 Foreground notification: ${message.notification?.title}');
        _showLocalNotification(message);
      });
    } catch (e) {
      debugPrint('❌ Error setting foreground message listener: $e');
    }

    // 7. Notification opened app (from background)
    try {
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('🔔 Opened from notification: ${message.data}');
        _handleNotificationData(message.data);
      });
    } catch (e) {
      debugPrint('❌ Error setting message opened app listener: $e');
    }

    // 8. Check if app opened from terminated state
    if (messaging != null) {
      try {
        final initialMessage = await messaging.getInitialMessage();
        if (initialMessage != null) {
          _handleNotificationData(initialMessage.data);
        }
      } catch (e) {
        debugPrint('❌ Error checking initial message: $e');
      }
    }

    // 9. Schedule daily local reminder
    try {
      await scheduleDailyReminder();
    } catch (e) {
      debugPrint('❌ Error scheduling daily reminder: $e');
    }
  }

  // ─── Schedule Daily Local Reminder ─────────────────────────────
  static Future<void> scheduleDailyReminder() async {
    const androidDetails = AndroidNotificationDetails(
      'daily_reminder_channel',
      'تذكير يومي للتوفير',
      channelDescription: 'تذكير يومي بأفضل العروض وكوبونات الخصم',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    try {
      // Schedule a daily periodic notification
      await _localNotifications.periodicallyShow(
        999, // Constant notification ID for daily reminder
        'أدِر عجلة التوفير اليومية! 🎁',
        'لا تفوت فرصة الفوز بكوبونات خصم ونقاط إضافية اليوم. أدر العجلة الآن!',
        RepeatInterval.daily,
        const NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
      debugPrint('🔔 Daily reminder scheduled successfully!');
    } catch (e) {
      debugPrint('❌ Error scheduling daily reminder: $e');
    }
  }

  // ─── Cancel Daily Local Reminder ───────────────────────────────
  static Future<void> cancelDailyReminder() async {
    try {
      await _localNotifications.cancel(999);
      debugPrint('🔔 Daily reminder cancelled successfully!');
    } catch (e) {
      debugPrint('❌ Error cancelling daily reminder: $e');
    }
  }

  // ─── Show Instant Test Notification ────────────────────────────
  static Future<void> showInstantTestNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'test_channel',
      'إشعار تجريبي',
      channelDescription: 'قناة اختبار الإشعارات الفورية',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    try {
      await _localNotifications.show(
        888, // Constant ID for test
        'إشعار تجريبي من كوبوني 🎉',
        'تهانينا! الإشعارات تعمل بشكل سليم على جهازك. وفر حتى 70% الآن!',
        const NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
        ),
      );
      debugPrint('🔔 Test notification sent successfully!');
    } catch (e) {
      debugPrint('❌ Error sending test notification: $e');
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