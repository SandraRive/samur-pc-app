import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../data/entreno.dart';
import '../data/progreso.dart';
import '../theme/app_theme.dart';
import '../widgets/selector_mazo.dart';

String _recortar(String s, int n) =>
    s.length <= n ? s : '${s.substring(0, n).trimRight()}…';

class UnirScreen extends StatefulWidget {
  final Color color;

  const UnirScreen({super.key, required this.color});

  @override
  State<UnirScreen> createState() => _UnirScreenState();
}

class _UnirScreenState extends State<UnirScreen> {
  static const _rondas = 3;

  Mazo? _mazo;
  int _ronda = 0;
  int _ok = 0;
  int _ko = 0;
  List<Carta> _izquierda = []; // términos
  List<Carta> _derecha = []; // significados (en otro orden)
  String? _seleccion; // id del término elegido a la izquierda
  final Set<String> _hechas = {};
  String? _malId; // significado que acabas de fallar (se pone rojo)
  bool _terminado = false;
  bool _record = false;

  void _empezar(Mazo m) {
    setState(() {
      _mazo = m;
      _ronda = 0;
      _ok = 0;
      _ko = 0;
      _terminado = false;
      _record = false;
      _prepararRonda();
    });
  }

  void _prepararRonda() {
    final porRonda = min(5, _mazo!.cartas.length);
    final cartas = (List.of(_mazo!.cartas)..shuffle()).take(porRonda).toList();
    _izquierda = List.of(cartas)..shuffle();
    _derecha = List.of(cartas)..shuffle();
    _seleccion = null;
    _malId = null;
    _hechas.clear();
  }

  void _tocarIzquierda(Carta c) {
    if (_hechas.contains(c.id)) return;
    setState(() => _seleccion = c.id);
  }

  void _tocarDerecha(Carta c) {
    if (_seleccion == null || _hechas.contains(c.id)) return;

    if (c.id == _seleccion) {
      // ¡Pareja correcta!
      HapticFeedback.lightImpact();
      setState(() {
        _ok++;
        _hechas.add(c.id);
        _seleccion = null;
      });
      if (_hechas.length == _izquierda.length) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!mounted) return;
          if (_ronda < _rondas - 1) {
            setState(() {
              _ronda++;
              _prepararRonda();
            });
          } else {
            _terminar();
          }
        });
      }
    } else {
      // Fallo: parpadea en rojo
      HapticFeedback.heavyImpact();
      setState(() {
        _ko++;
        _malId = c.id;
      });
      Future.delayed(const Duration(milliseconds: 450), () {
        if (mounted) setState(() => _malId = null);
      });
    }
  }

  void _terminar() {
    setState(() {
      _terminado = true;
      _record = progreso.guardarRecord('unir.${_mazo!.id}', _ok - _ko);
    });
    progreso.sumarXP(_ok);
  }

  @override
  Widget build(BuildContext context) {
    final m = _mazo;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.fondo,
        foregroundColor: AppColors.texto,
        scrolledUnderElevation: 0,
        title: Text(
          m == null ? 'Une columnas' : 'Une columnas · ${m.titulo}',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: widget.color,
          ),
        ),
      ),
      body: m == null
          ? SelectorMazo(
              intro: 'Toca un término y después su definición. Tres rondas de cinco.',
              filtro: (m) => m.cartas.length >= 4,
              detalle: (m) => '${m.cartas.length} elementos',
              alElegir: _empezar,
            )
          : (_terminado ? _resultado(m) : _juego(m)),
    );
  }

  // ==================== JUGANDO ====================
  Widget _juego(Mazo m) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      children: [
        Row(
          children: [
            Text(
              'Ronda ${_ronda + 1}/$_rondas',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            const Icon(LucideIcons.check, size: 16, color: cVerde),
            Text(' $_ok', style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(width: 12),
            const Icon(LucideIcons.x, size: 16, color: cRojo),
            Text(' $_ko', style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Toca un término de la izquierda y luego su definición.',
          style: TextStyle(fontSize: 12.5, color: AppColors.texto2),
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Columna izquierda: términos
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  for (final c in _izquierda)
                    _Pieza(
                      texto: c.termino,
                      esTermino: true,
                      color: m.color,
                      hecha: _hechas.contains(c.id),
                      seleccionada: _seleccion == c.id,
                      mal: false,
                      onTap: () => _tocarIzquierda(c),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Columna derecha: significados
            Expanded(
              flex: 3,
              child: Column(
                children: [
                  for (final c in _derecha)
                    _Pieza(
                      texto: _recortar(c.significado, 110),
                      esTermino: false,
                      color: m.color,
                      hecha: _hechas.contains(c.id),
                      seleccionada: false,
                      mal: _malId == c.id,
                      onTap: () => _tocarDerecha(c),
                    ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ==================== RESULTADO ====================
  Widget _resultado(Mazo m) {
    final forma = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        Icon(LucideIcons.trophy, size: 52, color: m.color),
        const SizedBox(height: 6),
        Center(
          child: Text(
            '$_ok/${_ok + _ko}',
            style: GoogleFonts.unbounded(
              fontSize: 44,
              fontWeight: FontWeight.w800,
              color: m.color,
            ),
          ),
        ),
        Center(
          child: Text(
            'emparejamientos acertados · $_ko fallos · +$_ok XP',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.texto2),
          ),
        ),
        if (_record)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Center(
              child: Text(
                '🏆 ¡Nuevo récord en este mazo!',
                style: TextStyle(fontWeight: FontWeight.w700, color: cAmarillo),
              ),
            ),
          ),
        const SizedBox(height: 22),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => _empezar(m),
            icon: const Icon(LucideIcons.rotateCcw, size: 18),
            label: const Text('Otra vez'),
            style: FilledButton.styleFrom(
              backgroundColor: m.color,
              foregroundColor: AppColors.fondo,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: forma,
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => setState(() => _mazo = null),
            icon: const Icon(LucideIcons.layers, size: 18),
            label: const Text('Otro mazo'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.texto,
              side: const BorderSide(color: AppColors.linea),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: forma,
            ),
          ),
        ),
      ],
    );
  }
}

// Una pieza de una de las dos columnas
class _Pieza extends StatelessWidget {
  final String texto;
  final bool esTermino;
  final Color color;
  final bool hecha;
  final bool seleccionada;
  final bool mal;
  final VoidCallback onTap;

  const _Pieza({
    required this.texto,
    required this.esTermino,
    required this.color,
    required this.hecha,
    required this.seleccionada,
    required this.mal,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final (fondo, borde) = hecha
        ? (cVerde.withValues(alpha: 0.12), cVerde)
        : mal
        ? (cRojo.withValues(alpha: 0.18), cRojo)
        : seleccionada
        ? (color.withValues(alpha: 0.2), color)
        : (AppColors.panel, AppColors.linea);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Opacity(
        opacity: hecha ? 0.55 : 1,
        child: GestureDetector(
          onTap: hecha ? null : onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 58),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: fondo,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: borde,
                width: seleccionada || mal ? 2 : 1,
              ),
            ),
            alignment: esTermino ? Alignment.center : Alignment.centerLeft,
            child: Text(
              texto,
              textAlign: esTermino ? TextAlign.center : TextAlign.left,
              style: esTermino
                  ? TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: hecha ? cVerde : color,
                    )
                  : const TextStyle(fontSize: 12, height: 1.3),
            ),
          ),
        ),
      ),
    );
  }
}
