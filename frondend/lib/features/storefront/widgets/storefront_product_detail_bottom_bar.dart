import 'package:flutter/material.dart';

/// Barra inferior fija para detalle de producto (solo móvil).
/// Botón WhatsApp con icono real de WhatsApp y diseño premium.
class StorefrontProductDetailBottomBar extends StatelessWidget {
  final bool canBuy;
  final bool canWhatsapp;
  final Color primaryColor;
  final VoidCallback? onAddToCart;
  final VoidCallback? onBuyNow;
  final VoidCallback? onWhatsapp;

  const StorefrontProductDetailBottomBar({
    super.key,
    required this.canBuy,
    required this.canWhatsapp,
    required this.primaryColor,
    this.onAddToCart,
    this.onBuyNow,
    this.onWhatsapp,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.98),
        border: const Border(top: BorderSide(color: Color(0xFFE5E7EB))),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Botón WhatsApp (siempre visible si hay WhatsApp configurado)
            if (canWhatsapp) ...[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onWhatsapp,
                  icon: Image.asset(
                    'assets/whatsappp.png',
                    width: 18,
                    height: 18,
                    fit: BoxFit.contain,
                  ),
                  label: const Text(
                    'WhatsApp',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF25D366)),
                    foregroundColor: const Color(0xFF25D366),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              if (canBuy) const SizedBox(width: 10),
            ],

            // Botón Agregar al carrito
            if (canBuy) ...[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onAddToCart,
                  icon: const Icon(Icons.add_shopping_cart_outlined, size: 18),
                  label: const Text(
                    'Agregar',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onBuyNow,
                  style: FilledButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                  label: const Text(
                    'Comprar',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
