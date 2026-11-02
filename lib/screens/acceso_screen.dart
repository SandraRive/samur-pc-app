import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/entreno.dart';
import '../theme/app_theme.dart';
import '../widgets/formulario_acceso.dart';
import '../widgets/monitor_ecg.dart';

// Lo primero que ves si no has iniciado sesión
class AccesoScreen extends StatelessWidget {
  const AccesoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            // ---------- LA TARJETA PRINCIPAL ----------
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.panel, Color(0xFF0D1324)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFF2E3E63)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Franja de chevrones naranja y amarilla
                    const SizedBox(
                      height: 14,
                      width: double.infinity,
                      child: CustomPaint(painter: _PintorFranja()),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Etiqueta con el punto rojo que late
                          Row(
                            children: [
                              const _PuntoLatiendo(),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'MANUAL DE PROCEDIMIENTOS · EDICIÓN 2026',
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 11,
                                    letterSpacing: 1.2,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.naranja,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Título enorme
                          Text.rich(
                            const TextSpan(
                              children: [
                                TextSpan(text: 'SAMUR'),
                                TextSpan(
                                  text: '·',
                                  style: TextStyle(color: AppColors.naranja),
                                ),
                                TextSpan(text: 'PC'),
                              ],
                            ),
                            style: GoogleFonts.unbounded(
                              fontSize: 42,
                              fontWeight: FontWeight.w900,
                              height: 1.0,
                              letterSpacing: -1,
                            ),
                          ),
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: 'en ',
                                  style: GoogleFonts.unbounded(
                                    fontWeight: FontWeight.w300,
                                    color: AppColors.naranja,
                                  ),
                                ),
                                const TextSpan(text: 'modo guardia'),
                              ],
                            ),
                            style: GoogleFonts.unbounded(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Tu manual, tus tests y tu entreno, siempre contigo.',
                            style: TextStyle(
                              height: 1.4,
                              color: AppColors.texto2,
                            ),
                          ),
                          const SizedBox(height: 18),

                          // 💚 El monitor con el ECG animado
                          const MonitorEcg(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 26),

            // ---------- EL FORMULARIO ----------
            const FormularioAcceso(),
            const SizedBox(height: 30),

            // ---------- TU MARCA ----------
            Center(
              child: Opacity(
                opacity: 0.9,
                child: Image.asset('assets/images/marca.png', height: 64),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== FRANJA DE CHEVRONES ====================
class _PintorFranja extends CustomPainter {
  const _PintorFranja();

  @override
  void paint(Canvas canvas, Size size) {
    // Fondo amarillo…
    canvas.drawRect(Offset.zero & size, Paint()..color = cAmarillo);
    // …y rayas naranjas inclinadas encima
    final naranja = Paint()..color = AppColors.naranja;
    const ancho = 18.0;
    final alto = size.height;
    for (double x = -alto; x < size.width + alto; x += ancho * 2) {
      final raya = Path()
        ..moveTo(x, alto)
        ..lineTo(x + ancho, alto)
        ..lineTo(x + ancho + alto, 0)
        ..lineTo(x + alto, 0)
        ..close();
      canvas.drawPath(raya, naranja);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter viejo) => false; // nunca cambia
}

// ==================== PUNTO ROJO QUE LATE ====================
class _PuntoLatiendo extends StatefulWidget {
  const _PuntoLatiendo();

  @override
  State<_PuntoLatiendo> createState() => _PuntoLatiendoState();
}

class _PuntoLatiendoState extends State<_PuntoLatiendo>
    with SingleTickerProviderStateMixin {
  // Va de 0 a 1 y vuelve, una y otra vez
  late final AnimationController _latido = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 857), // al ritmo del ECG (70 lpm)
  )..repeat(reverse: true);

  @override
  void dispose() {
    _latido.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _latido,
      builder: (context, _) => Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: cRojo,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: cRojo.withValues(alpha: 0.7 * _latido.value),
              blurRadius: 4 + 8 * _latido.value, // el brillo crece y decrece
              spreadRadius: 2 * _latido.value,
            ),
          ],
        ),
      ),
    );
  }
}
