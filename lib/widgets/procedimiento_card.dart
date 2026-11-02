import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../data/ambitos.dart';
import '../data/manual.dart';
import '../data/progreso.dart';
import '../screens/procedimiento_screen.dart';
import '../theme/app_theme.dart';

class ProcedimientoCard extends StatelessWidget {
  final Procedimiento proc;
  final Ambito ambito;
  final IconData icono; // el icono del bloque

  const ProcedimientoCard({
    super.key,
    required this.proc,
    required this.ambito,
    required this.icono,
  });

  static const _verde = Color(0xFF2EE6A6);

  @override
  Widget build(BuildContext context) {
    final c = ambito.color;
    const estiloDato = TextStyle(fontSize: 12, color: AppColors.texto2);

    return ListenableBuilder(
      listenable: progreso,
      builder: (context, _) {
        final hecho = progreso.estaEstudiado(proc.id);

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Material(
            color: AppColors.panel,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        ProcedimientoScreen(proc: proc, ambito: ambito),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  // Borde verdoso si ya está estudiado, como en tu web
                  border: Border.all(
                    color: hecho
                        ? _verde.withValues(alpha: 0.35)
                        : AppColors.linea,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icono del bloque
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: c.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icono, size: 20, color: c),
                    ),
                    const SizedBox(width: 12),
                    // Título + minutos + páginas
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            proc.titulo,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(
                                LucideIcons.clock,
                                size: 13,
                                color: AppColors.texto2,
                              ),
                              const SizedBox(width: 4),
                              Text('${proc.minutos} min', style: estiloDato),
                              const SizedBox(width: 12),
                              const Icon(
                                LucideIcons.fileText,
                                size: 13,
                                color: AppColors.texto2,
                              ),
                              const SizedBox(width: 4),
                              Text(proc.textoPaginas, style: estiloDato),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Check verde si está estudiado
                    if (hecho) ...[
                      const SizedBox(width: 8),
                      const Icon(
                        LucideIcons.badgeCheck,
                        size: 20,
                        color: _verde,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
