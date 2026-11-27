import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:lab11/core/error/failures.dart';
import 'package:lab11/core/usecase/usecase.dart';
import 'package:lab11/src/domain/home/usecases/seed_demo_data_usecase.dart';

// ---------------- первый запуск ----------------

/// Приветственный экран: заполнение демо-данными.
class WelcomeCubit extends Cubit<bool> {
  WelcomeCubit(this._seed) : super(false);
  final SeedDemoDataUseCase _seed;

  /// state == true, пока идёт заполнение (повторное нажатие игнорируется).
  Future<Failure?> seedDemo() async {
    if (state) return null;
    emit(true);
    final r = await _seed(const NoParams());
    if (!isClosed) emit(false);
    return r.getLeft().toNullable();
  }
}
