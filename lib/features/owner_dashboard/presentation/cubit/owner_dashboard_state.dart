import '../../../auth/domain/models/user_profile.dart';

class OwnerDashboardState {
  final List<UserProfile> reps;
  final bool isLoading;
  final String? error;

  OwnerDashboardState({
    this.reps = const [],
    this.isLoading = true,
    this.error,
  });

  OwnerDashboardState copyWith({
    List<UserProfile>? reps,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return OwnerDashboardState(
      reps: reps ?? this.reps,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
