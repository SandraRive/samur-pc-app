import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/ambitos.dart';
import '../theme/app_theme.dart';
import '../widgets/ambito_card.dart';
import '../widgets/tarjeta_rango.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Título con el punto naranja, como en tu web
            Text.rich(
              const TextSpan(
                children: [
                  TextSpan(text: 'SAMUR'),
                  TextSpan(
                    text: '·',
                    style: TextStyle(color: AppColors.naranja),
                  ),
                  TextSpan(text: 'PC\nen modo guardia'),
                ],
              ),
              style: GoogleFonts.unbounded(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                height: 1.15,
                color: AppColors.texto,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Manual de Procedimientos 2026',
              style: TextStyle(color: AppColors.texto2),
            ),
            const SizedBox(height: 24),
            const TarjetaRango(),
            // Una tarjeta por cada ámbito
            for (final a in ambitos) AmbitoCard(ambito: a),
          ],
        ),
      ),
    );
  }
}
