import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../data/progreso.dart';
import '../theme/app_theme.dart';

// Tarjeta con tu rango, tu XP y la barra hasta el siguiente rango
class TarjetaRango extends StatelessWidget {
  const TarjetaRango({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: progreso,
      builder: (context, _) {
        final rango = progreso.rango;
        final siguiente = progreso.siguienteRango;

        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.naranja.withValues(alpha: 0.14),
                AppColors.panel,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.naranja.withValues(alpha: 0.35),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.naranja.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      LucideIcons.trophy,
                      color: AppColors.naranja,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tu rango',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.texto2,
                          ),
                        ),
                        Text(
                          rango.nombre,
                          style: GoogleFonts.unbounded(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.texto,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${progreso.xp} XP',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.naranja,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Barra de progreso hacia el siguiente rango
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: progreso.porcentajeRango,
                  minHeight: 8,
                  backgroundColor: AppColors.linea,
                  color: AppColors.naranja,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                siguiente == null
                    ? '¡Has llegado al rango máximo! 🎖️'
                    : 'Te faltan ${siguiente.xp - progreso.xp} XP para ser ${siguiente.nombre}',
                style: const TextStyle(fontSize: 12, color: AppColors.texto2),
              ),
            ],
          ),
        );
      },
    );
  }
}
