import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:lab11/components/common.dart';
import 'package:lab11/components/view_state_view.dart';
import 'package:lab11/constants/app_theme.dart';
import 'package:lab11/core/bloc/view_state.dart';
import 'package:lab11/core/di/injection.dart';
import 'package:lab11/core/validation/validators.dart';
import 'package:lab11/src/users/domain/entities/user.dart';
import 'package:lab11/src/users/presentation/bloc/users_cubit.dart';
import 'package:lab11/src/users/presentation/pages/user_detail_page.dart';

class UsersPage extends StatelessWidget {
  const UsersPage({super.key, required this.actions});

  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<UsersCubit>(),
      child: Builder(
        builder: (context) {
          final cubit = context.read<UsersCubit>();
          return GradientScaffold(
            title: 'Пользователи',
            actions: actions,
            floatingActionButton: FloatingActionButton.extended(
              heroTag: 'users-fab',
              onPressed: () => showUserForm(context, cubit: cubit),
              icon: const Icon(Icons.person_add_alt),
              label: const Text('Пользователь'),
            ),
            body: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                  child: TextField(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search, color: Tf.primary),
                      hintText: 'Имя или email',
                    ),
                    onChanged: cubit.search,
                  ),
                ),
                Expanded(
                  child: BlocBuilder<UsersCubit, ViewState<List<User>>>(
                    builder: (context, state) => ViewStateView<List<User>>(
                      state: state,
                      onRetry: cubit.retry,
                      emptyIcon: Icons.group_outlined,
                      emptyText: 'Пользователей нет',
                      builder: (list) =>
                          NotificationListener<ScrollNotification>(
                            onNotification: (n) {
                              if (n.metrics.extentAfter < 300) cubit.loadMore();
                              return false;
                            },
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                              itemCount: list.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (_, i) {
                                final u = list[i];
                                return Card(
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 4,
                                    ),
                                    leading: UserAvatar(
                                      name: u.name,
                                      id: u.id,
                                      size: 42,
                                    ),
                                    title: Text(
                                      u.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: Text(u.email),
                                    trailing: const Icon(
                                      Icons.chevron_right,
                                      color: Tf.muted,
                                    ),
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            UserDetailPage(userId: u.id),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Создание или редактирование пользователя. Возвращает id нового пользователя.
Future<int?> showUserForm(
  BuildContext context, {
  required UsersCubit cubit,
  User? user,
}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Tf.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => _UserForm(cubit: cubit, user: user),
  );
}

class _UserForm extends StatefulWidget {
  const _UserForm({required this.cubit, this.user});

  final UsersCubit cubit;
  final User? user;

  @override
  State<_UserForm> createState() => _UserFormState();
}

class _UserFormState extends State<_UserForm> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.user?.name);
  late final _email = TextEditingController(text: widget.user?.email);
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() => _saving = true);
    final nav = Navigator.of(context);
    int? newId;
    final ok = await runGuarded(
      context,
      () async {
        if (widget.user == null) {
          final r = await widget.cubit.create(_name.text, _email.text);
          return r.fold((f) => f, (id) {
            newId = id;
            return null;
          });
        }
        return widget.cubit.update(widget.user!.id, _name.text, _email.text);
      },
      success: widget.user == null
          ? 'Пользователь создан'
          : 'Изменения сохранены',
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) nav.pop(newId ?? widget.user?.id);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.user == null ? 'Новый пользователь' : 'Редактирование',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Имя',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: Validators.form(
                (v) => Validators.text(v, 'Имя', max: 100),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.alternate_email),
              ),
              validator: Validators.form(Validators.email),
            ),
            if (widget.user != null) ...[
              const SizedBox(height: 10),
              Text(
                'Дата регистрации: ${fmtDate(widget.user!.registeredAt)}',
                style: const TextStyle(color: Tf.muted),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
  }
}
