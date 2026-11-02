import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../data/entreno.dart';
import '../data/progreso.dart';
import '../screens/entreno_screen.dart';
import '../theme/app_theme.dart';

// Botón grande de la portada que lleva al Entreno
class BannerEntreno extends StatelessWidget {
  const BannerEntreno({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: progreso,
      builder: (context, _) => Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const EntrenoScreen())),
            child: Ink(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [cNaranja.withValues(alpha: 0.30), AppColors.panel],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cNaranja.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: cNaranja,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      LucideIcons.dumbbell,
                      color: AppColors.fondo,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Entreno SAMUR·PC',
                          style: GoogleFonts.unbounded(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          progreso.retoHechoHoy
                              ? '✅ Reto del día hecho · 🔥 ${progreso.rachaDias} días'
                              : '🔥 Reto del día pendiente',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.texto2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(LucideIcons.chevronRight, color: cNaranja),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
