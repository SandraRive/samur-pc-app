import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../data/entreno.dart';
import '../data/progreso.dart';
import '../theme/app_theme.dart';
import '../widgets/carta_giratoria.dart';

class TarjetasScreen extends StatefulWidget {
  final Color color;

  const TarjetasScreen({super.key, required this.color});

  @override
  State<TarjetasScreen> createState() => _TarjetasScreenState();
}

class _TarjetasScreenState extends State<TarjetasScreen> {
  bool _enSesion = false;
  FuenteTarjetas? _fuente; // mazo de la sesión (null en el repaso de hoy)
  bool _mezcla = false; // true = repaso de hoy (todos los mazos)
  List<Tarjeta> _cola = [];
  int _i = 0;
  int _sabidas = 0;
  bool _girada = false;
  bool _terminada = false;
  final Map<String, String> _origen = {}; // tarjeta → nombre de su mazo

  // Tarjetas ya empezadas que tocan hoy, de todos los mazos
  List<Tarjeta> _pendientesHoy() {
    final salida = <Tarjeta>[];
    for (final f in fuentesTarjetas) {
      for (final t in f.tarjetas) {
        if (progreso.empezada(t.id) && progreso.tocaHoy(t.id)) {
          salida.add(t);
          _origen[t.id] = f.titulo;
        }
      }
    }
    return salida;
  }

  void _empezarSesion(
    List<Tarjeta> tarjetas, {
    required bool mezcla,
    FuenteTarjetas? fuente,
  }) {
    final aTocar = tarjetas.where((t) => progreso.tocaHoy(t.id)).toList();
    // Primero las que ya has visto (las de caja más baja antes), luego nuevas
    final vistas = aTocar.where((t) => progreso.empezada(t.id)).toList()
      ..shuffle()
      ..sort(
        (a, b) => progreso.cajaDe(a.id)!.compareTo(progreso.cajaDe(b.id)!),
      );
    final nuevas = aTocar.where((t) => !progreso.empezada(t.id)).toList()
      ..shuffle();

    setState(() {
      _enSesion = true;
      _fuente = fuente;
      _mezcla = mezcla;
      _cola = [...vistas, ...nuevas].take(mezcla ? 40 : 20).toList();
      _i = 0;
      _sabidas = 0;
      _girada = false;
      _terminada = _cola.isEmpty;
    });
  }

  void _valorar(bool sabia) {
    final t = _cola[_i];
    progreso.valorarTarjeta(t.id, sabia);
    if (sabia) {
      _sabidas++;
      progreso.marcarDominada(t.id);
    } else if (_mezcla) {
      // En el repaso de hoy, la que fallas vuelve a salir 4 tarjetas después
      _cola.insert(min(_cola.length, _i + 4), t);
    }

    if (_i + 1 >= _cola.length) {
      setState(() => _terminada = true);
      progreso.sumarXP(_sabidas);
      return;
    }
    setState(() {
      _i++;
      _girada = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Si estás en una sesión, "atrás" vuelve a la lista de mazos
    return PopScope(
      canPop: !_enSesion,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _enSesion = false);
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.fondo,
          foregroundColor: AppColors.texto,
          scrolledUnderElevation: 0,
          title: Text(
            !_enSesion
                ? 'Tarjetas'
                : (_mezcla ? 'Repaso de hoy' : _fuente!.titulo),
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: widget.color,
            ),
          ),
        ),
        body: ListenableBuilder(
          listenable: progreso,
          builder: (context, _) => !_enSesion
              ? _portada()
              : (_terminada ? _resultado() : _tarjeta()),
        ),
      ),
    );
  }

  // Las 5 cajas con cuántas tarjetas hay en cada una
  Widget _cajas(Iterable<Tarjeta> tarjetas) {
    final n = List.filled(5, 0);
    for (final t in tarjetas) {
      final c = progreso.cajaDe(t.id);
      if (c != null) n[c - 1]++;
    }
    return Row(
      children: [
        for (var k = 0; k < 5; k++)
          Expanded(
            child: Container(
              margin: EdgeInsets.only(right: k < 4 ? 6 : 0),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.panel,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.linea),
              ),
              child: Column(
                children: [
                  Text(
                    '${n[k]}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Caja ${k + 1}',
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: AppColors.texto2,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // ==================== PORTADA ====================
  Widget _portada() {
    final hoy = _pendientesHoy();
    final c = widget.color;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
      children: [
        Text(
          'Repaso espaciado',
          style: GoogleFonts.unbounded(
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Cada tarjeta empieza en la caja 1. Si la sabes, sube de caja y tarda más en volver: '
          'al día siguiente, a los 3, 7 y 14 días. Si la fallas, vuelve a la caja 1. '
          'Entra un ratito cada día y haz el «Repaso de hoy».',
          style: TextStyle(height: 1.4, color: AppColors.texto2),
        ),
        const SizedBox(height: 16),

        // Repaso de hoy
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: c.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: c.withValues(alpha: 0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                hoy.isEmpty
                    ? 'Hoy no tienes repasos pendientes'
                    : '${hoy.length} ${hoy.length == 1 ? 'tarjeta te toca' : 'tarjetas te tocan'} hoy',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                hoy.isEmpty
                    ? 'Empieza un mazo nuevo o adelanta tarjetas de los que ya tienes.'
                    : 'Mezcla todos los mazos que ya has empezado. Primero lo que más te cuesta.',
                style: const TextStyle(
                  fontSize: 12.5,
                  height: 1.4,
                  color: AppColors.texto2,
                ),
              ),
              if (hoy.isNotEmpty) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _empezarSesion(hoy, mezcla: true),
                    icon: const Icon(LucideIcons.calendarCheck, size: 18),
                    label: const Text('Repaso de hoy'),
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
          ),
        ),
        const SizedBox(height: 12),
        _cajas(fuentesTarjetas.expand((f) => f.tarjetas)),

        for (final (titulo, deMazo) in [
          ('Claves, códigos y escalas', true),
          ('Preguntas del manual por bloque', false),
        ]) ...[
          const SizedBox(height: 22),
          Text(
            titulo,
            style: GoogleFonts.unbounded(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          for (final f in fuentesTarjetas.where((f) => f.deMazo == deMazo))
            _filaFuente(f),
        ],
      ],
    );
  }

  Widget _filaFuente(FuenteTarjetas f) {
    final empezadas = f.tarjetas.where((t) => progreso.empezada(t.id)).length;
    final paraHoy = f.tarjetas.where((t) => progreso.tocaHoy(t.id)).length;
    final dominadas = f.tarjetas
        .where((t) => (progreso.cajaDe(t.id) ?? 0) >= 4)
        .length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _empezarSesion(f.tarjetas, mezcla: false, fuente: f),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.linea),
            ),
            child: Row(
              children: [
                Icon(f.icono, size: 18, color: f.color),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        f.titulo,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '${f.tarjetas.length} tarjetas${empezadas > 0 ? ' · $paraHoy para hoy' : ''}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.texto2,
                        ),
                      ),
                      if (empezadas > 0) ...[
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: dominadas / f.tarjetas.length,
                            minHeight: 4,
                            backgroundColor: AppColors.linea,
                            color: f.color,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
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

  // ==================== SESIÓN ====================
  Widget _tarjeta() {
    final t = _cola[_i];
    final c = _fuente?.color ?? widget.color;
    final caja = progreso.cajaDe(t.id);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
      children: [
        Row(
          children: [
            Text(
              '${_i + 1}/${_cola.length}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: _i / _cola.length,
                  minHeight: 6,
                  backgroundColor: AppColors.linea,
                  color: c,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Icon(LucideIcons.check, size: 16, color: cVerde),
            Text(
              ' $_sabidas',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // La tarjeta: se gira al tocarla
        GestureDetector(
          onTap: () => setState(() => _girada = !_girada),
          child: SizedBox(
            height: 330,
            child: CartaGiratoria(
              girada: _girada,
              frente: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: c.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: c.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      _mezcla
                          ? (_origen[t.id] ?? '')
                          : 'Toca para ver la respuesta',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.texto2,
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          child: Text(
                            t.frente,
                            textAlign: TextAlign.center,
                            style: t.esClave
                                ? GoogleFonts.unbounded(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    color: c,
                                  )
                                : const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    height: 1.35,
                                  ),
                          ),
                        ),
                      ),
                    ),
                    Text(
                      caja == null ? 'Nueva' : 'Caja $caja',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.texto2,
                      ),
                    ),
                  ],
                ),
              ),
              dorso: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.panel,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: c, width: 1.5),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'RESPUESTA',
                        style: TextStyle(
                          fontSize: 11,
                          letterSpacing: 1.5,
                          color: AppColors.texto2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        t.dorso,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          height: 1.35,
                        ),
                      ),
                      if (t.explicacion.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          t.explicacion,
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color: AppColors.texto2,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Botones de valorar (solo después de girar)
        if (_girada)
          Row(
            children: [
              Expanded(
                child: _boton(
                  'No lo sabía',
                  LucideIcons.x,
                  cRojo,
                  () => _valorar(false),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _boton(
                  'Lo sabía',
                  LucideIcons.check,
                  cVerde,
                  () => _valorar(true),
                ),
              ),
            ],
          )
        else
          const Center(
            child: Text(
              'Toca la tarjeta para darle la vuelta 🔄',
              style: TextStyle(color: AppColors.texto2),
            ),
          ),
        const SizedBox(height: 22),
        _cajas(_mezcla ? _cola : _fuente!.tarjetas),
      ],
    );
  }

  Widget _boton(String texto, IconData icono, Color color, VoidCallback onTap) {
    return FilledButton.icon(
      onPressed: onTap,
      icon: Icon(icono, size: 18),
      label: Text(texto),
      style: FilledButton.styleFrom(
        backgroundColor: color,
        foregroundColor: AppColors.fondo,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ==================== RESULTADO ====================
  Widget _resultado() {
    final c = _fuente?.color ?? widget.color;
    final forma = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        Icon(LucideIcons.trophy, size: 52, color: c),
        const SizedBox(height: 6),
        const Center(
          child: Text(
            'Sesión terminada',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        Center(
          child: Text(
            '$_sabidas/${_cola.length}',
            style: GoogleFonts.unbounded(
              fontSize: 44,
              fontWeight: FontWeight.w800,
              color: c,
            ),
          ),
        ),
        Center(
          child: Text(
            _cola.isEmpty
                ? 'No tienes tarjetas pendientes hoy aquí.'
                : 'tarjetas que ya sabías · +$_sabidas XP',
            style: const TextStyle(color: AppColors.texto2),
          ),
        ),
        const SizedBox(height: 18),
        _cajas(_mezcla ? _cola : _fuente!.tarjetas),
        const SizedBox(height: 22),
        if (!_mezcla) ...[
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                progreso.adelantar(_fuente!.tarjetas.map((t) => t.id));
                _empezarSesion(
                  _fuente!.tarjetas,
                  mezcla: false,
                  fuente: _fuente,
                );
              },
              icon: const Icon(LucideIcons.plus, size: 18),
              label: const Text('Seguir con este mazo'),
              style: FilledButton.styleFrom(
                backgroundColor: c,
                foregroundColor: AppColors.fondo,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: forma,
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => setState(() => _enSesion = false),
            icon: const Icon(LucideIcons.layers2, size: 18),
            label: const Text('Volver a los mazos'),
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
