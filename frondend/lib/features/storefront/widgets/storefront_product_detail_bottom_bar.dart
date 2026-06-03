import 'package:flutter/material.dart';

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
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 360;
            final spacing = compact ? 6.0 : 8.0;
            final fontSize = compact ? 11.0 : 12.0;
            final iconSize = compact ? 16.0 : 18.0;
            final verticalPadding = compact ? 12.0 : 13.0;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: canWhatsapp ? onWhatsapp : null,
                    icon: Image.asset(
                      'assets/whatsappp.png',
                      width: iconSize,
                      height: iconSize,
                      fit: BoxFit.contain,
                    ),
                    label: Text(
                      'WhatsApp',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: fontSize,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF25D366)),
                      foregroundColor: const Color(0xFF25D366),
                      disabledForegroundColor: const Color(0xFF94A3B8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: EdgeInsets.symmetric(vertical: verticalPadding),
                    ),
                  ),
                ),
                SizedBox(width: spacing),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: canBuy ? onAddToCart : null,
                    icon: Icon(Icons.add_shopping_cart_outlined, size: iconSize),
                    label: Text(
                      'Agregar',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: fontSize,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: EdgeInsets.symmetric(vertical: verticalPadding),
                    ),
                  ),
                ),
                SizedBox(width: spacing),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: canBuy ? onBuyNow : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: primaryColor,
                      disabledBackgroundColor: const Color(0xFFCBD5E1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: EdgeInsets.symmetric(vertical: verticalPadding),
                    ),
                    icon: Icon(Icons.shopping_bag_outlined, size: iconSize),
                    label: Text(
                      'Comprar',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: fontSize,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
