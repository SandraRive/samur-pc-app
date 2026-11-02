import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../data/entreno.dart';
import '../data/progreso.dart';
import '../theme/app_theme.dart';
import '../widgets/opcion_respuesta.dart';

// Una trampa: [tema, pregunta, [4 opciones], índice correcto, [porqué de cada opción]]
class _Trampa {
  final String tema;
  final String pregunta;
  final List<String> opciones;
  final int correcta;
  final List<String> porques;

  _Trampa(List x)
    : tema = x[0] as String,
      pregunta = x[1] as String,
      opciones = (x[2] as List).cast<String>(),
      correcta = x[3] as int,
      porques = (x[4] as List).cast<String>();
}

enum _Fase { intro, jugando, fin }

class TrampaScreen extends StatefulWidget {
  final Color color;

  const TrampaScreen({super.key, required this.color});

  @override
  State<TrampaScreen> createState() => _TrampaScreenState();
}

class _TrampaScreenState extends State<TrampaScreen> {
  late final List<_Trampa> _todas = [
    for (final x in datosEntreno['trampas'] as List) _Trampa(x as List),
  ];

  _Fase _fase = _Fase.intro;
  List<_Trampa> _items = [];
  int _i = 0;
  int _ok = 0;
  List<int> _orden = []; // en qué orden se muestran las 4 opciones
  int? _elegida; // posición tocada en pantalla
  final List<(_Trampa, int)> _caidas = []; // (trampa, opción que elegiste)
  bool _rondaDeDiez = true;
  bool _record = false;

  void _empezar(bool diez) {
    setState(() {
      _rondaDeDiez = diez;
      _items = (List.of(
        _todas,
      )..shuffle()).take(diez ? 10 : _todas.length).toList();
      _i = 0;
      _ok = 0;
      _caidas.clear();
      _record = false;
      _fase = _Fase.jugando;
      _prepararOrden();
    });
  }

  void _prepararOrden() {
    _orden = List.generate(_items[_i].opciones.length, (j) => j)..shuffle();
    _elegida = null;
  }

  void _responder(int k) {
    if (_elegida != null) return;
    final t = _items[_i];
    final acierto = _orden[k] == t.correcta;
    setState(() {
      _elegida = k;
      if (acierto) {
        _ok++;
      } else {
        _caidas.add((t, _orden[k]));
      }
    });
    acierto ? HapticFeedback.lightImpact() : HapticFeedback.heavyImpact();
  }

  void _siguiente() {
    if (_i + 1 >= _items.length) {
      setState(() {
        _fase = _Fase.fin;
        if (_rondaDeDiez) _record = progreso.guardarRecord('trampa', _ok);
      });
      progreso.sumarXP(_ok * 2);
      return;
    }
    setState(() {
      _i++;
      _prepararOrden();
    });
  }

  EstadoOpcion _estado(int k) {
    if (_elegida == null) return EstadoOpcion.normal;
    if (_orden[k] == _items[_i].correcta) return EstadoOpcion.correcta;
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
        title: Text(
          'Caza la trampa',
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

  Widget _botonPrincipal(String texto, IconData icono, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onTap,
        icon: Icon(icono, size: 18),
        label: Text(texto),
        style: FilledButton.styleFrom(
          backgroundColor: widget.color,
          foregroundColor: AppColors.fondo,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  // ==================== INTRO ====================
  Widget _intro() {
    final record = progreso.record('trampa');
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        Icon(LucideIcons.crosshair, size: 52, color: widget.color),
        const SizedBox(height: 14),
        Text(
          'Opciones que casi son iguales',
          textAlign: TextAlign.center,
          style: GoogleFonts.unbounded(
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Aquí las opciones cambian en una cifra o una palabra («mayor» o «menor», '
          '«siempre», «al menos»). Al responder verás por qué cada opción es verdadera o falsa, '
          'para que aprendas cómo se construyen los distractores.',
          textAlign: TextAlign.center,
          style: TextStyle(height: 1.45, color: AppColors.texto2),
        ),
        const SizedBox(height: 22),
        _botonPrincipal(
          '10 trampas al azar',
          LucideIcons.play,
          () => _empezar(true),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => _empezar(false),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.texto,
              side: const BorderSide(color: AppColors.linea),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text('Las ${_todas.length} seguidas'),
          ),
        ),
        if (record > 0) ...[
          const SizedBox(height: 14),
          Center(
            child: Text(
              'Tu mejor ronda de 10: $record/10 🏆',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ],
    );
  }

  // ==================== JUGANDO ====================
  Widget _jugando() {
    final t = _items[_i];
    final respondida = _elegida != null;
    final acierto = respondida && _orden[_elegida!] == t.correcta;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
      children: [
        Row(
          children: [
            Text(
              '${_i + 1}/${_items.length}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: (_i + (respondida ? 1 : 0)) / _items.length,
                  minHeight: 6,
                  backgroundColor: AppColors.linea,
                  color: widget.color,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Icon(LucideIcons.check, size: 16, color: cVerde),
            Text(' $_ok', style: const TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          t.tema.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            letterSpacing: 1.2,
            color: widget.color,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          t.pregunta,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 20),
        for (var k = 0; k < _orden.length; k++)
          OpcionRespuesta(
            letra: 'ABCD'[k],
            texto: t.opciones[_orden[k]],
            porque: t.porques[_orden[k]], // 👈 el porqué de cada opción
            estado: _estado(k),
            onTap: () => _responder(k),
          ),
        if (respondida) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                acierto ? LucideIcons.circleCheck : LucideIcons.circleX,
                color: acierto ? cVerde : cRojo,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                acierto ? '¡Trampa esquivada! 🎯' : 'Has caído en la trampa',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: acierto ? cVerde : cRojo,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _botonPrincipal(
            _i + 1 < _items.length ? 'Siguiente' : 'Ver resultado',
            LucideIcons.arrowRight,
            _siguiente,
          ),
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
        Center(
          child: Text(
            '$_ok/${_items.length}',
            style: GoogleFonts.unbounded(
              fontSize: 44,
              fontWeight: FontWeight.w800,
              color: widget.color,
            ),
          ),
        ),
        Center(
          child: Text(
            _record ? '🏆 ¡Nuevo récord! · +${_ok * 2} XP' : '+${_ok * 2} XP',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: _record ? cAmarillo : AppColors.texto,
            ),
          ),
        ),
        const SizedBox(height: 22),
        _botonPrincipal(
          'Otra ronda',
          LucideIcons.rotateCcw,
          () => _empezar(_rondaDeDiez),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Volver'),
          ),
        ),
        if (_caidas.isNotEmpty) ...[
          const SizedBox(height: 26),
          Text(
            'Las trampas en las que caíste',
            style: GoogleFonts.unbounded(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          for (final (t, elegida) in _caidas)
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
                    t.tema,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.texto2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    t.pregunta,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '✕ Elegiste: ${t.opciones[elegida]}',
                    style: const TextStyle(
                      color: cRojo,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    t.porques[elegida],
                    style: const TextStyle(
                      fontSize: 12.5,
                      height: 1.35,
                      color: AppColors.texto2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '✓ Correcta: ${t.opciones[t.correcta]}',
                    style: const TextStyle(
                      color: cVerde,
                      fontWeight: FontWeight.w800,
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
