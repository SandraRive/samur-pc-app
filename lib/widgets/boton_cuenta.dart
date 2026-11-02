import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/progreso.dart';
import '../screens/cuenta_screen.dart';
import '../theme/app_theme.dart';

// Tu foto (o tu inicial) arriba a la derecha: lleva a tu cuenta
class BotonCuenta extends StatelessWidget {
  const BotonCuenta({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: progreso,
      builder: (context, _) {
        final foto = progreso.foto;
        final email = FirebaseAuth.instance.currentUser?.email ?? '';
        final nombre = progreso.alias.isNotEmpty ? progreso.alias : email;
        final inicial = nombre.isEmpty ? '?' : nombre[0].toUpperCase();

        return GestureDetector(
          onTap: () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const CuentaScreen())),
          child: CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.naranja,
            backgroundImage: foto != null ? MemoryImage(foto) : null,
            child: foto == null
                ? Text(
                    inicial,
                    style: GoogleFonts.unbounded(
                      fontWeight: FontWeight.w800,
                      color: AppColors.fondo,
                    ),
                  )
                : null,
          ),
        );
      },
    );
  }
}
