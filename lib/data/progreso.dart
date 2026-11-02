import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'manual.dart';
import 'tests.dart';

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

// "2026-11-02": la fecha de un día en texto, para guardarla
String claveDia(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String get hoy => claveDia(DateTime.now());

class Progreso extends ChangeNotifier {
  static const _clave = 'samurpc-v1';

  final Set<String> _estudiados = {};
  final Set<String> _dominadas = {};
  final Map<String, Pregunta> _fallos = {}; // preguntas falladas pendientes
  final Set<String> _dias = {}; // días en los que has ganado XP
  String _retoDiario = ''; // último día que hiciste el reto
  final Map<String, int> _records = {}; // mejores puntuaciones por juego
  int _xp = 0;

  int get xp => _xp;

  bool estaEstudiado(String id) => _estudiados.contains(id);

  int cuantosEstudiados(Iterable<Procedimiento> procs) =>
      procs.where((p) => estaEstudiado(p.id)).length;

  bool estaDominada(String idPregunta) => _dominadas.contains(idPregunta);

  List<Pregunta> get fallos => _fallos.values.toList();

  bool get retoHechoHoy => _retoDiario == hoy;

  int record(String juego) => _records[juego] ?? 0;

  // Guarda la puntuación si supera el récord. Devuelve true si es nuevo récord
  bool guardarRecord(String juego, int puntos) {
    if (puntos <= record(juego)) return false;
    _records[juego] = puntos;
    notifyListeners();
    _guardar();
    return true;
  }

  // ---------- RACHA DE DÍAS ----------
  // Cuenta hacia atrás los días seguidos con actividad (hoy o, si no, desde ayer)
  int get rachaDias {
    var d = DateTime.now();
    if (!_dias.contains(claveDia(d))) {
      d = DateTime(d.year, d.month, d.day - 1); // ayer
      if (!_dias.contains(claveDia(d))) return 0;
    }
    var n = 0;
    while (_dias.contains(claveDia(d))) {
      n++;
      d = DateTime(d.year, d.month, d.day - 1); // un día antes
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

  // ---------- ACCIONES ----------
  void alternarEstudiado(String id) {
    if (_estudiados.remove(id)) {
      _xp = max(0, _xp - 10);
    } else {
      _estudiados.add(id);
      _xp += 10;
      _dias.add(hoy); // cuenta para la racha
    }
    notifyListeners();
    _guardar();
  }

  void sumarXP(int puntos) {
    _xp = max(0, _xp + puntos);
    if (puntos > 0) _dias.add(hoy);
    notifyListeners();
    _guardar();
  }

  bool marcarDominada(String idPregunta) {
    final esNueva = _dominadas.add(idPregunta);
    if (esNueva) {
      notifyListeners();
      _guardar();
    }
    return esNueva;
  }

  // Apunta una pregunta fallada (las generadas, sin id, no se guardan)
  void registrarFallo(Pregunta p) {
    if (p.id.isEmpty) return;
    _fallos[p.id] = p;
    notifyListeners();
    _guardar();
  }

  // Al acertarla, sale de la lista de fallos
  void quitarFallo(String idPregunta) {
    if (_fallos.remove(idPregunta) != null) {
      notifyListeners();
      _guardar();
    }
  }

  void marcarRetoHecho() {
    _retoDiario = hoy;
    notifyListeners();
    _guardar();
  }

  // ---------- GUARDAR / CARGAR ----------
  Future<void> cargar() async {
    final prefs = await SharedPreferences.getInstance();
    final texto = prefs.getString(_clave);
    if (texto == null) return;

    final datos = jsonDecode(texto) as Map<String, dynamic>;
    _xp = datos['xp'] as int? ?? 0;
    _estudiados.addAll((datos['estudiados'] as List? ?? []).cast<String>());
    _dominadas.addAll((datos['dominadas'] as List? ?? []).cast<String>());
    _dias.addAll((datos['dias'] as List? ?? []).cast<String>());
    _retoDiario = datos['retoDiario'] as String? ?? '';
    _records.addAll(
      (datos['records'] as Map<String, dynamic>? ?? {}).cast<String, int>(),
    );
    for (final f in datos['fallos'] as List? ?? []) {
      final p = Pregunta.fromJson(f as Map<String, dynamic>);
      _fallos[p.id] = p;
    }
  }

  Future<void> _guardar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _clave,
      jsonEncode({
        'xp': _xp,
        'estudiados': _estudiados.toList(),
        'dominadas': _dominadas.toList(),
        'dias': _dias.toList(),
        'retoDiario': _retoDiario,
        'records': _records,
        'fallos': [for (final p in _fallos.values) p.toJson()],
      }),
    );
  }
}

final progreso = Progreso();
