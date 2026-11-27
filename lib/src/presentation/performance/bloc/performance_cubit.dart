import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:lab11/core/error/failures.dart';
import 'package:lab11/core/usecase/usecase.dart';
import 'package:lab11/src/domain/performance/entities/benchmark_result.dart';
import 'package:lab11/src/domain/performance/usecases/performance_usecases.dart';

// ---------------- производительность ----------------

class PerformanceState {
  const PerformanceState({
    this.busy,
    this.taskCount,
    this.seedTime,
    this.results,
    this.error,
  });

  final String? busy;
  final int? taskCount;
  final Duration? seedTime;
  final List<BenchmarkResult>? results;
  final Failure? error;
}

class PerformanceCubit extends Cubit<PerformanceState> {
  PerformanceCubit(this._count, this._seed, this._bench, this._clear)
    : super(const PerformanceState()) {
    refreshCount();
  }
  final CountTasksUseCase _count;
  final GenerateLargeDataUseCase _seed;
  final RunBenchmarkUseCase _bench;
  final ClearAllDataUseCase _clear;

  bool get isBusy => state.busy != null;

  Future<void> refreshCount() async {
    final c = (await _count(const NoParams())).getOrElse((_) => 0);
    if (!isClosed) {
      emit(
        PerformanceState(
          taskCount: c,
          seedTime: state.seedTime,
          results: state.results,
        ),
      );
    }
  }

  Future<void> generate() async {
    if (isBusy) return;
    emit(
      PerformanceState(
        busy: 'Генерация данных…',
        taskCount: state.taskCount,
        results: state.results,
      ),
    );
    final sw = Stopwatch()..start();
    final r = await _seed(const NoParams());
    emit(
      PerformanceState(
        taskCount: state.taskCount,
        seedTime: sw.elapsed,
        results: state.results,
        error: r.getLeft().toNullable(),
      ),
    );
    await refreshCount();
  }

  Future<void> benchmark() async {
    if (isBusy) return;
    emit(
      PerformanceState(
        busy: 'Измеряем запросы…',
        taskCount: state.taskCount,
        seedTime: state.seedTime,
      ),
    );
    final r = await _bench(const NoParams());
    emit(
      PerformanceState(
        taskCount: state.taskCount,
        seedTime: state.seedTime,
        results: r.getOrElse((_) => const []),
        error: r.getLeft().toNullable(),
      ),
    );
  }

  Future<void> clearAll() async {
    if (isBusy) return;
    emit(PerformanceState(busy: 'Удаление…', taskCount: state.taskCount));
    await _clear(const NoParams());
    emit(const PerformanceState());
    await refreshCount();
  }
}
