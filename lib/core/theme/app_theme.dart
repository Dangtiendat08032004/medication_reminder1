import 'package:flutter/material.dart';
import 'colors.dart';

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.onPrimaryContainer,
      error: AppColors.error,
      onError: AppColors.onError,
      surface: AppColors.surface,
      onSurface: AppColors.onSurface,
      brightness: Brightness.light,
    ),
    useMaterial3: true,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primaryDark,
      primary: AppColors.primaryDark,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.onPrimaryContainer,
      error: AppColors.error,
      onError: AppColors.onError,
      surface: const Color(0xFF1C1B1F),
      onSurface: const Color(0xFFE6E1E5),
      brightness: Brightness.dark,
    ),
    useMaterial3: true,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primaryDark,
      foregroundColor: Colors.white,
    ),
  );
}
