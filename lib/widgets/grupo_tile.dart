import 'package:flutter/material.dart';

import '../data/ambitos.dart';
import '../data/manual.dart';
import '../theme/app_theme.dart';
import '../screens/procedimiento_screen.dart';

class GrupoTile extends StatelessWidget {
  final Ambito ambito;
  final String grupo;

  const GrupoTile({super.key, required this.ambito, required this.grupo});

  @override
  Widget build(BuildContext context) {
    final c = ambito.color;
    final procs = manual.procedimientosDe(ambito.id, grupo);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior:
          Clip.antiAlias, // recorta el contenido a las esquinas redondas
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.linea),
      ),
      child: ExpansionTile(
        shape: const Border(), // sin líneas al abrir
        collapsedShape: const Border(), // sin líneas al cerrar
        iconColor: c,
        collapsedIconColor: AppColors.texto2,
        leading: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: c, shape: BoxShape.circle),
        ),
        title: Text(grupo, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(
          '${procs.length} procedimientos',
          style: const TextStyle(fontSize: 12, color: AppColors.texto2),
        ),
        childrenPadding: const EdgeInsets.only(bottom: 8),
        children: [
          for (final p in procs)
            ListTile(
              dense: true,
              title: Text(p.titulo),
              trailing: const Icon(
                Icons.chevron_right,
                color: AppColors.texto2,
              ),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        ProcedimientoScreen(proc: p, ambito: ambito),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
