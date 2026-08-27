import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../errors/app_exception.dart';

/// نتيجة تحديد الموقع: إحداثيات دقيقة + عنوان نصي مقروء (لو قدرنا نجيبه).
class LocationResult {
  final double latitude;
  final double longitude;

  /// عنوان مقروء اتبني من الإحداثيات (شارع/حي/مدينة). ممكن يرجع فاضي لو
  /// خدمة الـ reverse geocoding فشلت — الإحداثيات نفسها تفضل صح برضه.
  final String? readableAddress;

  const LocationResult({
    required this.latitude,
    required this.longitude,
    this.readableAddress,
  });
}

/// يمسك موقع الجهاز الحالي بالظبط (GPS)، ويحاول يترجمه لعنوان نصي مقروء.
///
/// أي خطأ (صلاحية مرفوضة، GPS مقفول، فشل الشبكة) بيترجم لـ [AppException]
/// برسالة عربية واضحة عشان showAppError يقدر يعرضها زي أي خطأ تاني في
/// التطبيق.
class LocationService {
  LocationService._();

  static Future<LocationResult> getCurrentLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const AppException(
          'خدمة الموقع (GPS) مقفولة في الجهاز، فعّلها من الإعدادات وحاول تاني');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const AppException('محتاجين إذن الوصول للموقع عشان نحدد مكان العميل');
    }
    if (permission == LocationPermission.deniedForever) {
      throw const AppException(
          'إذن الموقع مرفوض بشكل دائم — فعّله يدويًا من إعدادات التطبيق');
    }

    late final Position position;
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
    } catch (_) {
      throw const AppException(
          'تعذر تحديد الموقع، اتأكد إنك في مكان مفتوح وحاول تاني');
    }

    final address = await _reverseGeocode(position.latitude, position.longitude);

    return LocationResult(
      latitude: position.latitude,
      longitude: position.longitude,
      readableAddress: address,
    );
  }

  /// بيحاول يحوّل الإحداثيات لعنوان نصي. لو الخدمة مش متاحة أو فشلت، بيرجع
  /// null بهدوء بدل ما يوقف كل عملية إضافة العميل — الإحداثيات هي الأهم.
  static Future<String?> _reverseGeocode(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isEmpty) return null;

      final p = placemarks.first;
      final parts = [
        p.street,
        p.subLocality,
        p.locality,
        p.administrativeArea,
      ].where((part) => part != null && part.trim().isNotEmpty).toList();

      return parts.isEmpty ? null : parts.join('، ');
    } catch (_) {
      return null;
    }
  }
}
