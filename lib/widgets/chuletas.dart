import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../data/ambitos.dart';
import '../data/manual.dart';
import '../data/retos.dart';
import '../screens/procedimiento_screen.dart';
import '../theme/app_theme.dart';

// El color de un ámbito por su id
Color _colorDe(String id) => ambitos.firstWhere((a) => a.id == id).color;

// Abre el procedimiento cuyo título contenga ese texto (como procLink en tu web)
void _abrirProcedimiento(BuildContext context, String trozoTitulo) {
  final buscado = normalizar(trozoTitulo);
  for (final p in manual.procedimientos) {
    if (normalizar(p.titulo).contains(buscado)) {
      final ambito = ambitos.firstWhere((a) => a.id == p.ambito);
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ProcedimientoScreen(proc: p, ambito: ambito),
        ),
      );
      return;
    }
  }
}

// ==================== TODAS LAS CHULETAS ====================

class Chuletas extends StatelessWidget {
  const Chuletas({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Chuleta(
          titulo: 'Prioridades de la Central',
          icono: LucideIcons.siren,
          color: _colorDe('sva'),
          enlace: 'Gestión de recursos',
          child: const _Prioridades(),
        ),
        _Chuleta(
          titulo: 'Situaciones operativas USVA',
          icono: LucideIcons.activity,
          color: _colorDe('central'),
          enlace: 'Gestión de recursos',
          textoEnlace: 'Ver tiempos de control',
          child: const _Semaforo(),
        ),
        _Chuleta(
          titulo: 'IMV · petos de colores',
          icono: LucideIcons.triangleAlert,
          color: _colorDe('svb'),
          enlace: 'Incidentes con múltiples',
          textoEnlace: 'Procedimiento IMV',
          child: const _Petos(),
        ),
        _Chuleta(
          titulo: 'Triaje STARS',
          icono: LucideIcons.listOrdered,
          color: _colorDe('svb'),
          child: _Stars(color: _colorDe('svb')),
        ),
        _Chuleta(
          titulo: 'Claves de radio',
          subtitulo: 'Toca una tarjeta para girarla',
          icono: LucideIcons.radio,
          color: _colorDe('central'),
          enlace: 'Procedimiento radiotelefónico',
          child: _Claves(color: _colorDe('central')),
        ),
        _Chuleta(
          titulo: 'Códigos de incidente',
          icono: LucideIcons.hash,
          color: _colorDe('operativos'),
          child: _Codigos(color: _colorDe('operativos')),
        ),
        _Chuleta(
          titulo: 'Códigos específicos',
          icono: LucideIcons.heartPulse,
          color: _colorDe('operativos'),
          child: _Especificos(color: _colorDe('operativos')),
        ),
        _Chuleta(
          titulo: 'Indicativos',
          subtitulo: 'Toca uno para ver quién es',
          icono: LucideIcons.users,
          color: _colorDe('admin'),
          child: _Indicativos(color: _colorDe('admin')),
        ),
      ],
    );
  }
}

// El "marco" común de cada chuleta: título, contenido y enlace opcional
class _Chuleta extends StatelessWidget {
  final String titulo;
  final String? subtitulo;
  final IconData icono;
  final Color color;
  final String? enlace; // trozo del título del procedimiento a abrir
  final String? textoEnlace; // texto del botón (si no, el propio enlace)
  final Widget child;

  const _Chuleta({
    required this.titulo,
    required this.icono,
    required this.color,
    required this.child,
    this.subtitulo,
    this.enlace,
    this.textoEnlace,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.linea),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icono, size: 20, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  titulo,
                  style: GoogleFonts.unbounded(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (subtitulo != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                subtitulo!,
                style: const TextStyle(fontSize: 12, color: AppColors.texto2),
              ),
            ),
          const SizedBox(height: 14),
          child,
          if (enlace != null) ...[
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _abrirProcedimiento(context, enlace!),
                icon: const Icon(LucideIcons.arrowRight, size: 16),
                iconAlignment: IconAlignment.end,
                label: Text(textoEnlace ?? enlace!),
                style: TextButton.styleFrom(foregroundColor: color),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ==================== PRIORIDADES ====================

class _Prioridades extends StatelessWidget {
  const _Prioridades();

  static const _datos = [
    (
      'P1',
      'Emergencia',
      'Urgencia vital. Unidad activada en emergencia.',
      Color(0xFFFF3B5C),
    ),
    (
      'P2',
      'Urgencia',
      'Urgencia no vital. Unidad activada en emergencia.',
      Color(0xFFFF9F1A),
    ),
    (
      'P3',
      'Preferente',
      'No vital, con condicionante social. Sin activación en emergencia.',
      Color(0xFFFFD23F),
    ),
    (
      'P4',
      'Normal',
      'No urgencia. Sin activación en emergencia.',
      Color(0xFF2EE6A6),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final (codigo, nombre, texto, color) in _datos)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    codigo,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: AppColors.fondo,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nombre,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        texto,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.35,
                          color: AppColors.texto2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ==================== SEMÁFORO USVA ====================

class _Semaforo extends StatelessWidget {
  const _Semaforo();

  static const _datos = [
    (
      Color(0xFF2EE6A6),
      '1 · Verde',
      'Normalidad. Asignación de recursos habitual.',
    ),
    (
      Color(0xFFFFD23F),
      '2 · Amarillo',
      'Alerta de saturación: ≤ 6 USVA mañana, ≤ 5 tarde, ≤ 2 noche. Control estricto de tiempos.',
    ),
    (
      Color(0xFFFF3B5C),
      '3 · Rojo',
      'Saturación: solo 2 USVA en M/T y 1 de noche. Se reservan USVA para códigos graves.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final (color, titulo, texto) in _datos)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Luz del semáforo, con brillo
                Container(
                  width: 14,
                  height: 14,
                  margin: const EdgeInsets.only(top: 3),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.6),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: titulo,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        TextSpan(text: ' — $texto'),
                      ],
                    ),
                    style: const TextStyle(fontSize: 13.5, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ==================== PETOS IMV ====================

class _Petos extends StatelessWidget {
  const _Petos();

  static const _datos = [
    (Color(0xFFFF3B5C), 'Jefe de Dispositivo Sanitario'),
    (Color(0xFF2EE6A6), 'Jefe PSA'),
    (Color(0xFF9B5CFF), 'Rescate sanitario / 1er triaje'),
    (Color(0xFF9B5CFF), 'Triaje (2º)'),
    (Color(0xFF9B5CFF), 'Numerador'),
    (Color(0xFFFF8A1A), 'Espera de recursos'),
    (Color(0xFF2EE6A6), 'Filiación'),
    (Color(0xFF2EE6A6), 'Evacuación'),
    (Color(0xFF2E8BFF), 'Logística y comunicaciones'),
    (Color(0xFF2EE6A6), 'Pacientes leves («verde»)'),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final (color, texto) in _datos)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.fondo,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.linea),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 8),
                Text(texto, style: const TextStyle(fontSize: 12.5)),
              ],
            ),
          ),
      ],
    );
  }
}

// ==================== TRIAJE STARS ====================

class _Stars extends StatelessWidget {
  final Color color;

  const _Stars({required this.color});

  static const _pasos = [
    (
      'Rescate',
      'En el foco, por uno de los primeros TATS. Separa moderados/graves recuperables de ilesos y fallecidos.',
    ),
    (
      'Asistencia',
      'En zona templada, por médico o enfermero. Graves y moderados frente a leves.',
    ),
    (
      'Estabilización',
      'Responsable del PSA. Estabilización inmediata + traslado urgente, o traslado urgente con estabilización en ruta.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var k = 0; k < _pasos.length; k++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${k + 1}',
                    style: TextStyle(fontWeight: FontWeight.w800, color: color),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: _pasos[k].$1,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        TextSpan(text: ' · ${_pasos[k].$2}'),
                      ],
                    ),
                    style: const TextStyle(fontSize: 13.5, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'A-CLA-RE',
                style: TextStyle(fontWeight: FontWeight.w800, color: color),
              ),
              const TextSpan(
                text: ': Agrupar en el PRV · CLAsificar con STARS · REplantear recursos.',
              ),
            ],
          ),
          style: const TextStyle(
            fontSize: 13,
            height: 1.4,
            color: AppColors.texto2,
          ),
        ),
      ],
    );
  }
}

// ==================== CLAVES DE RADIO (GIRATORIAS) ====================

class _Claves extends StatelessWidget {
  final Color color;

  const _Claves({required this.color});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      padding: EdgeInsets.zero,
      crossAxisCount: 2,
      shrinkWrap: true, // ocupa solo lo que necesita
      physics:
          const NeverScrollableScrollPhysics(), // el scroll lo hace la pantalla
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1.2,
      children: [
        for (final (clave, significado) in referencia.claves)
          _ClaveGiratoria(clave: clave, significado: significado, color: color),
      ],
    );
  }
}

class _ClaveGiratoria extends StatefulWidget {
  final String clave;
  final String significado;
  final Color color;

  const _ClaveGiratoria({
    required this.clave,
    required this.significado,
    required this.color,
  });

  @override
  State<_ClaveGiratoria> createState() => _ClaveGiratoriaState();
}

class _ClaveGiratoriaState extends State<_ClaveGiratoria> {
  bool _girada = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _girada = !_girada),
      // Anima el ángulo de 0 a π (180°) o al revés
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: _girada ? pi : 0),
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
        builder: (context, angulo, _) {
          final seVeElFrente = angulo < pi / 2; // hasta los 90°, el frente
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(
                3,
                2,
                0.0015,
              ) // perspectiva: da sensación de profundidad
              ..rotateY(angulo),
            child: seVeElFrente
                ? _frente()
                // El dorso se gira otros 180° para que el texto no se vea al revés
                : Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.rotationY(pi),
                    child: _dorso(),
                  ),
          );
        },
      ),
    );
  }

  Widget _frente() {
    final c = widget.color;
    final esLarga = widget.clave.length > 4;
    final esClave =
        RegExp(r'^\d').hasMatch(widget.clave) || widget.clave == 'VICTOR';

    return Container(
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.withValues(alpha: 0.5)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.clave,
              textAlign: TextAlign.center,
              style: GoogleFonts.unbounded(
                fontSize: esLarga ? 16 : 26,
                fontWeight: FontWeight.w800,
                color: c,
              ),
            ),
            if (esClave)
              const Text(
                'CLAVE',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.5,
                  color: AppColors.texto2,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _dorso() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.fondo,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: widget.color),
      ),
      child: Center(
        child: Text(
          widget.significado,
          textAlign: TextAlign.center,
          maxLines: 8,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, height: 1.3),
        ),
      ),
    );
  }
}

// ==================== CÓDIGOS DE INCIDENTE ====================

class _Codigos extends StatelessWidget {
  final Color color;

  const _Codigos({required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final g in referencia.codigos)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppColors.fondo,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.linea),
            ),
            child: ExpansionTile(
              shape: const Border(),
              collapsedShape: const Border(),
              iconColor: color,
              collapsedIconColor: AppColors.texto2,
              tilePadding: const EdgeInsets.symmetric(horizontal: 12),
              childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              title: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      g.numero,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      g.nombre,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              children: [
                for (final (codigo, texto) in g.codigos)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 54,
                          child: Text(
                            codigo,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            texto,
                            style: const TextStyle(
                              fontSize: 13.5,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

// ==================== CÓDIGOS ESPECÍFICOS ====================

class _Especificos extends StatelessWidget {
  final Color color;

  const _Especificos({required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final (codigo, texto) in referencia.especificos)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    codigo,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    texto,
                    style: const TextStyle(fontSize: 13.5, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ==================== INDICATIVOS ====================

class _Indicativos extends StatefulWidget {
  final Color color;

  const _Indicativos({required this.color});

  @override
  State<_Indicativos> createState() => _IndicativosState();
}

class _IndicativosState extends State<_Indicativos> {
  int? _elegido; // índice del indicativo tocado

  // Los mismos grupos que usa tu web
  late final List<Par> _todos = [
    for (final cat in [
      'Particulares',
      'Generales',
      'Según base o función',
      'Ajenos',
    ])
      ...?referencia.indicativos[cat],
  ];

  @override
  Widget build(BuildContext context) {
    final c = widget.color;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Caja con la respuesta (arriba, para verla sin hacer scroll)
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _elegido == null
                ? AppColors.fondo
                : c.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _elegido == null ? AppColors.linea : c),
          ),
          child: _elegido == null
              ? const Text(
                  'Toca un indicativo para ver quién es.',
                  style: TextStyle(color: AppColors.texto2),
                )
              : Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: _todos[_elegido!].$1,
                        style: GoogleFonts.jetBrainsMono(
                          fontWeight: FontWeight.w800,
                          color: c,
                        ),
                      ),
                      TextSpan(text: ' — ${_todos[_elegido!].$2}'),
                    ],
                  ),
                  style: const TextStyle(fontSize: 14, height: 1.4),
                ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (var i = 0; i < _todos.length; i++)
              GestureDetector(
                onTap: () => setState(() => _elegido = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: _elegido == i ? c : AppColors.fondo,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _elegido == i ? c : AppColors.linea,
                    ),
                  ),
                  child: Text(
                    _todos[i].$1,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: _elegido == i ? AppColors.fondo : AppColors.texto,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
