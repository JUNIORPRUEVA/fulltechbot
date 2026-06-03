import 'package:flutter/material.dart';

import '../theme/storefront_theme.dart';

class StorefrontProductActionBar extends StatelessWidget {
  final bool isDesktop;
  final bool canBuy;
  final bool canWhatsapp;
  final int quantity;
  final Color primaryColor;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final VoidCallback? onAddToCart;
  final VoidCallback? onBuyNow;
  final VoidCallback? onWhatsapp;

  const StorefrontProductActionBar({
    super.key,
    required this.isDesktop,
    required this.canBuy,
    required this.canWhatsapp,
    required this.quantity,
    required this.primaryColor,
    required this.onDecrease,
    required this.onIncrease,
    required this.onAddToCart,
    required this.onBuyNow,
    required this.onWhatsapp,
  });

  @override
  Widget build(BuildContext context) {
    if (isDesktop) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cantidad',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          _QuantitySelector(
            quantity: quantity,
            onDecrease: onDecrease,
            onIncrease: onIncrease,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: canBuy ? onBuyNow : null,
              style: FilledButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              icon: const Icon(Icons.bolt_rounded),
              label: const Text('Comprar ahora'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: canBuy ? onAddToCart : null,
              icon: const Icon(Icons.shopping_cart_outlined),
              label: const Text('Agregar al carrito'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: canWhatsapp ? onWhatsapp : null,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: StorefrontColors.whatsapp),
                foregroundColor: StorefrontColors.whatsapp,
                disabledForegroundColor: const Color(0xFF94A3B8),
              ),
              icon: const Icon(Icons.chat_outlined),
              label: const Text('Consultar por WhatsApp'),
            ),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.98),
        border: const Border(top: BorderSide(color: Color(0xFFE5E7EB))),
        boxShadow: StorefrontShadows.medium,
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
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: StorefrontColors.whatsapp),
                      foregroundColor: StorefrontColors.whatsapp,
                      disabledForegroundColor: const Color(0xFF94A3B8),
                      padding: EdgeInsets.symmetric(vertical: verticalPadding),
                    ),
                    icon: Icon(Icons.chat_outlined, size: iconSize),
                    label: Text(
                      'WhatsApp',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: fontSize),
                    ),
                  ),
                ),
                SizedBox(width: spacing),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: canBuy ? onAddToCart : null,
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: verticalPadding),
                    ),
                    icon: Icon(Icons.add_shopping_cart_outlined, size: iconSize),
                    label: Text(
                      'Agregar',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: fontSize),
                    ),
                  ),
                ),
                SizedBox(width: spacing),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: canBuy ? onBuyNow : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: EdgeInsets.symmetric(vertical: verticalPadding),
                    ),
                    icon: Icon(Icons.shopping_bag_outlined, size: iconSize),
                    label: Text(
                      'Comprar',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: fontSize),
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

class _QuantitySelector extends StatelessWidget {
  final int quantity;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  const _QuantitySelector({
    required this.quantity,
    required this.onDecrease,
    required this.onIncrease,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: quantity > 1 ? onDecrease : null,
            icon: const Icon(Icons.remove_rounded),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '$quantity',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          IconButton(
            onPressed: onIncrease,
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
    );
  }
}
