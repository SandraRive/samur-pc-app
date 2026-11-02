import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'theme/app_theme.dart';
import 'data/manual.dart';
import 'data/progreso.dart';
import 'data/tests.dart';
import 'data/retos.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // prepara Flutter antes de leer archivos
  await cargarManual(); // lee el JSON
  await cargarTests();
  await cargarReferencia();
  await progreso.cargar(); // recupera tu XP y lo estudiado
  runApp(const SamurApp()); // y ahora sí, arranca la app
}

class SamurApp extends StatelessWidget {
  const SamurApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SAMUR-PC',
      debugShowCheckedModeBanner: false, // quita la cinta de DEBUG
      theme: temaSamur(),
      home: const HomeScreen(),
    );
  }
}
