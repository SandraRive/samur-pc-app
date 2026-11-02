import 'dart:math';

import 'package:flutter/material.dart';

// Una carta que muestra el frente o el dorso con un giro 3D.
// Quien la usa decide cuándo está girada (girada: true/false).
class CartaGiratoria extends StatelessWidget {
  final bool girada;
  final Widget frente;
  final Widget dorso;

  const CartaGiratoria({
    super.key,
    required this.girada,
    required this.frente,
    required this.dorso,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: girada ? pi : 0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      builder: (context, angulo, _) {
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0015)
            ..rotateY(angulo),
          child: angulo < pi / 2
              ? frente
              : Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.rotationY(pi),
                  child: dorso,
                ),
        );
      },
    );
  }
}
