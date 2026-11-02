import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'manual.dart';
import 'tests.dart';

import 'dart:typed_data';

// Un rango de la guardia
class Rango {
  final int xp;
  final String nombre;
  final String descripcion;

  const Rango(this.xp, this.nombre, this.descripcion);
}

const rangos = <Rango>[
  Rango(0, 'Aspirante', 'Acabas de entrar en la base'),
  Rango(60, 'Voluntario/a PC', 'Primeras guardias'),
  Rango(180, 'TATS', 'Ya conoces las claves'),
  Rango(400, 'Enfermero/a', 'Dominas técnicas y fármacos'),
  Rango(750, 'Médico/a SVA', 'Protocolos bajo control'),
  Rango(1200, 'Charly', 'Jefe/a de División de Guardia'),
  Rango(1800, 'Supervisor/a', 'Visión de todo el operativo'),
  Rango(2600, 'Directivo/a de Guardia', 'Máximo responsable de la guardia'),
];

// "2026-11-02": la fecha de un día en texto
String claveDia(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String get hoy => claveDia(DateTime.now());

class Progreso extends ChangeNotifier {
  static const _clave = 'samurpc-v1';
  static const diasPorCaja = [0, 1, 3, 7, 14];

  final Set<String> _estudiados = {};
  final Set<String> _dominadas = {};
  final Map<String, Pregunta> _fallos = {};
  final Set<String> _dias = {};
  final Map<String, int> _records = {};
  final List<Map<String, dynamic>> _simulacros = [];
  final Map<String, List<int>> _cajas =
      {}; // id tarjeta → [caja 1-5, cuándo vuelve (ms)]
  String _retoDiario = '';
  int _xp = 0;
  int _actualizado = 0; // 🆕 cuándo cambió por última vez (ms), para la nube
  String _alias = '';
  String _foto = ''; // la foto convertida en texto (base64), para guardarla
  Uint8List? _fotoBytes; // la misma foto, lista para mostrarla

  // ==================== CONSULTAS ====================
  int get xp => _xp;
  int get actualizado => _actualizado;
  String get alias => _alias;
  Uint8List? get foto => _fotoBytes;

  bool estaEstudiado(String id) => _estudiados.contains(id);

  int cuantosEstudiados(Iterable<Procedimiento> procs) =>
      procs.where((p) => estaEstudiado(p.id)).length;

  bool estaDominada(String idPregunta) => _dominadas.contains(idPregunta);

  int get totalEstudiados => _estudiados.length;
  int get totalDominadas => _dominadas.length;

  List<Pregunta> get fallos => _fallos.values.toList();

  bool get retoHechoHoy => _retoDiario == hoy;

  int record(String juego) => _records[juego] ?? 0;

  List<Map<String, dynamic>> get simulacros => List.unmodifiable(_simulacros);

  // ---------- RACHA DE DÍAS ----------
  int get rachaDias {
    var d = DateTime.now();
    if (!_dias.contains(claveDia(d))) {
      d = DateTime(d.year, d.month, d.day - 1);
      if (!_dias.contains(claveDia(d))) return 0;
    }
    var n = 0;
    while (_dias.contains(claveDia(d))) {
      n++;
      d = DateTime(d.year, d.month, d.day - 1);
    }
    return n;
  }

  // ---------- RANGOS ----------
  int get _indiceRango {
    var i = 0;
    for (var k = 0; k < rangos.length; k++) {
      if (_xp >= rangos[k].xp) i = k;
    }
    return i;
  }

  Rango get rango => rangos[_indiceRango];

  Rango? get siguienteRango =>
      _indiceRango + 1 < rangos.length ? rangos[_indiceRango + 1] : null;

  double get porcentajeRango {
    final sig = siguienteRango;
    if (sig == null) return 1;
    return ((_xp - rango.xp) / (sig.xp - rango.xp)).clamp(0.0, 1.0).toDouble();
  }

  // ---------- TARJETAS (LEITNER) ----------
  int? cajaDe(String id) => _cajas[id]?[0];
  bool empezada(String id) => _cajas.containsKey(id);

  bool tocaHoy(String id) {
    final c = _cajas[id];
    return c == null || c[1] <= DateTime.now().millisecondsSinceEpoch;
  }

  // ==================== ACCIONES ====================
  void alternarEstudiado(String id) {
    if (_estudiados.remove(id)) {
      _xp = max(0, _xp - 10);
    } else {
      _estudiados.add(id);
      _xp += 10;
      _dias.add(hoy);
    }
    _cambio();
  }

  void sumarXP(int puntos) {
    _xp = max(0, _xp + puntos);
    if (puntos > 0) _dias.add(hoy);
    _cambio();
  }

  bool marcarDominada(String idPregunta) {
    final esNueva = _dominadas.add(idPregunta);
    if (esNueva) _cambio();
    return esNueva;
  }

  void registrarFallo(Pregunta p) {
    if (p.id.isEmpty) return;
    _fallos[p.id] = p;
    _cambio();
  }

  void quitarFallo(String idPregunta) {
    if (_fallos.remove(idPregunta) != null) _cambio();
  }

  void marcarRetoHecho() {
    _retoDiario = hoy;
    _cambio();
  }

  bool guardarRecord(String juego, int puntos) {
    if (puntos <= record(juego)) return false;
    _records[juego] = puntos;
    _cambio();
    return true;
  }

  bool guardarRecordMinimo(String juego, int valor) {
    final antes = _records[juego];
    if (antes != null && valor >= antes) return false;
    _records[juego] = valor;
    _cambio();
    return true;
  }

  void guardarSimulacro(Map<String, dynamic> s) {
    _simulacros.add(s);
    if (_simulacros.length > 20) _simulacros.removeAt(0);
    _cambio();
  }

  void valorarTarjeta(String id, bool sabia) {
    final actual = _cajas[id]?[0] ?? 1;
    final caja = sabia ? min(5, actual + 1) : 1;
    final vuelve = DateTime.now().add(Duration(days: diasPorCaja[caja - 1]));
    _cajas[id] = [caja, vuelve.millisecondsSinceEpoch];
    _cambio();
  }

  void adelantar(Iterable<String> ids) {
    final ahora = DateTime.now().millisecondsSinceEpoch;
    for (final id in ids) {
      final c = _cajas[id];
      if (c != null && c[0] < 3 && c[1] > ahora) c[1] = 0;
    }
    _cambio();
  }

  // ---------- PERFIL ----------
  void cambiarAlias(String nuevo) {
    _alias = nuevo.trim();
    _cambio();
  }

  void cambiarFoto(Uint8List? bytes) {
    _fotoBytes = bytes;
    _foto = bytes == null ? '' : base64Encode(bytes); // imagen → texto
    _cambio();
  }

  // ---------- EMPEZAR DE CERO ----------
  // Borra todo el progreso (pero no el alias ni la foto) y lo sube a la nube
  void reiniciarProgreso() {
    _vaciarProgreso();
    _cambio();
  }

  // Al cerrar sesión: deja el móvil limpio para la siguiente cuenta
  void vaciarAlCerrarSesion() {
    _vaciarProgreso();
    _alias = '';
    _foto = '';
    _fotoBytes = null;
    _actualizado = 0; // así, al volver a entrar, ganará la versión de la nube
    notifyListeners();
    _guardarLocal();
  }

  void _vaciarProgreso() {
    _xp = 0;
    _retoDiario = '';
    _estudiados.clear();
    _dominadas.clear();
    _dias.clear();
    _records.clear();
    _simulacros.clear();
    _cajas.clear();
    _fallos.clear();
  }

  // Todo cambio pasa por aquí: apunta la hora, avisa a las pantallas y guarda
  void _cambio() {
    _actualizado = DateTime.now().millisecondsSinceEpoch;
    notifyListeners();
    _guardarLocal();
  }

  // ==================== JSON (para el móvil y para la nube) ====================
  Map<String, dynamic> aJson() => {
    'xp': _xp,
    'estudiados': _estudiados.toList(),
    'dominadas': _dominadas.toList(),
    'dias': _dias.toList(),
    'retoDiario': _retoDiario,
    'records': _records,
    'simulacros': _simulacros,
    'cajas': _cajas,
    'fallos': [for (final p in _fallos.values) p.toJson()],
    'actualizado': _actualizado,
    'alias': _alias,
    'foto': _foto,
  };

  // Rellena todo a partir de un JSON (vacía antes lo que hubiera)
  void _leer(Map<String, dynamic> datos) {
    _xp = (datos['xp'] as num?)?.toInt() ?? 0;
    _actualizado = (datos['actualizado'] as num?)?.toInt() ?? 0;
    _retoDiario = datos['retoDiario'] as String? ?? '';
    _alias = datos['alias'] as String? ?? '';
    _foto = datos['foto'] as String? ?? '';
    _fotoBytes = _foto.isEmpty ? null : base64Decode(_foto); // texto → imagen
    _estudiados
      ..clear()
      ..addAll((datos['estudiados'] as List? ?? []).cast<String>());
    _dominadas
      ..clear()
      ..addAll((datos['dominadas'] as List? ?? []).cast<String>());
    _dias
      ..clear()
      ..addAll((datos['dias'] as List? ?? []).cast<String>());

    _records.clear();
    (datos['records'] as Map? ?? {}).forEach((k, v) {
      _records[k as String] = (v as num).toInt();
    });

    _simulacros.clear();
    for (final s in datos['simulacros'] as List? ?? []) {
      _simulacros.add(Map<String, dynamic>.from(s as Map));
    }

    _cajas.clear();
    (datos['cajas'] as Map? ?? {}).forEach((id, valor) {
      _cajas[id as String] = [
        for (final n in valor as List) (n as num).toInt(),
      ];
    });

    _fallos.clear();
    for (final f in datos['fallos'] as List? ?? []) {
      final p = Pregunta.fromJson(Map<String, dynamic>.from(f as Map));
      _fallos[p.id] = p;
    }
  }

  // ==================== GUARDAR / CARGAR ====================
  Future<void> cargar() async {
    final prefs = await SharedPreferences.getInstance();
    final texto = prefs.getString(_clave);
    if (texto == null) return;
    _leer(jsonDecode(texto) as Map<String, dynamic>);
  }

  // 🆕 Sustituye tu progreso por el que viene de la nube
  void reemplazarCon(Map<String, dynamic> datos) {
    _leer(datos);
    notifyListeners();
    _guardarLocal();
  }

  Future<void> _guardarLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_clave, jsonEncode(aJson()));
  }
}

final progreso = Progreso();
