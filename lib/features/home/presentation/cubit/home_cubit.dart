import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_exception.dart';
import '../../data/home_repository.dart';
import 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit(this._repository) : super(const HomeInitial());

  final HomeRepository _repository;

  Future<void> loadWeeklySummary({bool forceRefresh = false}) async {
    emit(const HomeLoading());
    try {
      final summary = await _repository.getWeeklyCollectionsSummary(
        forceRefresh: forceRefresh,
      );
      emit(HomeLoaded(summary));
    } catch (e) {
      emit(HomeError(mapErrorToAppException(e).message));
    }
  }
}
