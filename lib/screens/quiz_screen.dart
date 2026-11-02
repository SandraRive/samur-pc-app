import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../data/progreso.dart';
import '../data/tests.dart';
import '../theme/app_theme.dart';

const _verde = Color(0xFF2EE6A6);
const _rojo = Color(0xFFFF4D6A);
const _amarillo = Color(0xFFFFD23F);

// Los estados posibles de una opción
enum _Estado { normal, correcta, incorrecta, apagada }

// Una pregunta lista para jugar, con sus 4 opciones ya barajadas
class _Ronda {
  final Pregunta pregunta;
  final List<String> opciones;

  _Ronda(this.pregunta)
    : opciones = [pregunta.correcta, ...pregunta.distractores]..shuffle();

  int get indiceCorrecta => opciones.indexOf(pregunta.correcta);
}

// Elige n preguntas: primero las que aún no dominas (como tu web)
List<Pregunta> _elegir(List<Pregunta> todas, int n) {
  final barajadas = [...todas]..shuffle();
  return [
    ...barajadas.where((p) => !progreso.estaDominada(p.id)),
    ...barajadas.where((p) => progreso.estaDominada(p.id)),
  ].take(n).toList();
}

class QuizScreen extends StatefulWidget {
  final String titulo;
  final List<Pregunta> preguntas; // de dónde elegir
  final Color color;
  final int cuantas; // cuántas preguntas tiene la ronda

  const QuizScreen({
    super.key,
    required this.titulo,
    required this.preguntas,
    required this.color,
    this.cuantas = 10, // si no se dice nada, 10
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late final List<_Ronda> _rondas;
  int _i = 0; // pregunta actual
  int? _elegida; // opción elegida (null = aún sin responder)
  int _aciertos = 0;
  int _racha = 0;
  int _mejorRacha = 0;
  int _nuevasDominadas = 0;
  int _xpGanada = 0;
  final List<Pregunta> _falladas = [];

  bool get _terminado => _i >= _rondas.length;

  // initState se ejecuta UNA vez, al abrir la pantalla
  @override
  void initState() {
    super.initState();
    _rondas = _elegir(
      widget.preguntas,
      widget.cuantas,
    ).map(_Ronda.new).toList();
  }

  void _responder(int k) {
    if (_elegida != null) return; // ya respondida
    final ronda = _rondas[_i];
    final acierto = k == ronda.indiceCorrecta;

    setState(() {
      _elegida = k;
      if (acierto) {
        _aciertos++;
        _racha++;
        _mejorRacha = max(_mejorRacha, _racha);
        if (progreso.marcarDominada(ronda.pregunta.id)) _nuevasDominadas++;
      } else {
        _racha = 0;
        _falladas.add(ronda.pregunta);
      }
    });

    // 📳 Vibración: suave si aciertas, fuerte si fallas
    acierto ? HapticFeedback.lightImpact() : HapticFeedback.heavyImpact();
  }

  void _siguiente() {
    setState(() {
      _i++;
      _elegida = null;
      if (_terminado) {
        // +3 XP por acierto y +10 de bonus por pleno (reglas de tu web)
        _xpGanada = _aciertos * 3 + (_aciertos == _rondas.length ? 10 : 0);
      }
    });
    if (_terminado) progreso.sumarXP(_xpGanada);
  }

  _Estado _estadoOpcion(int k, _Ronda ronda) {
    if (_elegida == null) return _Estado.normal;
    if (k == ronda.indiceCorrecta) return _Estado.correcta;
    if (k == _elegida) return _Estado.incorrecta;
    return _Estado.apagada;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.fondo,
        foregroundColor: AppColors.texto,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.x),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.titulo,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: widget.color,
          ),
        ),
      ),
      body: _terminado ? _resultado() : _pregunta(),
    );
  }

  // ==================== PANTALLA DE PREGUNTA ====================
  Widget _pregunta() {
    final ronda = _rondas[_i];
    final c = widget.color;
    final respondida = _elegida != null;
    final acierto = _elegida == ronda.indiceCorrecta;
    final enRacha = _racha >= 3;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        // Progreso + racha
        Row(
          children: [
            Text(
              '${_i + 1}/${_rondas.length}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: (_i + (respondida ? 1 : 0)) / _rondas.length,
                  minHeight: 6,
                  backgroundColor: AppColors.linea,
                  color: c,
                ),
              ),
            ),
            const SizedBox(width: 12),
            _IndicadorRacha(racha: _racha),
          ],
        ),
        const SizedBox(height: 28),

        // Enunciado
        Text(
          ronda.pregunta.enunciado,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 24),

        // Opciones A, B, C, D
        for (var k = 0; k < ronda.opciones.length; k++)
          _Opcion(
            letra: 'ABCD'[k],
            texto: ronda.opciones[k],
            estado: _estadoOpcion(k, ronda),
            onTap: () => _responder(k),
          ),

        // Corrección + explicación + botón siguiente
        if (respondida) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                acierto ? LucideIcons.circleCheck : LucideIcons.circleX,
                size: 20,
                color: acierto ? _verde : _rojo,
              ),
              const SizedBox(width: 8),
              Text(
                acierto
                    ? (enRacha
                          ? '¡Correcto! Racha de $_racha 🔥'
                          : '¡Correcto!')
                    : 'Incorrecto',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: acierto ? _verde : _rojo,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _amarillo.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _amarillo.withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(LucideIcons.lightbulb, size: 18, color: _amarillo),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    ronda.pregunta.explicacion,
                    style: const TextStyle(height: 1.45),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _siguiente,
              icon: const Icon(LucideIcons.arrowRight, size: 18),
              iconAlignment: IconAlignment.end, // la flecha a la derecha
              label: Text(
                _i + 1 < _rondas.length ? 'Siguiente' : 'Ver resultado',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: c,
                foregroundColor: AppColors.fondo,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ==================== PANTALLA DE RESULTADO ====================
  Widget _resultado() {
    final total = _rondas.length;
    final pleno = _aciertos == total;
    final c = widget.color;
    final colorTrofeo = pleno ? _amarillo : c;
    final forma = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        Center(
          child: Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: colorTrofeo.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              pleno ? LucideIcons.trophy : LucideIcons.medal,
              size: 44,
              color: colorTrofeo,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            pleno ? '¡Pleno! 🎉' : '¡Ronda terminada!',
            style: GoogleFonts.unbounded(
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Center(
          child: Text(
            '$_aciertos/$total aciertos',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.texto2,
            ),
          ),
        ),
        const SizedBox(height: 22),

        // Tres datos: XP, mejor racha, nuevas dominadas
        Row(
          children: [
            Expanded(
              child: _Dato(
                icono: LucideIcons.star,
                valor: '+$_xpGanada',
                etiqueta: 'XP',
                color: AppColors.naranja,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _Dato(
                icono: LucideIcons.flame,
                valor: '$_mejorRacha',
                etiqueta: 'Mejor racha',
                color: AppColors.naranja,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _Dato(
                icono: LucideIcons.badgeCheck,
                valor: '$_nuevasDominadas',
                etiqueta: 'Dominadas nuevas',
                color: _verde,
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),

        // Lo que has fallado
        if (_falladas.isNotEmpty) ...[
          Text(
            'Para repasar',
            style: GoogleFonts.unbounded(
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          for (final p in _falladas)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.panel,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.linea),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.enunciado,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        LucideIcons.arrowRight,
                        size: 16,
                        color: _verde,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          p.correcta,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: _verde,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    p.explicacion,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: AppColors.texto2,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
        ],

        // Botones
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () {
              // Sustituye esta pantalla por una ronda nueva
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => QuizScreen(
                    titulo: widget.titulo,
                    preguntas: widget.preguntas,
                    color: c,
                    cuantas: widget.cuantas,
                  ),
                ),
              );
            },
            icon: const Icon(LucideIcons.rotateCcw, size: 18),
            label: const Text('Otra ronda'),
            style: FilledButton.styleFrom(
              backgroundColor: c,
              foregroundColor: AppColors.fondo,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: forma,
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.texto,
              side: const BorderSide(color: AppColors.linea),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: forma,
            ),
            child: const Text('Volver'),
          ),
        ),
      ],
    );
  }
}

// Una opción de respuesta (A, B, C, D)
class _Opcion extends StatelessWidget {
  final String letra;
  final String texto;
  final _Estado estado;
  final VoidCallback onTap;

  const _Opcion({
    required this.letra,
    required this.texto,
    required this.estado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Colores según el estado: fondo, borde y letra
    final (fondo, borde, colorLetra) = switch (estado) {
      _Estado.correcta => (_verde.withValues(alpha: 0.15), _verde, _verde),
      _Estado.incorrecta => (_rojo.withValues(alpha: 0.15), _rojo, _rojo),
      _ => (AppColors.panel, AppColors.linea, AppColors.texto2),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Opacity(
        opacity: estado == _Estado.apagada ? 0.45 : 1,
        child: Material(
          color: fondo,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: estado == _Estado.normal
                ? onTap
                : null, // tras responder, ya no se puede tocar
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
                    child: Text(
                      texto,
                      style: const TextStyle(fontSize: 15, height: 1.35),
                    ),
                  ),
                  if (estado == _Estado.correcta)
                    const Icon(
                      LucideIcons.circleCheck,
                      color: _verde,
                      size: 20,
                    ),
                  if (estado == _Estado.incorrecta)
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

// Cajita con un dato del resultado
class _Dato extends StatelessWidget {
  final IconData icono;
  final String valor;
  final String etiqueta;
  final Color color;

  const _Dato({
    required this.icono,
    required this.valor,
    required this.etiqueta,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
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
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          Text(
            etiqueta,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: AppColors.texto2),
          ),
        ],
      ),
    );
  }
}

// Indicador de racha: gris normalmente, pastilla naranja con 🔥 a partir de 3
class _IndicadorRacha extends StatelessWidget {
  final int racha;

  const _IndicadorRacha({required this.racha});

  @override
  Widget build(BuildContext context) {
    final enRacha = racha >= 3;

    return AnimatedScale(
      scale: enRacha ? 1.15 : 1, // un poco más grande cuando hay racha
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutBack, // efecto "rebote"
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: enRacha
              ? AppColors.naranja.withValues(alpha: 0.18)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: enRacha ? AppColors.naranja : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            enRacha
                ? const Text('🔥', style: TextStyle(fontSize: 14))
                : const Icon(
                    LucideIcons.flame,
                    size: 16,
                    color: AppColors.texto2,
                  ),
            const SizedBox(width: 4),
            Text(
              '$racha',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: enRacha ? AppColors.naranja : AppColors.texto2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
