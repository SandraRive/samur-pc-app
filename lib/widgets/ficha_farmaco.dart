import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../data/manual.dart';
import '../theme/app_theme.dart';
import 'bloque_contenido.dart';

// Colores de los apartados (los mismos que tu web)
const _cyan = Color(0xFF2EC4F1);
const _verde = Color(0xFF2EE6A6);
const _amarillo = Color(0xFFFFD23F);
const _rojo = Color(0xFFFF3B5C);
const _violeta = Color(0xFFB98CFF);
const _naranja = Color(0xFFFF6B1A);
const _rosa = Color(0xFFFF7AC6); // color del Vademécum

// Icono y color de cada apartado: devuelve DOS cosas a la vez (un "record")
(IconData, Color) _estiloCampo(String titulo) => switch (titulo) {
  'Función' || 'Acción' => (LucideIcons.target, _cyan),
  'Indicaciones' => (LucideIcons.circleCheck, _verde),
  'Dosis' => (LucideIcons.pill, _amarillo),
  'Contraindicaciones' => (LucideIcons.ban, _rojo),
  'Interacciones' => (LucideIcons.gitMerge, _violeta),
  'Efectos secundarios' => (LucideIcons.triangleAlert, _naranja),
  'Presentación' => (LucideIcons.package, AppColors.texto2),
  'Precauciones' => (LucideIcons.shieldAlert, _naranja),
  _ => (LucideIcons.info, AppColors.texto2),
};

// Abre la ficha del fármaco nº [indice] en un panel desde abajo
void abrirFicha(BuildContext context, int indice) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true, // permite que el panel sea alto
    backgroundColor: AppColors.panel,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85, // empieza ocupando el 85 % de la pantalla
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scroll) => _Ficha(indice: indice, scroll: scroll),
    ),
  );
}

// StatefulWidget porque recuerda qué fármaco se está viendo (anterior/siguiente)
class _Ficha extends StatefulWidget {
  final int indice;
  final ScrollController scroll;

  const _Ficha({required this.indice, required this.scroll});

  @override
  State<_Ficha> createState() => _FichaState();
}

class _FichaState extends State<_Ficha> {
  late int _i = widget.indice;

  void _irA(int nuevo) {
    setState(() => _i = nuevo);
    widget.scroll.jumpTo(0); // vuelve arriba del todo
  }

  @override
  Widget build(BuildContext context) {
    final lista = manual.farmacos;
    final f = lista[_i];

    return ListView(
      controller: widget.scroll,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        // Rayita para arrastrar
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.linea,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Etiqueta + botón cerrar
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _rosa.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(99),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.pill, size: 14, color: _rosa),
                  SizedBox(width: 6),
                  Text(
                    'Vademécum',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _rosa,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(LucideIcons.x, color: AppColors.texto2),
              onPressed: () => Navigator.of(context).pop(), // cierra el panel
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Nombre del fármaco
        Text(
          f.nombre,
          style: GoogleFonts.unbounded(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppColors.texto,
          ),
        ),
        const SizedBox(height: 18),

        // Apartados de la ficha
        for (final campo in f.campos) _CampoFicha(campo: campo),
        const SizedBox(height: 8),

        // Anterior / siguiente
        Row(
          children: [
            Expanded(
              child: _i > 0
                  ? _BotonNav(
                      texto: lista[_i - 1].nombre,
                      haciaDelante: false,
                      onTap: () => _irA(_i - 1),
                    )
                  : const SizedBox(),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _i < lista.length - 1
                  ? _BotonNav(
                      texto: lista[_i + 1].nombre,
                      haciaDelante: true,
                      onTap: () => _irA(_i + 1),
                    )
                  : const SizedBox(),
            ),
          ],
        ),
      ],
    );
  }
}

// Un apartado de la ficha (Función, Dosis…) con su icono y color
class _CampoFicha extends StatelessWidget {
  final Campo campo;

  const _CampoFicha({required this.campo});

  @override
  Widget build(BuildContext context) {
    final (icono, color) = _estiloCampo(campo.titulo); // "abre" el record

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
      decoration: BoxDecoration(
        color: AppColors.fondo,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.linea),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icono, size: 16, color: color),
              const SizedBox(width: 8),
              Text(
                campo.titulo,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final b in campo.bloques)
            BloqueContenido(bloque: b, color: color),
        ],
      ),
    );
  }
}

// Botón "← Anterior" / "Siguiente →"
class _BotonNav extends StatelessWidget {
  final String texto;
  final bool haciaDelante;
  final VoidCallback onTap;

  const _BotonNav({
    required this.texto,
    required this.haciaDelante,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final etiqueta = Flexible(
      child: Text(
        texto,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );

    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.texto,
        side: const BorderSide(color: AppColors.linea),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: haciaDelante
            ? [
                etiqueta,
                const SizedBox(width: 6),
                const Icon(LucideIcons.arrowRight, size: 16),
              ]
            : [
                const Icon(LucideIcons.arrowLeft, size: 16),
                const SizedBox(width: 6),
                etiqueta,
              ],
      ),
    );
  }
}
