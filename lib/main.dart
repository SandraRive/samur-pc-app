import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'data/entreno.dart';
import 'data/manual.dart';
import 'data/nube.dart';
import 'data/progreso.dart';
import 'data/retos.dart';
import 'data/tests.dart';
import 'firebase_options.dart';
import 'screens/acceso_screen.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await cargarManual();
  await cargarTests();
  await cargarReferencia();
  await cargarEntreno();
  await progreso.cargar();
  nube.iniciar();
  runApp(const SamurApp());
}

class SamurApp extends StatelessWidget {
  const SamurApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SAMUR-PC',
      debugShowCheckedModeBanner: false,
      theme: temaSamur(),
      home: const _Portero(),
    );
  }
}

// El "portero": sin sesión → bienvenida · con sesión → portada
class _Portero extends StatelessWidget {
  const _Portero();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Un instante al arrancar, mientras Firebase comprueba si hay sesión
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppColors.naranja),
            ),
          );
        }
        return snapshot.data == null
            ? const AccesoScreen()
            : const HomeScreen();
      },
    );
  }
}
