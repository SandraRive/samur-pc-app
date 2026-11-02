import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../data/entreno.dart';
import '../data/progreso.dart';
import '../theme/app_theme.dart';

class ClasificaScreen extends StatefulWidget {
  final Color color;

  const ClasificaScreen({super.key, required this.color});

  @override
  State<ClasificaScreen> createState() => _ClasificaScreenState();
}

class _ClasificaScreenState extends State<ClasificaScreen> {
  // Los 10 juegos del entreno.json
  late final List<Map<String, dynamic>> _juegos =
      (datosEntreno['clasifica'] as List).cast<Map<String, dynamic>>();

  int? _k; // juego elegido
  List<(String, int)> _items = []; // (caso, cajón correcto)
  int _i = 0;
  int _ok = 0;
  int? _elegido; // cajón tocado en este caso
  final List<(String, int)> _fallos = [];
  bool _terminado = false;
  bool _record = false;

  List<String> get _cajones => (_juegos[_k!]['b'] as List).cast<String>();

  void _empezar(int k) {
    setState(() {
      _k = k;
      _items = [
        for (final x in _juegos[k]['i'] as List) (x[0] as String, x[1] as int),
      ]..shuffle();
      _i = 0;
      _ok = 0;
      _elegido = null;
      _fallos.clear();
      _terminado = false;
      _record = false;
    });
  }

  void _elegir(int j) {
    if (_elegido != null) return;
    final acierto = j == _items[_i].$2;
    setState(() {
      _elegido = j;
      if (acierto) {
        _ok++;
      } else {
        _fallos.add(_items[_i]);
      }
    });
    if (acierto) {
      HapticFeedback.lightImpact();
      Future.delayed(
        const Duration(milliseconds: 500),
        _siguiente,
      ); // pasa sola
    } else {
      HapticFeedback.heavyImpact(); // si fallas, esperamos a que pulses Siguiente
    }
  }

  void _siguiente() {
    if (!mounted) return;
    if (_i + 1 >= _items.length) {
      setState(() {
        _terminado = true;
        _record = progreso.guardarRecord('clasifica.$_k', _ok);
      });
      progreso.sumarXP(_ok);
      return;
    }
    setState(() {
      _i++;
      _elegido = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.fondo,
        foregroundColor: AppColors.texto,
        scrolledUnderElevation: 0,
        title: Text(
          _k == null ? 'Clasifica' : _juegos[_k!]['t'] as String,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: widget.color,
          ),
        ),
      ),
      body: _k == null ? _lista() : (_terminado ? _resultado() : _jugar()),
    );
  }

  // ==================== ELEGIR JUEGO ====================
  Widget _lista() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
      children: [
        Text(
          'Elige un juego',
          style: GoogleFonts.unbounded(
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Te saldrá un caso cada vez. Mándalo al cajón que le corresponde.',
          style: TextStyle(height: 1.4, color: AppColors.texto2),
        ),
        const SizedBox(height: 18),
        for (var k = 0; k < _juegos.length; k++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: AppColors.panel,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => _empezar(k),
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
                              _juegos[k]['t'] as String,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              '${(_juegos[k]['i'] as List).length} casos · '
                              '${(_juegos[k]['b'] as List).length} cajones'
                              '${progreso.record('clasifica.$k') > 0 ? ' · récord ${progreso.record('clasifica.$k')}/${(_juegos[k]['i'] as List).length}' : ''}',
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
    final c = widget.color;
    final (caso, correcto) = _items[_i];
    final respondido = _elegido != null;
    final fallo = respondido && _elegido != correcto;

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
                  value: (_i + (respondido ? 1 : 0)) / _items.length,
                  minHeight: 6,
                  backgroundColor: AppColors.linea,
                  color: c,
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
          _juegos[_k!]['src'] as String,
          style: TextStyle(fontSize: 12, color: c),
        ),
        const SizedBox(height: 10),

        // El caso a clasificar
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: c.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.withValues(alpha: 0.5), width: 1.5),
          ),
          child: Text(
            caso,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Los cajones
        for (var j = 0; j < _cajones.length; j++)
          _Cajon(
            texto: _cajones[j],
            estado: !respondido
                ? 0
                : (j == correcto
                      ? 1
                      : (j == _elegido
                            ? -1
                            : 2)), // 1 bien · -1 mal · 2 apagado
            onTap: () => _elegir(j),
          ),

        if (fallo) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(LucideIcons.circleX, color: cRojo, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Va en «${_cajones[correcto]}»',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: cRojo,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _siguiente,
              icon: const Icon(LucideIcons.arrowRight, size: 18),
              iconAlignment: IconAlignment.end,
              label: Text(
                _i + 1 < _items.length ? 'Siguiente' : 'Ver resultado',
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

  // ==================== RESULTADO ====================
  Widget _resultado() {
    final c = widget.color;
    final forma = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        Icon(LucideIcons.trophy, size: 52, color: c),
        const SizedBox(height: 6),
        Center(
          child: Text(
            '$_ok/${_items.length}',
            style: GoogleFonts.unbounded(
              fontSize: 44,
              fontWeight: FontWeight.w800,
              color: c,
            ),
          ),
        ),
        Center(
          child: Text(
            _record ? '🏆 ¡Nuevo récord! · +$_ok XP' : '+$_ok XP',
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
            onPressed: () => _empezar(_k!),
            icon: const Icon(LucideIcons.rotateCcw, size: 18),
            label: const Text('Otra vez'),
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
          child: OutlinedButton.icon(
            onPressed: () => setState(() => _k = null),
            icon: const Icon(LucideIcons.columns3, size: 18),
            label: const Text('Otro juego'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.texto,
              side: const BorderSide(color: AppColors.linea),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: forma,
            ),
          ),
        ),
        if (_fallos.isNotEmpty) ...[
          const SizedBox(height: 26),
          Text(
            'Corrige estos',
            style: GoogleFonts.unbounded(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          for (final (caso, cajon) in _fallos)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.panel,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.linea),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(caso, style: const TextStyle(height: 1.35)),
                  const SizedBox(height: 4),
                  Text(
                    '→ ${_cajones[cajon]}',
                    style: const TextStyle(
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

// Un cajón: 0 normal · 1 correcto · -1 equivocado · 2 apagado
class _Cajon extends StatelessWidget {
  final String texto;
  final int estado;
  final VoidCallback onTap;

  const _Cajon({
    required this.texto,
    required this.estado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final (fondo, borde) = switch (estado) {
      1 => (cVerde.withValues(alpha: 0.15), cVerde),
      -1 => (cRojo.withValues(alpha: 0.15), cRojo),
      _ => (AppColors.panel, AppColors.linea),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Opacity(
        opacity: estado == 2 ? 0.45 : 1,
        child: Material(
          color: fondo,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: estado == 0 ? onTap : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borde, width: 1.5),
              ),
              child: Row(
                children: [
                  const Icon(
                    LucideIcons.inbox,
                    size: 18,
                    color: AppColors.texto2,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      texto,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (estado == 1)
                    const Icon(
                      LucideIcons.circleCheck,
                      color: cVerde,
                      size: 20,
                    ),
                  if (estado == -1)
                    const Icon(LucideIcons.circleX, color: cRojo, size: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
