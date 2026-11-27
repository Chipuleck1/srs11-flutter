import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:lab11/components/common.dart';
import 'package:lab11/constants/app_theme.dart';
import 'package:lab11/core/di/injection.dart';
import 'package:lab11/src/home/presentation/bloc/current_user_cubit.dart';
import 'package:lab11/src/home/presentation/bloc/welcome_cubit.dart';
import 'package:lab11/src/users/presentation/bloc/users_cubit.dart';
import 'package:lab11/src/users/presentation/pages/users_page.dart';

/// Первый запуск: база пустая.
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<WelcomeCubit>()),
        BlocProvider(create: (_) => getIt<UsersCubit>()),
      ],
      child: BlocBuilder<WelcomeCubit, bool>(
        builder: (context, loading) {
          final welcome = context.read<WelcomeCubit>();
          return Scaffold(
            body: Container(
              decoration: const BoxDecoration(gradient: Tf.gradient),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Spacer(),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          width: 92,
                          height: 92,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Tf.background,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: Tf.glow(0.6),
                          ),
                          child: const Icon(
                            Icons.task_alt_rounded,
                            size: 56,
                            color: Tf.accent,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      const Text(
                        'TaskFlow',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Проекты, задачи и команда — всё работает офлайн и хранится в SQLite.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          height: 1.4,
                        ),
                      ),
                      const Spacer(flex: 2),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: Tf.background,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: loading
                            ? null
                            : () async {
                                final id = await showUserForm(
                                  context,
                                  cubit: context.read<UsersCubit>(),
                                );
                                if (id != null) {
                                  await getIt<CurrentUserCubit>().select(id);
                                }
                              },
                        icon: const Icon(Icons.person_add_alt),
                        label: const Text('Создать пользователя'),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white),
                          minimumSize: const Size(0, 50),
                        ),
                        onPressed: loading
                            ? null
                            : () => runGuarded(context, welcome.seedDemo),
                        icon: loading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.auto_awesome),
                        label: const Text('Заполнить демо-данными'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
