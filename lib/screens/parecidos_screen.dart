import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../data/entreno.dart';
import '../theme/app_theme.dart';
import 'quiz_screen.dart';

class ParecidosScreen extends StatelessWidget {
  final Color color;

  const ParecidosScreen({super.key, required this.color});

  // Reutilizamos la pantalla de test: el truco sale en la bombilla 💡
  void _jugar(BuildContext context, int? grupo) {
    final preguntas = preguntasParecidos(grupo);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuizScreen(
          titulo: grupo == null
              ? '¿Cuál es cuál?'
              : gruposParecidos[grupo]['t'] as String,
          preguntas: preguntas,
          color: color,
          cuantas: preguntas.length,
          barajar: false,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final grupos = gruposParecidos;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.fondo,
        foregroundColor: AppColors.texto,
        scrolledUnderElevation: 0,
        title: Text(
          'Parecidos que se confunden',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          Text(
            'Lo que más se mezcla en un test',
            style: GoogleFonts.unbounded(
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Datos que se parecen tanto que en el examen es fácil cambiarlos. '
            'Repasa cada grupo con su truco y luego ponte a prueba.',
            style: TextStyle(height: 1.4, color: AppColors.texto2),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _jugar(context, null),
              icon: const Icon(LucideIcons.shuffle, size: 18),
              label: const Text('¿Cuál es cuál? (todo mezclado)'),
              style: FilledButton.styleFrom(
                backgroundColor: color,
                foregroundColor: AppColors.fondo,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          for (var k = 0; k < grupos.length; k++)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: AppColors.panel,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.linea),
              ),
              child: ExpansionTile(
                shape: const Border(),
                collapsedShape: const Border(),
                iconColor: color,
                collapsedIconColor: AppColors.texto2,
                title: Text(
                  grupos[k]['t'] as String,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  '${(grupos[k]['i'] as List).length} datos',
                  style: const TextStyle(fontSize: 12, color: AppColors.texto2),
                ),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                children: [
                  // Los datos del grupo
                  for (final x in grupos[k]['i'] as List)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              x[0] as String,
                              style: const TextStyle(color: AppColors.texto2),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              x[1] as String,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  // El truco
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 4, bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '✨ ${grupos[k]['tip']}',
                      style: const TextStyle(height: 1.4),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: () => _jugar(context, k),
                      icon: const Icon(LucideIcons.play, size: 16),
                      label: const Text('Practicar este grupo'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: color,
                        side: BorderSide(color: color.withValues(alpha: 0.5)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
