import 'package:flutter/material.dart';

class FollowupTypeBadge extends StatelessWidget {
  final String tipo;
  final double fontSize;

  const FollowupTypeBadge({
    super.key,
    required this.tipo,
    this.fontSize = 10,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getConfig();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: config.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: config.color.withValues(alpha: 0.2)),
      ),
      child: Text(
        config.label,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: config.color,
        ),
      ),
    );
  }

  _TypeConfig _getConfig() {
    switch (tipo) {
      case 'fecha_futura':
        return _TypeConfig(label: 'Fecha futura', color: const Color(0xFF2563EB));
      case 'reserva_instalacion':
        return _TypeConfig(label: 'Reserva instalación', color: const Color(0xFF7C3AED));
      case 'seguimiento_cotizacion':
        return _TypeConfig(label: 'Seg. cotización', color: const Color(0xFF0D9488));
      case 'esperando_pago':
        return _TypeConfig(label: 'Esperando pago', color: const Color(0xFFF59E0B));
      case 'coordinacion_visita':
        return _TypeConfig(label: 'Coord. visita', color: const Color(0xFF0891B2));
      case 'cliente_interesado':
        return _TypeConfig(label: 'Cliente interesado', color: const Color(0xFF059669));
      case 'seguimiento_instalacion':
        return _TypeConfig(label: 'Seg. instalación', color: const Color(0xFF4F46E5));
      case 'seguimiento_motor':
        return _TypeConfig(label: 'Seg. motor', color: const Color(0xFFDC2626));
      case 'seguimiento_camaras':
        return _TypeConfig(label: 'Seg. cámaras', color: const Color(0xFF0891B2));
      case 'seguimiento_componente':
        return _TypeConfig(label: 'Seg. componente', color: const Color(0xFF0D9488));
      case 'seguimiento_confirmacion':
        return _TypeConfig(label: 'Seg. confirmación', color: const Color(0xFF7C3AED));
      default:
        return _TypeConfig(label: tipo.replaceAll('_', ' '), color: const Color(0xFF6B7280));
    }
  }
}

class _TypeConfig {
  final String label;
  final Color color;

  const _TypeConfig({required this.label, required this.color});
}
