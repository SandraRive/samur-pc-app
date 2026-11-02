import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'manual.dart';

// Un rango de la guardia
class Rango {
  final int xp; // XP mínima para alcanzarlo
  final String nombre;
  final String descripcion;

  const Rango(this.xp, this.nombre, this.descripcion);
}

// Los mismos rangos que tu web
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

// Tu progreso: qué has estudiado y cuánta XP llevas.
// Es un ChangeNotifier: cuando cambia, avisa a las pantallas que lo escuchan.
class Progreso extends ChangeNotifier {
  static const _clave = 'samurpc-v1'; // la misma clave que tu web

  final Set<String> _estudiados = {};
  int _xp = 0;

  int get xp => _xp;

  bool estaEstudiado(String id) => _estudiados.contains(id);

  // Cuántos de una lista de procedimientos están estudiados
  int cuantosEstudiados(Iterable<Procedimiento> procs) =>
      procs.where((p) => estaEstudiado(p.id)).length;

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

  // De 0.0 a 1.0: cuánto llevas del rango actual al siguiente
  double get porcentajeRango {
    final sig = siguienteRango;
    if (sig == null) return 1;
    return ((_xp - rango.xp) / (sig.xp - rango.xp)).clamp(0.0, 1.0).toDouble();
  }

  // ---------- ACCIONES ----------
  void alternarEstudiado(String id) {
    if (_estudiados.remove(id)) {
      _xp = max(0, _xp - 10); // lo desmarcas → -10 XP
    } else {
      _estudiados.add(id); // lo marcas → +10 XP
      _xp += 10;
    }
    notifyListeners(); // 📣 "¡He cambiado!"
    _guardar();
  }

  void sumarXP(int puntos) {
    _xp = max(0, _xp + puntos);
    notifyListeners();
    _guardar();
  }

  // ---------- GUARDAR / CARGAR EN EL MÓVIL ----------
  Future<void> cargar() async {
    final prefs = await SharedPreferences.getInstance();
    final texto = prefs.getString(_clave);
    if (texto == null) return; // primera vez: no hay nada guardado

    final datos = jsonDecode(texto) as Map<String, dynamic>;
    _xp = datos['xp'] as int? ?? 0;
    _estudiados.addAll((datos['estudiados'] as List? ?? []).cast<String>());
  }

  Future<void> _guardar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _clave,
      jsonEncode({'xp': _xp, 'estudiados': _estudiados.toList()}),
    );
  }
}

// Tu progreso, disponible para toda la app
final progreso = Progreso();
