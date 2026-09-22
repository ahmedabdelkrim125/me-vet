import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mivet_app/core/routing/routes.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/network/connectivity_service.dart';
import '../../../core/notifications/notification_navigator.dart';
import '../../../core/utils/extensions.dart';
import '../../auth/domain/repositories/auth_repository_impl.dart';
import '../../auth/domain/models/user_profile.dart';
import 'widgets/splash_body.dart';
import 'widgets/splash_network_issue_body.dart';

enum SplashNetworkIssue { offline, weak }

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController entranceController;
  late final AnimationController loopController;

  Timer? _initialDelayTimer;
  StreamSubscription<NetworkStatus>? _connectivitySubscription;
  bool _startupInProgress = false;
  SplashNetworkIssue? _networkIssue;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();
    loopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _initialDelayTimer =
        Timer(const Duration(milliseconds: 2800), _startStartupCheck);

    _connectivitySubscription =
        ConnectivityService.instance.onStatusChange.listen((status) {
      if (status == NetworkStatus.online && _networkIssue != null) {
        _startStartupCheck();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _networkIssue != null) {
      _startStartupCheck();
    }
  }

  Future<void> _startStartupCheck() async {
    if (_startupInProgress || !mounted) return;
    _startupInProgress = true;

    final hasSession = Supabase.instance.client.auth.currentSession != null;
    if (!hasSession) {
      _startupInProgress = false;
      if (!mounted) return;
      context.pushReplacementNamed(Routes.loginTypeScreen);
      return;
    }

    final networkStatus = await ConnectivityService.instance.currentStatus();
    if (networkStatus == NetworkStatus.offline) {
      _startupInProgress = false;
      if (!mounted) return;
      setState(() => _networkIssue = SplashNetworkIssue.offline);
      return;
    }

    try {
      final profile = await AuthRepositoryImpl(Supabase.instance.client)
          .getCurrentUser()
          .timeout(const Duration(seconds: 10));

      _startupInProgress = false;
      if (!mounted) return;

      if (profile == null) {
        context.pushReplacementNamed(Routes.loginTypeScreen);
      } else if (profile.role == UserRole.owner) {
        context.pushReplacementNamed(Routes.ownerDashboard);
        await NotificationNavigator.instance.consumePending();
      } else {
        context.pushReplacementNamed(Routes.mainScreen);
        await NotificationNavigator.instance.consumePending();
      }
    } catch (error) {
      _startupInProgress = false;
      if (!mounted) return;

      final mapped =
          error is AppException ? error : mapErrorToAppException(error);
      final cause = mapped.cause;
      final isConnectivityIssue = error is TimeoutException ||
          cause is SocketException ||
          cause is TimeoutException;

      if (isConnectivityIssue) {
        setState(() {
          _networkIssue = cause is SocketException
              ? SplashNetworkIssue.offline
              : SplashNetworkIssue.weak;
        });
        return;
      }

      context.pushReplacementNamed(Routes.loginTypeScreen);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _initialDelayTimer?.cancel();
    _connectivitySubscription?.cancel();
    entranceController.dispose();
    loopController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _networkIssue == null
            ? SplashBody(
                entranceController: entranceController,
                loopController: loopController,
              )
            : SplashNetworkIssueBody(issue: _networkIssue!),
      ),
    );
  }
}
