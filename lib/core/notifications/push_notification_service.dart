import 'dart:convert';
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

  bool _localNotificationsInitialized = false;
  bool _tokenRefreshListenerRegistered = false;

  Future<void> initializeLocalNotifications() async {
    if (_localNotificationsInitialized) {
      debugPrint('[Push] initializeLocalNotifications: اتنادت قبل كده، هتجاهل');
      return;
    }

    try {
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      const initSettings = InitializationSettings(
        android: androidInit,
        iOS: iosInit,
      );
      await _localNotifications.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: _onLocalNotificationTapped,
      );

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

      await _messaging.setForegroundNotificationPresentationOptions(
        alert: false,
        badge: true,
        sound: false,
      );

      FirebaseMessaging.onMessage.listen(_showLocalNotification);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }

      _localNotificationsInitialized = true;
      debugPrint('[Push] initializeLocalNotifications: خلصت بنجاح');
    } catch (e, stack) {
      debugPrint('[Push] EXCEPTION في initializeLocalNotifications: $e');
      debugPrint('[Push] Stack trace: $stack');
    }
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

      if (!_tokenRefreshListenerRegistered) {
        _tokenRefreshListenerRegistered = true;
        _messaging.onTokenRefresh.listen((newToken) {
          debugPrint('[Push] onTokenRefresh: token جديد وصل');
          _saveToken(newToken);
        });
      }

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
      final result =
          await Supabase.instance.client.from('device_push_tokens').upsert(
        {
          'user_id': userId,
          'token': token,
          'platform': Platform.isIOS ? 'ios' : 'android',
          'updated_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'token',
      ).select();
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
    } catch (_) {}
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
        iOS: DarwinNotificationDetails(),
      ),
      payload: jsonEncode(message.data),
    );
  }

  void _onLocalNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;
    try {
      final data = Map<String, dynamic>.from(
        jsonDecode(payload) as Map,
      );
      _logNotificationTap(data);
    } catch (e) {
      debugPrint('[Push] _onLocalNotificationTapped: فشل decode للـ payload — $e');
    }
  }

  void _handleNotificationTap(RemoteMessage message) {
    _logNotificationTap(message.data);
  }

  void _logNotificationTap(Map<String, dynamic> data) {
    final type = data['type'];
    final relatedId = data['related_id'];
    debugPrint('[Push] notification tapped: type=$type related_id=$relatedId');
  }

  @pragma('vm:entry-point')
  static Future<void> firebaseBackgroundHandler(RemoteMessage message) async {}
}