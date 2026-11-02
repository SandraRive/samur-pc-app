import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../data/ambitos.dart';
import '../data/manual.dart';
import '../data/progreso.dart';
import '../data/tests.dart';
import '../theme/app_theme.dart';
import '../theme/iconos.dart';
import 'quiz_screen.dart';
import '../data/retos.dart';

const _verde = Color(0xFF2EE6A6);

// Cuántas preguntas de una lista tienes dominadas
int _dominadas(Iterable<Pregunta> preguntas) =>
    preguntas.where((p) => progreso.estaDominada(p.id)).length;

// El icono de un test: el de su bloque, como en tu web
IconData _iconoDeTest(Test t) {
  for (final g in manual.grupos(t.ambito)) {
    if (g.nombre == t.grupo) return iconoWeb(g.icono);
  }
  return LucideIcons.fileText;
}

// Abre una ronda de test
void _jugar(
  BuildContext context,
  String titulo,
  List<Pregunta> preguntas,
  Color color, {
  int cuantas = 10,
  bool barajar = true,
}) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => QuizScreen(
        titulo: titulo,
        preguntas: preguntas,
        color: color,
        cuantas: cuantas,
        barajar: barajar,
      ),
    ),
  );
}

class RepasoScreen extends StatelessWidget {
  final Ambito ambito;

  const RepasoScreen({super.key, required this.ambito});

  @override
  Widget build(BuildContext context) {
    final c = ambito.color;
    final espacioArriba = MediaQuery.paddingOf(context).top + kToolbarHeight;
    final todas = [for (final t in tests) ...t.preguntas];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.texto,
        scrolledUnderElevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [c.withValues(alpha: 0.22), AppColors.fondo],
            stops: const [0, 0.5],
          ),
        ),
        // Toda la pantalla escucha al progreso: al volver de un test, se actualiza sola
        child: ListenableBuilder(
          listenable: progreso,
          builder: (context, _) => ListView(
            padding: EdgeInsets.fromLTRB(20, espacioArriba + 8, 20, 32),
            children: [
              // ---------- CABECERA ----------
              Align(
                alignment: Alignment.centerLeft,
                child: Hero(
                  tag: 'icono-${ambito.id}',
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: c.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: c.withValues(alpha: 0.4)),
                    ),
                    child: Icon(ambito.icono, color: c, size: 36),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                ambito.nombre,
                style: GoogleFonts.unbounded(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.texto,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Ponte a prueba, sube de rango y repasa lo que más cae.',
                style: TextStyle(
                  fontSize: 15,
                  height: 1.4,
                  color: AppColors.texto2,
                ),
              ),
              const SizedBox(height: 22),

              // ---------- RANGO ----------
              _SeccionRango(color: c),
              const SizedBox(height: 30),

              // ---------- RETOS RÁPIDOS ----------
              Text(
                'Retos rápidos',
                style: GoogleFonts.unbounded(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Preguntas que se generan solas cada vez. Encadena racha y suma XP.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: AppColors.texto2,
                ),
              ),
              const SizedBox(height: 14),
              // De dos en dos, en filas
              for (var i = 0; i < retos.length; i += 2)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: _TarjetaReto(reto: retos[i])),
                        const SizedBox(width: 10),
                        Expanded(child: _TarjetaReto(reto: retos[i + 1])),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 30),

              // ---------- PONME A PRUEBA ----------
              Text(
                'Ponme a prueba',
                style: GoogleFonts.unbounded(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${tests.length} tests · ${todas.length} preguntas sacadas del manual. '
                'Una pregunta cuenta como dominada cuando la aciertas.',
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: AppColors.texto2,
                ),
              ),
              const SizedBox(height: 16),

              // Simulacro general
              _TarjetaGrande(
                icono: LucideIcons.trophy,
                titulo: 'Simulacro general',
                subtitulo: '20 preguntas de todos los ámbitos del manual',
                dominadas: _dominadas(todas),
                total: todas.length,
                color: c,
                onTap: () =>
                    _jugar(context, 'Simulacro general', todas, c, cuantas: 20),
              ),
              const SizedBox(height: 12),

              // Exámenes oficiales
              for (final x in examenes) ...[
                _TarjetaExamen(examen: x),
                const SizedBox(height: 12),
              ],

              // Un desplegable por cada ámbito que tenga tests
              for (final a in ambitos)
                if (tests.any((t) => t.ambito == a.id)) _AmbitoTests(ambito: a),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== RANGO ====================

class _SeccionRango extends StatelessWidget {
  final Color color;

  const _SeccionRango({required this.color});

  @override
  Widget build(BuildContext context) {
    final rango = progreso.rango;
    final siguiente = progreso.siguienteRango;
    final estudiados = progreso.cuantosEstudiados(manual.procedimientos);
    final esAlto = rangos.indexOf(rango) >= 5; // a partir de Charly, medalla

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withValues(alpha: 0.16), AppColors.panel],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  esAlto ? LucideIcons.medal : LucideIcons.trophy,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rango.nombre,
                      style: GoogleFonts.unbounded(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      rango.descripcion,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.texto2,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${progreso.xp}',
                style: GoogleFonts.unbounded(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'XP',
                style: TextStyle(fontWeight: FontWeight.w700, color: color),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progreso.porcentajeRango,
              minHeight: 8,
              backgroundColor: AppColors.linea,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            siguiente == null
                ? 'Rango máximo alcanzado 🎖️'
                : 'Siguiente rango: ${siguiente.nombre} a ${siguiente.xp} XP',
            style: const TextStyle(fontSize: 12, color: AppColors.texto2),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                LucideIcons.listChecks,
                size: 15,
                color: AppColors.texto2,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '$estudiados/${manual.procedimientos.length} procedimientos estudiados',
                  style: const TextStyle(fontSize: 12, color: AppColors.texto2),
                ),
              ),
              TextButton.icon(
                onPressed: () => _abrirRangos(context, color),
                icon: const Icon(LucideIcons.trophy, size: 16),
                label: const Text('Rangos'),
                style: TextButton.styleFrom(foregroundColor: color),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Panel desde abajo con la escala completa de rangos
void _abrirRangos(BuildContext context, Color color) {
  // Iconos de cada rango, los mismos que tu web
  const iconosRango = [
    LucideIcons.bookOpen,
    LucideIcons.handHelping,
    LucideIcons.ambulance,
    LucideIcons.syringe,
    LucideIcons.heartPulse,
    LucideIcons.radio,
    LucideIcons.shieldCheck,
    LucideIcons.medal,
  ];

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.panel,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scroll) {
        final actual = rangos.indexOf(progreso.rango);
        final siguiente = progreso.siguienteRango;

        return ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.linea,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Rangos de la guardia',
              style: GoogleFonts.unbounded(
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              siguiente == null
                  ? 'Tienes ${progreso.xp} XP. ¡Has llegado al rango máximo!'
                  : 'Tienes ${progreso.xp} XP. Te faltan ${siguiente.xp - progreso.xp} XP '
                        'para ser ${siguiente.nombre}.',
              style: const TextStyle(color: AppColors.texto2, height: 1.4),
            ),
            const SizedBox(height: 18),

            // La escala
            for (var k = 0; k < rangos.length; k++)
              _FilaRango(
                numero: k + 1,
                rango: rangos[k],
                icono: k > actual ? LucideIcons.lock : iconosRango[k],
                estado: k < actual
                    ? 'hecho'
                    : (k == actual ? 'actual' : 'bloqueado'),
                color: color,
              ),

            const SizedBox(height: 20),
            Row(
              children: [
                Icon(LucideIcons.star, size: 18, color: color),
                const SizedBox(width: 8),
                Text(
                  'Cómo se gana XP',
                  style: GoogleFonts.unbounded(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (final (puntos, texto) in [
              ('+10', 'Marcar un procedimiento como estudiado'),
              ('+3', 'Cada acierto en los tests'),
              ('+10', 'Bonus por pleno (todo acertado)'),
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 44,
                      child: Text(
                        puntos,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      ),
                    ),
                    Expanded(child: Text(texto)),
                  ],
                ),
              ),
          ],
        );
      },
    ),
  );
}

// Una fila de la escala de rangos
class _FilaRango extends StatelessWidget {
  final int numero;
  final Rango rango;
  final IconData icono;
  final String estado; // 'hecho', 'actual' o 'bloqueado'
  final Color color;

  const _FilaRango({
    required this.numero,
    required this.rango,
    required this.icono,
    required this.estado,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final esActual = estado == 'actual';
    final bloqueado = estado == 'bloqueado';
    final colorIcono = bloqueado
        ? AppColors.texto2
        : (estado == 'hecho' ? _verde : color);

    return Opacity(
      opacity: bloqueado ? 0.5 : 1,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: esActual ? color.withValues(alpha: 0.12) : AppColors.fondo,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: esActual ? color : AppColors.linea),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 22,
              child: Text(
                '$numero',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.texto2,
                ),
              ),
            ),
            Icon(icono, size: 20, color: colorIcono),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rango.nombre,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    rango.descripcion,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.texto2,
                    ),
                  ),
                  if (esActual && progreso.siguienteRango != null) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: progreso.porcentajeRango,
                        minHeight: 5,
                        backgroundColor: AppColors.linea,
                        color: color,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (esActual)
                  Text(
                    'Tu rango',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                Text(
                  '${rango.xp} XP',
                  style: const TextStyle(fontSize: 12, color: AppColors.texto2),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== TESTS ====================

// Tarjeta grande (Simulacro general)
class _TarjetaGrande extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String subtitulo;
  final int dominadas;
  final int total;
  final Color color;
  final VoidCallback onTap;

  const _TarjetaGrande({
    required this.icono,
    required this.titulo,
    required this.subtitulo,
    required this.dominadas,
    required this.total,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.panel,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.45)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icono, color: color, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          titulo,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          subtitulo,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.texto2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(LucideIcons.chevronRight, color: color),
                ],
              ),
              const SizedBox(height: 12),
              _BarraDominadas(dominadas: dominadas, total: total, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

// Desplegable de un ámbito con todos sus tests
class _AmbitoTests extends StatelessWidget {
  final Ambito ambito;

  const _AmbitoTests({required this.ambito});

  @override
  Widget build(BuildContext context) {
    final c = ambito.color;
    final suyos = tests.where((t) => t.ambito == ambito.id).toList();
    final preguntas = [for (final t in suyos) ...t.preguntas];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.linea),
      ),
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        iconColor: c,
        collapsedIconColor: AppColors.texto2,
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: c.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(ambito.icono, size: 19, color: c),
        ),
        title: Text(
          ambito.nombre,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '${suyos.length} test${suyos.length > 1 ? 's' : ''} · '
          '${preguntas.length} preguntas · ${_dominadas(preguntas)} dominadas',
          style: const TextStyle(fontSize: 12, color: AppColors.texto2),
        ),
        children: [
          // "Todo [ámbito]": 15 preguntas mezcladas de todos sus tests
          if (suyos.length > 1)
            _FilaTest(
              icono: LucideIcons.flame,
              titulo: 'Todo ${ambito.nombre}',
              subtitulo: '15 preguntas mezcladas',
              preguntas: preguntas,
              color: c,
              destacado: true,
              onTap: () => _jugar(
                context,
                'Todo ${ambito.nombre}',
                preguntas,
                c,
                cuantas: 15,
              ),
            ),
          for (final t in suyos)
            _FilaTest(
              icono: _iconoDeTest(t),
              titulo: t.titulo,
              subtitulo:
                  '${t.procId != null ? '${t.grupo} · ' : ''}'
                  '${t.preguntas.length} preguntas',
              preguntas: t.preguntas,
              color: c,
              onTap: () => _jugar(context, t.titulo, t.preguntas, c),
            ),
        ],
      ),
    );
  }
}

// Una fila de test dentro del desplegable
class _FilaTest extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String subtitulo;
  final List<Pregunta> preguntas;
  final Color color;
  final bool destacado;
  final VoidCallback onTap;

  const _FilaTest({
    required this.icono,
    required this.titulo,
    required this.subtitulo,
    required this.preguntas,
    required this.color,
    required this.onTap,
    this.destacado = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: destacado ? color.withValues(alpha: 0.10) : AppColors.fondo,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(icono, size: 18, color: color),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        subtitulo,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.texto2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _BarraDominadas(
                        dominadas: _dominadas(preguntas),
                        total: preguntas.length,
                        color: color,
                        compacta: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  LucideIcons.chevronRight,
                  size: 18,
                  color: AppColors.texto2,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Barra de "x/y dominadas"
class _BarraDominadas extends StatelessWidget {
  final int dominadas;
  final int total;
  final Color color;
  final bool compacta;

  const _BarraDominadas({
    required this.dominadas,
    required this.total,
    required this.color,
    this.compacta = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : dominadas / total,
              minHeight: compacta ? 4 : 6,
              backgroundColor: AppColors.linea,
              color: color,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '$dominadas/$total',
          style: TextStyle(
            fontSize: compacta ? 11 : 12,
            color: AppColors.texto2,
          ),
        ),
      ],
    );
  }
}

// ==================== RETOS Y EXÁMENES ====================

// Tarjeta de un reto rápido
class _TarjetaReto extends StatelessWidget {
  final Reto reto;

  const _TarjetaReto({required this.reto});

  @override
  Widget build(BuildContext context) {
    final color = ambitos.firstWhere((a) => a.id == reto.colorDe).color;

    return Material(
      color: AppColors.panel,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _jugar(
          context,
          reto.titulo,
          preguntasDeReto(reto.id), // se generan nuevas cada vez
          color,
          cuantas: reto.cuantas,
        ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.linea),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(reto.icono, size: 19, color: color),
              ),
              const SizedBox(height: 10),
              Text(
                reto.titulo,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                reto.subtitulo,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.3,
                  color: AppColors.texto2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Tarjeta del examen oficial, con dos formas de jugarlo
class _TarjetaExamen extends StatelessWidget {
  final Examen examen;

  const _TarjetaExamen({required this.examen});

  @override
  Widget build(BuildContext context) {
    final color = ambitos.firstWhere((a) => a.id == 'central').color;
    final total = examen.preguntas.length;
    final estiloBoton = OutlinedButton.styleFrom(
      foregroundColor: color,
      side: BorderSide(color: color.withValues(alpha: 0.5)),
      padding: const EdgeInsets.symmetric(vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(LucideIcons.fileText, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Preguntas de exámenes oficiales',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '${examen.titulo} · ${examen.subtitulo} · $total preguntas',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.texto2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _BarraDominadas(
            dominadas: _dominadas(examen.preguntas),
            total: total,
            color: color,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _jugar(
                    context,
                    examen.titulo,
                    examen.preguntas,
                    color,
                    cuantas: 20,
                  ),
                  icon: const Icon(LucideIcons.shuffle, size: 16),
                  label: const Text('20 al azar'),
                  style: estiloBoton,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _jugar(
                    context,
                    '${examen.titulo} · completo',
                    examen.preguntas,
                    color,
                    cuantas: total,
                    barajar: false, // en el orden del examen
                  ),
                  icon: const Icon(LucideIcons.listOrdered, size: 16),
                  label: const Text('Completo'),
                  style: estiloBoton,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
