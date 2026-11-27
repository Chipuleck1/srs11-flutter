import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:lab11/constants/app_theme.dart';
import 'package:lab11/core/di/injection.dart';
import 'package:lab11/src/presentation/bloc/home/current_user_cubit.dart';
import 'package:lab11/src/presentation/pages/home/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Все зависимости регистрируются централизованно (GetIt)
  await configureDependencies();
  await getIt<CurrentUserCubit>().init();
  runApp(const TaskFlowApp());
}

class TaskFlowApp extends StatelessWidget {
  const TaskFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: getIt<CurrentUserCubit>(),
      child: MaterialApp(
        title: 'TaskFlow',
        debugShowCheckedModeBanner: false,
        theme: Tf.theme(),
        home: const HomePage(),
      ),
    );
  }
}
