import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../data/entreno.dart';
import '../data/progreso.dart';
import '../theme/app_theme.dart';

class OrdenaScreen extends StatefulWidget {
  final Color color;

  const OrdenaScreen({super.key, required this.color});

  @override
  State<OrdenaScreen> createState() => _OrdenaScreenState();
}

class _OrdenaScreenState extends State<OrdenaScreen> {
  // Las 31 secuencias del entreno.json
  late final List<Map<String, dynamic>> _secuencias =
      (datosEntreno['secuencias'] as List).cast<Map<String, dynamic>>();

  int? _k; // secuencia elegida (null = eligiendo)
  List<int> _orden =
      []; // el orden actual, con la posición CORRECTA de cada paso
  bool _comprobado = false;

  List<String> get _pasos => (_secuencias[_k!]['s'] as List).cast<String>();

  bool _estaOrdenado(List<int> o) {
    for (var i = 0; i < o.length; i++) {
      if (o[i] != i) return false;
    }
    return true;
  }

  int get _enSuSitio => [
    for (var i = 0; i < _orden.length; i++)
      if (_orden[i] == i) i,
  ].length;

  void _empezar(int k) {
    final n = (_secuencias[k]['s'] as List).length;
    final orden = List.generate(n, (i) => i)..shuffle();
    // Que nunca empiece ya ordenado
    while (n > 1 && _estaOrdenado(orden)) {
      orden.shuffle();
    }
    setState(() {
      _k = k;
      _orden = orden;
      _comprobado = false;
    });
  }

  // Al soltar un paso en otra posición
  void _mover(int desde, int hasta) {
    setState(() {
      var destino = hasta;
      if (destino > desde) destino--; // ajuste necesario al bajar un elemento
      final paso = _orden.removeAt(desde);
      _orden.insert(destino, paso);
    });
  }

  void _comprobar() {
    if (_estaOrdenado(_orden)) {
      progreso.guardarRecord(
        'ordena.$_k',
        1,
      ); // marca la secuencia como superada
      progreso.sumarXP(5);
      HapticFeedback.lightImpact();
    } else {
      progreso.sumarXP(max(0, _enSuSitio - 1));
      HapticFeedback.heavyImpact();
    }
    setState(() => _comprobado = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.fondo,
        foregroundColor: AppColors.texto,
        scrolledUnderElevation: 0,
        title: Text(
          _k == null ? 'Ordena los pasos' : _secuencias[_k!]['t'] as String,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: widget.color,
          ),
        ),
      ),
      body: _k == null ? _lista() : (_comprobado ? _resultado() : _ordenar()),
    );
  }

  // ==================== ELEGIR SECUENCIA ====================
  Widget _lista() {
    final superadas = [
      for (var k = 0; k < _secuencias.length; k++)
        if (progreso.record('ordena.$k') > 0) k,
    ].length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
      children: [
        Text(
          'Elige una secuencia',
          style: GoogleFonts.unbounded(
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Los pasos salen desordenados. Arrástralos hasta dejarlos en orden y pulsa Comprobar. '
          'Llevas $superadas de ${_secuencias.length} superadas.',
          style: const TextStyle(height: 1.4, color: AppColors.texto2),
        ),
        const SizedBox(height: 18),
        for (var k = 0; k < _secuencias.length; k++)
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
                              _secuencias[k]['t'] as String,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              '${(_secuencias[k]['s'] as List).length} pasos · ${_secuencias[k]['src']}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.texto2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (progreso.record('ordena.$k') > 0)
                        const Icon(
                          LucideIcons.badgeCheck,
                          color: cVerde,
                          size: 20,
                        )
                      else
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

  // ==================== ORDENANDO ====================
  Widget _ordenar() {
    final pasos = _pasos;
    final c = widget.color;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _secuencias[_k!]['src'] as String,
                style: TextStyle(fontSize: 12, color: c),
              ),
              const SizedBox(height: 4),
              Text(
                'Ordena los ${pasos.length} pasos',
                style: GoogleFonts.unbounded(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Arrastra desde el asa ⠿ (o mantén pulsado un paso) para moverlo.',
                style: TextStyle(fontSize: 12, color: AppColors.texto2),
              ),
            ],
          ),
        ),
        // La lista que se puede reordenar arrastrando
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            buildDefaultDragHandles: false, // ponemos nuestras propias asas
            itemCount: _orden.length,
            onReorder: _mover,
            itemBuilder: (context, i) => ReorderableDelayedDragStartListener(
              key: ValueKey(
                _orden[i],
              ), // cada paso necesita una "etiqueta" única
              index: i,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
                  decoration: BoxDecoration(
                    color: AppColors.panel,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.linea),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: c.withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${i + 1}',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: c,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          pasos[_orden[i]],
                          style: const TextStyle(height: 1.35),
                        ),
                      ),
                      // El asa: arrastra al momento, sin esperar
                      ReorderableDragStartListener(
                        index: i,
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(
                            LucideIcons.gripVertical,
                            color: AppColors.texto2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _comprobar,
                icon: const Icon(LucideIcons.check, size: 18),
                label: const Text('Comprobar'),
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
          ),
        ),
      ],
    );
  }

  // ==================== RESULTADO ====================
  Widget _resultado() {
    final pasos = _pasos;
    final perfecto = _estaOrdenado(_orden);
    final c = widget.color;
    final forma = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
      children: [
        Text(
          perfecto ? '¡Orden perfecto! 🎉' : 'Así lo has dejado',
          style: GoogleFonts.unbounded(
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          perfecto ? '+5 XP' : '$_enSuSitio de ${pasos.length} en su sitio',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: perfecto ? cVerde : cRojo,
          ),
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < _orden.length; i++)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (_orden[i] == i ? cVerde : cRojo).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _orden[i] == i ? cVerde : cRojo),
            ),
            child: Row(
              children: [
                Text(
                  '${i + 1}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    pasos[_orden[i]],
                    style: const TextStyle(height: 1.35),
                  ),
                ),
                const SizedBox(width: 8),
                if (_orden[i] == i)
                  const Icon(LucideIcons.check, color: cVerde, size: 18)
                else
                  Text(
                    'es el ${_orden[i] + 1}.º',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: cRojo,
                    ),
                  ),
              ],
            ),
          ),
        if (!perfecto) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cAmarillo.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cAmarillo.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '💡 Orden correcto',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                for (var i = 0; i < pasos.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '${i + 1}. ${pasos[i]}',
                      style: const TextStyle(height: 1.35),
                    ),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => _empezar((_k! + 1) % _secuencias.length),
            icon: const Icon(LucideIcons.arrowRight, size: 18),
            iconAlignment: IconAlignment.end,
            label: const Text('Otra secuencia'),
            style: FilledButton.styleFrom(
              backgroundColor: c,
              foregroundColor: AppColors.fondo,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: forma,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _empezar(_k!),
                icon: const Icon(LucideIcons.rotateCcw, size: 16),
                label: const Text('Repetir'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.texto,
                  side: const BorderSide(color: AppColors.linea),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: forma,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => setState(() => _k = null),
                icon: const Icon(LucideIcons.listOrdered, size: 16),
                label: const Text('Lista'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.texto,
                  side: const BorderSide(color: AppColors.linea),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: forma,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
