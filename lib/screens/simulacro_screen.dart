import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../data/ambitos.dart';
import '../data/entreno.dart';
import '../data/progreso.dart';
import '../data/retos.dart';
import '../data/tests.dart';
import '../theme/app_theme.dart';
import 'simulacro_examen_screen.dart';

const _opcionesNumero = [20, 50, 95, 100, 0]; // 0 = todas
const _opcionesTiempo = [
  (0, 'Sin límite'),
  (30, '30 min'),
  (60, '60 min'),
  (90, '90 min'),
  (120, '120 min'),
  (-1, '1 min por pregunta'),
];

class SimulacroScreen extends StatefulWidget {
  const SimulacroScreen({super.key});

  @override
  State<SimulacroScreen> createState() => _SimulacroScreenState();
}

class _SimulacroScreenState extends State<SimulacroScreen> {
  final Set<String> _elegidos = {}; // ids de los tests elegidos
  bool _conExamen = false;
  int _numero = 50; // 0 = todas las elegidas
  int _minutos = 60;
  int _penalizacion = 1; // por defecto, cada 3 fallos restan 1

  // Todas las preguntas que entran en el sorteo, con su ámbito
  List<(Pregunta, String)> get _bolsa => [
    for (final t in tests)
      if (_elegidos.contains(t.id))
        for (final p in t.preguntas) (p, t.ambito),
    if (_conExamen && examenes.isNotEmpty)
      for (final p in examenes.first.preguntas) (p, 'examen'),
  ];

  int _cuantas(int disponibles) =>
      _numero == 0 ? disponibles : min(_numero, disponibles);

  String get _textoTiempo => switch (_minutos) {
    0 => 'sin límite de tiempo',
    -1 => '1 min por pregunta',
    _ => '$_minutos minutos',
  };

  void _empezar(List<(Pregunta, String)> bolsa) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SimulacroExamenScreen(
          bolsa: bolsa,
          cuantas: _cuantas(bolsa.length),
          minutos: _minutos,
          penalizacion: _penalizacion,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bolsa = _bolsa;
    final hayTemas = bolsa.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.fondo,
        foregroundColor: AppColors.texto,
        scrolledUnderElevation: 0,
        title: const Text(
          'Simulacro personalizado',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: cCyan,
          ),
        ),
      ),
      body: ListenableBuilder(
        listenable: progreso,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: [
            Text(
              'Monta tu examen',
              style: GoogleFonts.unbounded(
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Elige los temas que quieras combinar. Las respuestas no se corrigen '
              'hasta que entregues, como en el examen de verdad.',
              style: TextStyle(height: 1.4, color: AppColors.texto2),
            ),
            const SizedBox(height: 22),

            // ---------- 1 · TEMAS ----------
            const _Titulo('1 · Temas'),
            for (final a in ambitos)
              if (tests.any((t) => t.ambito == a.id)) _ambito(a),
            _filaExamen(),
            const SizedBox(height: 22),

            // ---------- 2 · NÚMERO ----------
            const _Titulo('2 · Número de preguntas'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final n in _opcionesNumero)
                  _Opcion(
                    texto: n == 0 ? 'Todas las elegidas' : '$n',
                    activa: _numero == n,
                    onTap: () => setState(() => _numero = n),
                  ),
              ],
            ),
            const SizedBox(height: 22),

            // ---------- 3 · TIEMPO ----------
            const _Titulo('3 · Tiempo'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (m, texto) in _opcionesTiempo)
                  _Opcion(
                    texto: texto,
                    activa: _minutos == m,
                    onTap: () => setState(() => _minutos = m),
                  ),
              ],
            ),
            const SizedBox(height: 22),

            // ---------- 4 · PENALIZACIÓN ----------
            const _Titulo('4 · Penalización'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var k = 0; k < penalizaciones.length; k++)
                  _Opcion(
                    texto: penalizaciones[k].$2,
                    activa: _penalizacion == k,
                    onTap: () => setState(() => _penalizacion = k),
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // ---------- RESUMEN + EMPEZAR ----------
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cCyan.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: cCyan.withValues(alpha: 0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hayTemas
                        ? '${_cuantas(bolsa.length)} preguntas'
                        : 'Elige al menos un tema',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hayTemas
                        ? 'de ${bolsa.length} disponibles · $_textoTiempo · '
                              '${penalizaciones[_penalizacion].$2.toLowerCase()}'
                        : 'Puedes mezclar bloques de distintos ámbitos y el examen oficial.',
                    style: const TextStyle(
                      fontSize: 12.5,
                      height: 1.4,
                      color: AppColors.texto2,
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: hayTemas
                          ? () => _empezar(bolsa)
                          : null, // apagado sin temas
                      icon: const Icon(LucideIcons.play, size: 18),
                      label: const Text('Empezar simulacro'),
                      style: FilledButton.styleFrom(
                        backgroundColor: cCyan,
                        foregroundColor: AppColors.fondo,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ---------- HISTORIAL ----------
            if (progreso.simulacros.isNotEmpty) ...[
              const SizedBox(height: 28),
              const _Titulo('Tus últimos simulacros'),
              for (final s in progreso.simulacros.reversed.take(5))
                _FilaHistorial(s),
            ],
          ],
        ),
      ),
    );
  }

  // Desplegable de un ámbito, con su casilla de "todo" y sus bloques
  Widget _ambito(Ambito a) {
    final suyos = tests.where((t) => t.ambito == a.id).toList();
    final elegidosAqui = suyos.where((t) => _elegidos.contains(t.id)).length;
    final todos = elegidosAqui == suyos.length;
    final preguntas = suyos.fold<int>(
      0,
      (suma, t) => suma + t.preguntas.length,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: elegidosAqui > 0
              ? a.color.withValues(alpha: 0.5)
              : AppColors.linea,
        ),
      ),
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        iconColor: a.color,
        collapsedIconColor: AppColors.texto2,
        tilePadding: const EdgeInsets.only(left: 4, right: 12),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        // Casilla de 3 estados: todo (✓), nada (vacía) o parte (–)
        leading: Checkbox(
          tristate: true,
          value: todos ? true : (elegidosAqui == 0 ? false : null),
          activeColor: a.color,
          checkColor: AppColors.fondo,
          onChanged: (_) => setState(() {
            if (todos) {
              _elegidos.removeAll(suyos.map((t) => t.id));
            } else {
              _elegidos.addAll(suyos.map((t) => t.id));
            }
          }),
        ),
        title: Row(
          children: [
            Icon(a.icono, size: 16, color: a.color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                a.nombre,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        subtitle: Text(
          elegidosAqui > 0
              ? '$elegidosAqui de ${suyos.length} bloques'
              : '${suyos.length} bloques · $preguntas preguntas',
          style: const TextStyle(fontSize: 12, color: AppColors.texto2),
        ),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final t in suyos)
                  _Opcion(
                    texto: t.titulo,
                    extra: '${t.preguntas.length}',
                    activa: _elegidos.contains(t.id),
                    color: a.color,
                    onTap: () => setState(() {
                      if (!_elegidos.remove(t.id)) _elegidos.add(t.id);
                    }),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Casilla del examen oficial
  Widget _filaExamen() {
    if (examenes.isEmpty) return const SizedBox();
    final x = examenes.first;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _conExamen ? cNaranja.withValues(alpha: 0.5) : AppColors.linea,
        ),
      ),
      child: CheckboxListTile(
        value: _conExamen,
        onChanged: (v) => setState(() => _conExamen = v ?? false),
        controlAffinity: ListTileControlAffinity.leading,
        activeColor: cNaranja,
        checkColor: AppColors.fondo,
        contentPadding: const EdgeInsets.only(left: 4, right: 12),
        title: Row(
          children: [
            const Icon(LucideIcons.fileText, size: 16, color: cNaranja),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                x.titulo,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        subtitle: Text(
          '${x.preguntas.length} preguntas reales',
          style: const TextStyle(fontSize: 12, color: AppColors.texto2),
        ),
      ),
    );
  }
}

class _Titulo extends StatelessWidget {
  final String texto;

  const _Titulo(this.texto);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        texto,
        style: GoogleFonts.unbounded(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    );
  }
}

// Botón de opción seleccionable (con contador opcional)
class _Opcion extends StatelessWidget {
  final String texto;
  final String? extra;
  final bool activa;
  final Color color;
  final VoidCallback onTap;

  const _Opcion({
    required this.texto,
    required this.activa,
    required this.onTap,
    this.extra,
    this.color = cCyan,
  });

  @override
  Widget build(BuildContext context) {
    final colorTexto = activa ? AppColors.fondo : AppColors.texto;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: activa ? color : AppColors.fondo,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: activa ? color : AppColors.linea),
        ),
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(text: texto),
              if (extra != null)
                TextSpan(
                  text: '  $extra',
                  style: TextStyle(color: colorTexto.withValues(alpha: 0.6)),
                ),
            ],
          ),
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: colorTexto,
          ),
        ),
      ),
    );
  }
}

// Una fila del historial
class _FilaHistorial extends StatelessWidget {
  final Map<String, dynamic> s;

  const _FilaHistorial(this.s);

  @override
  Widget build(BuildContext context) {
    final nota = (s['nota'] as num).toDouble();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.linea),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 58,
            child: Text(
              nota.toStringAsFixed(2).replaceAll('.', ','),
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: nota >= 5 ? cVerde : cRojo,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${s['ok']} aciertos · ${s['ko']} fallos · ${s['bl']} en blanco · ${s['n']} preguntas',
                  style: const TextStyle(fontSize: 12.5),
                ),
                Text(
                  '${s['fecha']}',
                  style: const TextStyle(fontSize: 11, color: AppColors.texto2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
