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
          if (canWhatsapp) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onWhatsapp,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: StorefrontColors.whatsapp),
                  foregroundColor: StorefrontColors.whatsapp,
                ),
                icon: const Icon(Icons.chat_outlined),
                label: const Text('Consultar por WhatsApp'),
              ),
            ),
          ],
        ],
      );
    }

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        border: const Border(top: BorderSide(color: Color(0xFFE5E7EB))),
        boxShadow: StorefrontShadows.medium,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _QuantitySelector(
                quantity: quantity,
                onDecrease: onDecrease,
                onIncrease: onIncrease,
                compact: true,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: canBuy ? onBuyNow : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  icon: const Icon(Icons.shopping_bag_outlined),
                  label: const Text('Comprar'),
                ),
              ),
              if (canWhatsapp) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onWhatsapp,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: StorefrontColors.whatsapp,
                      side: const BorderSide(color: StorefrontColors.whatsapp),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    icon: const Icon(Icons.chat_outlined),
                    label: const Text('WhatsApp'),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: canBuy ? onAddToCart : null,
              icon: const Icon(Icons.add_shopping_cart_outlined),
              label: const Text('Agregar al carrito'),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuantitySelector extends StatelessWidget {
  final int quantity;
  final bool compact;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  const _QuantitySelector({
    required this.quantity,
    required this.onDecrease,
    required this.onIncrease,
    this.compact = false,
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
            visualDensity: compact ? VisualDensity.compact : null,
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: compact ? 2 : 8),
            child: Text(
              '$quantity',
              style: TextStyle(
                fontSize: compact ? 16 : 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          IconButton(
            onPressed: onIncrease,
            icon: const Icon(Icons.add_rounded),
            visualDensity: compact ? VisualDensity.compact : null,
          ),
        ],
      ),
    );
  }
}
