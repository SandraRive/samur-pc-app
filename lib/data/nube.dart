import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'progreso.dart';

enum EstadoNube { desconectada, sincronizando, alDia, error }

// Se encarga de sincronizar tu progreso con Firestore
class Nube extends ChangeNotifier {
  EstadoNube estado = EstadoNube.desconectada;
  DateTime? ultimaSync;
  String? error;

  Timer? _espera;
  int _ultimoSubido = -1;

  // Tu documento en Firestore: usuarios/{tu id}
  DocumentReference<Map<String, dynamic>>? get _documento {
    final usuario = FirebaseAuth.instance.currentUser;
    if (usuario == null) return null;
    return FirebaseFirestore.instance.collection('usuarios').doc(usuario.uid);
  }

  void iniciar() {
    // 1) Cada vez que cambie tu progreso, programamos una subida
    progreso.addListener(_programarSubida);

    // 2) Cada vez que inicies (o cierres) sesión
    FirebaseAuth.instance.authStateChanges().listen((usuario) {
      if (usuario == null) {
        _cambiarEstado(EstadoNube.desconectada);
      } else {
        sincronizar();
      }
    });
  }

  // Compara móvil y nube y se queda con el más reciente
  Future<void> sincronizar() async {
    final doc = _documento;
    if (doc == null) return;
    _cambiarEstado(EstadoNube.sincronizando);
    try {
      final foto = await doc.get();
      final remoto = foto.data();
      final fechaRemota = (remoto?['actualizado'] as num?)?.toInt() ?? 0;

      if (remoto != null && fechaRemota > progreso.actualizado) {
        // ☁️ → 📱 La nube es más nueva: la bajamos
        _ultimoSubido = fechaRemota;
        progreso.reemplazarCon(remoto);
      } else {
        // 📱 → ☁️ El móvil es más nuevo (o la nube está vacía): lo subimos
        await _subir();
      }
      _exito();
    } catch (e) {
      _fallo(e);
    }
  }

  Future<void> _subir() async {
    final doc = _documento;
    if (doc == null) return;
    final datos = progreso.aJson();
    await doc.set(datos);
    _ultimoSubido = datos['actualizado'] as int;
  }

  // "Debounce": espera 3 s sin cambios antes de subir
  void _programarSubida() {
    if (_documento == null) return;
    _espera?.cancel(); // si ya había una subida esperando, la reinicia
    _espera = Timer(const Duration(seconds: 3), () async {
      if (progreso.actualizado == _ultimoSubido) return; // nada nuevo que subir
      _cambiarEstado(EstadoNube.sincronizando);
      try {
        await _subir();
        _exito();
      } catch (e) {
        _fallo(e);
      }
    });
  }

  void _exito() {
    ultimaSync = DateTime.now();
    error = null;
    _cambiarEstado(EstadoNube.alDia);
  }

  void _fallo(Object e) {
    error = '$e';
    _cambiarEstado(EstadoNube.error);
  }

  void _cambiarEstado(EstadoNube nuevo) {
    estado = nuevo;
    notifyListeners();
  }
}

final nube = Nube();
