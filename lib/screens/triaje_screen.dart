import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../data/entreno.dart';
import '../data/progreso.dart';
import '../theme/app_theme.dart';

// Una víctima: descripción, sus datos (etiqueta, valor, ¿alerta?), grupo correcto y explicación
class _Victima {
  final String descripcion;
  final List<(String, String, bool)> datos;
  final int grupo;
  final String explicacion;

  _Victima(List v)
    : descripcion = v[0] as String,
      datos = [
        for (final x in v[1] as List)
          (x[0] as String, x[1] as String, (x as List).length > 2 && x[2] == 1),
      ],
      grupo = v[2] as int,
      explicacion = v[3] as String;
}

// Uno de los tres triajes
class _FaseTriaje {
  final String nombre;
  final String donde;
  final String quien;
  final String objetivo;
  final List<(String, String, Color)> grupos; // (prioridad, descripción, color)
  final List<_Victima> victimas;

  _FaseTriaje(Map<String, dynamic> j)
    : nombre = j['n'] as String,
      donde = j['where'] as String,
      quien = j['who'] as String,
      objetivo = j['goal'] as String,
      grupos = [
        for (final b in j['b'] as List)
          (b[0] as String, b[1] as String, colorWeb(b[2] as String)),
      ],
      victimas = [for (final v in j['v'] as List) _Victima(v as List)];
}

class TriajeScreen extends StatefulWidget {
  final Color color;

  const TriajeScreen({super.key, required this.color});

  @override
  State<TriajeScreen> createState() => _TriajeScreenState();
}

class _TriajeScreenState extends State<TriajeScreen> {
  late final List<_FaseTriaje> _fases = [
    for (final t in datosEntreno['triaje'] as List)
      _FaseTriaje(t as Map<String, dynamic>),
  ];
  late final List<int> _porFase = (datosEntreno['triajeVictimas'] as List)
      .cast<int>();
  late final int _segundosPorVictima = datosEntreno['triajeSegundos'] as int;

  bool _eligiendo = true; // pantalla de elegir triaje
  List<int> _plan = []; // qué fases se juegan (las 3 o una)
  bool _completo = false;
  int _p = 0; // fase actual dentro del plan
  bool _enIntro = true; // mostrando la explicación de la fase
  List<_Victima> _vs = [];
  int _i = 0;
  int? _elegido;
  bool _agotado = false; // se acabó el tiempo de esta fase
  int _ok = 0;
  int _total = 0;
  bool _terminado = false;
  bool _record = false;
  final List<(int, _Victima, int)> _revisar =
      []; // (fase, víctima, elegido; -1 = sin triar)

  late DateTime _limite;
  int _msTotales = 1;
  Timer? _reloj;

  _FaseTriaje get _f => _fases[_plan[_p]];
  int get _quedanMs =>
      max(0, _limite.difference(DateTime.now()).inMilliseconds);

  @override
  void dispose() {
    _reloj?.cancel();
    super.dispose();
  }

  void _empezar(List<int> plan, bool completo) {
    setState(() {
      _plan = plan;
      _completo = completo;
      _p = 0;
      _ok = 0;
      _total = 0;
      _revisar.clear();
      _terminado = false;
      _record = false;
      _eligiendo = false;
      _enIntro = true;
    });
  }

  void _empezarFase() {
    _vs = (List.of(_f.victimas)..shuffle()).take(_porFase[_plan[_p]]).toList();
    _i = 0;
    _elegido = null;
    _agotado = false;
    // Un único reloj para toda la fase: 20 s × nº de víctimas
    _msTotales = _vs.length * _segundosPorVictima * 1000;
    _limite = DateTime.now().add(Duration(milliseconds: _msTotales));
    _reloj?.cancel();
    _reloj = Timer.periodic(const Duration(milliseconds: 200), (_) => _tic());
    setState(() => _enIntro = false);
  }

  void _tic() {
    if (_quedanMs > 0) {
      setState(() {}); // repinta la barra
      return;
    }
    // ⏱️ ¡Tiempo! Las víctimas que quedan cuentan como no triadas
    _reloj?.cancel();
    setState(() {
      _agotado = true;
      final desde = _i + (_elegido != null ? 1 : 0);
      for (var k = desde; k < _vs.length; k++) {
        _total++;
        _revisar.add((_plan[_p], _vs[k], -1));
      }
    });
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) _siguienteFase();
    });
  }

  // En el 1.er triaje hay dos cajones "No prioritario": cualquiera de los dos vale
  bool _esCorrecto(int j, _Victima v) =>
      j == v.grupo ||
      (_plan[_p] == 0 &&
          j > 0 &&
          v.grupo > 0 &&
          _f.grupos[j].$1 == _f.grupos[v.grupo].$1);

  void _clasificar(int j) {
    if (_elegido != null || _agotado) return;
    final v = _vs[_i];
    final bien = _esCorrecto(j, v);
    setState(() {
      _elegido = j;
      _total++;
      if (bien) {
        _ok++;
      } else {
        _revisar.add((_plan[_p], v, j));
      }
    });
    if (bien) {
      HapticFeedback.lightImpact();
      // Pasa sola, salvo que justo se haya acabado el tiempo
      Future.delayed(const Duration(milliseconds: 1300), () {
        if (mounted && !_agotado && _elegido == j) _siguienteVictima();
      });
    } else {
      HapticFeedback.heavyImpact();
    }
  }

  void _siguienteVictima() {
    if (_i + 1 >= _vs.length) {
      _reloj?.cancel();
      _siguienteFase();
      return;
    }
    setState(() {
      _i++;
      _elegido = null;
    });
  }

  void _siguienteFase() {
    if (_p + 1 >= _plan.length) {
      _terminar();
      return;
    }
    setState(() {
      _p++;
      _enIntro = true;
    });
  }

  void _terminar() {
    _reloj?.cancel();
    setState(() {
      _terminado = true;
      if (_completo) _record = progreso.guardarRecord('triaje', _ok);
    });
    progreso.sumarXP(_ok * 2);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.fondo,
        foregroundColor: AppColors.texto,
        scrolledUnderElevation: 0,
        title: Text(
          'Triaje STARS',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: widget.color,
          ),
        ),
      ),
      body: _eligiendo
          ? _elegirTriaje()
          : (_terminado
                ? _resultado()
                : (_enIntro ? _introFase() : _victima())),
    );
  }

  Widget _boton(
    String texto,
    IconData icono,
    VoidCallback onTap, {
    bool principal = true,
  }) {
    final forma = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );
    return SizedBox(
      width: double.infinity,
      child: principal
          ? FilledButton.icon(
              onPressed: onTap,
              icon: Icon(icono, size: 18),
              label: Text(texto),
              style: FilledButton.styleFrom(
                backgroundColor: widget.color,
                foregroundColor: AppColors.fondo,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: forma,
              ),
            )
          : OutlinedButton.icon(
              onPressed: onTap,
              icon: Icon(icono, size: 18),
              label: Text(texto),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.texto,
                side: const BorderSide(color: AppColors.linea),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: forma,
              ),
            ),
    );
  }

  Widget _tarjetaOpcion(String titulo, String subtitulo, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.linea),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        subtitulo,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.35,
                          color: AppColors.texto2,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(LucideIcons.chevronRight, color: AppColors.texto2),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==================== ELEGIR ====================
  Widget _elegirTriaje() {
    final total = _porFase.fold<int>(0, (a, b) => a + b);
    final record = progreso.record('triaje');
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
      children: [
        Text(
          'Un IMV, tres triajes',
          style: GoogleFonts.unbounded(
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'El sistema STARS hace tres triajes seguidos para detectar cuanto antes a los pacientes '
          'que más cuidados necesitan. Tienes $_segundosPorVictima segundos por víctima.',
          style: const TextStyle(height: 1.4, color: AppColors.texto2),
        ),
        const SizedBox(height: 18),
        _tarjetaOpcion(
          '▶ Simulacro completo',
          'Los tres triajes seguidos · $total víctimas${record > 0 ? ' · récord $record/$total' : ''}',
          () => _empezar([0, 1, 2], true),
        ),
        for (var k = 0; k < _fases.length; k++)
          _tarjetaOpcion(
            _fases[k].nombre,
            _fases[k].donde,
            () => _empezar([k], false),
          ),
        const SizedBox(height: 10),
        const Text(
          'El manual describe los grupos de cada triaje, pero no da cifras de corte. Los datos '
          'de cada víctima te ayudan a decidir; las explicaciones siguen el criterio del manual.',
          style: TextStyle(
            fontSize: 12.5,
            height: 1.4,
            color: AppColors.texto2,
          ),
        ),
      ],
    );
  }

  // ==================== INTRO DE CADA FASE ====================
  Widget _introFase() {
    final f = _f;
    Widget dato(IconData icono, String etiqueta, String texto) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 18, color: widget.color),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$etiqueta: ',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  TextSpan(text: texto),
                ],
              ),
              style: const TextStyle(height: 1.4),
            ),
          ),
        ],
      ),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
      children: [
        Text(
          'FASE ${_p + 1} DE ${_plan.length}',
          style: TextStyle(
            fontSize: 11,
            letterSpacing: 1.5,
            color: widget.color,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          f.nombre,
          style: GoogleFonts.unbounded(
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 16),
        dato(LucideIcons.mapPin, 'Dónde', f.donde),
        dato(LucideIcons.users, 'Quién', f.quien),
        dato(LucideIcons.route, 'Objetivo', f.objetivo),
        const SizedBox(height: 8),
        for (final (prioridad, desc, color) in f.grupos)
          _Grupo(prioridad: prioridad, descripcion: desc, color: color),
        const SizedBox(height: 16),
        _boton(
          'Empezar: ${_porFase[_plan[_p]]} víctimas',
          LucideIcons.play,
          _empezarFase,
        ),
      ],
    );
  }

  // ==================== VÍCTIMA ====================
  Widget _victima() {
    final v = _vs[_i];
    final fraccion = (_quedanMs / _msTotales).clamp(0.0, 1.0).toDouble();
    final poco = fraccion < 0.25;
    final respondida = _elegido != null;
    final bien = respondida && _esCorrecto(_elegido!, v);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
      children: [
        Row(
          children: [
            Icon(
              LucideIcons.clock,
              size: 16,
              color: poco ? cRojo : AppColors.texto2,
            ),
            Text(
              ' ${(_quedanMs / 1000).ceil()} s',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: poco ? cRojo : AppColors.texto,
              ),
            ),
            const Spacer(),
            const Icon(LucideIcons.check, size: 16, color: cVerde),
            Text(' $_ok', style: const TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: fraccion,
            minHeight: 6,
            backgroundColor: AppColors.linea,
            color: poco ? cRojo : widget.color,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '${_f.nombre} · víctima ${_i + 1} de ${_vs.length}',
          style: const TextStyle(fontSize: 12, color: AppColors.texto2),
        ),
        const SizedBox(height: 8),
        Text(
          v.descripcion,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 12),

        // Constantes: las alarmantes, en rojo
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (etiqueta, valor, alerta) in v.datos)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: alerta
                      ? cRojo.withValues(alpha: 0.12)
                      : AppColors.panel,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: alerta ? cRojo : AppColors.linea),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      etiqueta,
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: AppColors.texto2,
                      ),
                    ),
                    Text(
                      valor,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: alerta ? cRojo : AppColors.texto,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),

        // Los grupos del triaje
        for (var j = 0; j < _f.grupos.length; j++)
          _Grupo(
            prioridad: _f.grupos[j].$1,
            descripcion: _f.grupos[j].$2,
            color: _f.grupos[j].$3,
            estado: !respondida
                ? 0
                : (j == v.grupo ? 1 : (j == _elegido && !bien ? -1 : 2)),
            onTap: () => _clasificar(j),
          ),

        if (_agotado)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              '⏱️ ¡Tiempo! Las víctimas que quedaban cuentan como no triadas.',
              style: TextStyle(fontWeight: FontWeight.w800, color: cRojo),
            ),
          )
        else if (respondida) ...[
          const SizedBox(height: 6),
          Text(
            bien ? '✅ Bien' : '❌ Era «${_f.grupos[v.grupo].$2}»',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: bien ? cVerde : cRojo,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            v.explicacion,
            style: const TextStyle(height: 1.4, color: AppColors.texto2),
          ),
          if (!bien) ...[
            const SizedBox(height: 14),
            _boton('Siguiente', LucideIcons.arrowRight, _siguienteVictima),
          ],
        ],
      ],
    );
  }

  // ==================== RESULTADO ====================
  Widget _resultado() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        Icon(LucideIcons.trophy, size: 52, color: widget.color),
        const Center(
          child: Text(
            'Fin del simulacro',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        Center(
          child: Text(
            '$_ok/$_total',
            style: GoogleFonts.unbounded(
              fontSize: 44,
              fontWeight: FontWeight.w800,
              color: widget.color,
            ),
          ),
        ),
        Center(
          child: Text(
            'víctimas bien clasificadas · +${_ok * 2} XP',
            style: const TextStyle(color: AppColors.texto2),
          ),
        ),
        if (_record)
          const Center(
            child: Text(
              '🏆 ¡Nuevo récord!',
              style: TextStyle(fontWeight: FontWeight.w700, color: cAmarillo),
            ),
          ),
        const SizedBox(height: 22),
        _boton(
          'Otro simulacro',
          LucideIcons.rotateCcw,
          () => _empezar(_plan, _completo),
        ),
        const SizedBox(height: 10),
        _boton(
          'Elegir triaje',
          LucideIcons.tags,
          () => setState(() => _eligiendo = true),
          principal: false,
        ),
        if (_revisar.isNotEmpty) ...[
          const SizedBox(height: 26),
          Text(
            'Revisa estas víctimas',
            style: GoogleFonts.unbounded(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          for (final (fase, v, elegido) in _revisar)
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
                    _fases[fase].nombre,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.texto2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(v.descripcion, style: const TextStyle(height: 1.35)),
                  const SizedBox(height: 6),
                  Text(
                    '→ ${_fases[fase].grupos[v.grupo].$2}${elegido < 0 ? '  (sin triar a tiempo)' : ''}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: cVerde,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    v.explicacion,
                    style: const TextStyle(
                      fontSize: 12.5,
                      height: 1.35,
                      color: AppColors.texto2,
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

// Un grupo de triaje: barra de color + prioridad + descripción
// estado: 0 normal · 1 correcto · -1 equivocado · 2 apagado · null = solo informativo
class _Grupo extends StatelessWidget {
  final String prioridad;
  final String descripcion;
  final Color color;
  final int? estado;
  final VoidCallback? onTap;

  const _Grupo({
    required this.prioridad,
    required this.descripcion,
    required this.color,
    this.estado,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borde = switch (estado) {
      1 => cVerde,
      -1 => cRojo,
      _ => AppColors.linea,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Opacity(
        opacity: estado == 2 ? 0.4 : 1,
        child: Material(
          color: AppColors.panel,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: estado == 0 ? onTap : null,
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: borde,
                  width: estado == 1 || estado == -1 ? 2 : 1,
                ),
              ),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(width: 6, color: color), // la barra de color
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              prioridad,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: color,
                              ),
                            ),
                            Text(
                              descripcion,
                              style: const TextStyle(fontSize: 13, height: 1.3),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
