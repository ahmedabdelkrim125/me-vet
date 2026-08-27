import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/errors/app_exception.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _repository;
  StreamSubscription? _authSubscription;

  AuthCubit(this._repository) : super(const AuthState()) {
    _authSubscription = _repository.authStateChanges.listen((user) {
      emit(state.copyWith(
        status: user != null
            ? AuthStatus.authenticated
            : AuthStatus.unauthenticated,
        user: user,
      ));
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
    await _repository.signOut();
    emit(state.copyWith(status: AuthStatus.unauthenticated, user: null));
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
