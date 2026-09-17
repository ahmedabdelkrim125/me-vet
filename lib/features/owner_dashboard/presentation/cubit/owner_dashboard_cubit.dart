import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/owner_service.dart';
import 'owner_dashboard_state.dart';

class OwnerDashboardCubit extends Cubit<OwnerDashboardState> {
  final OwnerService _ownerService;

  OwnerDashboardCubit(this._ownerService) : super(OwnerDashboardState());

  Future<void> loadReps({bool silent = false}) async {
    if (!silent) {
      emit(state.copyWith(isLoading: true, clearError: true));
    }
    try {
      final reps = await _ownerService.getAllReps();
      emit(state.copyWith(reps: reps, isLoading: false, clearError: true));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      ));
    }
  }

  Future<void> deactivateRep(String repId) async {
    try {
      await _ownerService.deleteRep(repId);
      await Future.delayed(const Duration(milliseconds: 400));
      await loadReps(silent: true);
    } catch (e) {
      emit(state.copyWith(error: e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> reactivateRep(String repId) async {
    try {
      await _ownerService.reactivateRep(repId);
      await Future.delayed(const Duration(milliseconds: 400));
      await loadReps(silent: true);
    } catch (e) {
      emit(state.copyWith(error: e.toString().replaceAll('Exception: ', '')));
    }
  }
}
