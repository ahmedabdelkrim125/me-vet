import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/models/visit_status.dart';

class VisitRow {
  final String id;
  final String customerId;
  final int stopOrder;
  final RouteVisitStatus status;
  final DateTime scheduledAt;
  final DateTime statusUpdatedAt;

  const VisitRow({
    required this.id,
    required this.customerId,
    required this.stopOrder,
    required this.status,
    required this.scheduledAt,
    required this.statusUpdatedAt,
  });

  factory VisitRow.fromSupabaseRow(Map<String, dynamic> row) {
    return VisitRow(
      id: row['id'] as String,
      customerId: row['customer_id'] as String,
      stopOrder: (row['stop_order'] as num?)?.toInt() ?? 1,
      status: routeVisitStatusFromDb(row['status'] as String?),
      scheduledAt: DateTime.parse(row['scheduled_at'] as String),
      statusUpdatedAt: DateTime.parse(row['status_updated_at'] as String),
    );
  }
}

class ScheduleRow {
  final String id;
  final String customerId;
  final int weekday;
  final int hour;
  final int minute;

  const ScheduleRow({
    required this.id,
    required this.customerId,
    required this.weekday,
    required this.hour,
    required this.minute,
  });

  factory ScheduleRow.fromRow(Map<String, dynamic> row) {
    return ScheduleRow(
      id: row['id'] as String,
      customerId: row['customer_id'] as String,
      weekday: (row['weekday'] as num).toInt(),
      hour: (row['visit_hour'] as num).toInt(),
      minute: (row['visit_minute'] as num).toInt(),
    );
  }
}

class VisitsRepository {
  VisitsRepository._internal();

  static final VisitsRepository instance = VisitsRepository._internal();

  SupabaseClient get _supabase => Supabase.instance.client;

  DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

  Future<List<VisitRow>> getVisitsForDay(DateTime day) async {
    final start = _startOfDay(day);
    final end = start.add(const Duration(days: 1));
    final rows = await _supabase
        .from('customer_visits')
        .select()
        .gte('scheduled_at', start.toIso8601String())
        .lt('scheduled_at', end.toIso8601String())
        .order('stop_order', ascending: true);
    return (rows as List)
        .map((row) => VisitRow.fromSupabaseRow(row as Map<String, dynamic>))
        .toList();
  }

  Future<List<VisitRow>> getVisitsForCustomer(String customerId) async {
    final rows = await _supabase
        .from('customer_visits')
        .select()
        .eq('customer_id', customerId)
        .order('scheduled_at', ascending: false);
    return (rows as List)
        .map((row) => VisitRow.fromSupabaseRow(row as Map<String, dynamic>))
        .toList();
  }

  Future<List<VisitRow>> getVisitsInRange(DateTime start, DateTime end) async {
    final rows = await _supabase
        .from('customer_visits')
        .select()
        .gte('scheduled_at', start.toIso8601String())
        .lt('scheduled_at', end.toIso8601String());
    return (rows as List)
        .map((row) => VisitRow.fromSupabaseRow(row as Map<String, dynamic>))
        .toList();
  }

  Future<void> setTodayRoute(List<String> customerIds) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    final today = _startOfDay(DateTime.now());

    final existing = await getVisitsForDay(today);
    final existingByCustomer = {for (final v in existing) v.customerId: v};
    final keepIds = customerIds.toSet();

    final toDelete = existing
        .where((v) =>
            !keepIds.contains(v.customerId) &&
            v.status == RouteVisitStatus.pending)
        .map((v) => v.id)
        .toList();

    for (final id in toDelete) {
      await _supabase.from('customer_visits').delete().eq('id', id);
    }

    for (int i = 0; i < customerIds.length; i++) {
      final customerId = customerIds[i];
      final existingVisit = existingByCustomer[customerId];
      if (existingVisit != null) {
        await _supabase
            .from('customer_visits')
            .update({'stop_order': i + 1}).eq('id', existingVisit.id);
      } else {
        await _supabase.from('customer_visits').insert({
          'customer_id': customerId,
          'rep_id': userId,
          'stop_order': i + 1,
          'status': RouteVisitStatus.pending.dbValue,
          'scheduled_at': today.toIso8601String(),
        });
      }
    }
  }

  Future<void> updateStatus(String visitId, RouteVisitStatus status) async {
    await _supabase.from('customer_visits').update({
      'status': status.dbValue,
      'status_updated_at': DateTime.now().toIso8601String(),
    }).eq('id', visitId);
  }

  Future<void> updateStatusByCustomer(
    String customerId,
    RouteVisitStatus status,
  ) async {
    final today = _startOfDay(DateTime.now());
    final tomorrow = today.add(const Duration(days: 1));
    await _supabase
        .from('customer_visits')
        .update({
          'status': status.dbValue,
          'status_updated_at': DateTime.now().toIso8601String(),
        })
        .eq('customer_id', customerId)
        .gte('scheduled_at', today.toIso8601String())
        .lt('scheduled_at', tomorrow.toIso8601String());
  }

  Future<void> removeFromToday(String customerId) async {
    final today = _startOfDay(DateTime.now());
    final tomorrow = today.add(const Duration(days: 1));
    await _supabase
        .from('customer_visits')
        .delete()
        .eq('customer_id', customerId)
        .gte('scheduled_at', today.toIso8601String())
        .lt('scheduled_at', tomorrow.toIso8601String());
  }

  Future<void> reorderToday(List<String> orderedCustomerIds) async {
    for (int i = 0; i < orderedCustomerIds.length; i++) {
      await updateStopOrderByCustomer(orderedCustomerIds[i], i + 1);
    }
  }

  Future<void> updateStopOrderByCustomer(String customerId, int order) async {
    final today = _startOfDay(DateTime.now());
    final tomorrow = today.add(const Duration(days: 1));
    await _supabase
        .from('customer_visits')
        .update({'stop_order': order})
        .eq('customer_id', customerId)
        .gte('scheduled_at', today.toIso8601String())
        .lt('scheduled_at', tomorrow.toIso8601String());
  }

  Future<DateTime?> lastVisitDateForCustomer(String customerId) async {
    final rows = await _supabase
        .from('customer_visits')
        .select('scheduled_at')
        .eq('customer_id', customerId)
        .neq('status', RouteVisitStatus.pending.dbValue)
        .order('scheduled_at', ascending: false)
        .limit(1);
    final list = rows as List;
    if (list.isEmpty) return null;
    return DateTime.parse(
        (list.first as Map<String, dynamic>)['scheduled_at'] as String);
  }

  Future<List<VisitRow>> getVisitsForWeek(DateTime anyDayInWeek) async {
    final start = _startOfWeek(anyDayInWeek);
    final end = start.add(const Duration(days: 7));
    final rows = await _supabase
        .from('customer_visits')
        .select()
        .gte('scheduled_at', start.toIso8601String())
        .lt('scheduled_at', end.toIso8601String())
        .order('scheduled_at', ascending: true)
        .order('stop_order', ascending: true);
    return (rows as List)
        .map((row) => VisitRow.fromSupabaseRow(row as Map<String, dynamic>))
        .toList();
  }

  Future<void> scheduleVisit({
    required String customerId,
    required DateTime scheduledAt,
    int stopOrder = 1,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    final dayStart = _startOfDay(scheduledAt);
    final dayEnd = dayStart.add(const Duration(days: 1));

    final existing = await _supabase
        .from('customer_visits')
        .select('id')
        .eq('customer_id', customerId)
        .gte('scheduled_at', dayStart.toIso8601String())
        .lt('scheduled_at', dayEnd.toIso8601String())
        .maybeSingle();

    if (existing != null) {
      await _supabase
          .from('customer_visits')
          .update({'scheduled_at': scheduledAt.toIso8601String()})
          .eq('id', existing['id'] as String);
      return;
    }

    await _supabase.from('customer_visits').insert({
      'customer_id': customerId,
      'rep_id': userId,
      'stop_order': stopOrder,
      'status': RouteVisitStatus.pending.dbValue,
      'scheduled_at': scheduledAt.toIso8601String(),
    });
  }

  Future<void> rescheduleVisit(String visitId, DateTime newDate) async {
    await _supabase
        .from('customer_visits')
        .update({'scheduled_at': newDate.toIso8601String()}).eq('id', visitId);
  }

  Future<void> removeVisit(String visitId) async {
    await _supabase.from('customer_visits').delete().eq('id', visitId);
  }

  Future<List<VisitRow>> pendingVisitsForDay(DateTime day) async {
    final start = _startOfDay(day);
    final end = start.add(const Duration(days: 1));
    final rows = await _supabase
        .from('customer_visits')
        .select()
        .eq('status', RouteVisitStatus.pending.dbValue)
        .gte('scheduled_at', start.toIso8601String())
        .lt('scheduled_at', end.toIso8601String());
    return (rows as List)
        .map((row) => VisitRow.fromSupabaseRow(row as Map<String, dynamic>))
        .toList();
  }

  Future<void> carryVisitsToDay(
    List<String> visitIds,
    DateTime targetDay,
  ) async {
    final target = _startOfDay(targetDay).add(const Duration(hours: 9));
    for (final id in visitIds) {
      await _supabase
          .from('customer_visits')
          .update({'scheduled_at': target.toIso8601String()}).eq('id', id);
    }
  }

  DateTime _startOfWeek(DateTime d) {
    final day = _startOfDay(d);
    return day.subtract(Duration(days: day.weekday % 7));
  }

  Future<List<ScheduleRow>> getScheduleForCustomer(String customerId) async {
    final rows = await _supabase
        .from('customer_schedule')
        .select()
        .eq('customer_id', customerId)
        .order('weekday', ascending: true);
    return (rows as List)
        .map((r) => ScheduleRow.fromRow(r as Map<String, dynamic>))
        .toList();
  }

  Future<List<ScheduleRow>> getMySchedule() async {
    final rows = await _supabase
        .from('customer_schedule')
        .select()
        .order('weekday', ascending: true)
        .order('visit_hour', ascending: true);
    return (rows as List)
        .map((r) => ScheduleRow.fromRow(r as Map<String, dynamic>))
        .toList();
  }

  Future<void> addSchedule({
    required String customerId,
    required int weekday,
    required int hour,
    required int minute,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    await _supabase.from('customer_schedule').upsert({
      'customer_id': customerId,
      'rep_id': userId,
      'weekday': weekday,
      'visit_hour': hour,
      'visit_minute': minute,
    }, onConflict: 'customer_id,weekday');
  }

  Future<void> removeSchedule(String scheduleId) async {
    await _supabase.from('customer_schedule').delete().eq('id', scheduleId);
  }
}
