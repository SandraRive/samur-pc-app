import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/ambitos.dart';
import '../data/manual.dart';
import '../theme/app_theme.dart';
import '../widgets/bloque_contenido.dart';
import '../data/tests.dart';
import 'quiz_screen.dart';

import 'package:lucide_flutter/lucide_flutter.dart';

import '../data/progreso.dart';

class ProcedimientoScreen extends StatelessWidget {
  final Procedimiento proc;
  final Ambito ambito;

  const ProcedimientoScreen({
    super.key,
    required this.proc,
    required this.ambito,
  });

  // "Pág. 18" o "Págs. 18–19"
  String get _paginas {
    final p = proc.paginas;
    if (p.length == 1) return 'Pág. ${p.first}';
    return 'Págs. ${p.first}–${p.last}';
  }

  @override
  Widget build(BuildContext context) {
    final c = ambito.color;
    final test = testPara(proc);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.fondo,
        foregroundColor: AppColors.texto,
        scrolledUnderElevation: 0,
        title: Text(
          proc.grupo,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          // Título del procedimiento
          Text(
            proc.titulo,
            style: GoogleFonts.unbounded(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.2,
              color: AppColors.texto,
            ),
          ),
          const SizedBox(height: 14),

          // Pastillas: ámbito y páginas del manual
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Pastilla(icono: ambito.icono, texto: ambito.nombre, color: c),
              if (proc.paginas.isNotEmpty)
                _Pastilla(
                  icono: Icons.menu_book,
                  texto: _paginas,
                  color: AppColors.texto2,
                ),
            ],
          ),
          const SizedBox(height: 16),
          _BotonEstudiado(proc: proc),
          if (test != null) ...[
            const SizedBox(height: 10),
            _BotonTest(test: test, color: c),
          ],
          const Divider(color: AppColors.linea, height: 36),

          // El contenido, pieza a pieza
          for (final b in proc.bloques) BloqueContenido(bloque: b, color: c),
        ],
      ),
    );
  }
}

// Botón "Marcar como estudiado" / "Estudiado"
class _BotonEstudiado extends StatelessWidget {
  final Procedimiento proc;

  const _BotonEstudiado({required this.proc});

  static const _verde = Color(0xFF2EE6A6);

  void _alPulsar(BuildContext context) {
    final rangoAntes = progreso.rango;
    final yaEstaba = progreso.estaEstudiado(proc.id);

    progreso.alternarEstudiado(proc.id);
    if (yaEstaba) return; // si lo has desmarcado, no celebramos nada 😅

    final subeDeRango = progreso.rango != rangoAntes;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            subeDeRango
                ? '🎖️ ¡Nuevo rango: ${progreso.rango.nombre}!'
                : '+10 XP 🎉',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    // Se redibuja solo cada vez que cambia el progreso
    return ListenableBuilder(
      listenable: progreso,
      builder: (context, _) {
        final hecho = progreso.estaEstudiado(proc.id);
        final forma = RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        );
        const relleno = EdgeInsets.symmetric(vertical: 14);

        return SizedBox(
          width: double.infinity,
          child: hecho
              ? FilledButton.icon(
                  onPressed: () => _alPulsar(context),
                  icon: const Icon(LucideIcons.badgeCheck, size: 18),
                  label: const Text('Estudiado'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _verde,
                    foregroundColor: AppColors.fondo,
                    padding: relleno,
                    shape: forma,
                  ),
                )
              : OutlinedButton.icon(
                  onPressed: () => _alPulsar(context),
                  icon: const Icon(LucideIcons.circleCheck, size: 18),
                  label: const Text('Marcar como estudiado (+10 XP)'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.texto,
                    side: const BorderSide(color: AppColors.linea),
                    padding: relleno,
                    shape: forma,
                  ),
                ),
        );
      },
    );
  }
}

// Pastillita con icono + texto (privada: solo se usa en este archivo)
class _Pastilla extends StatelessWidget {
  final IconData icono;
  final String texto;
  final Color color;

  const _Pastilla({
    required this.icono,
    required this.texto,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min, // que ocupe solo lo justo
        children: [
          Icon(icono, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            texto,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// Botón "Ponme a prueba": abre el test del procedimiento (o de su bloque)
class _BotonTest extends StatelessWidget {
  final Test test;
  final Color color;

  const _BotonTest({required this.test, required this.color});

  @override
  Widget build(BuildContext context) {
    final esDelBloque = test.procId == null;

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => QuizScreen(test: test, color: color),
            ),
          );
        },
        icon: const Icon(LucideIcons.gamepad2, size: 18),
        label: Text(
          esDelBloque ? 'Ponme a prueba · ${test.titulo}' : 'Ponme a prueba',
          overflow: TextOverflow.ellipsis,
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withValues(alpha: 0.5)),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
