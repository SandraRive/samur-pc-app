import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../data/entreno.dart';
import '../data/progreso.dart';
import '../theme/app_theme.dart';

class EscribeScreen extends StatefulWidget {
  final Color color;

  const EscribeScreen({super.key, required this.color});

  @override
  State<EscribeScreen> createState() => _EscribeScreenState();
}

class _EscribeScreenState extends State<EscribeScreen> {
  static const _porRonda = 10;

  Mazo? _mazo; // null = eligiendo mazo
  List<Carta> _cartas = [];
  int _i = 0;
  int _ok = 0;
  bool? _acierto; // null = aún sin comprobar
  bool _terminado = false;
  bool _record = false;
  final List<Carta> _falladas = [];
  final _texto = TextEditingController();

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  void _empezar(Mazo m) {
    setState(() {
      _mazo = m;
      _cartas = (List.of(m.cartas)..shuffle()).take(_porRonda).toList();
      _i = 0;
      _ok = 0;
      _acierto = null;
      _terminado = false;
      _record = false;
      _falladas.clear();
      _texto.clear();
    });
  }

  // ¿Lo escrito coincide con la clave? (también vale si la clave tiene
  // varias formas separadas por comas o barras, como "SVA/USVA")
  bool _esCorrecta(String escrito, Carta c) {
    final r = normalizarClave(escrito);
    if (r.isEmpty) return false;
    final formas = [c.termino, ...c.termino.split(RegExp(r'[,/]'))];
    return formas.any((k) {
      final n = normalizarClave(k);
      return n.isNotEmpty && n == r;
    });
  }

  void _comprobar() {
    if (_acierto != null || _texto.text.trim().isEmpty) return;
    final c = _cartas[_i];
    final bien = _esCorrecta(_texto.text, c);
    setState(() {
      _acierto = bien;
      if (bien) {
        _ok++;
        progreso.marcarDominada(c.id);
      } else {
        _falladas.add(c);
      }
    });
    bien ? HapticFeedback.lightImpact() : HapticFeedback.heavyImpact();
  }

  void _siguiente() {
    if (_i + 1 >= _cartas.length) {
      setState(() {
        _terminado = true;
        _record = progreso.guardarRecord('escribe.${_mazo!.id}', _ok);
      });
      progreso.sumarXP(_ok * 3);
      return;
    }
    setState(() {
      _i++;
      _acierto = null;
      _texto.clear();
    });
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
          _mazo == null ? 'Escribe la clave' : 'Escribe · ${_mazo!.titulo}',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: widget.color,
          ),
        ),
      ),
      body: _mazo == null
          ? _elegirMazo()
          : (_terminado ? _resultado() : _jugar()),
    );
  }

  // ==================== ELEGIR MAZO ====================
  Widget _elegirMazo() {
    final escribibles = mazos.where((m) => m.escribible).toList();
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Elige un mazo',
          style: GoogleFonts.unbounded(
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Lee el significado y escribe la clave, el código o la sigla. '
          'No importan las mayúsculas ni las tildes.',
          style: TextStyle(height: 1.4, color: AppColors.texto2),
        ),
        const SizedBox(height: 20),
        for (final m in escribibles)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: AppColors.panel,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => _empezar(m),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.linea),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: m.color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(m.icono, size: 20, color: m.color),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              m.titulo,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              '${m.cartas.length} cartas · récord ${progreso.record('escribe.${m.id}')}/$_porRonda',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.texto2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        LucideIcons.chevronRight,
                        color: AppColors.texto2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ==================== JUGANDO ====================
  Widget _jugar() {
    final m = _mazo!;
    final c = _cartas[_i];
    final comprobada = _acierto != null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        Row(
          children: [
            Text(
              '${_i + 1}/${_cartas.length}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: (_i + (comprobada ? 1 : 0)) / _cartas.length,
                  minHeight: 6,
                  backgroundColor: AppColors.linea,
                  color: m.color,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Icon(LucideIcons.check, size: 16, color: cVerde),
            const SizedBox(width: 4),
            Text('$_ok', style: const TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
        const SizedBox(height: 26),
        Text(
          '${m.tipo.toUpperCase()} · ${m.titulo}',
          style: TextStyle(fontSize: 11, letterSpacing: 1.2, color: m.color),
        ),
        const SizedBox(height: 8),
        Text(
          c.significado,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 22),

        // Campo para escribir
        TextField(
          controller: _texto,
          autofocus: true,
          enabled: !comprobada,
          textCapitalization: TextCapitalization.characters,
          autocorrect: false,
          onSubmitted: (_) => _comprobar(), // Enter = comprobar
          style: GoogleFonts.jetBrainsMono(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
          decoration: InputDecoration(
            hintText: 'Escribe aquí',
            hintStyle: const TextStyle(color: AppColors.texto2),
            filled: true,
            fillColor: AppColors.panel,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.linea),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: m.color, width: 1.5),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: (_acierto ?? false) ? cVerde : cRojo,
                width: 1.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),

        if (!comprobada)
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _comprobar,
              icon: const Icon(LucideIcons.check, size: 18),
              label: const Text('Comprobar'),
              style: FilledButton.styleFrom(
                backgroundColor: m.color,
                foregroundColor: AppColors.fondo,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          )
        else ...[
          Row(
            children: [
              Icon(
                _acierto! ? LucideIcons.circleCheck : LucideIcons.circleX,
                size: 20,
                color: _acierto! ? cVerde : cRojo,
              ),
              const SizedBox(width: 8),
              Text(
                _acierto! ? '¡Exacto!' : 'No es esa',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _acierto! ? cVerde : cRojo,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cAmarillo.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cAmarillo.withValues(alpha: 0.3)),
            ),
            child: Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: '💡 La respuesta es '),
                  TextSpan(
                    text: c.termino,
                    style: GoogleFonts.jetBrainsMono(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _siguiente,
              icon: const Icon(LucideIcons.arrowRight, size: 18),
              iconAlignment: IconAlignment.end,
              label: Text(
                _i + 1 < _cartas.length ? 'Siguiente' : 'Ver resultado',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: m.color,
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
    final m = _mazo!;
    final forma = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        Icon(LucideIcons.trophy, size: 52, color: m.color),
        const SizedBox(height: 8),
        Center(
          child: Text(
            '$_ok/${_cartas.length}',
            style: GoogleFonts.unbounded(
              fontSize: 44,
              fontWeight: FontWeight.w800,
              color: m.color,
            ),
          ),
        ),
        Center(
          child: Text(
            _record ? '🏆 ¡Nuevo récord! · +${_ok * 3} XP' : '+${_ok * 3} XP',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: _record ? cAmarillo : AppColors.texto,
            ),
          ),
        ),
        const SizedBox(height: 22),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => _empezar(m),
            icon: const Icon(LucideIcons.rotateCcw, size: 18),
            label: const Text('Otra ronda'),
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
            onPressed: () =>
                setState(() => _mazo = null), // vuelve a la lista de mazos
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
        if (_falladas.isNotEmpty) ...[
          const SizedBox(height: 28),
          Text(
            'Para repasar',
            style: GoogleFonts.unbounded(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          for (final c in _falladas)
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
                  Text(c.significado, style: const TextStyle(height: 1.35)),
                  const SizedBox(height: 6),
                  Text(
                    '→ ${c.termino}',
                    style: GoogleFonts.jetBrainsMono(
                      fontWeight: FontWeight.w800,
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
