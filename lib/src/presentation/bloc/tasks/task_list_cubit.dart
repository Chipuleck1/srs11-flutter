import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart' hide Task;

import 'package:lab11/core/bloc/view_state.dart';
import 'package:lab11/core/error/failures.dart';
import 'package:lab11/models/enums.dart';
import 'package:lab11/src/domain/entities/tasks/task.dart';
import 'package:lab11/src/domain/usecases/tasks/task_usecases.dart';

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
