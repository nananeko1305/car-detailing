import 'package:flutter/material.dart';

/// The app's one look, "Keramika": dark graphite with a pearl sheen, like a
/// ceramic coating. Carried by the [ThemeData], so widgets read it through
/// `context.colors` and never from statics.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.primary,
    required this.secondary,
    required this.mint,
    required this.warning,
    required this.danger,
    required this.success,
    required this.background,
    required this.surface,
    required this.surfaceHigh,
    required this.border,
    required this.ink,
    required this.muted,
    required this.onPrimary,
    required this.pearl,
    required this.displayFont,
    required this.bodyFont,
    required this.radius,
  });

  /// Solid stand-in for the pearl: links, rings, small accents. Passes 4.5:1
  /// as text on [surface].
  final Color primary;

  /// The teal end of the pearl, as text: workers, secondary accents.
  final Color secondary;

  /// The mint end of the pearl.
  final Color mint;

  /// Jobs whose day has passed without being finished.
  final Color warning;
  final Color danger;
  final Color success;
  final Color background;
  final Color surface;
  final Color surfaceHigh;
  final Color border;

  /// Main text color.
  final Color ink;

  /// Secondary text; passes 4.5:1 on [surface].
  final Color muted;

  /// Text and icons on [pearl].
  final Color onPrimary;

  /// The pearl gradient: the main button, the selected day and tab.
  final List<Color> pearl;
  final String displayFont;
  final String bodyFont;
  final double radius;

  LinearGradient get pearlGradient => LinearGradient(
    begin: const Alignment(-1, -0.6),
    end: const Alignment(1, 0.6),
    colors: pearl,
    stops: const [0, 0.55, 1],
  );

  /// Tinted background for avatars and highlights.
  Color get soft => primary.withValues(alpha: 0.16);

  /// Full-screen pages (login, notices): a faint violet glow at the top.
  BoxDecoration get softGradient => BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color.lerp(background, pearl.first, 0.12)!, background],
    ),
  );

  /// A display-font style.
  TextStyle display(double size, {FontWeight? weight, Color? color}) =>
      TextStyle(
        fontFamily: displayFont,
        fontSize: size,
        fontWeight: weight ?? FontWeight.w700,
        color: color ?? ink,
        height: 1.15,
      );

  @override
  AppColors copyWith() => this;

  @override
  AppColors lerp(AppColors? other, double t) => this;
}

const AppColors kCeramic = AppColors(
  primary: Color(0xFFB9AEFF),
  secondary: Color(0xFF9EE6EF),
  mint: Color(0xFFC8F7E1),
  warning: Color(0xFFFFB38A),
  danger: Color(0xFFFF8A8A),
  success: Color(0xFF6EE0A6),
  background: Color(0xFF111317),
  surface: Color(0xFF1A1D23),
  surfaceHigh: Color(0xFF23272F),
  border: Color(0x14FFFFFF),
  ink: Color(0xFFEDEFF3),
  muted: Color(0xFFA0A7B4),
  onPrimary: Color(0xFF0E1014),
  pearl: [Color(0xFFA795FF), Color(0xFF79DCEB), Color(0xFFBDF6DC)],
  displayFont: 'SpaceGrotesk',
  bodyFont: 'Inter',
  radius: 18,
);

extension AppColorsX on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}
