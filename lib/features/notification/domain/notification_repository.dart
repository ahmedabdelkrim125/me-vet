import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'models/app_notification_model.dart';
import 'models/notification_type.dart';

/// إشعارات حقيقية من جدول `notifications` في Supabase — بدل الداتا
/// الوهمية اللي كانت متخزنة محليًا (SharedPreferences) قبل كده.
///
/// أغلب الإشعارات (زي حد الائتمان) بتتسجل من ناحية السيرفر نفسه
/// (Postgres trigger)، مش من هنا. الكلاس ده مسؤوليته: يجيب الإشعارات
/// بتاعة اليوزر الحالي، يعرضها، يتابعها لحظيًا (Realtime) عشان أي
/// إشعار جديد يبان في الشاشة أول ما يتسجل من غير ما تحتاج تقفل
/// وتفتح التطبيق، ويحدّث حالة القراءة/الحذف.
///
/// `push()` لسه موجودة (نفس الاسم والباراميترز بالظبط) عشان
/// MockInventoryRepository يقدر يكمل يستخدمها زي ما هي لحد ما فيتشر
/// المخزون يتهاجر هو كمان لـ Supabase — الفرق إنها دلوقتي بتكتب في
/// Supabase فعليًا بدل التخزين المحلي.
class NotificationRepository {
  NotificationRepository._internal();

  static final NotificationRepository instance =
      NotificationRepository._internal();

  SupabaseClient get _supabase => Supabase.instance.client;

  final List<AppNotificationModel> _notifications = [];
  final ValueNotifier<List<AppNotificationModel>> notificationsNotifier =
      ValueNotifier<List<AppNotificationModel>>(<AppNotificationModel>[]);

  bool _initialized = false;
  RealtimeChannel? _channel;

  List<AppNotificationModel> get notifications => _notifications;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  /// أول مرة بس: بتجيب الإشعارات وتفتح الاشتراك اللحظي (Realtime).
  /// النداءات اللي بعد كده مبتعملش حاجة — استخدم [refresh] لو عايز
  /// تجبر تحديث فوري (زي أول ما شاشة الإشعارات تتفتح).
  Future<void> initialize() async {
    if (_initialized) return;
    await _fetch();
    _listenForRealtimeChanges();
    _initialized = true;
  }

  /// بيعيد تحميل الإشعارات من Supabase — استخدمها لما تفتح شاشة
  /// الإشعارات عشان تتأكد إن أي إشعار وصل والتطبيق كان مقفول/في شاشة
  /// تانية يبان فورًا.
  Future<void> refresh() => _fetch();

  Future<void> _fetch() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      _notifications.clear();
      notificationsNotifier.value = <AppNotificationModel>[];
      return;
    }

    try {
      final rows = await _supabase
          .from('notifications')
          .select()
          .order('created_at', ascending: false);
      _notifications
        ..clear()
        ..addAll((rows as List).map((row) =>
            AppNotificationModel.fromSupabaseRow(row as Map<String, dynamic>)));
      notificationsNotifier.value =
          List<AppNotificationModel>.from(_notifications);
    } catch (e) {
      debugPrint('[Notifications] فشل تحميل الإشعارات: $e');
    }
  }

  /// أي إضافة/تعديل/حذف على صف إشعارات اليوزر الحالي (سواء من التطبيق
  /// نفسه أو من trigger في السيرفر) بيوصلنا هنا لحظيًا، فبنعيد التحميل.
  void _listenForRealtimeChanges() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    _channel = _supabase
        .channel('public:notifications:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) => _fetch(),
        )
        .subscribe();
  }

  Future<void> dispose() async {
    final channel = _channel;
    if (channel != null) await _supabase.removeChannel(channel);
    _channel = null;
    _initialized = false;
  }

  Future<void> reset() async {
    await dispose();
    _notifications.clear();
    notificationsNotifier.value = <AppNotificationModel>[];
  }

  /// إنشاء إشعار للمستخدم الحالي نفسه — مستخدمة دلوقتي من
  /// MockInventoryRepository بس (تنبيهات المخزون لسه محلية). الإشعارات
  /// الحقيقية التانية (حد الائتمان مثلًا) بتتسجل من trigger في
  /// Supabase مباشرة، مش من هنا.
  Future<void> push({
    required NotificationType type,
    required String title,
    required String message,
    String? relatedId,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _supabase.from('notifications').insert({
        'user_id': userId,
        'type': type.dbValue,
        'title': title,
        'message': message,
        if (relatedId != null) 'related_id': relatedId,
      });
      // في الأغلب الـ Realtime subscription هيلقطها لوحده، بس بنعمل
      // fetch يدوي كمان للأمان لو الـ Realtime لسه ما اتفعّلش.
      await _fetch();
    } catch (e) {
      debugPrint('[Notifications] push فشل: $e');
    }
  }

  Future<void> markAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      // تحديث محلي فوري عشان الواجهة تستجيب على طول من غير ما تستنى
      // رحلة الشبكة، والتحديث الحقيقي في Supabase بيحصل بعدها.
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      notificationsNotifier.value =
          List<AppNotificationModel>.from(_notifications);
    }

    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true}).eq('id', id);
    } catch (e) {
      debugPrint('[Notifications] markAsRead فشل: $e');
    }
  }

  Future<void> markAllAsRead() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    for (var i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
    notificationsNotifier.value =
        List<AppNotificationModel>.from(_notifications);

    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);
    } catch (e) {
      debugPrint('[Notifications] markAllAsRead فشل: $e');
    }
  }

  Future<void> remove(String id) async {
    _notifications.removeWhere((n) => n.id == id);
    notificationsNotifier.value =
        List<AppNotificationModel>.from(_notifications);

    try {
      await _supabase.from('notifications').delete().eq('id', id);
    } catch (e) {
      debugPrint('[Notifications] remove فشل: $e');
    }
  }

  Future<void> clearAll() async {
    final userId = _supabase.auth.currentUser?.id;
    _notifications.clear();
    notificationsNotifier.value = <AppNotificationModel>[];
    if (userId == null) return;

    try {
      await _supabase.from('notifications').delete().eq('user_id', userId);
    } catch (e) {
      debugPrint('[Notifications] clearAll فشل: $e');
    }
  }
}
