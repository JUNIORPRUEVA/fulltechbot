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
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
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
          children: [
            _CompactActionIcon(
              onTap: canWhatsapp ? onWhatsapp : null,
              borderColor: const Color(0xFF25D366),
              foregroundColor: const Color(0xFF25D366),
              child: Image.asset(
                'assets/whatsappp.png',
                width: 18,
                height: 18,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 8),
            _CompactActionIcon(
              onTap: canBuy ? onAddToCart : null,
              borderColor: const Color(0xFFE2E8F0),
              foregroundColor: const Color(0xFF0F172A),
              child: const Icon(Icons.add_shopping_cart_outlined, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: canBuy ? onBuyNow : null,
                style: FilledButton.styleFrom(
                  backgroundColor: primaryColor,
                  disabledBackgroundColor: const Color(0xFFCBD5E1),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                ),
                icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                label: const Text(
                  'Comprar',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactActionIcon extends StatelessWidget {
  final VoidCallback? onTap;
  final Color borderColor;
  final Color foregroundColor;
  final Widget child;

  const _CompactActionIcon({
    required this.onTap,
    required this.borderColor,
    required this.foregroundColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;

    return SizedBox(
      width: 50,
      height: 50,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          side: BorderSide(
            color: isEnabled ? borderColor : const Color(0xFFE2E8F0),
          ),
          foregroundColor: isEnabled
              ? foregroundColor
              : const Color(0xFF94A3B8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: child,
      ),
    );
  }
}
