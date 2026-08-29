import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


class PushNotificationService {
  PushNotificationService._internal();

  static final PushNotificationService instance =
      PushNotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const String _androidChannelId = 'mivet_default_channel';

  Future<void> initializeLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _localNotifications.initialize(settings: initSettings);

    const channel = AndroidNotificationChannel(
      _androidChannelId,
      'إشعارات ميفيت',
      description: 'تنبيهات المخزون، العملاء، والتقارير',
      importance: Importance.high,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    FirebaseMessaging.onMessage.listen(_showLocalNotification);
    debugPrint('[Push] initializeLocalNotifications: خلصت بنجاح');
  }


  Future<void> registerDeviceForCurrentUser() async {
    debugPrint('[Push] registerDeviceForCurrentUser: بدأت');
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      debugPrint('[Push] current user_id = $userId');
      if (userId == null) {
        debugPrint('[Push] توقف: مفيش يوزر مسجّل دخول دلوقتي');
        return;
      }

      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint('[Push] نتيجة طلب الإذن: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('[Push] توقف: المستخدم رفض إذن الإشعارات');
        return;
      }

      final token = await _messaging.getToken();
      debugPrint('[Push] getToken() رجّع: '
          '${token == null ? "null" : "token طوله ${token.length} حرف"}');

      if (token == null) {
        debugPrint('[Push] توقف: مفيش token — على الأغلب مفيش Google '
            'Play Services متاحة على الجهاز/الإيميولاتور ده');
        return;
      }

      await _saveToken(token);

      _messaging.onTokenRefresh.listen((newToken) {
        debugPrint('[Push] onTokenRefresh: token جديد وصل');
        _saveToken(newToken);
      });

      debugPrint('[Push] registerDeviceForCurrentUser: خلصت بنجاح');
    } catch (e, stack) {
      debugPrint('[Push] EXCEPTION في registerDeviceForCurrentUser: $e');
      debugPrint('[Push] Stack trace: $stack');
    }
  }

  Future<void> _saveToken(String token) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      debugPrint('[Push] _saveToken: مفيش user_id، هتوقف من غير حفظ');
      return;
    }

    debugPrint('[Push] _saveToken: هحفظ token للـ user_id=$userId');
    try {
      final result = await Supabase.instance.client
          .from('device_push_tokens')
          .upsert(
            {
              'user_id': userId,
              'token': token,
              'platform': Platform.isIOS ? 'ios' : 'android',
              'updated_at': DateTime.now().toIso8601String(),
            },
            onConflict: 'token',
          )
          .select();
      debugPrint('[Push] _saveToken: نجح الحفظ — النتيجة: $result');
    } catch (e, stack) {
      debugPrint('[Push] _saveToken: فشل الحفظ — $e');
      debugPrint('[Push] Stack trace: $stack');
    }
  }


  Future<void> unregisterDevice() async {
    final token = await _messaging.getToken();
    if (token == null) return;
    try {
      await Supabase.instance.client
          .from('device_push_tokens')
          .delete()
          .eq('token', token);
    } catch (_) {
    }
  }

  void _showLocalNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _localNotifications.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannelId,
          'إشعارات ميفيت',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }


  @pragma('vm:entry-point')
  static Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  
  }
}
