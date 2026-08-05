import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mivet_app/core/routing/routes.dart' show Routes;
import 'core/routing/app_router.dart';
import 'core/utils/responsive_extension.dart';

class MevetApp extends StatelessWidget {
  const MevetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      onGenerateRoute: AppRouter.generateRoute,
      initialRoute: Routes.splashScreen,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        if (child == null) return const SizedBox.shrink();

        return ResponsiveInit(
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: child,
          ),
        );
      },
    );
  }
}
