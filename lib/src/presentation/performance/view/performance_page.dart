import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:lab11/components/common.dart';
import 'package:lab11/constants/app_theme.dart';
import 'package:lab11/core/di/injection.dart';
import 'package:lab11/src/presentation/performance/bloc/performance_cubit.dart';

/// Тест производительности: генерация 1000/100/10000 записей
/// и сравнение скорости запросов с индексами и без.
class PerformancePage extends StatelessWidget {
  const PerformancePage({super.key});

  Future<void> _clear(BuildContext context, PerformanceCubit cubit) async {
    if (await confirm(
      context,
      'Удалить все данные?',
      'Будут удалены все пользователи, проекты и задачи.',
    )) {
      await cubit.clearAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<PerformanceCubit>(),
      child: BlocConsumer<PerformanceCubit, PerformanceState>(
        listener: (context, state) {
          if (state.error != null) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.error!.message)));
          }
        },
        builder: (context, state) =>
            _build(context, context.read<PerformanceCubit>(), state),
      ),
    );
  }

  Widget _build(
    BuildContext context,
    PerformanceCubit cubit,
    PerformanceState state,
  ) {
    final busy = state.busy != null;
    return GradientScaffold(
      title: 'Производительность',
      subtitle: 'Индексы SQLite',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Тестовая база',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Добавляет 1 000 пользователей, 100 проектов (по 10 участников) и 10 000 задач.',
                    style: TextStyle(color: Tf.muted),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Сейчас задач в базе: ${state.taskCount ?? '…'}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (state.seedTime != null)
                    Text(
                      'Генерация заняла ${(state.seedTime!.inMilliseconds / 1000).toStringAsFixed(1)} с',
                      style: const TextStyle(color: Tf.muted),
                    ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: busy ? null : cubit.generate,
                    icon: const Icon(Icons.dataset_outlined),
                    label: const Text('Сгенерировать данные'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: Tf.accent),
            onPressed: busy ? null : cubit.benchmark,
            icon: const Icon(Icons.speed),
            label: const Text('Сравнить: с индексами и без'),
          ),
          if (busy) ...[
            const SizedBox(height: 20),
            const LinearProgressIndicator(
              color: Tf.accent,
              backgroundColor: Tf.accentSoft,
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(state.busy!, style: const TextStyle(color: Tf.muted)),
            ),
          ],
          if (state.results != null) ...[
            const SectionTitle('Среднее время запроса, мс'),
            for (final r in state.results!)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r.name,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _Metric(
                                label: 'С индексами',
                                value: r.withIndexMs,
                                color: Tf.primary,
                              ),
                            ),
                            Expanded(
                              child: _Metric(
                                label: 'Без индексов',
                                value: r.withoutIndexMs,
                                color: Tf.accent,
                              ),
                            ),
                            Pill(
                              label: '×${r.speedup.toStringAsFixed(1)}',
                              color: r.speedup >= 1.2 ? Tf.green : Tf.muted,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            const Text(
              'Индексы ускоряют поиск по равенству, диапазону и сортировку. '
              'Поиск LIKE \'%…%\' по подстроке индекс не использует, поэтому время почти не меняется.',
              style: TextStyle(color: Tf.muted, fontSize: 12.5),
            ),
          ],
          const SizedBox(height: 28),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Tf.accent,
              side: const BorderSide(color: Tf.accent),
            ),
            onPressed: busy ? null : () => _clear(context, cubit),
            icon: const Icon(Icons.delete_sweep_outlined),
            label: const Text('Удалить все данные'),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Tf.muted, fontSize: 12)),
        Text(
          value.toStringAsFixed(2),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}
