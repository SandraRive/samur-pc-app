import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';

// Quita tildes y pasa a minúsculas, para buscar sin preocuparse de acentos
String normalizar(String s) {
  const conTilde = 'áàäâéèëêíìïîóòöôúùüûñç';
  const sinTilde = 'aaaaeeeeiiiioooouuuunc';
  final resultado = StringBuffer();
  for (final letra in s.toLowerCase().split('')) {
    final i = conTilde.indexOf(letra);
    resultado.write(i >= 0 ? sinTilde[i] : letra);
  }
  return resultado.toString();
}

// ==================== PROCEDIMIENTOS ====================

// Un bloque (grupo) de un ámbito, con su icono
class Grupo {
  final String nombre;
  final String icono; // nombre del icono en el JSON (p. ej. 'users')

  const Grupo({required this.nombre, required this.icono});
}

// Un procedimiento del manual
class Procedimiento {
  final String id;
  final String ambito;
  final String grupo;
  final String titulo;
  final List<int> paginas;
  final List<Map<String, dynamic>> bloques;
  final int palabras;

  Procedimiento({
    required this.id,
    required this.ambito,
    required this.grupo,
    required this.titulo,
    required this.paginas,
    required this.bloques,
    required this.palabras,
  });

  // Minutos de lectura: misma fórmula que tu web (190 palabras/min, mínimo 1)
  int get minutos => max(1, (palabras / 190).round());

  // "pág. 18" o "pág. 18–19", como en tu web
  String get textoPaginas {
    if (paginas.isEmpty) return '';
    if (paginas.length == 1 || paginas.first == paginas.last) {
      return 'pág. ${paginas.first}';
    }
    return 'pág. ${paginas.first}–${paginas.last}';
  }

  factory Procedimiento.fromJson(Map<String, dynamic> j) {
    return Procedimiento(
      id: j['id'] as String,
      ambito: j['amb'] as String,
      grupo: j['grp'] as String,
      titulo: j['title'] as String,
      paginas: (j['p'] as List).cast<int>(),
      bloques: (j['b'] as List).cast<Map<String, dynamic>>(),
      palabras: j['w'] as int,
    );
  }
}

// ==================== VADEMÉCUM ====================

// Un apartado de la ficha de un fármaco (Función, Dosis…)
class Campo {
  final String titulo;
  final List<Map<String, dynamic>> bloques;

  const Campo({required this.titulo, required this.bloques});

  String get texto => bloques.map((b) => b['x'] ?? '').join(' ');
}

// Un fármaco con su ficha
class Farmaco {
  final String nombre;
  final List<Campo> campos;
  final String funcion; // resumen para la lista
  final String textoBusqueda; // todo su texto, sin tildes, para el buscador

  Farmaco({
    required this.nombre,
    required this.campos,
    required this.funcion,
    required this.textoBusqueda,
  });

  // Primera letra sin tilde ("Ácido" → "A")
  String get letra => normalizar(nombre)[0].toUpperCase();

  factory Farmaco.fromJson(Map<String, dynamic> j) {
    final nombre = j['n'] as String;
    final campos = [
      for (final f in j['f'] as List)
        Campo(
          titulo: f['f'] as String,
          bloques: (f['b'] as List).cast<Map<String, dynamic>>(),
        ),
    ];

    // El resumen sale del campo "Función" (o "Acción"); si no hay, del primero
    Campo? campoFuncion;
    for (final c in campos) {
      if (c.titulo.startsWith('Funci') || c.titulo.startsWith('Acci')) {
        campoFuncion = c;
        break;
      }
    }
    campoFuncion ??= campos.isEmpty ? null : campos.first;

    return Farmaco(
      nombre: nombre,
      campos: campos,
      funcion: campoFuncion?.texto ?? '',
      textoBusqueda: normalizar(
        '$nombre ${campos.map((c) => c.texto).join(' ')}',
      ),
    );
  }
}

// Una sigla y su significado
class Abreviatura {
  final String sigla;
  final String significado;

  const Abreviatura({required this.sigla, required this.significado});
}

// ==================== MANUAL ====================

class Manual {
  final List<Procedimiento> procedimientos;
  final Map<String, List<Grupo>> gruposPorAmbito;
  final List<Farmaco> farmacos;
  final List<Abreviatura> abreviaturas;

  Manual({
    required this.procedimientos,
    required this.gruposPorAmbito,
    required this.farmacos,
    required this.abreviaturas,
  });

  List<Grupo> grupos(String ambitoId) => gruposPorAmbito[ambitoId] ?? [];

  List<Procedimiento> procedimientosDe(String ambitoId, String grupo) {
    return procedimientos
        .where((p) => p.ambito == ambitoId && p.grupo == grupo)
        .toList();
  }

  int totalDe(String ambitoId) =>
      procedimientos.where((p) => p.ambito == ambitoId).length;
}

// El manual, disponible para toda la app
late final Manual manual;

// Lee el JSON y prepara el manual
Future<void> cargarManual() async {
  final texto = await rootBundle.loadString('assets/data/data.json');
  final json = jsonDecode(texto) as Map<String, dynamic>;

  final procs = (json['procs'] as List)
      .map((p) => Procedimiento.fromJson(p as Map<String, dynamic>))
      .toList();

  final grupos = <String, List<Grupo>>{
    for (final a in json['tree'] as List)
      a['id'] as String: [
        for (final g in a['groups'] as List)
          Grupo(nombre: g['name'] as String, icono: g['icon'] as String),
      ],
  };

  final farmacos = (json['drugs'] as List)
      .map((d) => Farmaco.fromJson(d as Map<String, dynamic>))
      .toList();

  final abreviaturas = [
    for (final a in json['abbr'] as List)
      Abreviatura(sigla: a[0] as String, significado: a[1] as String),
  ];

  manual = Manual(
    procedimientos: procs,
    gruposPorAmbito: grupos,
    farmacos: farmacos,
    abreviaturas: abreviaturas,
  );
}
