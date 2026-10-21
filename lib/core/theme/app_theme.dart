import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const _seed = Color(0xFF0B3D2E);

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.light,
      primary: const Color(0xFF0B3D2E),
      secondary: const Color(0xFFC45C26),
      surface: const Color(0xFFF4F6F5),
    );
    return _base(scheme, const Color(0xFFF4F6F5));
  }

  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.dark,
      primary: const Color(0xFF6FCFB0),
      secondary: const Color(0xFFE08A5D),
    );
    return _base(scheme, const Color(0xFF121816));
  }

  static ThemeData _base(ColorScheme scheme, Color scaffold) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffold,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'requested':
        return const Color(0xFFB45309);
      case 'assigned':
        return const Color(0xFF1D4ED8);
      case 'in_progress':
      case 'inprogress':
      case 'on_trip':
      case 'ontrip':
        return const Color(0xFF047857);
      case 'completed':
        return const Color(0xFF475569);
      case 'cancelled':
        return const Color(0xFFB91C1C);
      case 'available':
        return const Color(0xFF059669);
      case 'offline':
        return const Color(0xFF64748B);
      default:
        return const Color(0xFF334155);
    }
  }
}
