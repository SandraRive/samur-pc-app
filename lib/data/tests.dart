import 'dart:convert';

import 'package:flutter/services.dart';

import 'manual.dart';

// Una pregunta de test
class Pregunta {
  final String id; // vacío = pregunta generada (no cuenta como dominada)
  final String enunciado;
  final String correcta;
  final List<String> distractores; // las respuestas incorrectas
  final String explicacion;
  final List<String>?
  opcionesFijas; // si existe, las opciones van en este orden (exámenes)

  const Pregunta({
    required this.id,
    required this.enunciado,
    required this.correcta,
    required this.distractores,
    required this.explicacion,
    this.opcionesFijas,
  });

  // Convierte la pregunta en un mapa para guardarla como JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'enunciado': enunciado,
    'correcta': correcta,
    'distractores': distractores,
    'explicacion': explicacion,
    if (opcionesFijas != null) 'opcionesFijas': opcionesFijas,
  };

  // Y al revés: reconstruye la pregunta desde el JSON guardado
  factory Pregunta.fromJson(Map<String, dynamic> j) => Pregunta(
    id: j['id'] as String,
    enunciado: j['enunciado'] as String,
    correcta: j['correcta'] as String,
    distractores: (j['distractores'] as List).cast<String>(),
    explicacion: j['explicacion'] as String,
    opcionesFijas: (j['opcionesFijas'] as List?)?.cast<String>(),
  );
}

// Un test: de un procedimiento concreto o de un bloque entero
class Test {
  final String id;
  final String ambito;
  final String grupo;
  final String? procId; // null = test del bloque entero
  final String titulo;
  final List<Pregunta> preguntas;

  const Test({
    required this.id,
    required this.ambito,
    required this.grupo,
    required this.procId,
    required this.titulo,
    required this.preguntas,
  });

  factory Test.fromJson(Map<String, dynamic> j) {
    final id = j['id'] as String;
    return Test(
      id: id,
      ambito: j['amb'] as String,
      grupo: j['g'] as String,
      procId: j['p'] as String?,
      titulo: j['t'] as String,
      preguntas: [
        // Cada pregunta del JSON es: [enunciado, correcta, [3 incorrectas], explicación]
        for (final q in j['q'] as List)
          Pregunta(
            id: '$id|${_hash(q[0] as String)}',
            enunciado: q[0] as String,
            correcta: q[1] as String,
            distractores: (q[2] as List).cast<String>(),
            explicacion: q[3] as String,
          ),
      ],
    );
  }
}

// Todos los tests, disponibles para toda la app
late final List<Test> tests;

Future<void> cargarTests() async {
  final texto = await rootBundle.loadString('assets/data/quiz.json');
  tests = (jsonDecode(texto) as List)
      .map((t) => Test.fromJson(t as Map<String, dynamic>))
      .toList();
}

// El test de un procedimiento: el suyo propio o, si no tiene, el de su bloque
// (igual que la función setFor de tu web)
Test? testPara(Procedimiento p) {
  for (final t in tests) {
    if (t.procId == p.id) return t;
  }
  for (final t in tests) {
    if (t.procId == null && t.ambito == p.ambito && t.grupo == p.grupo) {
      return t;
    }
  }
  return null;
}

// Identificador corto de una pregunta a partir de su texto.
// Es la MISMA fórmula que usa tu web, así los ids coinciden en las dos.
String _hash(String s) {
  var h = 5381;
  for (final c in s.codeUnits) {
    h = ((h * 33) ^ c) & 0xFFFFFFFF;
  }
  return h.toRadixString(36);
}
