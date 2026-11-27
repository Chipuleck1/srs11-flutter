import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:lab11/components/common.dart';
import 'package:lab11/components/view_state_view.dart';
import 'package:lab11/constants/app_theme.dart';
import 'package:lab11/core/bloc/view_state.dart';
import 'package:lab11/core/di/injection.dart';
import 'package:lab11/src/domain/users/entities/user.dart';
import 'package:lab11/src/presentation/users/bloc/user_picker_cubit.dart';

/// Результат выбора пользователя: [user] == null означает «никто / все».
class UserChoice {
  const UserChoice(this.user);
  final User? user;
}

/// Выбор пользователя с поиском. Если задан [projectId] — только участники проекта.
/// [excludeProjectId] — скрыть уже состоящих в проекте (для добавления участника).
Future<UserChoice?> pickUser(
  BuildContext context, {
  required String title,
  int? projectId,
  int? excludeProjectId,
  String? noneLabel,
}) {
  return showModalBottomSheet<UserChoice>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Tf.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => BlocProvider(
      create: (_) =>
          getIt<UserPickerCubit>(param1: projectId, param2: excludeProjectId),
      child: _UserPickerSheet(title: title, noneLabel: noneLabel),
    ),
  );
}

class _UserPickerSheet extends StatelessWidget {
  const _UserPickerSheet({required this.title, this.noneLabel});

  final String title;
  final String? noneLabel;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<UserPickerCubit>();
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.75,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Имя или email',
                  ),
                  onChanged: cubit.search,
                ),
              ],
            ),
          ),
          if (noneLabel != null)
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Tf.primarySoft,
                child: Icon(Icons.people_outline, color: Tf.primary),
              ),
              title: Text(noneLabel!),
              onTap: () => Navigator.pop(context, const UserChoice(null)),
            ),
          Expanded(
            child: BlocBuilder<UserPickerCubit, ViewState<List<User>>>(
              builder: (context, state) => ViewStateView<List<User>>(
                state: state,
                onRetry: cubit.retry,
                emptyIcon: Icons.person_search,
                emptyText: 'Никого не найдено',
                builder: (users) => ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (_, i) {
                    final u = users[i];
                    return ListTile(
                      leading: UserAvatar(name: u.name, id: u.id),
                      title: Text(u.name),
                      subtitle: Text(u.email),
                      onTap: () => Navigator.pop(context, UserChoice(u)),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
