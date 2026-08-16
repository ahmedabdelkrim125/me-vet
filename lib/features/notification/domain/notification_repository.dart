import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/app_notification_model.dart';
import 'models/notification_type.dart';

class NotificationRepository {
  NotificationRepository._internal();

  static final NotificationRepository instance =
      NotificationRepository._internal();

  static const String _storageKey = 'app_notifications';

  final List<AppNotificationModel> _notifications = [];
  final ValueNotifier<List<AppNotificationModel>> notificationsNotifier =
      ValueNotifier<List<AppNotificationModel>>(<AppNotificationModel>[]);

  bool _initialized = false;

  List<AppNotificationModel> get notifications => _notifications;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> initialize() async {
    if (_initialized) return;

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_storageKey);

    if (raw != null && raw.isNotEmpty) {
      _notifications
        ..clear()
        ..addAll(
            raw.map((entry) => AppNotificationModel.fromJsonString(entry)));
    } else {
      _notifications
        ..clear()
        ..addAll(_seedNotifications);
      await _persist(prefs);
    }

    _sort();
    notificationsNotifier.value =
        List<AppNotificationModel>.from(_notifications);
    _initialized = true;
  }

  void _sort() {
    _notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> push({
    required NotificationType type,
    required String title,
    required String message,
    String? relatedId,
  }) async {
    await initialize();
    _notifications.insert(
      0,
      AppNotificationModel(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        type: type,
        title: title,
        message: message,
        createdAt: DateTime.now(),
        relatedId: relatedId,
      ),
    );
    await _persist();
    notificationsNotifier.value =
        List<AppNotificationModel>.from(_notifications);
  }

  Future<void> markAsRead(String id) async {
    await initialize();
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index == -1) return;
    _notifications[index] = _notifications[index].copyWith(isRead: true);
    await _persist();
    notificationsNotifier.value =
        List<AppNotificationModel>.from(_notifications);
  }

  Future<void> markAllAsRead() async {
    await initialize();
    for (var i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
    await _persist();
    notificationsNotifier.value =
        List<AppNotificationModel>.from(_notifications);
  }

  Future<void> remove(String id) async {
    await initialize();
    _notifications.removeWhere((n) => n.id == id);
    await _persist();
    notificationsNotifier.value =
        List<AppNotificationModel>.from(_notifications);
  }

  Future<void> clearAll() async {
    await initialize();
    _notifications.clear();
    await _persist();
    notificationsNotifier.value =
        List<AppNotificationModel>.from(_notifications);
  }

  Future<void> _persist([SharedPreferences? preferences]) async {
    final prefs = preferences ?? await SharedPreferences.getInstance();
    final encoded = _notifications.map((n) => n.toJsonString()).toList();
    await prefs.setStringList(_storageKey, encoded);
  }

  static List<AppNotificationModel> get _seedNotifications {
    final now = DateTime.now();
    return [
      AppNotificationModel(
        id: 'seed-1',
        type: NotificationType.vehicleStockLow,
        title: 'مخزون العربية منخفض',
        message:
            'صنف "فيتامين أ د3 إي" في عربيتك قل عن الحد الأدنى (متبقي 4 وحدات).',
        createdAt: now.subtract(const Duration(minutes: 20)),
      ),
      AppNotificationModel(
        id: 'seed-2',
        type: NotificationType.visitReminder,
        title: 'تذكير بزيارة',
        message: 'عيادة الشفاء البيطرية معاهاش زيارة من أسبوعين.',
        createdAt: now.subtract(const Duration(hours: 3)),
        relatedId: '2',
      ),
      AppNotificationModel(
        id: 'seed-3',
        type: NotificationType.creditLimitWarning,
        title: 'اقتراب من حد الائتمان',
        message: 'رصيد "مزرعة الفا لارج" وصل لـ 90٪ من حد الائتمان المسموح.',
        createdAt: now.subtract(const Duration(hours: 6)),
        relatedId: '5',
        isRead: true,
      ),
      AppNotificationModel(
        id: 'seed-4',
        type: NotificationType.customerStalled,
        title: 'عميل متوقف',
        message: 'مزرعة الدلتا للدواجن توقفت عن الطلب من شهرين.',
        createdAt: now.subtract(const Duration(days: 1)),
        relatedId: '3',
        isRead: true,
      ),
      AppNotificationModel(
        id: 'seed-5',
        type: NotificationType.mainStockLow,
        title: 'مخزون منخفض',
        message:
            'صنف "مضاد حيوي واسع المجال" في المخزن الرئيسي قل عن الحد الأدنى.',
        createdAt: now.subtract(const Duration(days: 1, hours: 4)),
        isRead: true,
      ),
      AppNotificationModel(
        id: 'seed-6',
        type: NotificationType.dailyReportReminder,
        title: 'تذكير بتقرير اليوم',
        message: 'لسه ما بعتّش تقرير اليوم للإدارة.',
        createdAt: now.subtract(const Duration(days: 2)),
        isRead: true,
      ),
    ];
  }
}
