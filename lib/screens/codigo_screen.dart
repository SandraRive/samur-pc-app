import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../data/entreno.dart';
import '../data/progreso.dart';
import '../theme/app_theme.dart';

enum _Fase { intro, jugando, fin }

class CodigoScreen extends StatefulWidget {
  final Color color;

  const CodigoScreen({super.key, required this.color});

  @override
  State<CodigoScreen> createState() => _CodigoScreenState();
}

class _CodigoScreenState extends State<CodigoScreen> {
  // Los 11 códigos: (nombre, descripción)
  late final List<(String, String)> _codigos = [
    for (final c in datosEntreno['codigos'] as List)
      (c[0] as String, c[1] as String),
  ];
  // Las 29 situaciones: (situación, código correcto, explicación)
  late final List<(String, int, String)> _casos = [
    for (final c in datosEntreno['codigoCasos'] as List)
      (c[0] as String, c[1] as int, c[2] as String),
  ];

  _Fase _fase = _Fase.intro;
  List<(String, int, String)> _items = [];
  int _i = 0;
  int _ok = 0;
  int? _elegido;
  bool _rondaDeDiez = true;
  bool _record = false;
  final List<(String, int, String)> _fallos = [];

  void _empezar(bool diez) {
    setState(() {
      _rondaDeDiez = diez;
      _items = (List.of(
        _casos,
      )..shuffle()).take(diez ? 10 : _casos.length).toList();
      _i = 0;
      _ok = 0;
      _elegido = null;
      _fallos.clear();
      _record = false;
      _fase = _Fase.jugando;
    });
  }

  void _elegir(int j) {
    if (_elegido != null) return;
    final bien = j == _items[_i].$2;
    setState(() {
      _elegido = j;
      if (bien) {
        _ok++;
      } else {
        _fallos.add(_items[_i]);
      }
    });
    bien ? HapticFeedback.lightImpact() : HapticFeedback.heavyImpact();
  }

  void _siguiente() {
    if (_i + 1 >= _items.length) {
      setState(() {
        _fase = _Fase.fin;
        if (_rondaDeDiez) _record = progreso.guardarRecord('codigo', _ok);
      });
      progreso.sumarXP(_ok * 2);
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
          '¿Qué código es?',
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

  // ==================== INTRO ====================
  Widget _intro() {
    final record = progreso.record('codigo');
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
      children: [
        Text(
          'Activa el código correcto',
          style: GoogleFonts.unbounded(
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Te describimos una situación real y tienes que elegir cuál de los 11 códigos de '
          'activación del manual corresponde. Después verás el criterio exacto.',
          style: TextStyle(height: 1.4, color: AppColors.texto2),
        ),
        const SizedBox(height: 16),
        for (final (nombre, desc) in _codigos)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 112,
                  child: Text(
                    nombre,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: widget.color,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    desc,
                    style: const TextStyle(fontSize: 13, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        _boton(
          '10 situaciones al azar',
          LucideIcons.play,
          () => _empezar(true),
        ),
        const SizedBox(height: 10),
        _boton(
          'Las ${_casos.length} seguidas',
          LucideIcons.listOrdered,
          () => _empezar(false),
          principal: false,
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
    final (situacion, correcto, explicacion) = _items[_i];
    final respondido = _elegido != null;
    final bien = _elegido == correcto;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
      children: [
        Row(
          children: [
            Text(
              '${_i + 1}/${_items.length}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            const Icon(LucideIcons.check, size: 16, color: cVerde),
            Text(' $_ok', style: const TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: widget.color.withValues(alpha: 0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(LucideIcons.radio, size: 16, color: widget.color),
                  const SizedBox(width: 6),
                  Text(
                    'SITUACIÓN',
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 1.5,
                      color: widget.color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                situacion,
                style: const TextStyle(fontSize: 16, height: 1.45),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Los 11 códigos como botones
        for (var j = 0; j < _codigos.length; j++)
          _BotonCodigo(
            nombre: _codigos[j].$1,
            descripcion: _codigos[j].$2,
            estado: !respondido
                ? 0
                : (j == correcto ? 1 : (j == _elegido ? -1 : 2)),
            onTap: () => _elegir(j),
          ),

        if (respondido) ...[
          const SizedBox(height: 6),
          Text(
            bien ? '✅ ¡Correcto!' : '❌ Era el ${_codigos[correcto].$1}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: bien ? cVerde : cRojo,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cAmarillo.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cAmarillo.withValues(alpha: 0.3)),
            ),
            child: Text(
              '💡 $explicacion',
              style: const TextStyle(height: 1.45),
            ),
          ),
          const SizedBox(height: 16),
          _boton(
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
        _boton(
          'Otra ronda',
          LucideIcons.rotateCcw,
          () => _empezar(_rondaDeDiez),
        ),
        const SizedBox(height: 10),
        _boton(
          'Volver',
          LucideIcons.arrowLeft,
          () => Navigator.of(context).pop(),
          principal: false,
        ),
        if (_fallos.isNotEmpty) ...[
          const SizedBox(height: 26),
          Text(
            'Repasa estos',
            style: GoogleFonts.unbounded(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          for (final (situacion, correcto, explicacion) in _fallos)
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
                  Text(situacion, style: const TextStyle(height: 1.4)),
                  const SizedBox(height: 6),
                  Text(
                    '→ ${_codigos[correcto].$1}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: cVerde,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    explicacion,
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

// Botón de un código: 0 normal · 1 correcto · -1 equivocado · 2 apagado
class _BotonCodigo extends StatelessWidget {
  final String nombre;
  final String descripcion;
  final int estado;
  final VoidCallback onTap;

  const _BotonCodigo({
    required this.nombre,
    required this.descripcion,
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
      padding: const EdgeInsets.only(bottom: 6),
      child: Opacity(
        opacity: estado == 2 ? 0.4 : 1,
        child: Material(
          color: fondo,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: estado == 0 ? onTap : null,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borde, width: 1.5),
              ),
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: nombre,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    TextSpan(
                      text: '  ·  $descripcion',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.texto2,
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
