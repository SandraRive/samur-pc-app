import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../data/entreno.dart';
import '../data/progreso.dart';
import '../theme/app_theme.dart';
import '../widgets/opcion_respuesta.dart';

// Una opción de un paso: (texto, ¿correcta?, explicación, consecuencia si fallas)
typedef _OpcionCaso = (String, bool, String, String);

class CasosScreen extends StatefulWidget {
  final Color color;

  const CasosScreen({super.key, required this.color});

  @override
  State<CasosScreen> createState() => _CasosScreenState();
}

class _CasosScreenState extends State<CasosScreen> {
  late final List<Map<String, dynamic>> _casos = (datosEntreno['casos'] as List)
      .cast<Map<String, dynamic>>();

  Map<String, dynamic>? _caso;
  int _paso = 0;
  int _ok = 0;
  String _consecuencia = ''; // lo que ha pasado por tu último error
  List<_OpcionCaso> _opciones = []; // opciones del paso, barajadas
  int? _elegida;
  bool _terminado = false;
  final List<(String, String, _OpcionCaso)> _desvios =
      []; // (pregunta, tu opción, la correcta)

  List<Map<String, dynamic>> get _pasos =>
      (_caso!['steps'] as List).cast<Map<String, dynamic>>();
  Color get _colorCaso => colorWeb(_caso!['c'] as String?);

  void _empezar(Map<String, dynamic> caso) {
    setState(() {
      _caso = caso;
      _paso = 0;
      _ok = 0;
      _consecuencia = '';
      _desvios.clear();
      _terminado = false;
      _prepararPaso();
    });
  }

  void _prepararPaso() {
    _opciones = [
      for (final o in _pasos[_paso]['o'] as List)
        (
          o[0] as String,
          o[1] == 1,
          o[2] as String,
          (o as List).length > 3 ? o[3] as String : '',
        ),
    ]..shuffle();
    _elegida = null;
  }

  int get _correcta => _opciones.indexWhere((o) => o.$2);

  void _elegir(int k) {
    if (_elegida != null) return;
    final o = _opciones[k];
    setState(() {
      _elegida = k;
      if (o.$2) {
        _ok++;
      } else {
        _desvios.add((
          _pasos[_paso]['q'] as String,
          o.$1,
          _opciones[_correcta],
        ));
      }
    });
    o.$2 ? HapticFeedback.lightImpact() : HapticFeedback.heavyImpact();
  }

  void _continuar() {
    final o = _opciones[_elegida!];
    if (_paso + 1 >= _pasos.length) {
      setState(() => _terminado = true);
      progreso.guardarRecord('caso.${_caso!['id']}', _ok);
      progreso.sumarXP(_ok * 2);
      return;
    }
    setState(() {
      // Si te desviaste, el caso cambia: se muestra la consecuencia en el paso siguiente
      _consecuencia = o.$2 ? '' : o.$4;
      _paso++;
      _prepararPaso();
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
        title: Text(
          _caso == null ? 'Casos clínicos' : _caso!['t'] as String,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: widget.color,
          ),
        ),
      ),
      body: _caso == null ? _lista() : (_terminado ? _resultado() : _jugar()),
    );
  }

  Widget _boton(
    String texto,
    IconData icono,
    VoidCallback onTap,
    Color color, {
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
              iconAlignment: IconAlignment.end,
              label: Text(texto),
              style: FilledButton.styleFrom(
                backgroundColor: color,
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

  // ==================== LISTA DE CASOS ====================
  Widget _lista() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
      children: [
        Text(
          'Como en la calle',
          style: GoogleFonts.unbounded(
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Lee la situación y decide qué harías en cada paso. Si te desvías del procedimiento, '
          'el caso cambia y al final verás en qué te saliste y qué dice el manual.',
          style: TextStyle(height: 1.4, color: AppColors.texto2),
        ),
        const SizedBox(height: 18),
        for (final c in _casos)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: AppColors.panel,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => _empezar(c),
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
                          color: colorWeb(c['c'] as String?)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          iconoEntreno(c['icon'] as String),
                          size: 20,
                          color: colorWeb(c['c'] as String?),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              c['t'] as String,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              '${(c['steps'] as List).length} decisiones · ${c['src']}'
                              '${progreso.record('caso.${c['id']}') > 0 ? ' · récord ${progreso.record('caso.${c['id']}')}/${(c['steps'] as List).length}' : ''}',
                              style: const TextStyle(
                                fontSize: 12,
                                height: 1.35,
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
    final paso = _pasos[_paso];
    final c = _colorCaso;
    final respondida = _elegida != null;
    final elegida = respondida ? _opciones[_elegida!] : null;
    final constantes = (paso['v'] as List?) ?? [];

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
      children: [
        Row(
          children: [
            Text(
              'Paso ${_paso + 1}/${_pasos.length}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: (_paso + (respondida ? 1 : 0)) / _pasos.length,
                  minHeight: 6,
                  backgroundColor: AppColors.linea,
                  color: c,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(_caso!['src'] as String, style: TextStyle(fontSize: 12, color: c)),
        const SizedBox(height: 8),

        // La introducción, solo en el primer paso
        if (_paso == 0) ...[
          Text(
            _caso!['intro'] as String,
            style: const TextStyle(fontSize: 15, height: 1.5),
          ),
          const SizedBox(height: 12),
        ],

        // Lo que ha pasado por tu error anterior
        if (_consecuencia.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cNaranja.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cNaranja.withValues(alpha: 0.5)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  LucideIcons.triangleAlert,
                  size: 18,
                  color: cNaranja,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _consecuencia,
                    style: const TextStyle(height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Constantes del paciente
        if (constantes.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final x in constantes)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.panel,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.linea),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        x[0] as String,
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: AppColors.texto2,
                        ),
                      ),
                      Text(
                        x[1] as String,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
        ],

        Text(
          paso['q'] as String,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 16),
        for (var k = 0; k < _opciones.length; k++)
          OpcionRespuesta(
            letra: 'ABCD'[k],
            texto: _opciones[k].$1,
            estado: _estado(k),
            onTap: () => _elegir(k),
          ),

        if (elegida != null) ...[
          const SizedBox(height: 6),
          Text(
            elegida.$2 ? '✅ Correcto' : '❌ Te has desviado del procedimiento',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: elegida.$2 ? cVerde : cRojo,
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
              elegida.$2
                  ? '💡 ${elegida.$3}'
                  : '💡 ${elegida.$3} Lo indicado: ${_opciones[_correcta].$1}.',
              style: const TextStyle(height: 1.45),
            ),
          ),
          const SizedBox(height: 16),
          _boton(
            _paso + 1 < _pasos.length ? 'Continuar' : 'Ver resumen',
            LucideIcons.arrowRight,
            _continuar,
            c,
          ),
        ],
      ],
    );
  }

  // ==================== RESUMEN ====================
  Widget _resultado() {
    final c = _colorCaso;
    final n = _pasos.length;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        Icon(LucideIcons.trophy, size: 52, color: c),
        const Center(
          child: Text(
            'Caso terminado',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        Center(
          child: Text(
            '$_ok/$n',
            style: GoogleFonts.unbounded(
              fontSize: 44,
              fontWeight: FontWeight.w800,
              color: c,
            ),
          ),
        ),
        Center(
          child: Text(
            _ok == n
                ? 'Has seguido el procedimiento de principio a fin · +${_ok * 2} XP'
                : 'decisiones según el procedimiento · +${_ok * 2} XP',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.texto2),
          ),
        ),
        const SizedBox(height: 22),
        _boton(
          'Repetir caso',
          LucideIcons.rotateCcw,
          () => _empezar(_caso!),
          c,
        ),
        const SizedBox(height: 10),
        _boton(
          'Otro caso',
          LucideIcons.stethoscope,
          () => setState(() => _caso = null),
          c,
          principal: false,
        ),
        if (_desvios.isNotEmpty) ...[
          const SizedBox(height: 26),
          Text(
            'Dónde te desviaste',
            style: GoogleFonts.unbounded(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          for (final (pregunta, tuya, correcta) in _desvios)
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
                    pregunta,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '✕ Elegiste: $tuya',
                    style: const TextStyle(color: cRojo, height: 1.35),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '✓ Procedimiento: ${correcta.$1}',
                    style: const TextStyle(
                      color: cVerde,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    correcta.$3,
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
