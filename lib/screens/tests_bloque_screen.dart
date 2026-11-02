import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/ambitos.dart';
import '../data/progreso.dart';
import '../data/tests.dart';
import '../theme/app_theme.dart';
import 'repaso_screen.dart';

// Test por bloque: elige ámbito y bloque, directamente
class TestsBloqueScreen extends StatelessWidget {
  const TestsBloqueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final totalPreguntas = tests.fold<int>(
      0,
      (suma, t) => suma + t.preguntas.length,
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.fondo,
        foregroundColor: AppColors.texto,
        scrolledUnderElevation: 0,
        title: const Text(
          'Test por bloque',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      // Escucha el progreso: al volver de un test, las barras se actualizan
      body: ListenableBuilder(
        listenable: progreso,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: [
            Text(
              'Elige ámbito y bloque',
              style: GoogleFonts.unbounded(
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${tests.length} tests · $totalPreguntas preguntas, con explicación en cada respuesta.',
              style: const TextStyle(height: 1.4, color: AppColors.texto2),
            ),
            const SizedBox(height: 20),
            // La misma lista que en la Zona de repaso, reutilizada
            for (final a in ambitos)
              if (tests.any((t) => t.ambito == a.id)) AmbitoTests(ambito: a),
          ],
        ),
      ),
    );
  }
}
