import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart' hide Task;
import 'package:sqlite3/common.dart' show SqliteException;

import 'package:lab11/core/error/exceptions.dart';
import 'package:lab11/core/error/failures.dart';

/// Централизованная обработка ошибок Data Layer.
/// Любое исключение превращается в понятный [Failure],
/// а технические детали пишутся только в лог разработки.
abstract final class ErrorHandler {
  static Failure toFailure(Object error, [StackTrace? stack]) {
    debugPrint('[ERROR] ${error.runtimeType}: $error');
    return switch (error) {
      Failure() => error,
      NetworkException() => const NetworkFailure(),
      ServerException() => const ServerFailure(),
      UnauthorizedException() => const UnauthorizedFailure(),
      BadRequestException() => const ValidationFailure(
        'Неверный запрос к серверу',
      ),
      NotFoundException() => const NotFoundFailure(),
      ParseException() => const ServerFailure(
        'Сервер вернул некорректные данные',
      ),
      DatabaseException() => const DatabaseFailure(),
      SqliteException(:final extendedResultCode) => _sqlite(extendedResultCode),
      _ => const UnknownFailure(),
    };
  }

  static Failure _sqlite(int code) => switch (code) {
    2067 || 1555 => const ValidationFailure(
      'Такая запись уже существует',
    ), // UNIQUE / PK
    787 => const ValidationFailure(
      'Связанная запись не найдена',
    ), // FOREIGN KEY
    _ => const DatabaseFailure(),
  };

  /// Выполняет [action] и возвращает Right(результат) или Left(Failure).
  static Future<Either<Failure, T>> guard<T>(
    Future<T> Function() action,
  ) async {
    try {
      return Right(await action());
    } catch (e, s) {
      return Left(toFailure(e, s));
    }
  }

  /// То же для потоков (Drift watch()): ошибка становится Left, поток не падает.
  static Stream<Either<Failure, T>> guardStream<T>(Stream<T> stream) =>
      stream.transform(
        StreamTransformer<T, Either<Failure, T>>.fromHandlers(
          handleData: (data, sink) => sink.add(Right(data)),
          handleError: (e, s, sink) => sink.add(Left(toFailure(e, s))),
        ),
      );
}
