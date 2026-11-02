import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

// Dibuja una pieza del contenido según su tipo (h, p, li, lab, pre)
class BloqueContenido extends StatelessWidget {
  final Map<String, dynamic> bloque;
  final Color color; // el color del ámbito

  const BloqueContenido({super.key, required this.bloque, required this.color});

  @override
  Widget build(BuildContext context) {
    final texto = (bloque['x'] ?? '') as String;

    return switch (bloque['t']) {
      'h' => _subtitulo(texto),
      'lab' => _etiqueta(texto),
      'li' => _punto(texto, bloque['l'] as int? ?? 0, bloque['o'] as String?),
      'pre' => _tabla(texto),
      _ => _parrafo(texto),
    };
  }

  // h → subtítulo con el color del ámbito
  Widget _subtitulo(String t) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      child: Text(
        t,
        style: GoogleFonts.unbounded(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          height: 1.3,
          color: color,
        ),
      ),
    );
  }

  // p → párrafo normal
  Widget _parrafo(String t) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        t,
        style: const TextStyle(
          fontSize: 15,
          height: 1.5,
          color: AppColors.texto,
        ),
      ),
    );
  }

  // lab → etiqueta destacada con barra lateral de color
  Widget _etiqueta(String t) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            border: Border(left: BorderSide(color: color, width: 3)),
          ),
          child: Text(
            t,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.texto,
            ),
          ),
        ),
      ),
    );
  }

  // li → punto de lista (numerado o con viñeta), con sangría según su nivel
  Widget _punto(String t, int nivel, String? orden) {
    return Padding(
      padding: EdgeInsets.only(left: nivel * 18.0, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            child: orden != null
                // Numerado: "1.", "2."...
                ? Text(
                    '$orden.',
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  )
                // Viñeta: puntito de color (nivel 0) o gris (subniveles)
                : Padding(
                    padding: const EdgeInsets.only(top: 9, left: 4),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: nivel == 0 ? color : AppColors.texto2,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
          ),
          Expanded(
            child: Text(
              t,
              style: const TextStyle(
                fontSize: 15,
                height: 1.5,
                color: AppColors.texto,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // pre → tabla en formato original, con scroll horizontal
  Widget _tabla(String t) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.linea),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Row(
              children: [
                Icon(
                  Icons.table_chart_outlined,
                  size: 14,
                  color: AppColors.texto2,
                ),
                SizedBox(width: 6),
                Text(
                  'Tabla / esquema · formato original',
                  style: TextStyle(fontSize: 11, color: AppColors.texto2),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection:
                Axis.horizontal, // las tablas son anchas → scroll lateral
            padding: const EdgeInsets.all(12),
            child: Text(
              t,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 11,
                height: 1.4,
                color: AppColors.texto,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
