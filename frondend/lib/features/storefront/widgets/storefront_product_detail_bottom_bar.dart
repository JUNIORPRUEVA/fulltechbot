import 'package:flutter/material.dart';

import '../theme/storefront_theme.dart';

/// Barra inferior fija con botones de acción principales.
/// Diseño elegante con sombra superior suave.
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
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPadding + 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Botón Agregar al carrito (outlined)
            Expanded(
              child: SizedBox(
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: canBuy ? onAddToCart : null,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryColor,
                    side: BorderSide(color: primaryColor.withValues(alpha: 0.3)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  icon: const Icon(Icons.add_shopping_cart_outlined, size: 20),
                  label: const Text(
                    'Agregar',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Botón Comprar / WhatsApp (sólido)
            Expanded(
              flex: canWhatsapp ? 1 : 1,
              child: SizedBox(
                height: 50,
                child: FilledButton.icon(
                  onPressed: canBuy
                      ? onBuyNow
                      : (canWhatsapp ? onWhatsapp : null),
                  style: FilledButton.styleFrom(
                    backgroundColor: canBuy
                        ? primaryColor
                        : const Color(0xFF25D366),
                    disabledBackgroundColor: const Color(0xFFCBD5E1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  icon: Icon(
                    canBuy
                        ? Icons.shopping_bag_outlined
                        : Icons.chat_outlined,
                    size: 20,
                  ),
                  label: Text(
                    canBuy ? 'Comprar' : 'WhatsApp',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
            // Botón WhatsApp adicional si ya hay compra
            if (canBuy && canWhatsapp) ...[
              const SizedBox(width: 10),
              SizedBox(
                height: 50,
                width: 50,
                child: OutlinedButton(
                  onPressed: onWhatsapp,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: StorefrontColors.whatsapp,
                    side: const BorderSide(color: StorefrontColors.whatsapp),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  child: const Icon(Icons.chat_outlined, size: 22),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
