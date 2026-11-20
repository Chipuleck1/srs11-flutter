/// Ошибки, которые видят Domain и Presentation.
/// [message] — понятный пользователю текст, без технических подробностей.
sealed class Failure {
  const Failure(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// Нет интернета / сервер недоступен.
class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Нет подключения к интернету']);
}

/// HTTP 5xx.
class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Ошибка сервера. Попробуйте позже']);
}

/// HTTP 401.
class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([super.message = 'Требуется авторизация']);
}

/// HTTP 400 и нарушение правил ввода / бизнес-правил.
class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Данные не найдены']);
}

/// Действие запрещено (например, удалить чужой комментарий).
class ForbiddenFailure extends Failure {
  const ForbiddenFailure(super.message);
}

/// Ошибка локальной базы данных.
class DatabaseFailure extends Failure {
  const DatabaseFailure([super.message = 'Не удалось сохранить данные']);
}

class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Что-то пошло не так']);
}

// ---------- бизнес-правила TaskFlow (подвиды ValidationFailure) ----------

class DuplicateEmailFailure extends ValidationFailure {
  const DuplicateEmailFailure()
    : super('Пользователь с таким email уже существует');
}

class DuplicateMemberFailure extends ValidationFailure {
  const DuplicateMemberFailure()
    : super('Пользователь уже состоит в этом проекте');
}

class NotProjectMemberFailure extends ValidationFailure {
  const NotProjectMemberFailure()
    : super('Исполнитель должен быть участником проекта');
}

class AssigneeOverloadedFailure extends ValidationFailure {
  const AssigneeOverloadedFailure()
    : super('У исполнителя уже 3 незавершённые задачи с таким дедлайном');
}

class UserHasOpenTasksFailure extends ValidationFailure {
  const UserHasOpenTasksFailure(int count)
    : super('Нельзя удалить пользователя: за ним $count незавершённых задач');
}

class NothingToUndoFailure extends ValidationFailure {
  const NothingToUndoFailure()
    : super('Нет изменений статуса, которые можно отменить');
}
