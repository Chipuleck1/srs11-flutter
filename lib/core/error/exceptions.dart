/// Исключения Data Layer. Наружу (в Domain) они не выходят:
/// репозитории превращают их в [Failure] через ErrorHandler.
sealed class DataException implements Exception {
  const DataException([this.details]);

  /// Технические подробности — только для логов.
  final String? details;

  @override
  String toString() => '$runtimeType(${details ?? ''})';
}

/// Нет соединения или таймаут.
class NetworkException extends DataException {
  const NetworkException([super.details]);
}

/// Сервер ответил 5xx.
class ServerException extends DataException {
  const ServerException(this.statusCode, [super.details]);
  final int statusCode;
}

/// Сервер ответил 401.
class UnauthorizedException extends DataException {
  const UnauthorizedException([super.details]);
}

/// Сервер ответил 400 (или другим 4xx, кроме 401/404).
class BadRequestException extends DataException {
  const BadRequestException([super.details]);
}

class NotFoundException extends DataException {
  const NotFoundException([super.details]);
}

/// Ответ не удалось разобрать.
class ParseException extends DataException {
  const ParseException([super.details]);
}

/// Ошибка локальной базы данных.
class DatabaseException extends DataException {
  const DatabaseException([super.details]);
}
