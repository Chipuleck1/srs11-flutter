import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:lab11/models/enums.dart';

/// Палитра TaskFlow: чёрный фон и красные акценты.
abstract final class Tf {
  // акценты
  static const primary = Color(0xFFE50914); // насыщенный красный
  static const accent = Color(0xFFFF3B3B); // яркий красный для выделения
  static const white = Colors.white;

  // поверхности
  static const background = Color(0xFF0A0A0B); // почти чёрный фон
  static const surface = Color(0xFF151518); // карточки, листы, диалоги
  static const surfaceHigh = Color(0xFF1F1F24); // поля ввода, чипы
  static const primarySoft = Color(0xFF2A0F12); // красный оттенок на тёмном
  static const accentSoft = Color(0xFF331216);
  static const border = Color(0xFF2A2A30);

  // текст
  static const ink = Color(0xFFF5F5F7);
  static const muted = Color(0xFF9B9BA3);

  // вспомогательные
  static const green = Color(0xFF2ECC71);
  static const orange = Color(0xFFFF8A3D);
  static const amber = Color(0xFFFFB627);

  /// Главный градиент: красный → тёмно-бордовый.
  static const gradient = LinearGradient(
    colors: [Color(0xFFFF2A2A), Color(0xFFB0060F), Color(0xFF4A0008)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Красное свечение для акцентных блоков.
  static List<BoxShadow> glow([double strength = 0.45]) => [
    BoxShadow(
      color: primary.withValues(alpha: strength),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  static ThemeData theme() {
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.dark,
      primary: primary,
      onPrimary: white,
      secondary: accent,
      onSecondary: white,
      surface: surface,
      onSurface: ink,
      error: accent,
    );
    final radius = BorderRadius.circular(16);
    return ThemeData(
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      fontFamily: 'Roboto',
      splashColor: primary.withValues(alpha: 0.15),
      highlightColor: primary.withValues(alpha: 0.08),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: white,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: white,
          letterSpacing: 0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: border),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surface,
        modalBackgroundColor: surface,
        dragHandleColor: border,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surfaceHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      listTileTheme: const ListTileThemeData(iconColor: muted, textColor: ink),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: white,
        shape: StadiumBorder(),
        elevation: 8,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: white,
          disabledBackgroundColor: surfaceHigh,
          minimumSize: const Size(0, 50),
          shape: RoundedRectangleBorder(borderRadius: radius),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            letterSpacing: 0.3,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accent,
          minimumSize: const Size(0, 46),
          side: const BorderSide(color: primary),
          shape: RoundedRectangleBorder(borderRadius: radius),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: accent),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceHigh,
        labelStyle: const TextStyle(color: muted),
        hintStyle: const TextStyle(color: muted),
        prefixIconColor: muted,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(color: accent),
        ),
      ),
      chipTheme: const ChipThemeData(
        backgroundColor: surfaceHigh,
        side: BorderSide(color: border),
        labelStyle: TextStyle(color: ink),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          backgroundColor: surfaceHigh,
          foregroundColor: ink,
          selectedBackgroundColor: primary,
          selectedForegroundColor: white,
          side: const BorderSide(color: border),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: primarySoft,
        surfaceTintColor: Colors.transparent,
        height: 70,
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(
            color: s.contains(WidgetState.selected) ? accent : muted,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => TextStyle(
            fontSize: 12,
            fontWeight: s.contains(WidgetState.selected)
                ? FontWeight.w800
                : FontWeight.w500,
            color: s.contains(WidgetState.selected) ? accent : muted,
          ),
        ),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: ink,
        unselectedLabelColor: muted,
        indicatorColor: primary,
        dividerColor: border,
        labelStyle: TextStyle(fontWeight: FontWeight.w800),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: primarySoft,
        circularTrackColor: Colors.transparent,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: surfaceHigh,
        contentTextStyle: const TextStyle(color: ink),
        actionTextColor: accent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: border),
        ),
      ),
      datePickerTheme: const DatePickerThemeData(backgroundColor: surface),
      dividerTheme: const DividerThemeData(color: border, space: 1),
    );
  }

  static Color statusColor(TaskStatus s) => switch (s) {
    TaskStatus.todo => muted,
    TaskStatus.inProgress => accent,
    TaskStatus.done => green,
    TaskStatus.cancelled => const Color(0xFF5E5E66),
  };

  static IconData statusIcon(TaskStatus s) => switch (s) {
    TaskStatus.todo => Icons.radio_button_unchecked,
    TaskStatus.inProgress => Icons.timelapse,
    TaskStatus.done => Icons.check_circle,
    TaskStatus.cancelled => Icons.cancel_outlined,
  };

  static Color priorityColor(TaskPriority p) => switch (p) {
    TaskPriority.low => const Color(0xFF8A8A94),
    TaskPriority.medium => amber,
    TaskPriority.high => orange,
    TaskPriority.critical => primary,
  };

  static Color projectStatusColor(ProjectStatus s) => switch (s) {
    ProjectStatus.active => accent,
    ProjectStatus.completed => green,
    ProjectStatus.archived => muted,
  };
}

String fmtDate(DateTime? d) {
  if (d == null) return '—';
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(d.day)}.${two(d.month)}.${d.year}';
}

String fmtDateTime(DateTime d) {
  String two(int v) => v.toString().padLeft(2, '0');
  return '${fmtDate(d)} ${two(d.hour)}:${two(d.minute)}';
}
