import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart' hide Task;

import '../../../core/error/failures.dart';
import '../../../core/usecase/usecase.dart';
import '../../domain/entities/entities.dart';
import '../../domain/usecases/app_usecases.dart';
import '../../domain/usecases/comment_usecases.dart';
import '../../domain/usecases/project_usecases.dart';
import '../../domain/usecases/task_usecases.dart';
import '../../domain/usecases/user_usecases.dart';
import 'view_state.dart';

// Cubit-ы получают только UseCase-ы (через GetIt). Ни Drift, ни Dio здесь нет.

/// Текущий пользователь приложения.
class CurrentUserCubit extends Cubit<int?> {
  CurrentUserCubit(this._get, this._set) : super(null);

  final GetCurrentUserIdUseCase _get;
  final SetCurrentUserIdUseCase _set;

  Future<void> init() async =>
      emit((await _get(const NoParams())).getOrElse((_) => null));

  Future<void> select(int? id) async {
    await _set(id);
    emit(id);
  }
}

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

// ---------------- проекты ----------------

class ProjectsCubit extends WatchCubit<List<ProjectSummary>> {
  ProjectsCubit(this._watch, this._create, this._update, this._delete) {
    load();
  }
  final WatchProjectsUseCase _watch;
  final CreateProjectUseCase _create;
  final UpdateProjectUseCase _update;
  final DeleteProjectUseCase _delete;

  @override
  Stream<Either<Failure, List<ProjectSummary>>> source() =>
      _watch(const NoParams());

  Future<Failure?> create(ProjectParams data, {int? ownerId}) =>
      act(_create((data: data, ownerId: ownerId)));
  Future<Failure?> update(int id, ProjectParams data) =>
      act(_update((id: id, data: data)));
  Future<Failure?> delete(int id) => act(_delete(id));
}

class ProjectDetailCubit extends WatchCubit<Project?> {
  ProjectDetailCubit(this.projectId, this._watch) {
    load();
  }
  final int projectId;
  final WatchProjectUseCase _watch;

  @override
  Stream<Either<Failure, Project?>> source() => _watch(projectId);
}

class MembersCubit extends WatchCubit<List<ProjectMember>> {
  MembersCubit(
    this.projectId,
    this._watch,
    this._add,
    this._role,
    this._remove,
  ) {
    load();
  }
  final int projectId;
  final WatchMembersUseCase _watch;
  final AddMemberUseCase _add;
  final ChangeMemberRoleUseCase _role;
  final RemoveMemberUseCase _remove;

  @override
  Stream<Either<Failure, List<ProjectMember>>> source() => _watch(projectId);

  Future<Failure?> add(int userId, MemberRole role) =>
      act(_add((projectId: projectId, userId: userId, role: role)));
  Future<Failure?> changeRole(int userId, MemberRole role) =>
      act(_role((projectId: projectId, userId: userId, role: role)));
  Future<Failure?> remove(int userId) =>
      act(_remove((projectId: projectId, userId: userId)));
}

// ---------------- список задач: фильтры + пагинация ----------------

class TaskListState {
  const TaskListState({
    required this.filter,
    required this.limit,
    this.items = const ViewLoading(),
    this.total,
    this.fixedAssignee = false,
    this.assigneeName,
  });

  final TaskFilter filter;
  final int limit;
  final ViewState<List<TaskDetails>> items;
  final int? total;
  final bool fixedAssignee;
  final String? assigneeName;

  bool get hasFilters =>
      filter.search.isNotEmpty ||
      filter.status != null ||
      filter.priority != null ||
      (!fixedAssignee && filter.assigneeId != null);

  /// Есть ли ещё страницы (загружено ровно limit строк).
  bool get hasMore =>
      items is ViewLoaded<List<TaskDetails>> &&
      (items as ViewLoaded<List<TaskDetails>>).data.length >= limit;

  TaskListState copyWith({
    TaskFilter? filter,
    int? limit,
    ViewState<List<TaskDetails>>? items,
    int? Function()? total,
    String? Function()? assigneeName,
  }) => TaskListState(
    filter: filter ?? this.filter,
    limit: limit ?? this.limit,
    items: items ?? this.items,
    total: total != null ? total() : this.total,
    fixedAssignee: fixedAssignee,
    assigneeName: assigneeName != null ? assigneeName() : this.assigneeName,
  );
}

class TaskListCubit extends Cubit<TaskListState> {
  TaskListCubit(this._watch, this._count, {int? projectId, int? assigneeId})
    : super(
        TaskListState(
          filter: TaskFilter(projectId: projectId, assigneeId: assigneeId),
          limit: pageSize,
          fixedAssignee: assigneeId != null,
        ),
      ) {
    _subscribe();
  }

  static const pageSize = 30;

  final WatchTasksUseCase _watch;
  final WatchTaskCountUseCase _count;
  StreamSubscription<Either<Failure, List<TaskDetails>>>? _itemsSub;
  StreamSubscription<Either<Failure, int>>? _countSub;
  Timer? _debounce;
  bool _loadingMore = false;

  void _subscribe() {
    _itemsSub?.cancel();
    _countSub?.cancel();
    _itemsSub = _watch((filter: state.filter, limit: state.limit)).listen((r) {
      if (isClosed) return;
      _loadingMore = false;
      emit(
        state.copyWith(
          items: r.fold(
            ViewError<List<TaskDetails>>.new,
            (list) => list.isEmpty ? const ViewEmpty() : ViewLoaded(list),
          ),
        ),
      );
    });
    _countSub = _count(state.filter).listen((r) {
      if (!isClosed) emit(state.copyWith(total: () => r.getOrElse((_) => 0)));
    });
  }

  /// Смена фильтра сбрасывает пагинацию на первую страницу.
  void _apply(TaskFilter filter) {
    emit(
      state.copyWith(
        filter: filter,
        limit: pageSize,
        items: const ViewLoading(),
      ),
    );
    _subscribe();
  }

  /// Поиск с debounce: запрос уходит через 300 мс после последнего символа.
  void setSearch(String value) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 300),
      () => _apply(state.filter.copyWith(search: value)),
    );
  }

  void setStatus(TaskStatus? s) =>
      _apply(state.filter.copyWith(status: () => s));
  void setPriority(TaskPriority? p) =>
      _apply(state.filter.copyWith(priority: () => p));
  void setAssignee(int? id, [String? name]) {
    emit(state.copyWith(assigneeName: () => name));
    _apply(state.filter.copyWith(assigneeId: () => id));
  }

  void setSort(TaskSort s) => _apply(state.filter.copyWith(sort: s));

  void clear() {
    final f = state.filter;
    _apply(
      TaskFilter(
        projectId: f.projectId,
        assigneeId: state.fixedAssignee ? f.assigneeId : null,
        sort: f.sort,
      ),
    );
  }

  /// Следующая страница. Повторный вызов, пока страница грузится, игнорируется.
  void loadMore() {
    if (_loadingMore || !state.hasMore) return;
    _loadingMore = true;
    emit(state.copyWith(limit: state.limit + pageSize));
    _subscribe();
  }

  void retry() => _apply(state.filter);

  @override
  Future<void> close() async {
    _debounce?.cancel();
    await _itemsSub?.cancel();
    await _countSub?.cancel();
    return super.close();
  }
}

// ---------------- задача ----------------

class TaskDetailCubit extends WatchCubit<TaskDetails?> {
  TaskDetailCubit(
    this.taskId,
    this._watch,
    this._status,
    this._undo,
    this._canUndo,
    this._priority,
    this._reassign,
    this._trash,
  ) {
    load();
  }

  final int taskId;
  final WatchTaskUseCase _watch;
  final ChangeTaskStatusUseCase _status;
  final UndoStatusChangeUseCase _undo;
  final CanUndoStatusChangeUseCase _canUndo;
  final ChangeTaskPriorityUseCase _priority;
  final ReassignTaskUseCase _reassign;
  final MoveTaskToTrashUseCase _trash;

  @override
  Stream<Either<Failure, TaskDetails?>> source() => _watch(taskId);

  @override
  bool isEmpty(TaskDetails? data) => data == null || data.task.isDeleted;

  Future<Failure?> changeStatus(TaskStatus s, int? actor) =>
      act(_status((id: taskId, status: s, actorId: actor)));
  Future<Failure?> undo(int? actor) =>
      act(_undo((taskId: taskId, actorId: actor)));
  Future<bool> canUndo() async =>
      (await _canUndo(taskId)).getOrElse((_) => false);
  Future<Failure?> changePriority(TaskPriority p) =>
      act(_priority((id: taskId, priority: p)));
  Future<Failure?> reassign(int? userId, int? actor) =>
      act(_reassign((id: taskId, assigneeId: userId, actorId: actor)));
  Future<Failure?> moveToTrash() => act(_trash(taskId));
}

class CommentsCubit extends WatchCubit<List<Comment>> {
  CommentsCubit(this.taskId, this._watch, this._add, this._delete) {
    load();
  }
  final int taskId;
  final WatchCommentsUseCase _watch;
  final AddCommentUseCase _add;
  final DeleteCommentUseCase _delete;

  @override
  Stream<Either<Failure, List<Comment>>> source() => _watch(taskId);

  Future<Failure?> add(int? authorId, String text) =>
      act(_add((taskId: taskId, authorId: authorId, text: text)));
  Future<Failure?> delete(int commentId, int? actor) =>
      act(_delete((commentId: commentId, actorId: actor)));
}

class AttachmentsCubit extends WatchCubit<List<Attachment>> {
  AttachmentsCubit(this.taskId, this._watch, this._add, this._delete) {
    load();
  }
  final int taskId;
  final WatchAttachmentsUseCase _watch;
  final AddAttachmentUseCase _add;
  final DeleteAttachmentUseCase _delete;

  @override
  Stream<Either<Failure, List<Attachment>>> source() => _watch(taskId);

  Future<Failure?> add(String name, String path) =>
      act(_add((taskId: taskId, fileName: name, filePath: path)));
  Future<Failure?> delete(int id) => act(_delete(id));
}

/// Форма задачи: справочники (проекты, участники) + отправка.
class TaskFormState {
  const TaskFormState({
    this.projects = const [],
    this.members = const [],
    this.submitting = false,
  });

  final List<Project> projects;
  final List<User> members;
  final bool submitting;

  TaskFormState copyWith({
    List<Project>? projects,
    List<User>? members,
    bool? submitting,
  }) => TaskFormState(
    projects: projects ?? this.projects,
    members: members ?? this.members,
    submitting: submitting ?? this.submitting,
  );
}

class TaskFormCubit extends Cubit<TaskFormState> {
  TaskFormCubit(
    this._projects,
    this._members,
    this._create,
    this._update,
    this._reassign,
  ) : super(const TaskFormState());

  final GetProjectsUseCase _projects;
  final GetProjectMembersUseCase _members;
  final CreateTaskUseCase _create;
  final UpdateTaskUseCase _update;
  final ReassignTaskUseCase _reassign;

  Future<void> init(int? projectId) async {
    final p = (await _projects(const NoParams())).getOrElse((_) => []);
    if (!isClosed) emit(state.copyWith(projects: p));
    await loadMembers(projectId);
  }

  Future<void> loadMembers(int? projectId) async {
    final m = projectId == null
        ? <User>[]
        : (await _members(projectId)).getOrElse((_) => []);
    if (!isClosed) emit(state.copyWith(members: m));
  }

  /// Защита от двойного нажатия: пока идёт сохранение, новый запрос не отправляется.
  Future<Failure?> submit({
    required Task? existing,
    required TaskDraft draft,
    required int? actorId,
  }) async {
    if (state.submitting) return null;
    emit(state.copyWith(submitting: true));
    final Either<Failure, Object?> result;
    if (existing == null) {
      result = await _create((draft: draft, actorId: actorId));
    } else {
      final updated = await _update((
        id: existing.id,
        title: draft.title,
        description: draft.description,
        priority: draft.priority,
        deadline: draft.deadline,
      ));
      result = updated.isLeft() || draft.assigneeId == existing.assigneeId
          ? updated
          : await _reassign((
              id: existing.id,
              assigneeId: draft.assigneeId,
              actorId: actorId,
            ));
    }
    if (!isClosed) emit(state.copyWith(submitting: false));
    return result.fold((f) => f, (_) => null);
  }
}

// ---------------- пользователи ----------------

class UsersCubit extends WatchCubit<List<User>> {
  UsersCubit(this._watch, this._create, this._update, this._delete) {
    load();
  }
  final WatchUsersUseCase _watch;
  final CreateUserUseCase _create;
  final UpdateUserUseCase _update;
  final DeleteUserUseCase _delete;

  static const pageSize = 50;
  String _search = '';
  int limit = pageSize;

  @override
  Stream<Either<Failure, List<User>>> source() =>
      _watch((search: _search, limit: limit));

  void search(String value) {
    _search = value;
    limit = pageSize;
    load();
  }

  void loadMore() {
    final s = state;
    if (s is ViewLoaded<List<User>> && s.data.length >= limit) {
      limit += pageSize;
      load();
    }
  }

  Future<Either<Failure, int>> create(String name, String email) =>
      _create((name: name, email: email));
  Future<Failure?> update(int id, String name, String email) =>
      act(_update((id: id, name: name, email: email)));
  Future<Failure?> delete(int id) => act(_delete(id));
}

class UserDetailCubit extends WatchCubit<User?> {
  UserDetailCubit(this.userId, this._watch) {
    load();
  }
  final int userId;
  final WatchUserUseCase _watch;

  @override
  Stream<Either<Failure, User?>> source() => _watch(userId);
}

/// Выбор пользователя с поиском (или только участников проекта).
class UserPickerCubit extends WatchCubit<List<User>> {
  UserPickerCubit(
    this._users,
    this._members, {
    this.projectId,
    this.excludeProjectId,
  }) {
    _init();
  }
  final WatchUsersUseCase _users;
  final GetProjectMembersUseCase _members;
  final int? projectId;
  final int? excludeProjectId;

  String _search = '';
  Set<int> _excluded = {};

  Future<void> _init() async {
    if (excludeProjectId != null) {
      _excluded = (await _members(excludeProjectId!))
          .getOrElse((_) => [])
          .map((u) => u.id)
          .toSet();
    }
    if (!isClosed) load();
  }

  @override
  Stream<Either<Failure, List<User>>> source() {
    final s = _search.toLowerCase();
    final base = projectId != null
        ? Stream.fromFuture(_members(projectId!)).map(
            (e) => e.map(
              (list) => list
                  .where(
                    (u) =>
                        u.name.toLowerCase().contains(s) || u.email.contains(s),
                  )
                  .toList(),
            ),
          )
        : _users((search: _search, limit: 100));
    return base.map(
      (e) => e.map(
        (list) => list.where((u) => !_excluded.contains(u.id)).toList(),
      ),
    );
  }

  void search(String value) {
    _search = value.trim();
    load();
  }
}

// ---------------- корзина ----------------

class TrashCubit extends WatchCubit<List<TaskDetails>> {
  TrashCubit(this._watch, this._restore, this._delete, this._empty) {
    load();
  }
  final WatchTrashUseCase _watch;
  final RestoreTaskUseCase _restore;
  final DeleteTaskForeverUseCase _delete;
  final EmptyTrashUseCase _empty;

  @override
  Stream<Either<Failure, List<TaskDetails>>> source() =>
      _watch(const NoParams());

  Future<Failure?> restore(int id) => act(_restore(id));
  Future<Failure?> deleteForever(int id) => act(_delete(id));
  Future<Failure?> emptyTrash() => act(_empty(const NoParams()));
}

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
