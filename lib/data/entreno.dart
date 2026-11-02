import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../theme/app_theme.dart';
import 'manual.dart';
import 'progreso.dart';
import 'retos.dart';
import 'tests.dart';
import 'ambitos.dart';

// Colores de tu Entreno
const cCyan = Color(0xFF2EC4F1);
const cRojo = Color(0xFFFF3B5C);
const cNaranja = Color(0xFFFF6B1A);
const cVioleta = Color(0xFFB98CFF);
const cVerde = Color(0xFF2EE6A6);
const cAmarillo = Color(0xFFFFD23F);

// Traduce los colores de tu web ("--cyan"…) a colores de Flutter
Color colorWeb(String? nombre) => switch (nombre) {
  '--cyan' => cCyan,
  '--red' => cRojo,
  '--orange' => cNaranja,
  '--violet' => cVioleta,
  '--green' => cVerde,
  '--yellow' => cAmarillo,
  _ => AppColors.texto2,
};

// ==================== CATÁLOGO DE JUEGOS ====================

class Juego {
  final int bandeja;
  final String id;
  final String titulo;
  final String descripcion;
  final IconData icono;
  final Color color;

  const Juego(
    this.bandeja,
    this.id,
    this.titulo,
    this.descripcion,
    this.icono,
    this.color,
  );
}

const bandejas = [
  ('Tests', 'Preguntas tipo examen sacadas del manual'),
  ('Juegos rápidos', 'Partidas cortas para fijar datos concretos'),
  ('Memorizar', 'Para estudiar a tu ritmo, día a día'),
  (
    'Como en la calle',
    'Casos, triaje y códigos para practicar decisiones reales',
  ),
];

const juegos = <Juego>[
  Juego(
    0,
    'tests',
    'Test por bloque',
    'Elige ámbito y bloque. Con explicación en cada respuesta.',
    LucideIcons.layers,
    cCyan,
  ),
  Juego(
    0,
    'examen',
    'Examen oficial TATS 2024',
    'Las 95 preguntas reales, en orden o 20 al azar.',
    LucideIcons.fileText,
    cCyan,
  ),
  Juego(
    0,
    'simulacro',
    'Simulacro personalizado',
    'Combina los temas que quieras, con tiempo y penalización.',
    LucideIcons.clipboardCheck,
    cCyan,
  ),
  Juego(
    0,
    'supervivencia',
    'Supervivencia',
    'Preguntas sin fin con 3 vidas y contrarreloj.',
    LucideIcons.heart,
    cRojo,
  ),
  Juego(
    0,
    'fallos',
    'Repaso de fallos',
    'Solo las preguntas que has fallado en cualquier test.',
    LucideIcons.rotateCcw,
    cNaranja,
  ),
  Juego(
    1,
    'verdadero-falso',
    'Verdadero o falso',
    '2 minutos: ¿esta respuesta es correcta?',
    LucideIcons.timer,
    cNaranja,
  ),
  Juego(
    1,
    'parejas',
    'Parejas',
    'Memory clásico: une cada término con su significado.',
    LucideIcons.grid2x2,
    cVioleta,
  ),
  Juego(
    1,
    'unir',
    'Une columnas',
    'Empareja cinco términos con su definición.',
    LucideIcons.gitMerge,
    cVerde,
  ),
  Juego(
    1,
    'escribe',
    'Escribe la clave',
    'Lee el significado y teclea la clave, el código o la sigla.',
    LucideIcons.keyboard,
    cAmarillo,
  ),
  Juego(
    1,
    'ordena',
    'Ordena los pasos',
    'Arrastra los pasos de cada protocolo hasta dejarlos en orden.',
    LucideIcons.listOrdered,
    cCyan,
  ),
  Juego(
    1,
    'clasifica',
    'Clasifica',
    'Manda cada caso a su cajón: prioridades, zonas, gravedad…',
    LucideIcons.columns3,
    cRojo,
  ),
  Juego(
    2,
    'tarjetas',
    'Tarjetas con repaso espaciado',
    'Cinco cajas: lo que te cuesta vuelve antes.',
    LucideIcons.layers2,
    cVioleta,
  ),
  Juego(
    2,
    'parecidos',
    'Parecidos que se confunden',
    'Los datos que más se mezclan, con su truco.',
    LucideIcons.scale,
    cVioleta,
  ),
  Juego(
    2,
    'trampa',
    'Caza la trampa',
    'Opciones que solo cambian en una cifra o una palabra.',
    LucideIcons.crosshair,
    cRojo,
  ),
  Juego(
    3,
    'casos',
    'Casos clínicos',
    'Decide paso a paso qué harías. Si te desvías, el caso cambia.',
    LucideIcons.stethoscope,
    cVerde,
  ),
  Juego(
    3,
    'triaje',
    'Simulador de triaje STARS',
    'Clasifica víctimas a contrarreloj en los tres triajes.',
    LucideIcons.tags,
    cRojo,
  ),
  Juego(
    3,
    'codigo',
    '¿Qué código es?',
    'Te describen una situación y activas el código correcto.',
    LucideIcons.hash,
    cNaranja,
  ),
];

// Los que ya funcionan en la app (iremos añadiendo en cada ronda)
const juegosListos = {
  'tests',
  'examen',
  'fallos',
  'supervivencia',
  'verdadero-falso',
  'escribe',
  'simulacro',
  'parejas',
  'unir',
  'ordena',
  'clasifica',
  'tarjetas',
  'parecidos',
  'trampa',
};

// ==================== DATOS DEL ENTRENO (entreno.json) ====================

late final Map<String, dynamic>
datosEntreno; // todo el JSON, para las próximas rondas
late final List<Mazo> mazos;

Future<void> cargarEntreno() async {
  datosEntreno = jsonDecode(
    await rootBundle.loadString('assets/data/entreno.json'),
  ) as Map<String, dynamic>;
  mazos = [
    for (final m in datosEntreno['mazos'] as List)
      Mazo.fromJson(m as Map<String, dynamic>),
  ];
}

const _iconosMazo = <String, IconData>{
  'radio': LucideIcons.radio,
  'hash': LucideIcons.hash,
  'siren': LucideIcons.siren,
  'users': LucideIcons.users,
  'map-pin': LucideIcons.mapPin,
  'book-a': LucideIcons.bookA,
  'pill': LucideIcons.pill,
  'baby': LucideIcons.baby,
  'heart-pulse': LucideIcons.heartPulse,
  'activity': LucideIcons.activity,
  'thermometer': LucideIcons.thermometer,
  'wind': LucideIcons.wind,
  'car': LucideIcons.car,
  'brain': LucideIcons.brain,
};

// Una carta: un término y su significado (clave → significado, Killip I → …)
class Carta {
  final String id;
  final String termino;
  final String significado;

  const Carta({
    required this.id,
    required this.termino,
    required this.significado,
  });
}

// Un mazo de cartas (Claves de radio, Escala de Glasgow…)
class Mazo {
  final String id;
  final String titulo;
  final String tipo; // "Clave", "Código", "Sigla"…
  final IconData icono;
  final Color color;
  final bool escribible; // ¿sirve para "Escribe la clave"?
  final List<Carta> cartas;

  const Mazo({
    required this.id,
    required this.titulo,
    required this.tipo,
    required this.icono,
    required this.color,
    required this.escribible,
    required this.cartas,
  });

  factory Mazo.fromJson(Map<String, dynamic> j) {
    final id = j['id'] as String;
    return Mazo(
      id: id,
      titulo: j['t'] as String,
      tipo: j['kind'] as String,
      icono: _iconosMazo[j['icon']] ?? LucideIcons.layers,
      color: colorWeb(j['c'] as String?),
      escribible: j['typ'] == 1,
      cartas: [
        for (final p in j['p'] as List)
          Carta(
            id: 'dk.$id|${_hash(p[0] as String)}',
            termino: p[0] as String,
            significado: p[1] as String,
          ),
      ],
    );
  }
}

// La misma fórmula de ids que tu web
String _hash(String s) {
  var h = 5381;
  for (final c in s.codeUnits) {
    h = ((h * 33) ^ c) & 0xFFFFFFFF;
  }
  return h.toRadixString(36);
}

String _recortar(String s, int n) {
  if (s.length <= n) return s;
  final corte = s.substring(0, n);
  final espacio = corte.lastIndexOf(' ');
  return '${espacio > 0 ? corte.substring(0, espacio) : corte}…';
}

// ==================== PREGUNTAS PARA LOS JUEGOS ====================

final _azar = Random();

// Todas las preguntas de los tests juntas (se calcula una vez y se guarda)
List<Pregunta>? _cacheTodas;
List<Pregunta> get todasLasPreguntas =>
    _cacheTodas ??= [for (final t in tests) ...t.preguntas];

// Convierte una carta en pregunta tipo test (en un sentido o en el otro)
Pregunta preguntaDeMazo(Mazo m, Carta c) {
  final pideSignificado = _azar.nextDouble() < 0.55;
  final correcta = pideSignificado ? c.significado : c.termino;
  final otras = m.cartas.where((x) => x != c).toList()..shuffle();
  final distractores = [
    for (final x in otras) pideSignificado ? x.significado : x.termino,
  ].where((t) => t != correcta).toSet().take(3).toList();

  return Pregunta(
    id: c.id,
    enunciado: pideSignificado
        ? '${m.tipo} «${c.termino}»: ¿qué es?'
        : '«${_recortar(c.significado, 140)}» ¿a qué corresponde?',
    correcta: correcta,
    distractores: distractores,
    explicacion: '',
  );
}

// La mezcla de Supervivencia: 70 % tests, 15 % examen, 15 % mazos
Pregunta preguntaMezcla() {
  final r = _azar.nextDouble();
  if (r < 0.70)
    return todasLasPreguntas[_azar.nextInt(todasLasPreguntas.length)];
  if (r < 0.85 && examenes.isNotEmpty) {
    final e = examenes.first.preguntas;
    return e[_azar.nextInt(e.length)];
  }
  final grandes = mazos.where((m) => m.cartas.length >= 10).toList();
  final m = grandes[_azar.nextInt(grandes.length)];
  return preguntaDeMazo(m, m.cartas[_azar.nextInt(m.cartas.length)]);
}

// Para "Escribe la clave": quita tildes, mayúsculas, espacios y palabras
// como "clave" o "código", igual que la función keyNorm de tu web
String normalizarClave(String s) {
  var t = normalizar(s)
      .replaceAll(RegExp(r'\b(clave|codigo|cod|indicativo|perfil|base)\b'), '');
  t = t.replaceAllMapped(
    RegExp(r'[\s.\-_,]+'),
    (m) => m[0]!.contains('.') ? '.' : '',
  );
  return t.replaceAll(RegExp(r'^\.+|\.+$'), '').trim();
}

// ==================== RETO DEL DÍA ====================

Pregunta _unaDe(List<Pregunta> lista) {
  final pendientes = lista.where((p) => !progreso.estaDominada(p.id)).toList();
  final origen = pendientes.isNotEmpty ? pendientes : lista;
  return origen[_azar.nextInt(origen.length)];
}

List<Pregunta> preguntasRetoDelDia() {
  final elegidas = <Pregunta>[];
  for (final amb in tests.map((t) => t.ambito).toSet()) {
    elegidas.add(
      _unaDe([
        for (final t in tests)
          if (t.ambito == amb) ...t.preguntas,
      ]),
    );
  }
  if (examenes.isNotEmpty) elegidas.add(_unaDe(examenes.first.preguntas));

  while (elegidas.length < 10) {
    final p = _unaDe(todasLasPreguntas);
    if (!elegidas.contains(p)) elegidas.add(p);
  }
  return (elegidas..shuffle()).take(10).toList();
}

// ==================== TARJETAS (LEITNER) ====================

class Tarjeta {
  final String id;
  final String frente;
  final String dorso;
  final String explicacion;
  final bool esClave; // las de mazos se ven en grande (10.1, P1…)

  const Tarjeta({
    required this.id,
    required this.frente,
    required this.dorso,
    required this.explicacion,
    required this.esClave,
  });
}

// Un "mazo" de tarjetas: un mazo del entreno o un test del manual
class FuenteTarjetas {
  final String id;
  final String titulo;
  final IconData icono;
  final Color color;
  final bool deMazo;
  final List<Tarjeta> tarjetas;

  const FuenteTarjetas({
    required this.id,
    required this.titulo,
    required this.icono,
    required this.color,
    required this.deMazo,
    required this.tarjetas,
  });
}

List<FuenteTarjetas>? _cacheFuentes;
List<FuenteTarjetas> get fuentesTarjetas => _cacheFuentes ??= [
  for (final m in mazos)
    FuenteTarjetas(
      id: 'd.${m.id}',
      titulo: m.titulo,
      icono: m.icono,
      color: m.color,
      deMazo: true,
      tarjetas: [
        for (final c in m.cartas)
          Tarjeta(
            id: c.id,
            frente: c.termino,
            dorso: c.significado,
            explicacion: '',
            esClave: true,
          ),
      ],
    ),
  for (final t in tests)
    FuenteTarjetas(
      id: 's.${t.id}',
      titulo: t.titulo,
      icono: ambitos.firstWhere((a) => a.id == t.ambito).icono,
      color: ambitos.firstWhere((a) => a.id == t.ambito).color,
      deMazo: false,
      tarjetas: [
        for (final p in t.preguntas)
          Tarjeta(
            id: p.id,
            frente: p.enunciado,
            dorso: p.correcta,
            explicacion: p.explicacion,
            esClave: false,
          ),
      ],
    ),
];

// ==================== PARECIDOS QUE SE CONFUNDEN ====================

List<Map<String, dynamic>> get gruposParecidos =>
    (datosEntreno['parecidos'] as List).cast<Map<String, dynamic>>();

// Genera preguntas de un grupo (o de todos mezclados, si grupo es null)
List<Pregunta> preguntasParecidos(int? grupo) {
  final indices = grupo == null
      ? List.generate(gruposParecidos.length, (k) => k)
      : [grupo];
  final salida = <Pregunta>[];

  for (final k in indices) {
    final g = gruposParecidos[k];
    final pares = [
      for (final x in g['i'] as List) (x[0] as String, x[1] as String),
    ];
    final truco = '✨ Truco · ${g['t']}: ${g['tip']}';

    for (final (a, b) in pares) {
      final otros = pares.where((x) => x.$1 != a).toList()..shuffle();
      salida.add(
        _azar.nextBool()
            ? Pregunta(
                id: '',
                enunciado: '¿A qué corresponde «$b»?',
                correcta: a,
                distractores: otros.map((x) => x.$1).take(3).toList(),
                explicacion: truco,
              )
            : Pregunta(
                id: '',
                enunciado: '$a:',
                correcta: b,
                distractores: otros
                    .map((x) => x.$2)
                    .where((v) => v != b)
                    .take(3)
                    .toList(),
                explicacion: truco,
              ),
      );
    }
  }
  salida.shuffle();
  return grupo == null ? salida.take(15).toList() : salida;
}
