import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../data/entreno.dart';
import '../data/progreso.dart';
import '../data/tests.dart';
import '../theme/app_theme.dart';
import '../widgets/opcion_respuesta.dart';

class SupervivenciaScreen extends StatefulWidget {
  final Color color;

  const SupervivenciaScreen({super.key, required this.color});

  @override
  State<SupervivenciaScreen> createState() => _SupervivenciaScreenState();
}

class _SupervivenciaScreenState extends State<SupervivenciaScreen> {
  static const _vidasIniciales = 3;

  int _vidas = _vidasIniciales;
  int _aciertos = 0;
  late Pregunta _pregunta;
  late List<String> _opciones;
  int? _elegida; // null = sin responder · -1 = se acabó el tiempo
  int _segundosTotales = 40;
  double _restante = 40; // segundos que quedan
  Timer? _reloj;
  bool _terminado = false;
  bool _record = false;
  final List<Pregunta> _falladas = [];

  int get _correcta => _opciones.indexOf(_pregunta.correcta);

  @override
  void initState() {
    super.initState();
    _nuevaPregunta();
  }

  // ⚠️ Muy importante: parar el reloj al salir de la pantalla
  @override
  void dispose() {
    _reloj?.cancel();
    super.dispose();
  }

  void _nuevaPregunta() {
    _pregunta = preguntaMezcla();
    _opciones = _pregunta.opcionesFijas != null
        ? List.of(_pregunta.opcionesFijas!)
        : ([_pregunta.correcta, ..._pregunta.distractores]..shuffle());

    // Tiempo según lo larga que sea la pregunta: entre 40 y 75 s (como tu web)
    final largo = _pregunta.enunciado.length + _opciones.join().length;
    _segundosTotales = (25 + largo / 8).round().clamp(40, 75).toInt();
    _restante = _segundosTotales.toDouble();
    _elegida = null;

    // El reloj: cada 0,1 s resta 0,1 s
    _reloj?.cancel();
    _reloj = Timer.periodic(const Duration(milliseconds: 100), (_) {
      setState(() => _restante -= 0.1);
      if (_restante <= 0) _responder(-1); // se acabó el tiempo = fallo
    });
  }

  void _responder(int k) {
    if (_elegida != null) return;
    _reloj?.cancel();
    final acierto = k == _correcta;

    setState(() {
      _elegida = k;
      if (acierto) {
        _aciertos++;
        if (_pregunta.id.isNotEmpty) progreso.marcarDominada(_pregunta.id);
        progreso.quitarFallo(_pregunta.id);
      } else {
        _vidas--;
        _falladas.add(_pregunta);
        progreso.registrarFallo(_pregunta);
      }
    });

    acierto ? HapticFeedback.lightImpact() : HapticFeedback.heavyImpact();
  }

  void _siguiente() {
    if (_vidas <= 0) {
      setState(() {
        _terminado = true;
        _record = progreso.guardarRecord('supervivencia', _aciertos);
      });
      progreso.sumarXP(_aciertos * 3);
      return;
    }
    setState(_nuevaPregunta);
  }

  void _reiniciar() {
    setState(() {
      _vidas = _vidasIniciales;
      _aciertos = 0;
      _falladas.clear();
      _terminado = false;
      _record = false;
      _nuevaPregunta();
    });
  }

  EstadoOpcion _estado(int k) {
    if (_elegida == null) return EstadoOpcion.normal;
    if (k == _correcta) return EstadoOpcion.correcta;
    if (k == _elegida) return EstadoOpcion.incorrecta;
    return EstadoOpcion.apagada;
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
          'Supervivencia',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: widget.color,
          ),
        ),
      ),
      body: _terminado ? _resultado() : _juego(),
    );
  }

  // ==================== JUGANDO ====================
  Widget _juego() {
    final c = widget.color;
    final respondida = _elegida != null;
    final acierto = _elegida == _correcta;
    final fraccion = (_restante / _segundosTotales).clamp(0.0, 1.0).toDouble();
    final pocoTiempo = fraccion < 0.25;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        // Vidas, aciertos y tiempo
        Row(
          children: [
            for (var v = 0; v < _vidasIniciales; v++)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(
                  v < _vidas ? '❤️' : '🖤',
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            const Spacer(),
            const Icon(LucideIcons.check, size: 16, color: cVerde),
            const SizedBox(width: 4),
            Text(
              '$_aciertos',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(width: 14),
            Icon(
              LucideIcons.timer,
              size: 16,
              color: pocoTiempo ? cRojo : AppColors.texto2,
            ),
            const SizedBox(width: 4),
            Text(
              '${_restante.ceil().clamp(0, 999)} s',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: pocoTiempo ? cRojo : AppColors.texto,
              ),
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
            color: pocoTiempo ? cRojo : c,
          ),
        ),
        const SizedBox(height: 26),

        Text(
          _pregunta.enunciado,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 24),

        for (var k = 0; k < _opciones.length; k++)
          OpcionRespuesta(
            letra: 'ABCD'[k],
            texto: _opciones[k],
            estado: _estado(k),
            onTap: () => _responder(k),
          ),

        if (respondida) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                acierto ? LucideIcons.circleCheck : LucideIcons.circleX,
                size: 20,
                color: acierto ? cVerde : cRojo,
              ),
              const SizedBox(width: 8),
              Text(
                _elegida == -1
                    ? 'Se acabó el tiempo'
                    : (acierto ? '¡Correcto!' : 'Incorrecto'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: acierto ? cVerde : cRojo,
                ),
              ),
            ],
          ),
          if (!acierto)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                _vidas > 0
                    ? 'Te ${_vidas == 1 ? 'queda 1 vida' : 'quedan $_vidas vidas'}'
                    : '💀 Te has quedado sin vidas',
                style: const TextStyle(color: AppColors.texto2),
              ),
            ),
          if (_pregunta.explicacion.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cAmarillo.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cAmarillo.withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(LucideIcons.lightbulb, size: 18, color: cAmarillo),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _pregunta.explicacion,
                      style: const TextStyle(height: 1.45),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _siguiente,
              icon: const Icon(LucideIcons.arrowRight, size: 18),
              iconAlignment: IconAlignment.end,
              label: Text(_vidas > 0 ? 'Siguiente' : 'Ver resultado'),
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

  // ==================== RESULTADO ====================
  Widget _resultado() {
    final c = widget.color;
    final forma = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        const Center(child: Text('💀', style: TextStyle(fontSize: 56))),
        const SizedBox(height: 8),
        Center(
          child: Text(
            '$_aciertos',
            style: GoogleFonts.unbounded(
              fontSize: 48,
              fontWeight: FontWeight.w800,
              color: c,
            ),
          ),
        ),
        const Center(
          child: Text(
            'aciertos antes de quedarte sin vidas',
            style: TextStyle(color: AppColors.texto2),
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: Text(
            _record
                ? '🏆 ¡Nuevo récord! · +${_aciertos * 3} XP'
                : 'Récord: ${progreso.record('supervivencia')} · +${_aciertos * 3} XP',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: _record ? cAmarillo : AppColors.texto,
            ),
          ),
        ),
        const SizedBox(height: 24),
        if (_falladas.isNotEmpty) ...[
          Text(
            'Las que te quitaron vidas',
            style: GoogleFonts.unbounded(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          for (final p in _falladas) _TarjetaRepaso(pregunta: p),
          const SizedBox(height: 12),
        ],
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _reiniciar,
            icon: const Icon(LucideIcons.rotateCcw, size: 18),
            label: const Text('Otra partida'),
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

// Pregunta fallada: enunciado → respuesta correcta
class _TarjetaRepaso extends StatelessWidget {
  final Pregunta pregunta;

  const _TarjetaRepaso({required this.pregunta});

  @override
  Widget build(BuildContext context) {
    return Container(
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
            pregunta.enunciado,
            style: const TextStyle(fontWeight: FontWeight.w600, height: 1.35),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(LucideIcons.arrowRight, size: 16, color: cVerde),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  pregunta.correcta,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: cVerde,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
