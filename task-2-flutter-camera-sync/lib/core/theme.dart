import 'package:flutter/material.dart';

/// Navy dark palette from the design reference. Text colors were picked for
/// WCAG AA contrast on [surface] and [background].
abstract final class AppColors {
  static const Color background = Color(0xFF070B16);
  static const Color surface = Color(0xFF0F1626);
  static const Color surfaceHigh = Color(0xFF18223A);
  static const Color primary = Color(0xFF3B66F5);
  static const Color onPrimary = Colors.white;
  static const Color textMuted = Color(0xFF9AA4B8);
  static const Color amber = Color(0xFFF5B83D);
  static const Color red = Color(0xFFFF7A7A);
  static const Color green = Color(0xFF4ADE80);
}

/// Colors of the upload states. Always paired with an icon and a label.
@immutable
class StatusColors extends ThemeExtension<StatusColors> {
  const StatusColors({
    required this.waiting,
    required this.retrying,
    required this.uploading,
    required this.synced,
    required this.queued,
  });

  final Color waiting;
  final Color retrying;
  final Color uploading;
  final Color synced;
  final Color queued;

  static const StatusColors standard = StatusColors(
    waiting: AppColors.amber,
    retrying: AppColors.red,
    uploading: AppColors.primary,
    synced: AppColors.green,
    queued: AppColors.textMuted,
  );

  @override
  StatusColors copyWith({
    Color? waiting,
    Color? retrying,
    Color? uploading,
    Color? synced,
    Color? queued,
  }) => StatusColors(
    waiting: waiting ?? this.waiting,
    retrying: retrying ?? this.retrying,
    uploading: uploading ?? this.uploading,
    synced: synced ?? this.synced,
    queued: queued ?? this.queued,
  );

  @override
  StatusColors lerp(ThemeExtension<StatusColors>? other, double t) {
    if (other is! StatusColors) return this;
    return StatusColors(
      waiting: Color.lerp(waiting, other.waiting, t)!,
      retrying: Color.lerp(retrying, other.retrying, t)!,
      uploading: Color.lerp(uploading, other.uploading, t)!,
      synced: Color.lerp(synced, other.synced, t)!,
      queued: Color.lerp(queued, other.queued, t)!,
    );
  }
}

abstract final class AppTheme {
  static const String monoFamily = 'monospace';

  /// Small, spaced, monospaced label used for section titles and statuses.
  static TextStyle label(BuildContext context, {Color? color}) =>
      Theme.of(context).textTheme.labelSmall!.copyWith(
        fontFamily: monoFamily,
        letterSpacing: 1.1,
        fontWeight: FontWeight.w600,
        color: color,
      );

  static ThemeData dark() {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
        ).copyWith(
          primary: AppColors.primary,
          onPrimary: AppColors.onPrimary,
          surface: AppColors.surface,
          surfaceContainerHighest: AppColors.surfaceHigh,
          error: AppColors.red,
        );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      extensions: const [StatusColors.standard],
    );
  }
}
