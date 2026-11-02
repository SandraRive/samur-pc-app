import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../theme/app_theme.dart';

const _verde = Color(0xFF2EE6A6);
const _rojo = Color(0xFFFF4D6A);

enum EstadoOpcion { normal, correcta, incorrecta, apagada }

class OpcionRespuesta extends StatelessWidget {
  final String letra;
  final String texto;
  final EstadoOpcion estado;
  final VoidCallback onTap;
  final String? porque; // explicación de la opción (se ve al responder)

  const OpcionRespuesta({
    super.key,
    required this.letra,
    required this.texto,
    required this.estado,
    required this.onTap,
    this.porque,
  });

  @override
  Widget build(BuildContext context) {
    final (fondo, borde, colorLetra) = switch (estado) {
      EstadoOpcion.correcta => (_verde.withValues(alpha: 0.15), _verde, _verde),
      EstadoOpcion.incorrecta => (_rojo.withValues(alpha: 0.15), _rojo, _rojo),
      _ => (AppColors.panel, AppColors.linea, AppColors.texto2),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Opacity(
        opacity: estado == EstadoOpcion.apagada ? 0.45 : 1,
        child: Material(
          color: fondo,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: estado == EstadoOpcion.normal ? onTap : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borde, width: 1.5),
              ),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: borde.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      letra,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: colorLetra,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          texto,
                          style: const TextStyle(fontSize: 15, height: 1.35),
                        ),
                        // El porqué solo aparece después de responder
                        if (porque != null && estado != EstadoOpcion.normal)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              porque!,
                              style: const TextStyle(
                                fontSize: 12.5,
                                height: 1.35,
                                color: AppColors.texto2,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (estado == EstadoOpcion.correcta)
                    const Icon(
                      LucideIcons.circleCheck,
                      color: _verde,
                      size: 20,
                    ),
                  if (estado == EstadoOpcion.incorrecta)
                    const Icon(LucideIcons.circleX, color: _rojo, size: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
