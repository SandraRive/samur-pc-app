import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../data/entreno.dart';
import '../theme/app_theme.dart';

// Formulario de "Entrar" / "Crear cuenta"
class FormularioAcceso extends StatefulWidget {
  const FormularioAcceso({super.key});

  @override
  State<FormularioAcceso> createState() => _FormularioAccesoState();
}

class _FormularioAccesoState extends State<FormularioAcceso> {
  final _email = TextEditingController();
  final _contrasena = TextEditingController();
  bool _crearCuenta = false;
  bool _cargando = false;
  bool _verContrasena = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _contrasena.dispose();
    super.dispose();
  }

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
      // El "portero" de la app detecta la sesión y abre la portada solo
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _error = _traducir(e.code));
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          decoration: _decoracion('Email', LucideIcons.mail),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _contrasena,
          obscureText: !_verContrasena,
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
        FilledButton.icon(
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
