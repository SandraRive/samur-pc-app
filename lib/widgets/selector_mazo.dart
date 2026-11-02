import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../data/entreno.dart';
import '../theme/app_theme.dart';

// Lista de mazos para elegir con cuál jugar (la usan varios juegos)
class SelectorMazo extends StatelessWidget {
  final String intro;
  final bool Function(Mazo) filtro; // qué mazos sirven para este juego
  final String Function(Mazo)
  detalle; // texto bajo el nombre (récord, nº de cartas…)
  final void Function(Mazo) alElegir;

  const SelectorMazo({
    super.key,
    required this.intro,
    required this.filtro,
    required this.detalle,
    required this.alElegir,
  });

  @override
  Widget build(BuildContext context) {
    final validos = mazos.where(filtro).toList();
    final secciones = [
      ('Mazos grandes', validos.where((m) => m.cartas.length >= 10).toList()),
      (
        'Escalas y clasificaciones',
        validos.where((m) => m.cartas.length < 10).toList(),
      ),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
      children: [
        Text(
          'Elige un mazo',
          style: GoogleFonts.unbounded(
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          intro,
          style: const TextStyle(height: 1.4, color: AppColors.texto2),
        ),
        for (final (titulo, lista) in secciones)
          if (lista.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              titulo,
              style: GoogleFonts.unbounded(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            for (final m in lista)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: AppColors.panel,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => alElegir(m),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.linea),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: m.color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(m.icono, size: 19, color: m.color),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  m.titulo,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  detalle(m),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.texto2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            LucideIcons.chevronRight,
                            color: AppColors.texto2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
      ],
    );
  }
}
