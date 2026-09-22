import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:device_preview/device_preview.dart';
import 'package:mivet_app/core/routing/routes.dart';
import 'package:mivet_app/core/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/notifications/notification_navigator.dart';
import 'core/routing/app_router.dart';
import 'core/theme/theme_controller.dart';
import 'core/utils/responsive_extension.dart';
import 'features/auth/domain/repositories/auth_repository_impl.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';

class MevetApp extends StatefulWidget {
  const MevetApp({super.key});

  static final navigatorKey = GlobalKey<NavigatorState>();

  @override
  State<MevetApp> createState() => _MevetAppState();
}

class _MevetAppState extends State<MevetApp> {
  @override
  void initState() {
    super.initState();
    NotificationNavigator.instance.setNavigatorKey(MevetApp.navigatorKey);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthCubit(AuthRepositoryImpl(Supabase.instance.client)),
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: ThemeController.instance.themeMode,
        builder: (context, mode, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            navigatorKey: MevetApp.navigatorKey,
            onGenerateRoute: AppRouter.generateRoute,
            initialRoute: Routes.splashScreen,
            // Build ONLY the splash route. Without this, Flutter also creates
            // a hidden "/" route underneath it (because the route name is
            // nested), and pressing back from the main screen lands on it,
            // showing "Route not found".
            onGenerateInitialRoutes: (_) => [
              AppRouter.generateRoute(
                const RouteSettings(name: Routes.splashScreen),
              ),
            ],
            locale: DevicePreview.locale(context) ?? const Locale('ar'),
            supportedLocales: const [Locale('ar'), Locale('en')],
            themeMode: mode,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            builder: (context, child) {
              if (child == null) return const SizedBox.shrink();

              final devicePreviewApp = DevicePreview.appBuilder(context, child);

              return ResponsiveInit(
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: devicePreviewApp,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
