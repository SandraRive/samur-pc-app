import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

// El "molde" de un ámbito: qué datos tiene cada uno
class Ambito {
  final String id;
  final String nombre;
  final String descripcion;
  final IconData icono;
  final Color color;
  final int total; // nº de procedimientos, fármacos o tests

  const Ambito({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.icono,
    required this.color,
    required this.total,
  });

  // Texto que acompaña al número según el tipo de ámbito
  String get etiquetaTotal => switch (id) {
    'vademecum' => 'fármacos',
    'repaso' => 'tests',
    _ => 'procedimientos',
  };
}

// Los ámbitos de la portada, con los mismos colores e iconos que tu web
const ambitos = <Ambito>[
  Ambito(
    id: 'admin',
    nombre: 'Administrativos',
    descripcion: 'Organización, funciones de guardia, uniformidad y protección del interviniente',
    icono: LucideIcons.clipboardList,
    color: Color(0xFF8FA2FF),
    total: 23,
  ),
  Ambito(
    id: 'central',
    nombre: 'Central de Comunicaciones',
    descripcion:
        'Llamadas, prioridades, recursos, radio y consejos transtelefónicos',
    icono: LucideIcons.headset,
    color: Color(0xFF2EC4F1),
    total: 13,
  ),
  Ambito(
    id: 'operativos',
    nombre: 'Operativos',
    descripcion: 'Actuación general, coordinación con otros servicios, códigos y grandes incidentes',
    icono: LucideIcons.siren,
    color: Color(0xFFFF7A2E),
    total: 41,
  ),
  Ambito(
    id: 'psico',
    nombre: 'Asistencia psicológica',
    descripcion: 'Intervención del psicólogo de guardia en crisis, duelo, suicidio y violencia',
    icono: LucideIcons.brain,
    color: Color(0xFFC38CFF),
    total: 9,
  ),
  Ambito(
    id: 'sva',
    nombre: 'Soporte Vital Avanzado',
    descripcion: 'Protocolos médicos SVA por especialidades',
    icono: LucideIcons.heart,
    color: Color(0xFFFF4D6A),
    total: 65,
  ),
  Ambito(
    id: 'svb',
    nombre: 'Soporte Vital Básico',
    descripcion:
        'Actuación de las unidades de SVB: valoración, patologías y trauma',
    icono: LucideIcons.briefcaseMedical,
    color: Color(0xFFFFB020),
    total: 19,
  ),
  Ambito(
    id: 'tecnicas',
    nombre: 'Técnicas',
    descripcion: 'Paso a paso de las técnicas sanitarias: cardiacas, vasculares, vía aérea, trauma…',
    icono: LucideIcons.syringe,
    color: Color(0xFF2EE6C0),
    total: 65,
  ),
  Ambito(
    id: 'vademecum',
    nombre: 'Anexos · Vademécum',
    descripcion: 'Fichas de fármacos con función, indicaciones, dosis y contraindicaciones, más el glosario de abreviaturas',
    icono: LucideIcons.pill,
    color: Color(0xFFFF7AC6),
    total: 86,
  ),
  Ambito(
    id: 'repaso',
    nombre: 'Zona de repaso',
    descripcion: 'Tests, juegos y consulta rápida: claves de radio, códigos, prioridades, triaje y tus rangos de XP',
    icono: LucideIcons.gamepad2,
    color: Color(0xFFFFD23F),
    total: 101,
  ),
];
