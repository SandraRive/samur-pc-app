import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../data/entreno.dart';
import '../data/progreso.dart';
import '../data/retos.dart';
import '../data/tests.dart';
import '../theme/app_theme.dart';

enum _Fase { intro, jugando, fin }

class VerdaderoFalsoScreen extends StatefulWidget {
  final Color color;

  const VerdaderoFalsoScreen({super.key, required this.color});

  @override
  State<VerdaderoFalsoScreen> createState() => _VerdaderoFalsoScreenState();
}

class _VerdaderoFalsoScreenState extends State<VerdaderoFalsoScreen> {
  static const _duracion = 120; // 2 minutos

  final _azar = Random();
  _Fase _fase = _Fase.intro;
  int _aciertos = 0;
  int _fallos = 0;
  late DateTime _fin; // momento en el que se acaba el tiempo
  Timer? _reloj;
  late Pregunta _p;
  late String _mostrada; // la respuesta que enseñamos
  bool _esVerdad = true; // ¿la respuesta mostrada es la correcta?
  bool? _destello; // true = verde, false = rojo, null = nada
  bool _bloqueado = false;
  bool _record = false;
  final List<Pregunta> _dudas = [];

  // Segundos que quedan
  double get _quedan =>
      max(0, _fin.difference(DateTime.now()).inMilliseconds / 1000);

  @override
  void dispose() {
    _reloj?.cancel();
    super.dispose();
  }

  void _empezar() {
    _aciertos = 0;
    _fallos = 0;
    _dudas.clear();
    _record = false;
    _fin = DateTime.now().add(const Duration(seconds: _duracion));
    _nuevaFrase();
    setState(() => _fase = _Fase.jugando);

    _reloj?.cancel();
    _reloj = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (_quedan <= 0) {
        _terminar();
      } else {
        setState(() {}); // solo para repintar la barra de tiempo
      }
    });
  }

  // Elige una pregunta y decide si enseñamos la respuesta buena o una mala
  void _nuevaFrase() {
    final delExamen = examenes.isNotEmpty && _azar.nextDouble() >= 0.85;
    final lista = delExamen ? examenes.first.preguntas : todasLasPreguntas;
    _p = lista[_azar.nextInt(lista.length)];

    final falsas = _p.opcionesFijas != null
        ? _p.opcionesFijas!.where((o) => o != _p.correcta).toList()
        : List.of(_p.distractores);

    _esVerdad = falsas.isEmpty || _azar.nextBool();
    _mostrada = _esVerdad ? _p.correcta : falsas[_azar.nextInt(falsas.length)];
    _destello = null;
    _bloqueado = false;
  }

  void _responder(bool diceVerdadero) {
    if (_bloqueado) return;
    final bien = diceVerdadero == _esVerdad;

    setState(() {
      _bloqueado = true;
      _destello = bien;
      if (bien) {
        _aciertos++;
      } else {
        _fallos++;
        _fin = _fin.subtract(const Duration(seconds: 1)); // ¡castigo!
        _dudas.add(_p);
      }
    });
    bien ? HapticFeedback.lightImpact() : HapticFeedback.heavyImpact();

    // Espera un momento (para ver el destello) y pasa a la siguiente
    Future.delayed(Duration(milliseconds: bien ? 250 : 600), () {
      if (!mounted || _fase != _Fase.jugando) return;
      setState(_nuevaFrase);
    });
  }

  void _terminar() {
    _reloj?.cancel();
    setState(() {
      _fase = _Fase.fin;
      _record = progreso.guardarRecord('verdadero-falso', _aciertos);
    });
    progreso.sumarXP(_aciertos);
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
          'Verdadero o falso',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: widget.color,
          ),
        ),
      ),
      body: switch (_fase) {
        _Fase.intro => _intro(),
        _Fase.jugando => _jugando(),
        _Fase.fin => _resultado(),
      },
    );
  }

  Widget _botonGrande(
    String texto,
    IconData icono,
    VoidCallback onTap, {
    Color? color,
  }) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onTap,
        icon: Icon(icono, size: 18),
        label: Text(texto),
        style: FilledButton.styleFrom(
          backgroundColor: color ?? widget.color,
          foregroundColor: AppColors.fondo,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  // ==================== INTRO ====================
  Widget _intro() {
    final record = progreso.record('verdadero-falso');
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 20),
        Icon(LucideIcons.timer, size: 56, color: widget.color),
        const SizedBox(height: 16),
        Center(
          child: Text(
            '2 minutos',
            style: GoogleFonts.unbounded(
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Verás una pregunta y una respuesta. Di si esa respuesta es la correcta. '
          'Cada acierto suma 1 punto, cada fallo resta 1 segundo.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, height: 1.45, color: AppColors.texto2),
        ),
        const SizedBox(height: 28),
        _botonGrande('Empezar', LucideIcons.play, _empezar),
        if (record > 0) ...[
          const SizedBox(height: 14),
          Center(
            child: Text(
              'Tu récord: $record 🏆',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ],
    );
  }

  // ==================== JUGANDO ====================
  Widget _jugando() {
    final fraccion = (_quedan / _duracion).clamp(0.0, 1.0).toDouble();
    final pocoTiempo = _quedan < 15;
    final colorDestello = _destello == null
        ? null
        : (_destello! ? cVerde : cRojo);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        Row(
          children: [
            Icon(
              LucideIcons.clock,
              size: 16,
              color: pocoTiempo ? cRojo : AppColors.texto2,
            ),
            const SizedBox(width: 4),
            Text(
              '${_quedan.ceil()} s',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: pocoTiempo ? cRojo : AppColors.texto,
              ),
            ),
            const Spacer(),
            const Icon(LucideIcons.check, size: 16, color: cVerde),
            const SizedBox(width: 4),
            Text(
              '$_aciertos',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: fraccion,
            minHeight: 6,
            backgroundColor: AppColors.linea,
            color: pocoTiempo ? cRojo : widget.color,
          ),
        ),
        const SizedBox(height: 24),

        // La tarjeta, que se ilumina en verde o rojo al responder
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: colorDestello?.withValues(alpha: 0.15) ?? AppColors.panel,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorDestello ?? AppColors.linea,
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _p.enunciado,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'RESPUESTA PROPUESTA',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 1.5,
                  color: AppColors.texto2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _mostrada,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  height: 1.35,
                  color: widget.color,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _botonGrande(
                'Verdadero',
                LucideIcons.check,
                () => _responder(true),
                color: cVerde,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _botonGrande(
                'Falso',
                LucideIcons.x,
                () => _responder(false),
                color: cRojo,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ==================== RESULTADO ====================
  Widget _resultado() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        const Center(child: Text('⏱️', style: TextStyle(fontSize: 52))),
        Center(
          child: Text(
            '$_aciertos',
            style: GoogleFonts.unbounded(
              fontSize: 48,
              fontWeight: FontWeight.w800,
              color: widget.color,
            ),
          ),
        ),
        Center(
          child: Text(
            'aciertos · $_fallos fallos · +$_aciertos XP',
            style: const TextStyle(color: AppColors.texto2),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            _record
                ? '🏆 ¡Nuevo récord!'
                : 'Récord: ${progreso.record('verdadero-falso')}',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: _record ? cAmarillo : AppColors.texto,
            ),
          ),
        ),
        const SizedBox(height: 24),
        _botonGrande('Otra vez', LucideIcons.rotateCcw, _empezar),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.texto,
              side: const BorderSide(color: AppColors.linea),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Volver'),
          ),
        ),
        if (_dudas.isNotEmpty) ...[
          const SizedBox(height: 28),
          Text(
            'Preguntas en las que dudaste',
            style: GoogleFonts.unbounded(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          for (final p in _dudas.take(12))
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
                  const SizedBox(height: 6),
                  Text(
                    '→ ${p.correcta}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: cVerde,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }
}
