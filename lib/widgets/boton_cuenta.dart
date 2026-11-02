import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../data/entreno.dart';
import '../screens/cuenta_screen.dart';
import '../theme/app_theme.dart';

// Icono de la nube: verde si hay sesión, gris tachada si no
class BotonCuenta extends StatelessWidget {
  const BotonCuenta({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final conectada = snapshot.data != null;
        return IconButton(
          tooltip: 'Tu cuenta',
          icon: Icon(
            conectada ? LucideIcons.cloudCheck : LucideIcons.cloudOff,
            color: conectada ? cVerde : AppColors.texto2,
          ),
          onPressed: () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const CuentaScreen())),
        );
      },
    );
  }
}
