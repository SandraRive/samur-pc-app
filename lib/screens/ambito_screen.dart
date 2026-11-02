import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../data/ambitos.dart';
import '../data/manual.dart';
import '../theme/app_theme.dart';
import '../theme/iconos.dart';
import '../widgets/procedimiento_card.dart';
import '../widgets/filtro_chip.dart';
import '../data/progreso.dart';

// StatefulWidget porque recuerda qué chip está seleccionado
class AmbitoScreen extends StatefulWidget {
  final Ambito ambito;

  const AmbitoScreen({super.key, required this.ambito});

  @override
  State<AmbitoScreen> createState() => _AmbitoScreenState();
}

class _AmbitoScreenState extends State<AmbitoScreen> {
  String? _filtro; // null = "Todo"; si no, el nombre del bloque elegido

  @override
  Widget build(BuildContext context) {
    final ambito = widget.ambito; // en un State, los datos se leen con widget.
    final c = ambito.color;
    final grupos = manual.grupos(ambito.id);
    final visibles = _filtro == null
        ? grupos
        : grupos.where((g) => g.nombre == _filtro).toList();
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
                height: 1.15,
                color: AppColors.texto,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              ambito.descripcion,
              style: const TextStyle(
                fontSize: 15,
                height: 1.4,
                color: AppColors.texto2,
              ),
            ),
            const SizedBox(height: 24),

            // ---------- CONTENIDO ----------
            if (grupos.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.panel,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.linea),
                ),
                child: const Text(
                  '🚧 Muy pronto: esta sección tendrá su propia pantalla.',
                  style: TextStyle(color: AppColors.texto2, height: 1.4),
                ),
              )
            else ...[
              // Fila de chips con scroll lateral
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FiltroChip(
                      icono: LucideIcons.layers,
                      texto: 'Todo',
                      total: manual.totalDe(ambito.id),
                      color: c,
                      activo: _filtro == null,
                      onTap: () => setState(() => _filtro = null),
                    ),
                    for (final g in grupos)
                      FiltroChip(
                        icono: iconoWeb(g.icono),
                        texto: g.nombre,
                        total: manual
                            .procedimientosDe(ambito.id, g.nombre)
                            .length,
                        color: c,
                        activo: _filtro == g.nombre,
                        onTap: () => setState(() => _filtro = g.nombre),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Una sección por cada bloque visible
              for (final g in visibles) ...[
                _CabeceraGrupo(
                  icono: iconoWeb(g.icono),
                  nombre: g.nombre,
                  procs: manual.procedimientosDe(ambito.id, g.nombre),
                  color: c,
                ),
                for (final p in manual.procedimientosDe(ambito.id, g.nombre))
                  ProcedimientoCard(
                    proc: p,
                    ambito: ambito,
                    icono: iconoWeb(g.icono),
                  ),
                const SizedBox(height: 18),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

// Título de cada bloque: icono + nombre + progreso (estudiados/total)
class _CabeceraGrupo extends StatelessWidget {
  final IconData icono;
  final String nombre;
  final List<Procedimiento> procs;
  final Color color;

  const _CabeceraGrupo({
    required this.icono,
    required this.nombre,
    required this.procs,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icono, size: 20, color: color),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              nombre,
              style: GoogleFonts.unbounded(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.texto,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Se actualiza solo al marcar/desmarcar
          ListenableBuilder(
            listenable: progreso,
            builder: (context, _) => Text(
              '${progreso.cuantosEstudiados(procs)}/${procs.length}',
              style: const TextStyle(fontSize: 12, color: AppColors.texto2),
            ),
          ),
        ],
      ),
    );
  }
}
