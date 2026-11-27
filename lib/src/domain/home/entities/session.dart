/// Сессия: кто сейчас работает с приложением (от его имени пишется история,
/// добавляются комментарии). Сохраняется между запусками.
class Session {
  const Session({this.currentUserId});

  final int? currentUserId;

  bool get hasUser => currentUserId != null;
}
