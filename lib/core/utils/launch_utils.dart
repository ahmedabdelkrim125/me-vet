import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// دوال مشتركة لفتح المكالمة / واتساب / الخرائط من أي مكان في التطبيق.
/// كل دالة بتوريك SnackBar واضح لو العملية فشلت (رقم فاضي، مفيش تطبيق
/// يقدر يفتح الرابط، إلخ) بدل ما تفشل بصمت.
class LaunchUtils {
  LaunchUtils._();

  static Future<void> call(BuildContext context, String phone) async {
    if (phone.trim().isEmpty) {
      _showMessage(context, 'لا يوجد رقم هاتف مسجل لهذا العميل');
      return;
    }
    final uri = Uri(scheme: 'tel', path: phone.trim());
    await _launch(context, uri, 'تعذر فتح تطبيق الاتصال');
  }

  static Future<void> whatsapp(
    BuildContext context,
    String phone, {
    String? message,
  }) async {
    if (phone.trim().isEmpty) {
      _showMessage(context, 'لا يوجد رقم هاتف مسجل لهذا العميل');
      return;
    }
    final normalized = _normalizePhone(phone);
    final query = message != null && message.isNotEmpty
        ? '?text=${Uri.encodeComponent(message)}'
        : '';
    final uri = Uri.parse('https://wa.me/$normalized$query');
    await _launch(context, uri, 'تعذر فتح واتساب');
  }

  static Future<void> openMap(BuildContext context, String address) async {
    if (address.trim().isEmpty) {
      _showMessage(context, 'لا يوجد عنوان مسجل لهذا العميل');
      return;
    }
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1'
      '&query=${Uri.encodeComponent(address)}',
    );
    await _launch(context, uri, 'تعذر فتح تطبيق الخرائط');
  }

  /// بيفتح الخرائط بالظبط على نقطة محددة بالإحداثيات (lat/lng)، مش بحث
  /// نصي عن اسم/عنوان — أدق بكتير لو العميل عنده موقع GPS محفوظ.
  static Future<void> openMapAtCoordinates(
    BuildContext context,
    double latitude,
    double longitude,
  ) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1'
      '&query=$latitude,$longitude',
    );
    await _launch(context, uri, 'تعذر فتح تطبيق الخرائط');
  }

  /// يحوّل رقم مصري محلي (01xxxxxxxxx) لصيغة دولية (+20) عشان wa.me
  /// يقبله. لو الرقم أصلًا دولي (+ أو 00) بيسيبه زي ما هو.
  static String _normalizePhone(String phone) {
    var digits = phone.trim().replaceAll(RegExp(r'[^0-9+]'), '');
    if (digits.startsWith('+')) digits = digits.substring(1);
    if (digits.startsWith('00')) digits = digits.substring(2);
    if (digits.startsWith('0')) digits = '20${digits.substring(1)}';
    return digits;
  }

  static Future<void> _launch(
    BuildContext context,
    Uri uri,
    String errorMessage,
  ) async {
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        _showMessage(context, errorMessage);
      }
    } catch (_) {
      if (context.mounted) _showMessage(context, errorMessage);
    }
  }

  static void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
