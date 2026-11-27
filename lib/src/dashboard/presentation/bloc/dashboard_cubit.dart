import 'dart:async';

import 'package:fpdart/fpdart.dart' hide Task;

import 'package:lab11/core/bloc/view_state.dart';
import 'package:lab11/core/error/failures.dart';
import 'package:lab11/core/usecase/usecase.dart';
import 'package:lab11/src/dashboard/domain/entities/dashboard_stats.dart';
import 'package:lab11/src/dashboard/domain/usecases/watch_dashboard_usecase.dart';

class DashboardCubit extends WatchCubit<DashboardStats> {
  DashboardCubit(this._watch) {
    load();
  }
  final WatchDashboardUseCase _watch;

  @override
  Stream<Either<Failure, DashboardStats>> source() => _watch(const NoParams());

  @override
  bool isEmpty(DashboardStats data) => false;
}
