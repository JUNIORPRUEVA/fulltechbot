import 'package:flutter/material.dart';

class StorefrontCategoryChip extends StatelessWidget {
  final String categoria;
  final int total;
  final Color primaryColor;
  final Color secondaryColor;
  final VoidCallback onTap;
  final IconData? icon;

  const StorefrontCategoryChip({
    super.key,
    required this.categoria,
    required this.total,
    required this.primaryColor,
    required this.secondaryColor,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: secondaryColor.withValues(alpha: 0.15),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: secondaryColor),
              const SizedBox(width: 8),
            ],
            Text(
              categoria,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: primaryColor,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: secondaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                '$total',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: secondaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StorefrontCategoryIcon extends StatelessWidget {
  final String categoria;
  final Color primaryColor;
  final Color secondaryColor;
  final VoidCallback onTap;

  const StorefrontCategoryIcon({
    super.key,
    required this.categoria,
    required this.primaryColor,
    required this.secondaryColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFE5E7EB).withValues(alpha: 0.5),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              _getCategoryIcon(categoria),
              size: 24,
              color: secondaryColor,
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 72,
            child: Text(
              categoria,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String categoria) {
    final cat = categoria.toLowerCase();
    if (cat.contains('cámara') || cat.contains('camara') || cat.contains('seguridad')) {
      return Icons.videocam_rounded;
    } else if (cat.contains('motor') || cat.contains('automatización') || cat.contains('automatizacion')) {
      return Icons.precision_manufacturing_rounded;
    } else if (cat.contains('herramienta') || cat.contains('eléctrico') || cat.contains('electrico')) {
      return Icons.handyman_rounded;
    } else if (cat.contains('computadora') || cat.contains('laptop') || cat.contains('pc')) {
      return Icons.computer_rounded;
    } else if (cat.contains('pos') || cat.contains('punto de venta') || cat.contains('venta')) {
      return Icons.point_of_sale_rounded;
    } else if (cat.contains('accesorio') || cat.contains('accesorios')) {
      return Icons.cable_rounded;
    } else if (cat.contains('red') || cat.contains('wifi') || cat.contains('internet')) {
      return Icons.wifi_rounded;
    } else if (cat.contains('audio') || cat.contains('sonido') || cat.contains('parlante')) {
      return Icons.speaker_rounded;
    } else if (cat.contains('oferta') || cat.contains('descuento') || cat.contains('sale')) {
      return Icons.local_offer_rounded;
    }
    return Icons.category_rounded;
  }
}
