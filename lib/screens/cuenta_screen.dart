import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../data/entreno.dart';
import '../theme/app_theme.dart';

class CuentaScreen extends StatelessWidget {
  const CuentaScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
      // Escucha a Firebase: cuando entras o sales, la pantalla cambia sola
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          final usuario = snapshot.data;
          return usuario == null
              ? const _Formulario()
              : _Perfil(usuario: usuario);
        },
      ),
    );
  }
}

// ==================== SIN SESIÓN: FORMULARIO ====================

class _Formulario extends StatefulWidget {
  const _Formulario();

  @override
  State<_Formulario> createState() => _FormularioState();
}

class _FormularioState extends State<_Formulario> {
  final _email = TextEditingController();
  final _contrasena = TextEditingController();
  bool _crearCuenta = false; // false = entrar · true = crear cuenta
  bool _cargando = false;
  bool _verContrasena = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _contrasena.dispose();
    super.dispose();
  }

  // Traduce los errores de Firebase al español
  String _traducir(String codigo) => switch (codigo) {
    'invalid-email' => 'Ese email no tiene un formato válido.',
    'user-disabled' => 'Esta cuenta está desactivada.',
    'user-not-found' ||
    'wrong-password' ||
    'invalid-credential' => 'Email o contraseña incorrectos.',
    'email-already-in-use' =>
      'Ya existe una cuenta con ese email. Prueba a entrar.',
    'weak-password' => 'La contraseña es muy corta: usa al menos 6 caracteres.',
    'network-request-failed' => 'No hay conexión a internet.',
    'too-many-requests' =>
      'Demasiados intentos. Espera un poco y vuelve a probar.',
    _ => 'Algo ha fallado ($codigo). Inténtalo de nuevo.',
  };

  Future<void> _enviar() async {
    final email = _email.text.trim();
    final contrasena = _contrasena.text;
    if (email.isEmpty || contrasena.isEmpty) {
      setState(() => _error = 'Escribe tu email y tu contraseña.');
      return;
    }

    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      if (_crearCuenta) {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: contrasena,
        );
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: contrasena,
        );
      }
      // ¡No hace falta navegar! El StreamBuilder detecta la sesión y cambia la pantalla
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _traducir(e.code));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _olvideContrasena() async {
    final email = _email.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Escribe primero tu email y vuelve a pulsar.');
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '📧 Te hemos enviado un email a $email para cambiar la contraseña.',
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _traducir(e.code));
    }
  }

  InputDecoration _decoracion(String texto, IconData icono, {Widget? sufijo}) {
    return InputDecoration(
      hintText: texto,
      hintStyle: const TextStyle(color: AppColors.texto2),
      prefixIcon: Icon(icono, size: 18, color: AppColors.texto2),
      suffixIcon: sufijo,
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
    );
  }

  Widget _pestana(String texto, bool activa, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: activa ? AppColors.naranja : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            texto,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: activa ? AppColors.fondo : AppColors.texto2,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        const Icon(LucideIcons.cloud, size: 52, color: AppColors.naranja),
        const SizedBox(height: 12),
        Text(
          'Guarda tu progreso en la nube',
          textAlign: TextAlign.center,
          style: GoogleFonts.unbounded(
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Así no lo perderás aunque borres la app o cambies de móvil. '
          'La cuenta es opcional: sin ella, la app funciona igual.',
          textAlign: TextAlign.center,
          style: TextStyle(height: 1.4, color: AppColors.texto2),
        ),
        const SizedBox(height: 22),

        // Entrar / Crear cuenta
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.panel,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.linea),
          ),
          child: Row(
            children: [
              _pestana(
                'Entrar',
                !_crearCuenta,
                () => setState(() => _crearCuenta = false),
              ),
              _pestana(
                'Crear cuenta',
                _crearCuenta,
                () => setState(() => _crearCuenta = true),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        TextField(
          controller: _email,
          keyboardType: TextInputType.emailAddress, // teclado con @
          autocorrect: false,
          decoration: _decoracion('Email', LucideIcons.mail),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _contrasena,
          obscureText: !_verContrasena, // ocultar con puntitos
          onSubmitted: (_) => _enviar(),
          decoration: _decoracion(
            _crearCuenta ? 'Contraseña (mínimo 6 caracteres)' : 'Contraseña',
            LucideIcons.lock,
            sufijo: IconButton(
              icon: Icon(
                _verContrasena ? LucideIcons.eyeOff : LucideIcons.eye,
                size: 18,
              ),
              color: AppColors.texto2,
              onPressed: () => setState(() => _verContrasena = !_verContrasena),
            ),
          ),
        ),

        if (_error != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cRojo.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: cRojo.withValues(alpha: 0.5)),
            ),
            child: Text(
              _error!,
              style: const TextStyle(color: cRojo, fontWeight: FontWeight.w600),
            ),
          ),
        ],
        const SizedBox(height: 16),

        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _cargando ? null : _enviar,
            icon: _cargando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.fondo,
                    ),
                  )
                : Icon(
                    _crearCuenta ? LucideIcons.userRound : LucideIcons.logIn,
                    size: 18,
                  ),
            label: Text(_crearCuenta ? 'Crear cuenta' : 'Entrar'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.naranja,
              foregroundColor: AppColors.fondo,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        if (!_crearCuenta)
          TextButton(
            onPressed: _olvideContrasena,
            child: const Text(
              '¿Olvidaste la contraseña?',
              style: TextStyle(color: AppColors.texto2),
            ),
          ),
      ],
    );
  }
}

// ==================== CON SESIÓN: PERFIL ====================

class _Perfil extends StatelessWidget {
  final User usuario;

  const _Perfil({required this.usuario});

  Future<void> _cerrarSesion(BuildContext context) async {
    final seguro = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.panel,
        title: const Text('¿Cerrar sesión?'),
        content: const Text('Tu progreso seguirá guardado en este móvil.'),
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
    if (seguro == true) await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final email = usuario.email ?? '';
    final inicial = email.isEmpty ? '?' : email[0].toUpperCase();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        Center(
          child: CircleAvatar(
            radius: 38,
            backgroundColor: AppColors.naranja,
            child: Text(
              inicial,
              style: GoogleFonts.unbounded(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: AppColors.fondo,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Center(
          child: Text(
            email,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: cVerde.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(99),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.cloudCheck, size: 16, color: cVerde),
                SizedBox(width: 6),
                Text(
                  'Conectada a la nube',
                  style: TextStyle(fontWeight: FontWeight.w700, color: cVerde),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.panel,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.linea),
          ),
          child: const Text(
            '🚧 En el siguiente paso, aquí verás la sincronización de tu progreso.',
            style: TextStyle(height: 1.4, color: AppColors.texto2),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _cerrarSesion(context),
            icon: const Icon(LucideIcons.logOut, size: 18),
            label: const Text('Cerrar sesión'),
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
      ],
    );
  }
}
