import 'package:flutter/material.dart';

const Color visionInk = Color(0xFF121611);
const Color visionPanel = Color(0xFF1C241A);
const Color visionLine = Color(0xFF314033);
const Color visionAccent = Color(0xFFD6EF7A);
const Color visionMuted = Color(0xFFB7C3B2);

ThemeData buildVisionTheme() {
  const ColorScheme scheme = ColorScheme.dark(
    surface: visionInk,
    primary: visionAccent,
    onPrimary: Color(0xFF1A2408),
    secondary: Color(0xFF8FBC8A),
    onSecondary: Color(0xFF10210F),
    onSurface: Color(0xFFF4F7F0),
    error: Color(0xFFFF8D7A),
    outline: visionLine,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: visionInk,
    appBarTheme: const AppBarTheme(
      backgroundColor: visionInk,
      foregroundColor: Color(0xFFF4F7F0),
      elevation: 0,
      centerTitle: false,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: visionPanel,
      indicatorColor: visionAccent.withValues(alpha: 0.18),
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: visionAccent,
      thumbColor: visionAccent,
      inactiveTrackColor: visionLine,
    ),
  );
}
