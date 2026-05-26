import 'package:flutter/material.dart';

class FollowupStatusBadge extends StatelessWidget {
  final String estado;
  final double fontSize;

  const FollowupStatusBadge({
    super.key,
    required this.estado,
    this.fontSize = 10,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getConfig();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: config.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: config.color.withValues(alpha: 0.3)),
      ),
      child: Text(
        config.label.toUpperCase(),
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          color: config.color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  _StatusConfig _getConfig() {
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return _StatusConfig(
          label: 'Pendiente',
          color: const Color(0xFFF59E0B),
        );
      case 'finalizado':
        return _StatusConfig(
          label: 'Finalizado',
          color: const Color(0xFF10B981),
        );
      case 'cancelado':
        return _StatusConfig(
          label: 'Cancelado',
          color: const Color(0xFFEF4444),
        );
      case 'recuperado':
        return _StatusConfig(
          label: 'Recuperado',
          color: const Color(0xFF8B5CF6),
        );
      case 'pausado':
        return _StatusConfig(
          label: 'Pausado',
          color: const Color(0xFF6B7280),
        );
      default:
        return _StatusConfig(
          label: estado,
          color: const Color(0xFF6B7280),
        );
    }
  }
}

class _StatusConfig {
  final String label;
  final Color color;

  const _StatusConfig({required this.label, required this.color});
}
