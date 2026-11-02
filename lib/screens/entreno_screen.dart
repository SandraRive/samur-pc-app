import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../data/ambitos.dart';
import '../data/entreno.dart';
import '../data/progreso.dart';
import '../theme/app_theme.dart';
import 'quiz_screen.dart';
import 'repaso_screen.dart';
import 'escribe_screen.dart';
import 'supervivencia_screen.dart';
import 'verdadero_falso_screen.dart';
import 'simulacro_screen.dart';
import '../data/retos.dart';
import 'tests_bloque_screen.dart';

class EntrenoScreen extends StatelessWidget {
  const EntrenoScreen({super.key});

  // Qué hace cada juego al tocarlo
  void _abrir(BuildContext context, Juego j) {
    switch (j.id) {
      case 'tests':
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const TestsBloqueScreen()));
      case 'fallos':
        final fallos = progreso.fallos;
        if (fallos.isEmpty) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(content: Text('¡No tienes fallos pendientes! 💪')),
            );
          return;
        }
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => QuizScreen(
              titulo: 'Repaso de fallos',
              preguntas: fallos,
              color: j.color,
            ),
          ),
        );
      case 'supervivencia':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => SupervivenciaScreen(color: j.color),
          ),
        );
      case 'verdadero-falso':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => VerdaderoFalsoScreen(color: j.color),
          ),
        );
      case 'escribe':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => EscribeScreen(color: j.color)),
        );
      case 'simulacro':
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const SimulacroScreen()));
      case 'examen':
        _elegirModoExamen(context, j.color);
    }
  }

  void _empezarReto(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuizScreen(
          titulo: 'Reto del día',
          preguntas: preguntasRetoDelDia(),
          color: cNaranja,
          barajar: false, // ya vienen elegidas y barajadas
          esRetoDiario: true,
        ),
      ),
    );
  }

  // Panel para elegir cómo hacer el examen oficial
  void _elegirModoExamen(BuildContext context, Color color) {
    if (examenes.isEmpty) return;
    final x = examenes.first;

    void jugar(
      BuildContext ctx, {
      required int cuantas,
      required bool barajar,
    }) {
      Navigator.of(ctx).pop(); // cierra el panel
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => QuizScreen(
            titulo: x.titulo,
            preguntas: x.preguntas,
            color: color,
            cuantas: cuantas,
            barajar: barajar,
          ),
        ),
      );
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.panel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize:
                MainAxisSize.min, // el panel mide solo lo que necesita
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              const SizedBox(height: 18),
              Text(
                x.titulo,
                style: GoogleFonts.unbounded(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${x.subtitulo} · ${x.preguntas.length} preguntas',
                style: const TextStyle(fontSize: 13, color: AppColors.texto2),
              ),
              const SizedBox(height: 18),
              _OpcionModo(
                icono: LucideIcons.shuffle,
                titulo: '20 al azar',
                descripcion: 'Primero las que aún no dominas',
                color: color,
                onTap: () => jugar(ctx, cuantas: 20, barajar: true),
              ),
              const SizedBox(height: 10),
              _OpcionModo(
                icono: LucideIcons.listOrdered,
                titulo: 'Examen completo',
                descripcion:
                    'Las ${x.preguntas.length} preguntas en el orden del examen',
                color: color,
                onTap: () =>
                    jugar(ctx, cuantas: x.preguntas.length, barajar: false),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final espacioArriba = MediaQuery.paddingOf(context).top + kToolbarHeight;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.texto,
        scrolledUnderElevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [cNaranja.withValues(alpha: 0.20), AppColors.fondo],
            stops: const [0, 0.45],
          ),
        ),
        child: ListenableBuilder(
          listenable: progreso,
          builder: (context, _) => ListView(
            padding: EdgeInsets.fromLTRB(20, espacioArriba + 4, 20, 32),
            children: [
              // ---------- CABECERA ----------
              Text.rich(
                const TextSpan(
                  children: [
                    TextSpan(text: 'Entreno SAMUR'),
                    TextSpan(
                      text: '·',
                      style: TextStyle(color: cNaranja),
                    ),
                    TextSpan(text: 'PC'),
                  ],
                ),
                style: GoogleFonts.unbounded(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'TESTS · JUEGOS · MEMORIA',
                style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 2,
                  color: AppColors.texto2,
                ),
              ),
              const SizedBox(height: 18),

              // ---------- ESTADÍSTICAS ----------
              Row(
                children: [
                  Expanded(
                    child: _Estadistica(
                      icono: LucideIcons.trophy,
                      valor: '${progreso.xp} XP',
                      etiqueta: progreso.rango.nombre,
                      color: cAmarillo,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _Estadistica(
                      icono: LucideIcons.flame,
                      valor:
                          '${progreso.rachaDias} ${progreso.rachaDias == 1 ? 'día' : 'días'}',
                      etiqueta: 'Racha',
                      color: cNaranja,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _Estadistica(
                      icono: LucideIcons.rotateCcw,
                      valor: '${progreso.fallos.length}',
                      etiqueta: 'Fallos pendientes',
                      color: cRojo,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ---------- RETO DEL DÍA ----------
              _TarjetaReto(
                hecho: progreso.retoHechoHoy,
                onTap: () => _empezarReto(context),
              ),
              const SizedBox(height: 26),

              // ---------- BANDEJAS DE JUEGOS ----------
              for (var b = 0; b < bandejas.length; b++) ...[
                Text(
                  bandejas[b].$1,
                  style: GoogleFonts.unbounded(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  bandejas[b].$2,
                  style: const TextStyle(fontSize: 13, color: AppColors.texto2),
                ),
                const SizedBox(height: 12),
                ..._filasDeJuegos(
                  context,
                  juegos.where((j) => j.bandeja == b).toList(),
                ),
                const SizedBox(height: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Coloca los juegos de dos en dos
  List<Widget> _filasDeJuegos(BuildContext context, List<Juego> lista) {
    return [
      for (var i = 0; i < lista.length; i += 2)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _TarjetaJuego(
                    juego: lista[i],
                    onTap: () => _abrir(context, lista[i]),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: i + 1 < lista.length
                      ? _TarjetaJuego(
                          juego: lista[i + 1],
                          onTap: () => _abrir(context, lista[i + 1]),
                        )
                      : const SizedBox(), // hueco si el número es impar
                ),
              ],
            ),
          ),
        ),
    ];
  }
}

// Cajita de estadística
class _Estadistica extends StatelessWidget {
  final IconData icono;
  final String valor;
  final String etiqueta;
  final Color color;

  const _Estadistica({
    required this.icono,
    required this.valor,
    required this.etiqueta,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.linea),
      ),
      child: Column(
        children: [
          Icon(icono, size: 18, color: color),
          const SizedBox(height: 6),
          Text(
            valor,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
          Text(
            etiqueta,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: AppColors.texto2),
          ),
        ],
      ),
    );
  }
}

// Tarjeta grande del reto del día
class _TarjetaReto extends StatelessWidget {
  final bool hecho;
  final VoidCallback onTap;

  const _TarjetaReto({required this.hecho, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cNaranja.withValues(alpha: 0.28), AppColors.panel],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cNaranja.withValues(alpha: 0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.flame, size: 16, color: cNaranja),
              const SizedBox(width: 6),
              const Text(
                'RETO DEL DÍA',
                style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w800,
                  color: cNaranja,
                ),
              ),
              const Spacer(),
              if (hecho)
                const Icon(LucideIcons.badgeCheck, size: 20, color: cVerde),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            hecho
                ? 'Reto de hoy completado'
                : '10 preguntas, una de cada bloque',
            style: GoogleFonts.unbounded(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hecho
                ? '¡Bien hecho! Mañana tendrás uno nuevo. Puedes repetirlo, pero ya sin bonus.'
                : 'Una pregunta de cada ámbito y una del examen oficial. +20 XP de bonus.',
            style: const TextStyle(
              fontSize: 13,
              height: 1.4,
              color: AppColors.texto2,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onTap,
              icon: Icon(
                hecho ? LucideIcons.rotateCcw : LucideIcons.arrowRight,
                size: 18,
              ),
              iconAlignment: IconAlignment.end,
              label: Text(hecho ? 'Repetir' : 'Empezar'),
              style: FilledButton.styleFrom(
                backgroundColor: cNaranja,
                foregroundColor: AppColors.fondo,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Tarjeta de un juego (atenuada si aún no está hecho)
class _TarjetaJuego extends StatelessWidget {
  final Juego juego;
  final VoidCallback onTap;

  const _TarjetaJuego({required this.juego, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final listo = juegosListos.contains(juego.id);
    final c = juego.color;

    return Opacity(
      opacity: listo ? 1 : 0.45,
      child: Material(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: listo ? onTap : null,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.linea),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: c.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(juego.icono, size: 18, color: c),
                    ),
                    const Spacer(),
                    if (!listo)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.linea,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: const Text(
                          'Pronto',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  juego.titulo,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  juego.descripcion,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.3,
                    color: AppColors.texto2,
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

// Una opción grande dentro del panel del examen
class _OpcionModo extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String descripcion;
  final Color color;
  final VoidCallback onTap;

  const _OpcionModo({
    required this.icono,
    required this.titulo,
    required this.descripcion,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.fondo,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.45)),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icono, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      descripcion,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.texto2,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(LucideIcons.chevronRight, color: color),
            ],
          ),
        ),
      ),
    );
  }
}
