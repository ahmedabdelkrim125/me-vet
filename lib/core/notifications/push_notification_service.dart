import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// خدمة الإشعارات الحقيقية (Push Notifications) — لو التطبيق مقفول أو
/// شغال في الخلفية، Firebase Cloud Messaging (FCM) هو اللي بيوصّل
/// الإشعار للموبايل (زي يوتيوب/فيسبوك بالظبط). لو التطبيق مفتوح قدام
/// المستخدم وقت وصول الإشعار، FCM لوحده مبيعملش حاجة ظاهرة، فبنستخدم
/// flutter_local_notifications عشان نعرضه يدويًا في اللحظة دي.
///
/// المسؤوليات هنا:
/// 1) طلب إذن الإشعارات من المستخدم.
/// 2) تسجيل الجهاز (FCM token) وحفظه في Supabase عشان السيرفر يعرف
///    يبعتله.
/// 3) عرض أي إشعار بيوصل والتطبيق مفتوح.
///
/// إرسال الإشعار الفعلي (لما حد الائتمان يتخطى مثلًا) بيحصل من ناحية
/// Supabase (trigger + Edge Function)، مش من هنا — الكلاس ده استقبال
/// وتسجيل بس.
///
/// كل الـ logs هنا مبدوءة بـ [Push] عشان تتفلتر بسهولة في الـ console.
/// دي logs تشخيصية مؤقتة، هنقللها بعد ما نتأكد كل حاجة شغالة.
class PushNotificationService {
  PushNotificationService._internal();

  static final PushNotificationService instance =
      PushNotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const String _androidChannelId = 'mivet_default_channel';

  /// لازم تتنادى مرة واحدة بس، بدري في main() قبل runApp.
  Future<void> initializeLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _localNotifications.initialize(initSettings);

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

    // إشعار جاي والتطبيق مفتوح قدام المستخدم فعليًا.
    FirebaseMessaging.onMessage.listen(_showLocalNotification);
    debugPrint('[Push] initializeLocalNotifications: خلصت بنجاح');
  }

  /// لازم تتنادى بعد ما اليوزر يسجّل دخول بنجاح (أو لما جلسة محفوظة
  /// ترجع تلقائيًا) — بتطلب الإذن (لو محتاج) وتسجّل الـ token في
  /// Supabase عشان يبقى معروف نبعتله.
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

      // التوكن بيتغيّر أحيانًا (إعادة تثبيت، مسح بيانات...)، فلازم نتابعه.
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

  /// لو المستخدم عمل logout، الأفضل نمسح الـ token بتاع الجهاز ده من
  /// الجدول عشان ميوصلوش إشعارات وهو مش مسجّل دخول.
  Future<void> unregisterDevice() async {
    final token = await _messaging.getToken();
    if (token == null) return;
    try {
      await Supabase.instance.client
          .from('device_push_tokens')
          .delete()
          .eq('token', token);
    } catch (_) {
      // مش حرجة — لو فشلت، الـ token هيتحدّث/يتمسح لوحده مع الوقت.
    }
  }

  void _showLocalNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannelId,
          'إشعارات ميفيت',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  /// المفروض تكون top-level أو static (مش closure) عشان Flutter يقدر
  /// يناديها من عملية منفصلة (isolate) لما التطبيق يكون مقفول تمامًا.
  @pragma('vm:entry-point')
  static Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
    // مفيش حاجة لازم نعملها هنا فعليًا — النظام (أندرويد/آيفون) بيعرض
    // الإشعار الجاهز من جوه الـ "notification" payload لوحده حتى لو
    // التطبيق مقفول. الدالة دي مطلوبة كـ registration بس عشان FCM
    // يقدر يوقظ التطبيق في الخلفية لو احتاج.
  }
}
