import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../data/entreno.dart';
import '../data/nube.dart';
import '../data/progreso.dart';
import '../theme/app_theme.dart';

class CuentaScreen extends StatelessWidget {
  const CuentaScreen({super.key});

  // ---------- FOTO ----------
  Future<void> _cambiarFoto(BuildContext context) async {
    final origen = await showModalBottomSheet<ImageSource?>(
      context: context,
      backgroundColor: AppColors.panel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(LucideIcons.image),
              title: const Text('Elegir de la galería'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(LucideIcons.camera),
              title: const Text('Hacer una foto'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
            ),
            if (progreso.foto != null)
              ListTile(
                leading: const Icon(LucideIcons.trash2, color: cRojo),
                title: const Text(
                  'Quitar la foto',
                  style: TextStyle(color: cRojo),
                ),
                onTap: () {
                  progreso.cambiarFoto(null);
                  Navigator.of(ctx).pop();
                },
              ),
          ],
        ),
      ),
    );
    if (origen == null) return;

    // Pequeña y comprimida: así cabe en la base de datos gratis
    final foto = await ImagePicker().pickImage(
      source: origen,
      maxWidth: 300,
      maxHeight: 300,
      imageQuality: 70,
    );
    if (foto == null) return; // cancelaste
    progreso.cambiarFoto(await foto.readAsBytes());
  }

  // ---------- BORRAR DATOS ----------
  Future<void> _borrarDatos(BuildContext context) async {
    final palabra = TextEditingController();
    final confirmado = await showDialog<bool>(
      context: context,
      // StatefulBuilder: un trocito con "memoria" (para activar el botón al escribir)
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, actualizar) {
          final listo = palabra.text.trim().toUpperCase() == 'BORRAR';
          return AlertDialog(
            backgroundColor: AppColors.panel,
            title: const Text('¿Empezar de cero?'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Se borrará TODO tu progreso: XP, rango, estudiados, preguntas dominadas, '
                  'fallos, tarjetas, récords y simulacros. También en la nube. '
                  'No se puede deshacer.',
                  style: TextStyle(height: 1.4),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Escribe BORRAR para confirmar:',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: palabra,
                  textCapitalization: TextCapitalization.characters,
                  onChanged: (_) => actualizar(() {}),
                  decoration: const InputDecoration(hintText: 'BORRAR'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: listo
                    ? () => Navigator.of(ctx).pop(true)
                    : null, // apagado hasta escribirlo
                child: Text(
                  'Borrar todo',
                  style: TextStyle(color: listo ? cRojo : AppColors.texto2),
                ),
              ),
            ],
          );
        },
      ),
    );
    if (confirmado != true) return;
    progreso.reiniciarProgreso();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('🧹 Progreso borrado. ¡A empezar de cero!')),
    );
  }

  // ---------- CERRAR SESIÓN ----------
  Future<void> _cerrarSesion(BuildContext context) async {
    final seguro = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.panel,
        title: const Text('¿Cerrar sesión?'),
        content: const Text(
          'Tu progreso está a salvo en la nube. Al volver a entrar, lo recuperarás.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Cerrar sesión', style: TextStyle(color: cRojo)),
          ),
        ],
      ),
    );
    if (seguro != true) return;
    await FirebaseAuth.instance.signOut();
    progreso.vaciarAlCerrarSesion(); // el móvil queda limpio para la siguiente cuenta
    if (!context.mounted) return;
    Navigator.of(context)
        .popUntil((ruta) => ruta.isFirst); // vuelve al inicio (la bienvenida)
  }

  @override
  Widget build(BuildContext context) {
    final usuario = FirebaseAuth.instance.currentUser;
    if (usuario == null)
      return const Scaffold(); // un instante al cerrar sesión
    final email = usuario.email ?? '';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.fondo,
        foregroundColor: AppColors.texto,
        scrolledUnderElevation: 0,
        title: const Text(
          'Tu cuenta',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListenableBuilder(
        listenable: progreso,
        builder: (context, _) {
          final foto = progreso.foto;
          final nombre = progreso.alias.isNotEmpty ? progreso.alias : email;
          final inicial = nombre.isEmpty ? '?' : nombre[0].toUpperCase();

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              // Foto (toca para cambiarla)
              Center(
                child: GestureDetector(
                  onTap: () => _cambiarFoto(context),
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: AppColors.naranja,
                        backgroundImage: foto != null
                            ? MemoryImage(foto)
                            : null,
                        child: foto == null
                            ? Text(
                                inicial,
                                style: GoogleFonts.unbounded(
                                  fontSize: 34,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.fondo,
                                ),
                              )
                            : null,
                      ),
                      // Iconito de cámara en la esquina
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: AppColors.panel,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.naranja,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            LucideIcons.camera,
                            size: 16,
                            color: AppColors.naranja,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const _CampoAlias(),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  email,
                  style: const TextStyle(fontSize: 13, color: AppColors.texto2),
                ),
              ),
              const SizedBox(height: 24),

              const _EstadoNube(),
              const SizedBox(height: 28),

              // ---------- ZONA PELIGROSA ----------
              const Row(
                children: [
                  Icon(LucideIcons.triangleAlert, size: 16, color: cRojo),
                  SizedBox(width: 8),
                  Text(
                    'Zona peligrosa',
                    style: TextStyle(fontWeight: FontWeight.w800, color: cRojo),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _borrarDatos(context),
                  icon: const Icon(LucideIcons.trash2, size: 18),
                  label: const Text('Borrar mis datos y empezar de cero'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: cRojo,
                    side: BorderSide(color: cRojo.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _cerrarSesion(context),
                  icon: const Icon(LucideIcons.logOut, size: 18),
                  label: const Text('Cerrar sesión'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.texto,
                    side: const BorderSide(color: AppColors.linea),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// Campo para escribir y guardar tu alias
class _CampoAlias extends StatefulWidget {
  const _CampoAlias();

  @override
  State<_CampoAlias> createState() => _CampoAliasState();
}

class _CampoAliasState extends State<_CampoAlias> {
  late final _texto = TextEditingController(text: progreso.alias);

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  void _guardar() {
    progreso.cambiarAlias(_texto.text);
    FocusScope.of(context).unfocus(); // cierra el teclado
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('✅ Alias guardado')));
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _texto,
      textAlign: TextAlign.center,
      maxLength: 24,
      onSubmitted: (_) => _guardar(),
      style: GoogleFonts.unbounded(fontSize: 18, fontWeight: FontWeight.w700),
      decoration: InputDecoration(
        hintText: 'Escribe tu alias',
        hintStyle: const TextStyle(color: AppColors.texto2),
        counterText: '', // oculta el contador de letras
        prefixIcon: const Icon(
          LucideIcons.pencil,
          size: 16,
          color: AppColors.texto2,
        ),
        suffixIcon: IconButton(
          icon: const Icon(LucideIcons.check, color: AppColors.naranja),
          onPressed: _guardar,
        ),
        filled: true,
        fillColor: AppColors.panel,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.linea),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.naranja, width: 1.5),
        ),
      ),
    );
  }
}

// Tarjeta con el estado de la sincronización
class _EstadoNube extends StatelessWidget {
  const _EstadoNube();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([nube, progreso]),
      builder: (context, _) {
        final (icono, color, texto) = switch (nube.estado) {
          EstadoNube.sincronizando => (
            LucideIcons.refreshCw,
            cAmarillo,
            'Sincronizando…',
          ),
          EstadoNube.alDia => (
            LucideIcons.cloudCheck,
            cVerde,
            'Todo guardado en la nube',
          ),
          EstadoNube.error => (
            LucideIcons.cloudOff,
            cRojo,
            'No se ha podido sincronizar',
          ),
          EstadoNube.desconectada => (
            LucideIcons.cloudOff,
            AppColors.texto2,
            'Sin conexión con la nube',
          ),
        };
        final hora = nube.ultimaSync;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.panel,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icono, color: color, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      texto,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
              if (hora != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Última vez: ${hora.hour.toString().padLeft(2, '0')}:${hora.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 12, color: AppColors.texto2),
                ),
              ],
              if (nube.error != null) ...[
                const SizedBox(height: 6),
                Text(
                  nube.error!,
                  style: const TextStyle(fontSize: 11, color: AppColors.texto2),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                'Tu progreso: ${progreso.xp} XP · ${progreso.totalEstudiados} estudiados · '
                '${progreso.totalDominadas} preguntas dominadas',
                style: const TextStyle(fontSize: 12.5, height: 1.4),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: nube.estado == EstadoNube.sincronizando
                      ? null
                      : nube.sincronizar,
                  icon: const Icon(LucideIcons.refreshCw, size: 16),
                  label: const Text('Sincronizar ahora'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.texto,
                    side: const BorderSide(color: AppColors.linea),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
