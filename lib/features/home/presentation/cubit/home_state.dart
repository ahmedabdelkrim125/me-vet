import 'package:equatable/equatable.dart';

import '../../domain/models/weekly_financial_summary.dart';

abstract class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => [];
}

class HomeInitial extends HomeState {
  const HomeInitial();
}

class HomeLoading extends HomeState {
  const HomeLoading();
}

class HomeLoaded extends HomeState {
  final WeeklyFinancialSummary summary;

  const HomeLoaded(this.summary);

  @override
  List<Object?> get props => [summary];
}

class HomeError extends HomeState {
  final String message;

  const HomeError(this.message);

  @override
  List<Object?> get props => [message];
}
