import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../data/ambitos.dart';
import '../data/entreno.dart';
import '../data/progreso.dart';
import '../data/tests.dart';
import '../theme/app_theme.dart';

// Las 3 penalizaciones posibles (las mismas que tu web)
const penalizaciones = [
  (0.0, 'Sin penalización'),
  (1 / 3, 'Cada 3 fallos restan 1 acierto'),
  (1 / 4, 'Cada 4 fallos restan 1 acierto'),
];

// Fecha corta para el historial: "2 nov · 18:55"
String fechaCorta(DateTime d) {
  const meses = [
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sept',
    'oct',
    'nov',
    'dic',
  ];
  final hh = d.hour.toString().padLeft(2, '0');
  final mm = d.minute.toString().padLeft(2, '0');
  return '${d.day} ${meses[d.month - 1]} · $hh:$mm';
}

// Una pregunta del examen, con sus opciones ya preparadas y su ámbito
class _Item {
  final Pregunta p;
  final String ambito; // id del ámbito o 'examen'
  final List<String> opciones;

  _Item(this.p, this.ambito)
    : opciones = p.opcionesFijas != null
          ? List.of(p.opcionesFijas!)
          : ([p.correcta, ...p.distractores]..shuffle());

  int get correcta => opciones.indexOf(p.correcta);
}

class SimulacroExamenScreen extends StatefulWidget {
  final List<(Pregunta, String)>
  bolsa; // todas las preguntas posibles + su ámbito
  final int cuantas;
  final int minutos; // 0 = sin límite · -1 = 1 min por pregunta
  final int penalizacion; // índice en `penalizaciones`

  const SimulacroExamenScreen({
    super.key,
    required this.bolsa,
    required this.cuantas,
    required this.minutos,
    required this.penalizacion,
  });

  @override
  State<SimulacroExamenScreen> createState() => _SimulacroExamenScreenState();
}

class _SimulacroExamenScreenState extends State<SimulacroExamenScreen> {
  late final List<_Item> _items;
  late final List<int> _respuestas; // -1 = en blanco
  late final List<bool> _marcadas; // marcadas para revisar
  int _i = 0;
  int _segundos = 0; // 0 = sin límite
  late final DateTime _inicio;
  Timer? _reloj;

  // Resultado
  bool _entregado = false;
  bool _porTiempo = false;
  int _ok = 0, _ko = 0, _bl = 0;
  double _neto = 0, _nota = 0;
  final Map<String, List<int>> _porAmbito = {}; // ámbito → [aciertos, total]
  String _filtro =
      'mal'; // 'mal' (fallos + blanco), 'ko' (solo fallos), 'todas'

  int get _n => _items.length;
  int get _quedan => _segundos - DateTime.now().difference(_inicio).inSeconds;

  String get _textoReloj {
    final q = max(0, _quedan);
    return '${q ~/ 60}:${(q % 60).toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    final bolsa = List.of(widget.bolsa)..shuffle();
    _items = bolsa.take(widget.cuantas).map((x) => _Item(x.$1, x.$2)).toList();
    _respuestas = List.filled(_items.length, -1);
    _marcadas = List.filled(_items.length, false);
    _inicio = DateTime.now();

    _segundos = widget.minutos == 0
        ? 0
        : (widget.minutos < 0 ? _items.length : widget.minutos) * 60;

    if (_segundos > 0) {
      _reloj = Timer.periodic(const Duration(milliseconds: 500), (_) {
        if (_quedan <= 0) {
          _entregar(porTiempo: true);
        } else {
          setState(() {});
        }
      });
    }
  }

  @override
  void dispose() {
    _reloj?.cancel();
    super.dispose();
  }

  // ==================== CORREGIR ====================
  void _entregar({bool porTiempo = false}) {
    if (_entregado) return;
    _reloj?.cancel();

    var ok = 0, ko = 0, bl = 0;
    final porAmbito = <String, List<int>>{};
    for (var k = 0; k < _n; k++) {
      final it = _items[k];
      final cuenta = porAmbito.putIfAbsent(it.ambito, () => [0, 0]);
      cuenta[1]++;
      final r = _respuestas[k];
      if (r < 0) {
        bl++;
      } else if (r == it.correcta) {
        ok++;
        cuenta[0]++;
        progreso.marcarDominada(it.p.id);
        progreso.quitarFallo(it.p.id);
      } else {
        ko++;
        progreso.registrarFallo(it.p);
      }
    }

    final pen = penalizaciones[widget.penalizacion].$1;
    final neto = max(0.0, ok - ko * pen);
    final nota = neto / _n * 10;

    progreso.guardarSimulacro({
      'fecha': fechaCorta(DateTime.now()),
      'n': _n,
      'ok': ok,
      'ko': ko,
      'bl': bl,
      'nota': nota,
    });
    progreso.sumarXP(ok);

    setState(() {
      _entregado = true;
      _porTiempo = porTiempo;
      _ok = ok;
      _ko = ko;
      _bl = bl;
      _neto = neto;
      _nota = nota;
      _porAmbito
        ..clear()
        ..addAll(porAmbito);
    });
  }

  // ==================== VENTANAS DE CONFIRMACIÓN ====================
  Future<void> _confirmarEntrega() async {
    final enBlanco = _respuestas.where((r) => r < 0).length;
    final marcadas = _marcadas.where((m) => m).length;

    final entregar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.panel,
        title: const Text('¿Entregar el examen?'),
        content: Text(
          '${_n - enBlanco}/$_n respondidas'
          '${enBlanco > 0 ? ' · $enBlanco en blanco' : ''}'
          '${marcadas > 0 ? ' · $marcadas marcadas para revisar' : ''}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Seguir revisando'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: cNaranja,
              foregroundColor: AppColors.fondo,
            ),
            child: const Text('Entregar'),
          ),
        ],
      ),
    );
    if (entregar == true) _entregar();
  }

  Future<bool> _confirmarSalida() async {
    final salir = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.panel,
        title: const Text('¿Salir del simulacro?'),
        content: const Text('Perderás las respuestas de este intento.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Seguir'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Salir', style: TextStyle(color: cRojo)),
          ),
        ],
      ),
    );
    return salir ?? false;
  }

  @override
  Widget build(BuildContext context) {
    // PopScope: si el examen no está entregado, pregunta antes de salir
    return PopScope(
      canPop: _entregado,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmarSalida() && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.fondo,
          foregroundColor: AppColors.texto,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(LucideIcons.x),
            onPressed: () =>
                Navigator.of(context).maybePop(), // pasa por el PopScope
          ),
          title: const Text(
            'Simulacro',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: cCyan,
            ),
          ),
        ),
        body: _entregado ? _resultado() : _examen(),
      ),
    );
  }

  // ==================== DURANTE EL EXAMEN ====================
  Widget _examen() {
    final it = _items[_i];
    final respondidas = _respuestas.where((r) => r >= 0).length;
    final pocoTiempo = _segundos > 0 && _quedan < 120;
    final estiloSecundario = OutlinedButton.styleFrom(
      foregroundColor: AppColors.texto,
      side: const BorderSide(color: AppColors.linea),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
      children: [
        // Reloj + respondidas + entregar
        Row(
          children: [
            if (_segundos > 0) ...[
              Icon(
                LucideIcons.clock,
                size: 16,
                color: pocoTiempo ? cRojo : AppColors.texto2,
              ),
              const SizedBox(width: 4),
              Text(
                _textoReloj,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: pocoTiempo ? cRojo : AppColors.texto,
                ),
              ),
              const SizedBox(width: 14),
            ],
            const Icon(LucideIcons.check, size: 16, color: cVerde),
            const SizedBox(width: 4),
            Text(
              '$respondidas/$_n',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _confirmarEntrega,
              icon: const Icon(LucideIcons.send, size: 16),
              label: const Text('Entregar'),
              style: TextButton.styleFrom(foregroundColor: cNaranja),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          'Pregunta ${_i + 1} de $_n',
          style: const TextStyle(fontSize: 12, color: AppColors.texto2),
        ),
        const SizedBox(height: 6),
        Text(
          it.p.enunciado,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 20),

        // Opciones: se marcan, pero NO se corrigen hasta entregar
        for (var k = 0; k < it.opciones.length; k++)
          _OpcionSim(
            letra: 'ABCD'[k],
            texto: it.opciones[k],
            elegida: _respuestas[_i] == k,
            onTap: () => setState(() => _respuestas[_i] = k),
          ),
        const SizedBox(height: 6),

        // Anterior · En blanco · Marcar
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: _i > 0 ? () => setState(() => _i--) : null,
              icon: const Icon(LucideIcons.arrowLeft, size: 16),
              label: const Text('Anterior'),
              style: estiloSecundario,
            ),
            OutlinedButton.icon(
              onPressed: _respuestas[_i] >= 0
                  ? () => setState(() => _respuestas[_i] = -1)
                  : null,
              icon: const Icon(LucideIcons.eraser, size: 16),
              label: const Text('En blanco'),
              style: estiloSecundario,
            ),
            OutlinedButton.icon(
              onPressed: () => setState(() => _marcadas[_i] = !_marcadas[_i]),
              icon: const Icon(LucideIcons.flag, size: 16),
              label: Text(_marcadas[_i] ? 'Marcada' : 'Marcar'),
              style: _marcadas[_i]
                  ? OutlinedButton.styleFrom(
                      foregroundColor: cNaranja,
                      side: const BorderSide(color: cNaranja),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    )
                  : estiloSecundario,
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _i + 1 < _n
                ? () => setState(() => _i++)
                : _confirmarEntrega,
            icon: Icon(
              _i + 1 < _n ? LucideIcons.arrowRight : LucideIcons.send,
              size: 18,
            ),
            iconAlignment: IconAlignment.end,
            label: Text(_i + 1 < _n ? 'Siguiente' : 'Revisar y entregar'),
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
        const SizedBox(height: 20),

        // Cuadrícula para saltar a cualquier pregunta
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.panel,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.linea),
          ),
          child: ExpansionTile(
            initiallyExpanded: _n <= 60,
            shape: const Border(),
            collapsedShape: const Border(),
            iconColor: cCyan,
            collapsedIconColor: AppColors.texto2,
            leading: const Icon(
              LucideIcons.layoutGrid,
              size: 18,
              color: AppColors.texto2,
            ),
            title: const Text(
              'Ver todas las preguntas',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
            children: [
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (var k = 0; k < _n; k++)
                    GestureDetector(
                      onTap: () => setState(() => _i = k),
                      child: Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _respuestas[k] >= 0
                              ? cCyan.withValues(alpha: 0.25)
                              : AppColors.fondo,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: k == _i
                                ? AppColors.texto
                                : (_marcadas[k] ? cNaranja : AppColors.linea),
                            width: (k == _i || _marcadas[k]) ? 2 : 1,
                          ),
                        ),
                        child: Text(
                          '${k + 1}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==================== RESULTADO ====================
  Widget _resultado() {
    final aprobado = _nota >= 5;
    final forma = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );

    // Qué preguntas enseñar en la revisión según el filtro
    final indices = [
      for (var k = 0; k < _n; k++)
        if (_filtro == 'todas' ||
            (_filtro == 'ko' &&
                _respuestas[k] >= 0 &&
                _respuestas[k] != _items[k].correcta) ||
            (_filtro == 'mal' && _respuestas[k] != _items[k].correcta))
          k,
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        Center(
          child: Text(
            _porTiempo ? '⏱️ Se acabó el tiempo' : '📨 Examen entregado',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.texto2,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Center(
          child: Text(
            _nota.toStringAsFixed(2).replaceAll('.', ','),
            style: GoogleFonts.unbounded(
              fontSize: 52,
              fontWeight: FontWeight.w800,
              color: aprobado ? cVerde : cRojo,
            ),
          ),
        ),
        Center(
          child: Text(
            'nota sobre 10 · ${penalizaciones[widget.penalizacion].$2.toLowerCase()}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: AppColors.texto2),
          ),
        ),
        const SizedBox(height: 18),

        // Aciertos, fallos, blancos, netos
        Row(
          children: [
            Expanded(
              child: _Dato(valor: '$_ok', etiqueta: 'aciertos', color: cVerde),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _Dato(valor: '$_ko', etiqueta: 'fallos', color: cRojo),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _Dato(
                valor: '$_bl',
                etiqueta: 'en blanco',
                color: AppColors.texto2,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _Dato(
                valor: _neto.toStringAsFixed(1).replaceAll('.', ','),
                etiqueta: 'netos',
                color: cCyan,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Resultado por ámbito
        Text(
          'Por ámbito',
          style: GoogleFonts.unbounded(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        for (final e in _porAmbito.entries)
          _FilaAmbito(ambito: e.key, ok: e.value[0], total: e.value[1]),
        const SizedBox(height: 18),

        // Botones
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => SimulacroExamenScreen(
                  bolsa: widget.bolsa,
                  cuantas: widget.cuantas,
                  minutos: widget.minutos,
                  penalizacion: widget.penalizacion,
                ),
              ),
            ),
            icon: const Icon(LucideIcons.rotateCcw, size: 18),
            label: const Text('Otro simulacro igual'),
            style: FilledButton.styleFrom(
              backgroundColor: cCyan,
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
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(LucideIcons.settings2, size: 18),
            label: const Text('Cambiar temas'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.texto,
              side: const BorderSide(color: AppColors.linea),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: forma,
            ),
          ),
        ),
        const SizedBox(height: 26),

        // Revisión
        Text(
          'Revisión',
          style: GoogleFonts.unbounded(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (clave, texto) in [
              ('mal', 'Fallos y en blanco (${_ko + _bl})'),
              ('ko', 'Solo fallos ($_ko)'),
              ('todas', 'Todas ($_n)'),
            ])
              GestureDetector(
                onTap: () => setState(() => _filtro = clave),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _filtro == clave ? cCyan : AppColors.panel,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _filtro == clave ? cCyan : AppColors.linea,
                    ),
                  ),
                  child: Text(
                    texto,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: _filtro == clave
                          ? AppColors.fondo
                          : AppColors.texto,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        if (indices.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'Nada que revisar aquí. ¡Muy bien! 💪',
                style: TextStyle(color: AppColors.texto2),
              ),
            ),
          )
        else
          for (final k in indices)
            _FilaRevision(
              numero: k + 1,
              item: _items[k],
              respuesta: _respuestas[k],
            ),
      ],
    );
  }
}

// Opción del simulacro: se puede elegir, pero no se corrige
class _OpcionSim extends StatelessWidget {
  final String letra;
  final String texto;
  final bool elegida;
  final VoidCallback onTap;

  const _OpcionSim({
    required this.letra,
    required this.texto,
    required this.elegida,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: elegida ? cCyan.withValues(alpha: 0.12) : AppColors.panel,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: elegida ? cCyan : AppColors.linea,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: elegida ? cCyan : AppColors.linea,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    letra,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: elegida ? AppColors.fondo : AppColors.texto2,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    texto,
                    style: const TextStyle(fontSize: 15, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Cajita de dato del resultado
class _Dato extends StatelessWidget {
  final String valor;
  final String etiqueta;
  final Color color;

  const _Dato({
    required this.valor,
    required this.etiqueta,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.linea),
      ),
      child: Column(
        children: [
          Text(
            valor,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            etiqueta,
            style: const TextStyle(fontSize: 11, color: AppColors.texto2),
          ),
        ],
      ),
    );
  }
}

// Barra de resultado de un ámbito
class _FilaAmbito extends StatelessWidget {
  final String ambito;
  final int ok;
  final int total;

  const _FilaAmbito({
    required this.ambito,
    required this.ok,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    Ambito? a;
    for (final x in ambitos) {
      if (x.id == ambito) a = x;
    }
    final color = a?.color ?? cNaranja;
    final nombre = a?.nombre ?? 'Examen oficial';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              nombre,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12.5),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: total == 0 ? 0 : ok / total,
                minHeight: 8,
                backgroundColor: AppColors.linea,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$ok/$total',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

// Una pregunta en la revisión: correcta en verde, tu respuesta errónea en rojo
class _FilaRevision extends StatelessWidget {
  final int numero;
  final _Item item;
  final int respuesta;

  const _FilaRevision({
    required this.numero,
    required this.item,
    required this.respuesta,
  });

  @override
  Widget build(BuildContext context) {
    final buena = item.correcta;
    final (colorEstado, iconoEstado) = respuesta < 0
        ? (AppColors.texto2, LucideIcons.eraser)
        : (respuesta == buena
              ? (cVerde, LucideIcons.circleCheck)
              : (cRojo, LucideIcons.circleX));

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorEstado.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(iconoEstado, size: 18, color: colorEstado),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$numero. ${item.p.enunciado}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (var j = 0; j < item.opciones.length; j++)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '${'ABCD'[j]}  ${item.opciones[j]}',
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.35,
                  fontWeight: j == buena ? FontWeight.w800 : FontWeight.w400,
                  color: j == buena
                      ? cVerde
                      : (j == respuesta ? cRojo : AppColors.texto2),
                  decoration: (j == respuesta && j != buena)
                      ? TextDecoration.lineThrough
                      : null,
                ),
              ),
            ),
          if (respuesta < 0)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                'Dejada en blanco',
                style: TextStyle(fontSize: 12, color: AppColors.texto2),
              ),
            ),
          if (respuesta != buena && item.p.explicacion.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '💡 ${item.p.explicacion}',
              style: const TextStyle(
                fontSize: 13,
                height: 1.4,
                color: AppColors.texto2,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
