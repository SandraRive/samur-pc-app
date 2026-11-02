import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Tu paleta, como las variables de :root en CSS
class AppColors {
  static const naranja = Color(0xFFFF6B1A);
  static const fondo = Color(0xFF080C17);
  static const panel = Color(0xFF111A2F);
  static const linea = Color(0xFF22304F);
  static const texto = Color(0xFFEEF2FF);
  static const texto2 = Color(0xFFAEB9D6);
}

ThemeData temaSamur() {
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.naranja,
      brightness: Brightness.dark,
      primary: AppColors.naranja,
      surface: AppColors.panel,
      onSurface: AppColors.texto,
    ),
    scaffoldBackgroundColor: AppColors.fondo,
    fontFamily: GoogleFonts.figtree().fontFamily, // 👈 Figtree para toda la app
  );
}
