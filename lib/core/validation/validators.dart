import 'package:fpdart/fpdart.dart' hide Task;

import 'package:lab11/core/error/failures.dart';

/// Правила проверки данных — часть бизнес-логики (Domain).
abstract final class Validators {
  static final _emailRegExp = RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$');

  /// Обязательный текст: возвращает обрезанную строку или ValidationFailure.
  static Either<Failure, String> text(
    String? value,
    String field, {
    int min = 1,
    int max = 200,
  }) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return Left(ValidationFailure('Поле «$field» обязательно'));
    if (v.length < min) {
      return Left(ValidationFailure('«$field»: минимум $min символа'));
    }
    if (v.length > max) {
      return Left(ValidationFailure('«$field»: максимум $max символов'));
    }
    return Right(v);
  }

  static Either<Failure, String> email(String? value) {
    final v = value?.trim().toLowerCase() ?? '';
    if (!_emailRegExp.hasMatch(v)) {
      return const Left(ValidationFailure('Введите корректный email'));
    }
    return Right(v);
  }

  /// Для TextFormField: текст ошибки или null.
  static String? Function(String?) form(
    Either<Failure, String> Function(String?) rule,
  ) =>
      (v) => rule(v).fold((f) => f.message, (_) => null);
}
