import 'package:flutter/widgets.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

// Traduce el nombre del icono del data.json al icono de Lucide,
// exactamente igual que hace tu web
const _iconos = <String, IconData>{
  'users': LucideIcons.users,
  'shield': LucideIcons.shieldCheck,
  'hand': LucideIcons.handHelping,
  'phone': LucideIcons.phoneCall,
  'message': LucideIcons.messageSquareHeart,
  'chat': LucideIcons.messagesSquare,
  'route': LucideIcons.route,
  'link': LucideIcons.link2,
  'heart-hand': LucideIcons.heartHandshake,
  'code': LucideIcons.hash,
  'truck': LucideIcons.truck,
  'alert': LucideIcons.triangleAlert,
  'brain': LucideIcons.brain,
  'lungs': LucideIcons.wind,
  'flask': LucideIcons.flaskConical,
  'heart': LucideIcons.heart,
  'stomach': LucideIcons.stethoscope,
  'drop': LucideIcons.droplet,
  'kidney': LucideIcons.bean,
  'neuro': LucideIcons.brainCircuit,
  'baby': LucideIcons.baby,
  'child': LucideIcons.smile,
  'bolt': LucideIcons.zap,
  'mind': LucideIcons.brainCog,
  'bone': LucideIcons.bone,
  'pulse': LucideIcons.activity,
  'eye': LucideIcons.eye,
  'tools': LucideIcons.wrench,
  'wave': LucideIcons.audioWaveform,
  'soap': LucideIcons.sparkles,
  'tube': LucideIcons.pipette,
  'bandage': LucideIcons.bandage,
  'syringe': LucideIcons.syringe,
};

// Si algún nombre no está en la lista, usa un icono de documento
IconData iconoWeb(String nombre) => _iconos[nombre] ?? LucideIcons.fileText;
