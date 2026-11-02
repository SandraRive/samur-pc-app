import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../data/ambitos.dart';
import '../data/manual.dart';
import '../theme/app_theme.dart';
import '../widgets/ficha_farmaco.dart';
import '../widgets/filtro_chip.dart';

class VademecumScreen extends StatefulWidget {
  final Ambito ambito;

  const VademecumScreen({super.key, required this.ambito});

  @override
  State<VademecumScreen> createState() => _VademecumScreenState();
}

class _VademecumScreenState extends State<VademecumScreen> {
  int _pestana = 0; // 0 = Fármacos, 1 = Abreviaturas
  String _busqueda = '';
  String? _letra; // null = todas
  final _controlador =
      TextEditingController(); // controla el texto del buscador

  @override
  void dispose() {
    _controlador.dispose(); // libera el controlador al salir de la pantalla
    super.dispose();
  }

  void _cambiarPestana(int nueva) {
    setState(() {
      _pestana = nueva;
      _busqueda = '';
      _letra = null;
    });
    _controlador.clear(); // vacía el buscador al cambiar de pestaña
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.ambito.color;
    final q = normalizar(_busqueda.trim());
    final espacioArriba = MediaQuery.paddingOf(context).top + kToolbarHeight;

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
        child: ListView(
          padding: EdgeInsets.fromLTRB(20, espacioArriba + 8, 20, 24),
          children: [
            // ---------- CABECERA ----------
            Align(
              alignment: Alignment.centerLeft,
              child: Hero(
                tag: 'icono-${widget.ambito.id}',
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: c.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: c.withValues(alpha: 0.4)),
                  ),
                  child: Icon(widget.ambito.icono, color: c, size: 36),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _pestana == 0 ? 'Vademécum' : 'Abreviaturas',
              style: GoogleFonts.unbounded(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppColors.texto,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _pestana == 0
                  ? 'Relación de fármacos empleados por SAMUR-Protección Civil en las dosis e indicaciones más habituales. Toca una ficha para abrirla.'
                  : 'Las siglas del manual y su significado.',
              style: const TextStyle(
                fontSize: 15,
                height: 1.4,
                color: AppColors.texto2,
              ),
            ),
            const SizedBox(height: 20),

            // ---------- PESTAÑAS ----------
            Row(
              children: [
                FiltroChip(
                  icono: LucideIcons.pill,
                  texto: 'Fármacos',
                  total: manual.farmacos.length,
                  color: c,
                  activo: _pestana == 0,
                  onTap: () => _cambiarPestana(0),
                ),
                FiltroChip(
                  icono: LucideIcons.bookA,
                  texto: 'Abreviaturas',
                  total: manual.abreviaturas.length,
                  color: c,
                  activo: _pestana == 1,
                  onTap: () => _cambiarPestana(1),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ---------- BUSCADOR ----------
            TextField(
              controller: _controlador,
              onChanged: (texto) => setState(() => _busqueda = texto),
              style: const TextStyle(color: AppColors.texto),
              decoration: InputDecoration(
                hintText: _pestana == 0
                    ? 'Filtra por nombre, indicación o efecto…'
                    : 'Busca una sigla o su significado…',
                hintStyle: const TextStyle(color: AppColors.texto2),
                prefixIcon: const Icon(
                  LucideIcons.search,
                  size: 18,
                  color: AppColors.texto2,
                ),
                filled: true,
                fillColor: AppColors.panel,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.linea),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: c, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // ---------- CONTENIDO DE LA PESTAÑA ----------
            if (_pestana == 0) ..._farmacos(c, q) else ..._abreviaturas(c, q),
          ],
        ),
      ),
    );
  }

  // Letras A–Z + lista de fármacos filtrada
  List<Widget> _farmacos(Color c, String q) {
    final letrasConFarmacos = manual.farmacos.map((f) => f.letra).toSet();
    final indices = [
      for (var i = 0; i < manual.farmacos.length; i++)
        if ((_letra == null || manual.farmacos[i].letra == _letra) &&
            (q.isEmpty || manual.farmacos[i].textoBusqueda.contains(q)))
          i,
    ];

    return [
      // Fila de letras
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _Letra(
              texto: '·',
              color: c,
              activa: _letra == null,
              habilitada: true,
              onTap: () => setState(() => _letra = null),
            ),
            for (final l in 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split(''))
              _Letra(
                texto: l,
                color: c,
                activa: _letra == l,
                habilitada: letrasConFarmacos.contains(l),
                onTap: () => setState(() => _letra = l),
              ),
          ],
        ),
      ),
      const SizedBox(height: 16),

      if (indices.isEmpty)
        const _SinResultados(texto: 'No hay fármacos con ese filtro.')
      else
        for (final i in indices) _TarjetaFarmaco(indice: i, color: c),
    ];
  }

  // Lista de abreviaturas filtrada
  List<Widget> _abreviaturas(Color c, String q) {
    final lista = manual.abreviaturas
        .where(
          (a) =>
              q.isEmpty ||
              normalizar('${a.sigla} ${a.significado}').contains(q),
        )
        .toList();

    if (lista.isEmpty) return [const _SinResultados(texto: 'Sin resultados.')];

    return [
      for (final a in lista)
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.panel,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.linea),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 90,
                child: Text(
                  a.sigla,
                  style: TextStyle(fontWeight: FontWeight.w800, color: c),
                ),
              ),
              Expanded(
                child: Text(
                  a.significado,
                  style: const TextStyle(height: 1.35),
                ),
              ),
            ],
          ),
        ),
    ];
  }
}

// Botón de una letra del filtro A–Z
class _Letra extends StatelessWidget {
  final String texto;
  final Color color;
  final bool activa;
  final bool habilitada;
  final VoidCallback onTap;

  const _Letra({
    required this.texto,
    required this.color,
    required this.activa,
    required this.habilitada,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Opacity(
        opacity: habilitada ? 1 : 0.3, // letras sin fármacos, apagadas
        child: GestureDetector(
          onTap: habilitada ? onTap : null, // si está apagada, no hace nada
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: activa ? color : AppColors.panel,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: activa ? color : AppColors.linea),
            ),
            child: Text(
              texto,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: activa ? AppColors.fondo : AppColors.texto,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Tarjeta de un fármaco en la lista
class _TarjetaFarmaco extends StatelessWidget {
  final int indice;
  final Color color;

  const _TarjetaFarmaco({required this.indice, required this.color});

  @override
  Widget build(BuildContext context) {
    final f = manual.farmacos[indice];

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => abrirFicha(context, indice),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.linea),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(LucideIcons.pill, size: 18, color: color),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        f.nombre,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        f.funcion,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.texto2,
                        ),
                      ),
                    ],
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

// Mensaje cuando el filtro no encuentra nada
class _SinResultados extends StatelessWidget {
  final String texto;

  const _SinResultados({required this.texto});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Text(texto, style: const TextStyle(color: AppColors.texto2)),
      ),
    );
  }
}
