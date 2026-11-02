import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../data/entreno.dart';
import '../data/progreso.dart';
import '../theme/app_theme.dart';
import '../widgets/carta_giratoria.dart';
import '../widgets/selector_mazo.dart';

// Una ficha del memory: la mitad de una pareja
class _Ficha {
  final Carta carta;
  final bool esTermino; // true = el término (10.1) · false = el significado
  final String texto;

  _Ficha(this.carta, this.esTermino, this.texto);
}

String _recortar(String s, int n) =>
    s.length <= n ? s : '${s.substring(0, n).trimRight()}…';

class ParejasScreen extends StatefulWidget {
  final Color color;

  const ParejasScreen({super.key, required this.color});

  @override
  State<ParejasScreen> createState() => _ParejasScreenState();
}

class _ParejasScreenState extends State<ParejasScreen> {
  Mazo? _mazo;
  List<Carta> _cartas = []; // las parejas de esta partida
  List<_Ficha> _fichas = []; // las 12 fichas del tablero
  final List<int> _abiertas = []; // fichas boca arriba ahora mismo (máx. 2)
  final Set<int> _encontradas = {};
  int _intentos = 0;
  bool _bloqueado = false; // mientras se dan la vuelta, no se puede tocar
  late DateTime _inicio;
  bool _terminado = false;
  bool _record = false;
  int _segundos = 0;
  int _xp = 0;

  void _empezar(Mazo m) {
    final n = min(6, m.cartas.length);
    final cartas = (List.of(m.cartas)..shuffle()).take(n).toList();
    setState(() {
      _mazo = m;
      _cartas = cartas;
      _fichas = [
        for (final c in cartas) ...[
          _Ficha(c, true, c.termino),
          _Ficha(c, false, _recortar(c.significado, 90)),
        ],
      ]..shuffle();
      _abiertas.clear();
      _encontradas.clear();
      _intentos = 0;
      _bloqueado = false;
      _terminado = false;
      _record = false;
      _inicio = DateTime.now();
    });
  }

  void _tocar(int i) {
    if (_bloqueado || _abiertas.contains(i) || _encontradas.contains(i)) return;
    setState(() => _abiertas.add(i));
    if (_abiertas.length < 2) return;

    // Dos fichas abiertas: ¿son pareja?
    _intentos++;
    final a = _fichas[_abiertas[0]];
    final b = _fichas[_abiertas[1]];
    final esPareja = a.carta == b.carta && a.esTermino != b.esTermino;

    if (esPareja) {
      HapticFeedback.lightImpact();
      setState(() {
        _encontradas.addAll(_abiertas);
        _abiertas.clear();
      });
      if (_encontradas.length == _fichas.length) {
        Future.delayed(const Duration(milliseconds: 600), _terminar);
      }
    } else {
      // No son pareja: se ven un momento y se vuelven a tapar
      _bloqueado = true;
      Future.delayed(const Duration(milliseconds: 900), () {
        if (!mounted) return;
        setState(() {
          _abiertas.clear();
          _bloqueado = false;
        });
      });
    }
  }

  void _terminar() {
    if (!mounted) return;
    final n = _cartas.length;
    final xp =
        10 +
        (_intentos <= n + 2 ? 5 : 0); // bonus si lo haces con pocos intentos
    setState(() {
      _terminado = true;
      _segundos = DateTime.now().difference(_inicio).inSeconds;
      _xp = xp;
      _record = progreso.guardarRecordMinimo('parejas.${_mazo!.id}', _intentos);
    });
    progreso.sumarXP(xp);
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
          m == null ? 'Parejas' : 'Parejas · ${m.titulo}',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: widget.color,
          ),
        ),
      ),
      body: m == null
          ? SelectorMazo(
              intro: 'Encuentra cada término y su significado. Gana quien lo haga en menos intentos.',
              filtro: (m) => m.cartas.length >= 3,
              detalle: (m) {
                final r = progreso.record('parejas.${m.id}');
                return '${m.cartas.length} elementos${r > 0 ? ' · mejor marca: $r intentos' : ''}';
              },
              alElegir: _empezar,
            )
          : (_terminado ? _resultado(m) : _tablero(m)),
    );
  }

  // ==================== TABLERO ====================
  Widget _tablero(Mazo m) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      children: [
        Row(
          children: [
            const Icon(
              LucideIcons.rotateCcw,
              size: 16,
              color: AppColors.texto2,
            ),
            const SizedBox(width: 6),
            Text(
              '$_intentos intentos',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            const Icon(LucideIcons.check, size: 16, color: cVerde),
            const SizedBox(width: 4),
            Text(
              '${_encontradas.length ~/ 2}/${_cartas.length}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 0.78,
          children: [
            for (var i = 0; i < _fichas.length; i++)
              GestureDetector(
                onTap: () => _tocar(i),
                child: CartaGiratoria(
                  girada: _abiertas.contains(i) || _encontradas.contains(i),
                  frente: _frente(m),
                  dorso: _dorso(m, _fichas[i], _encontradas.contains(i)),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _frente(Mazo m) {
    return Container(
      decoration: BoxDecoration(
        color: m.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: m.color.withValues(alpha: 0.4)),
      ),
      child: Center(child: Icon(m.icono, color: m.color, size: 28)),
    );
  }

  Widget _dorso(Mazo m, _Ficha f, bool encontrada) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: encontrada ? cVerde.withValues(alpha: 0.15) : AppColors.panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: encontrada ? cVerde : m.color, width: 1.5),
      ),
      child: Center(
        child: Text(
          f.texto,
          textAlign: TextAlign.center,
          maxLines: 7,
          overflow: TextOverflow.ellipsis,
          style: f.esTermino
              ? TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: m.color,
                )
              : const TextStyle(fontSize: 11.5, height: 1.25),
        ),
      ),
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
        const Center(
          child: Text(
            '¡Todas encontradas!',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        Center(
          child: Text(
            '$_intentos',
            style: GoogleFonts.unbounded(
              fontSize: 48,
              fontWeight: FontWeight.w800,
              color: m.color,
            ),
          ),
        ),
        Center(
          child: Text(
            'intentos en $_segundos s · +$_xp XP',
            style: const TextStyle(color: AppColors.texto2),
          ),
        ),
        if (_record)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Center(
              child: Text(
                '🏆 ¡Mejor marca en este mazo!',
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
            label: const Text('Otra partida'),
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
        const SizedBox(height: 26),
        Text(
          'Las parejas de esta partida',
          style: GoogleFonts.unbounded(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        for (final c in _cartas)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: c.termino,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: m.color,
                    ),
                  ),
                  TextSpan(text: ' — ${c.significado}'),
                ],
              ),
              style: const TextStyle(fontSize: 13.5, height: 1.4),
            ),
          ),
      ],
    );
  }
}
