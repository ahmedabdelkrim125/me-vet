import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/notifications/push_notification_service.dart';
import '../../../home/data/home_repository.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _repository;
  StreamSubscription? _authSubscription;

  AuthCubit(this._repository) : super(const AuthState()) {
    _authSubscription = _repository.authStateChanges.listen((user) {
      debugPrint('[Push] authStateChanges emitted: user=${user?.id}');
      emit(state.copyWith(
        status: user != null
            ? AuthStatus.authenticated
            : AuthStatus.unauthenticated,
        user: user,
      ));
      // هنا بس، مش جوّا signInAsRep/signInAsOwner — عشان ده الحدث اللي
      // بيتطلق في الحالتين: تسجيل دخول جديد فعليًا، أو استرجاع جلسة
      // محفوظة تلقائيًا لما التطبيق يفتح من غير ما اليوزر يعمل حاجة
      // (INITIAL_SESSION).
      if (user != null) {
        debugPrint('[Push] هنادي registerDeviceForCurrentUser دلوقتي');
        unawaited(PushNotificationService.instance.registerDeviceForCurrentUser());
      }
    });
  }

  Future<void> signInAsRep({required String phone, required String pin}) async {
    emit(state.copyWith(status: AuthStatus.loading));
    try {
      final user = await _repository.signInAsRep(phone: phone, pin: pin);
      emit(state.copyWith(status: AuthStatus.authenticated, user: user));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: mapErrorToAppException(e).message,
      ));
    }
  }

  Future<void> signInAsOwner({
    required String email,
    required String password,
  }) async {
    emit(state.copyWith(status: AuthStatus.loading));
    try {
      final user =
          await _repository.signInAsOwner(email: email, password: password);
      emit(state.copyWith(status: AuthStatus.authenticated, user: user));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: mapErrorToAppException(e).message,
      ));
    }
  }

  Future<void> signOut() async {
    await PushNotificationService.instance.unregisterDevice();
    sl<HomeRepository>().clearCache();
    await _repository.signOut();
    emit(state.copyWith(status: AuthStatus.unauthenticated, user: null));
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
