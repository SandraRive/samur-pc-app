import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

// Chip de filtro: icono + nombre + contador. Se usa en varias pantallas
class FiltroChip extends StatelessWidget {
  final IconData icono;
  final String texto;
  final int total;
  final Color color;
  final bool activo;
  final VoidCallback onTap;

  const FiltroChip({
    super.key,
    required this.icono,
    required this.texto,
    required this.total,
    required this.color,
    required this.activo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorContenido = activo ? AppColors.fondo : AppColors.texto;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: activo ? color : AppColors.panel,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: activo ? color : AppColors.linea),
          ),
          child: Row(
            children: [
              Icon(
                icono,
                size: 16,
                color: activo ? AppColors.fondo : AppColors.texto2,
              ),
              const SizedBox(width: 6),
              Text(
                texto,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colorContenido,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                decoration: BoxDecoration(
                  color: activo
                      ? AppColors.fondo.withValues(alpha: 0.15)
                      : AppColors.linea,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '$total',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: colorContenido,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
