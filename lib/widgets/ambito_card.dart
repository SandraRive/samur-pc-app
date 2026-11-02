import 'package:flutter/material.dart';

import '../data/ambitos.dart';
import '../theme/app_theme.dart';
import '../screens/ambito_screen.dart';
import '../screens/vademecum_screen.dart';
import '../screens/repaso_screen.dart';

class AmbitoCard extends StatelessWidget {
  final Ambito ambito;

  const AmbitoCard({super.key, required this.ambito});

  @override
  Widget build(BuildContext context) {
    final c = ambito.color;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => switch (ambito.id) {
                  'vademecum' => VademecumScreen(ambito: ambito),
                  'repaso' => RepasoScreen(ambito: ambito),
                  _ => AmbitoScreen(ambito: ambito),
                },
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.linea),
            ),
            child: Row(
              children: [
                // Cuadradito del icono
                Hero(
                  tag: 'icono-${ambito.id}',
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: c.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(ambito.icono, color: c),
                  ),
                ),
                const SizedBox(width: 14),
                // Nombre y descripción
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ambito.nombre,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ambito.descripcion,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.texto2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // Pastilla con el nº de procedimientos
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: c.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    '${ambito.total}',
                    style: TextStyle(color: c, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
