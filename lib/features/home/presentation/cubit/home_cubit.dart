import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_exception.dart';
import '../../data/home_repository.dart';
import 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit(this._repository) : super(const HomeInitial());

  final HomeRepository _repository;

  Future<void> loadWeeklySummary({bool forceRefresh = false}) async {
    if (isClosed) return;
    emit(const HomeLoading());
    try {
      final summary = await _repository.getWeeklyCollectionsSummary(
        forceRefresh: forceRefresh,
      );
      if (isClosed) return;
      emit(HomeLoaded(summary));
    } catch (e) {
      if (isClosed) return;
      emit(HomeError(mapErrorToAppException(e).message));
    }
  }
}
