import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/entreno.dart';
import '../data/manual.dart';
import '../data/progreso.dart';
import '../theme/app_theme.dart';

// Monitor de constantes con ECG animado, como el de tu web
class MonitorEcg extends StatefulWidget {
  const MonitorEcg({super.key});

  @override
  State<MonitorEcg> createState() => _MonitorEcgState();
}

// "with SingleTickerProviderStateMixin" le da a la pantalla la capacidad de crear un Ticker
class _MonitorEcgState extends State<MonitorEcg>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  double _t = 0; // segundos desde que empezó a dibujarse

  @override
  void initState() {
    super.initState();
    // El Ticker avisa en cada fotograma (unas 60 veces por segundo)
    _ticker = createTicker((transcurrido) {
      setState(() => _t = transcurrido.inMicroseconds / 1e6);
    })..start();
  }

  @override
  void dispose() {
    _ticker.dispose(); // ¡muy importante pararlo al salir!
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ahora = DateTime.now();
    final hora = [
      ahora.hour,
      ahora.minute,
      ahora.second,
    ].map((n) => n.toString().padLeft(2, '0')).join(':');

    // La FC "baila" un poquito en cada latido: 69, 70, 71…
    final latido = (_t / _PintorEcg.latido).floor();
    final fc = 69 + latido % 3;

    final total = manual.procedimientos.length;
    final porcentaje = total == 0
        ? 0
        : (progreso.cuantosEstudiados(manual.procedimientos) * 100 / total)
              .round();

    final mono = GoogleFonts.jetBrainsMono(
      fontSize: 11.5,
      color: AppColors.texto2,
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF05070F),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.linea),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text('DII · 25 mm/s', style: mono),
              const Spacer(),
              Text(hora, style: mono),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 110,
            width: double.infinity,
            // RepaintBoundary: aísla el dibujo para que no repinte toda la pantalla
            child: RepaintBoundary(child: CustomPaint(painter: _PintorEcg(_t))),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _Constante(etiqueta: 'FC', valor: '$fc', color: cVerde),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: _Constante(
                  etiqueta: 'SatO2 %',
                  valor: '98',
                  color: cAmarillo,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Constante(
                  etiqueta: 'ESTUDIADO',
                  valor: '$porcentaje%',
                  color: cCyan,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Una cajita de constante (FC, SatO2…)
class _Constante extends StatelessWidget {
  final String etiqueta;
  final String valor;
  final Color color;

  const _Constante({
    required this.etiqueta,
    required this.valor,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.linea),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            etiqueta,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10,
              letterSpacing: 1,
              color: AppColors.texto2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            valor,
            style: GoogleFonts.unbounded(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== EL DIBUJO DEL ECG ====================
class _PintorEcg extends CustomPainter {
  final double t;

  _PintorEcg(this.t);

  static const latido = 60 / 70; // segundos por latido (70 lpm)

  // La forma de un latido: onda P, complejo QRS y onda T.
  // Cada onda es una "campana" (gaussiana) en su sitio del latido.
  static double ecg(double tiempo) {
    final p =
        (tiempo % latido) / latido; // en qué punto del latido estamos (0 a 1)
    double campana(double centro, double anchura, double altura) =>
        altura * exp(-pow((p - centro) / anchura, 2));
    return campana(0.15, 0.030, 0.12) + // onda P
        campana(0.30, 0.014, -0.14) + // Q
        campana(0.32, 0.020, 1.00) + // R (el pico grande)
        campana(0.345, 0.016, -0.28) + // S
        campana(0.56, 0.050, 0.25); // onda T
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Cuadrícula de fondo, como el papel del electro
    final rejilla = Paint()
      ..color = const Color(0xFF111B2E)
      ..strokeWidth = 1;
    for (double x = 0; x < w; x += 18) {
      canvas.drawLine(Offset(x, 0), Offset(x, h), rejilla);
    }
    for (double y = 0; y < h; y += 18) {
      canvas.drawLine(Offset(0, y), Offset(w, y), rejilla);
    }

    // El "cabezal" recorre la pantalla de izquierda a derecha (3 latidos por pantalla)
    final velocidad = w / (3 * latido); // píxeles por segundo
    final cabeza = (t * velocidad) % w;
    const hueco = 16.0; // el hueco negro delante del cabezal

    double alturaEn(double tiempo) => h * 0.62 - ecg(tiempo) * h * 0.5;

    // Construimos el trazo punto a punto, saltándonos el hueco
    final trazos = <Path>[];
    Path? actual;
    for (double x = 0; x <= w; x += 0.75) {
      if (x > cabeza && x < cabeza + hueco) {
        if (actual != null) trazos.add(actual);
        actual = null;
        continue;
      }
      // Lo que hay detrás del cabezal es "nuevo"; lo de delante, la vuelta anterior
      final tiempo = x <= cabeza
          ? t - (cabeza - x) / velocidad
          : t - (cabeza + w - x) / velocidad;
      final y = alturaEn(tiempo);
      if (actual == null) {
        actual = Path()..moveTo(x, y);
      } else {
        actual.lineTo(x, y);
      }
    }
    if (actual != null) trazos.add(actual);

    // Primero un brillo difuminado, luego la línea nítida encima
    final brillo = Paint()
      ..color = cVerde.withValues(alpha: 0.35)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    final linea = Paint()
      ..color = cVerde
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    for (final trazo in trazos) {
      canvas.drawPath(trazo, brillo);
      canvas.drawPath(trazo, linea);
    }

    // El puntito blanco del cabezal
    canvas.drawCircle(
      Offset(cabeza, alturaEn(t)),
      3.5,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(_PintorEcg viejo) => viejo.t != t; // repinta si ha pasado el tiempo
}
