import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import 'manual.dart';
import 'tests.dart';

// Un "par" de textos: (clave, significado), (código, descripción)…
typedef Par = (String, String);

// ==================== DATOS DE REFERENCIA (ref.json) ====================

class GrupoCodigos {
  final String numero;
  final String nombre;
  final List<Par> codigos;

  const GrupoCodigos({
    required this.numero,
    required this.nombre,
    required this.codigos,
  });
}

class Referencia {
  final List<Par> claves;
  final List<GrupoCodigos> codigos;
  final Map<String, List<Par>> indicativos; // por categoría
  final List<Par> especificos;

  const Referencia({
    required this.claves,
    required this.codigos,
    required this.indicativos,
    required this.especificos,
  });
}

// Un examen oficial
class Examen {
  final String id;
  final String titulo;
  final String subtitulo;
  final List<Pregunta> preguntas;

  const Examen({
    required this.id,
    required this.titulo,
    required this.subtitulo,
    required this.preguntas,
  });
}

late final Referencia referencia;
late final List<Examen> examenes;

Future<void> cargarReferencia() async {
  // Convierte [[a, b], [c, d]] en una lista de pares
  List<Par> pares(List lista) => [
    for (final x in lista) (x[0] as String, x[1] as String),
  ];

  final ref = jsonDecode(
    await rootBundle.loadString('assets/data/ref.json'),
  ) as Map<String, dynamic>;

  referencia = Referencia(
    claves: pares(ref['claves'] as List),
    codigos: [
      for (final g in ref['codigos'] as List)
        GrupoCodigos(
          numero: g['n'] as String,
          nombre: g['name'] as String,
          codigos: pares(g['c'] as List),
        ),
    ],
    indicativos: {
      for (final e in (ref['ind'] as Map<String, dynamic>).entries)
        e.key: pares(e.value as List),
    },
    especificos: pares(ref['esp'] as List),
  );

  final ex = jsonDecode(
    await rootBundle.loadString('assets/data/examenes.json'),
  ) as List;
  examenes = [
    for (final x in ex)
      Examen(
        id: x['id'] as String,
        titulo: x['t'] as String,
        subtitulo: x['sub'] as String,
        preguntas: [
          // Cada pregunta: [número, enunciado, [a, b, c], índice de la correcta]
          for (final q in x['q'] as List)
            Pregunta(
              id: 'ex.${x['id']}|${q[0]}',
              enunciado: q[1] as String,
              correcta: (q[2] as List)[q[3] as int] as String,
              distractores: const [],
              explicacion:
                  'Respuesta correcta según la plantilla oficial: ${'abc'[q[3] as int]})',
              opcionesFijas: (q[2] as List).cast<String>(),
            ),
        ],
      ),
  ];
}

// ==================== RETOS RÁPIDOS ====================

class Reto {
  final String id;
  final String titulo;
  final String subtitulo;
  final IconData icono;
  final String colorDe; // id del ámbito cuyo color usa
  final int cuantas;

  const Reto(
    this.id,
    this.titulo,
    this.subtitulo,
    this.icono,
    this.colorDe,
    this.cuantas,
  );
}

// Los mismos 6 retos que tu web
const retos = <Reto>[
  Reto(
    'claves',
    'Claves de radio',
    '¿Qué significa la clave…?',
    LucideIcons.radio,
    'central',
    10,
  ),
  Reto(
    'codigos',
    'Códigos de incidente',
    'Del número al tipo de incidente',
    LucideIcons.hash,
    'operativos',
    10,
  ),
  Reto(
    'indicativos',
    'Indicativos',
    'Charly, Romeo, Beta, Zeta…',
    LucideIcons.users,
    'admin',
    10,
  ),
  Reto(
    'farmacos',
    'Fármacos',
    'Adivina el fármaco por su función',
    LucideIcons.pill,
    'vademecum',
    10,
  ),
  Reto(
    'abrev',
    'Abreviaturas',
    'Siglas del manual',
    LucideIcons.bookA,
    'tecnicas',
    10,
  ),
  Reto(
    'mix',
    'Guardia completa',
    'Mezcla de todo, 15 preguntas',
    LucideIcons.flame,
    'sva',
    15,
  ),
];

final _azar = Random();

// Devuelve una copia barajada
List<T> _barajar<T>(Iterable<T> x) => x.toList()..shuffle();

// Recorta un texto largo sin partir palabras: "Esto es un tex…"
String _recortar(String s, int n) {
  if (s.length <= n) return s;
  final corte = s.substring(0, n);
  final espacio = corte.lastIndexOf(' ');
  return '${espacio > 0 ? corte.substring(0, espacio) : corte}…';
}

// Crea una pregunta generada (sin id ni explicación)
Pregunta _pregunta(
  String enunciado,
  String correcta,
  Iterable<String> distractores,
) {
  return Pregunta(
    id: '',
    enunciado: enunciado,
    correcta: correcta,
    distractores: distractores.toSet().take(3).toList(), // sin repetidos
    explicacion: '',
  );
}

// Tapa el nombre del fármaco dentro de su descripción: "La •••••• es…"
String _ocultarNombre(Farmaco f) {
  var texto = f.funcion;
  for (final palabra in f.nombre.split(RegExp(r'[\s/]+'))) {
    if (palabra.length > 4) {
      texto = texto.replaceAll(
        RegExp(RegExp.escape(palabra), caseSensitive: false),
        '•••',
      );
    }
  }
  return texto;
}

// Fabrica todas las preguntas posibles de un reto (igual que poolOf en tu web)
List<Pregunta> preguntasDeReto(String modo) {
  switch (modo) {
    case 'claves':
      final c = referencia.claves
          .where((x) => !x.$1.startsWith('Estatus'))
          .toList();
      return [
        for (final (k, v) in c)
          if (_azar.nextDouble() < 0.65)
            _pregunta(
              '¿Qué significa la clave $k?',
              v,
              _barajar(c.where((x) => x.$1 != k && x.$2 != v)).map((x) => x.$2),
            )
          else
            _pregunta(
              '«${_recortar(v, 110)}» ¿Qué clave es?',
              'Clave $k',
              _barajar(c.where((x) => x.$1 != k)).map((x) => 'Clave ${x.$1}'),
            ),
      ];

    case 'codigos':
      // Todos los códigos, recordando a qué grupo pertenecen
      final todos = [
        for (final g in referencia.codigos)
          for (final (c, t) in g.codigos) (c, t, g),
      ];
      final lista = <Pregunta>[];
      for (final (c, t, g) in todos) {
        // Distractores: primero del mismo grupo (más difícil), luego de otros
        final candidatos = [
          ..._barajar(todos.where((x) => x.$1 != c && x.$3 == g)),
          ..._barajar(todos.where((x) => x.$1 != c && x.$3 != g)),
        ];
        lista.add(
          _azar.nextBool()
              ? _pregunta(
                  '¿Qué es el código de incidente $c?',
                  t,
                  candidatos.map((x) => x.$2).where((x) => x != t),
                )
              : _pregunta(
                  '«$t» corresponde al código…',
                  c,
                  candidatos.map((x) => x.$1),
                ),
        );
      }
      return lista;

    case 'indicativos':
      final todos = [
        for (final cat in [
          'Particulares',
          'Generales',
          'Según base o función',
          'Ajenos',
        ])
          ...?referencia.indicativos[cat],
      ];
      return [
        for (final (k, v) in todos)
          _pregunta(
            '¿Quién o qué es «$k»?',
            v,
            _barajar(todos.where((x) => x.$1 != k && x.$2 != v))
                .map((x) => x.$2),
          ),
      ];

    case 'farmacos':
      final fs = manual.farmacos.where((f) => f.funcion.length > 25).toList();
      final nombres = {for (final f in fs) f.nombre};
      return [
        for (final f in fs)
          _pregunta(
            '¿Qué fármaco es? «${_recortar(_ocultarNombre(f), 190)}»',
            f.nombre,
            _barajar(nombres.where((n) => n != f.nombre)),
          ),
      ];

    case 'abrev':
      final todas = manual.abreviaturas
          .where((a) => a.sigla.length > 1)
          .toList();
      return [
        for (final a in todas)
          _pregunta(
            '¿Qué significa «${a.sigla}»?',
            a.significado,
            _barajar(
              todas.where(
                (x) => x.sigla != a.sigla && x.significado != a.significado,
              ),
            ).map((x) => x.significado),
          ),
      ];

    case 'mix':
      return [
        for (final m in [
          'claves',
          'codigos',
          'indicativos',
          'farmacos',
          'abrev',
        ])
          ...preguntasDeReto(m),
      ];

    default:
      return [];
  }
}
