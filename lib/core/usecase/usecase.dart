import 'dart:async';

import 'package:fpdart/fpdart.dart' hide Task;

import '../error/failures.dart';

/// Базовый UseCase: одно бизнес-действие, результат — `Either<Failure, T>`.
abstract class UseCase<T, P> {
  Future<Either<Failure, T>> call(P params);
}

/// UseCase, который возвращает поток (реактивные данные из базы).
abstract class StreamUseCase<T, P> {
  Stream<Either<Failure, T>> call(P params);
}

class NoParams {
  const NoParams();
}

/// Достаёт значение из Either, а при Left прерывает [eitherDo].
typedef Bind = Future<R> Function<R>(FutureOr<Either<Failure, R>> either);

class _ShortCircuit implements Exception {
  const _ShortCircuit(this.failure);
  final Failure failure;
}

/// Последовательная проверка правил без вложенных fold():
/// ```dart
/// return eitherDo(($) async {
///   final name = await $(Validators.text(raw, 'Имя'));
///   if (await $(repo.emailExists(email))) fail(const DuplicateEmailFailure());
///   return await $(repo.createUser(...));
/// });
/// ```
Future<Either<Failure, T>> eitherDo<T>(Future<T> Function(Bind $) body) async {
  try {
    return Right(
      await body(<R>(either) async {
        final e = await either;
        return e.fold((f) => throw _ShortCircuit(f), (v) => v);
      }),
    );
  } on _ShortCircuit catch (s) {
    return Left(s.failure);
  }
}

/// Прерывает [eitherDo] с указанной ошибкой.
Never fail(Failure failure) => throw _ShortCircuit(failure);
