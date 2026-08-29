import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/di/service_locator.dart';
import 'core/notifications/push_notification_service.dart';
import 'me_vet_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  await dotenv.load(fileName: '.env');

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    publishableKey: dotenv.env['SUPABASE_PUBLISHABLE_KEY'] ?? '',
  );

  setupServiceLocator();

  // Firebase لسه أندرويد بس دلوقتي (google-services.json مبعوت من العميل).
  // آيفون هيحتاج GoogleService-Info.plist + حساب Apple Developer لاحقًا.
  try {
    await Firebase.initializeApp();
    debugPrint('[Push] Firebase.initializeApp() نجح');
  } catch (e, stack) {
    debugPrint('[Push] Firebase.initializeApp() فشل: $e');
    debugPrint('[Push] Stack trace: $stack');
  }
  FirebaseMessaging.onBackgroundMessage(
      PushNotificationService.firebaseBackgroundHandler);
  await PushNotificationService.instance.initializeLocalNotifications();

  runApp(const MevetApp());
}
