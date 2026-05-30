import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/storefront_api_service.dart';
import '../services/storefront_helpers.dart';
import '../theme/storefront_theme.dart';
import 'storefront_price_widget.dart';
import 'storefront_smart_image.dart';

class StorefrontProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final String slug;
  final Color primaryColor;
  final Color secondaryColor;
  final bool compact;
  final String? whatsapp;

  const StorefrontProductCard({
    super.key,
    required this.product,
    required this.slug,
    required this.primaryColor,
    required this.secondaryColor,
    this.compact = false,
    this.whatsapp,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 1024;
    return LayoutBuilder(
      builder: (context, constraints) {
        final isListCompact = compact && !constraints.hasBoundedHeight;

        if (isListCompact) {
          return _ListProductCard(
            product: product,
            slug: slug,
            primaryColor: primaryColor,
            secondaryColor: secondaryColor,
            whatsapp: whatsapp,
          );
        }

        return _GridProductCard(
          product: product,
          slug: slug,
          primaryColor: primaryColor,
          secondaryColor: secondaryColor,
          whatsapp: whatsapp,
          isDesktop: isDesktop,
        );
      },
    );
  }
}

class _GridProductCard extends StatefulWidget {
  final Map<String, dynamic> product;
  final String slug;
  final Color primaryColor;
  final Color secondaryColor;
  final String? whatsapp;
  final bool isDesktop;

  const _GridProductCard({
    required this.product,
    required this.slug,
    required this.primaryColor,
    required this.secondaryColor,
    required this.whatsapp,
    required this.isDesktop,
  });

  @override
  State<_GridProductCard> createState() => _GridProductCardState();
}

class _GridProductCardState extends State<_GridProductCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final title = widget.product['titulo']?.toString().trim() ?? '';
    final description = StorefrontHelpers.getShortDescription(widget.product);
    final price = StorefrontHelpers.getDisplayPrice(widget.product);
    final originalPrice = StorefrontHelpers.getOriginalPrice(widget.product);
    final image = StorefrontHelpers.getPrimaryImage(widget.product);
    final productId = widget.product['id']?.toString() ?? '';
    final stock = int.tryParse(widget.product['stock']?.toString() ?? '0') ?? 0;
    final hasStock = stock > 0;
    final hasPrice = price != null && price > 0;

    return AnimatedScale(
      scale: _pressed ? 0.985 : 1,
      duration: const Duration(milliseconds: 140),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(widget.isDesktop ? 20 : 16),
        child: InkWell(
          onTap: () => _openProduct(context, productId),
          onHighlightChanged: (value) => setState(() => _pressed = value),
          borderRadius: BorderRadius.circular(widget.isDesktop ? 20 : 16),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.isDesktop ? 20 : 16),
              boxShadow: StorefrontShadows.soft,
              border: Border.all(color: const Color(0xFFE8EEF4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: widget.isDesktop ? 60 : 58,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(widget.isDesktop ? 20 : 16),
                        ),
                        child: DecoratedBox(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                          child: StorefrontSmartImage(
                            source: image,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        left: 8,
                        child: _StatusBadge(
                          label: hasStock ? 'Disponible' : 'Agotado',
                          color: hasStock
                              ? const Color(0xFF16A34A)
                              : const Color(0xFFDC2626),
                        ),
                      ),
                      if (originalPrice != null && hasPrice)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: _StatusBadge(
                            label: 'Oferta',
                            color: const Color(0xFFEA580C),
                          ),
                        ),
                      Positioned(
                        right: 8,
                        bottom: 8,
                        child: _CardActionButton(
                          primaryColor: widget.primaryColor,
                          icon: hasPrice
                              ? Icons.add_shopping_cart_rounded
                              : Icons.chat_bubble_outline_rounded,
                          onTap: () => hasPrice
                              ? _addToCart(context)
                              : _quoteProduct(context, title),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: widget.isDesktop ? 40 : 42,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      widget.isDesktop ? 12 : 8,
                      widget.isDesktop ? 10 : 8,
                      widget.isDesktop ? 12 : 8,
                      widget.isDesktop ? 12 : 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title.isEmpty ? 'Producto sin nombre' : title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: widget.isDesktop ? 13.5 : 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: widget.isDesktop ? 11.5 : 10.5,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF64748B),
                            height: 1.28,
                          ),
                        ),
                        const Spacer(),
                        StorefrontPriceWidget(
                          precio: price,
                          precioOriginal: originalPrice,
                          primaryColor: widget.primaryColor,
                          large: false,
                          currencyPrefix: 'RD\$',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _addToCart(BuildContext context) async {
    try {
      final sessionId = await StorefrontHelpers.ensureSessionId(widget.slug);
      final image = StorefrontHelpers.getPrimaryImage(widget.product);
      final price = StorefrontHelpers.getDisplayPrice(widget.product) ?? 0;
      final title = widget.product['titulo']?.toString() ?? 'Producto';
      final productId = widget.product['id']?.toString() ?? '';

      await StorefrontApiService.addCartItem(
        widget.slug,
        sessionId,
        productoId: productId,
        nombreProducto: title,
        cantidad: 1,
        precioUnitario: price.toDouble(),
        imagenUrl: image,
      );

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$title agregado al carrito'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al agregar al carrito'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _quoteProduct(BuildContext context, String title) async {
    final phone = widget.whatsapp?.replaceAll(RegExp(r'[^\d]'), '') ?? '';
    if (phone.isEmpty) {
      _openProduct(context, widget.product['id']?.toString() ?? '');
      return;
    }

    final url =
        'https://wa.me/$phone?text=${Uri.encodeComponent('Hola FULLTECH, quiero cotizar: $title')}';
    await launchUrl(Uri.parse(url));
  }

  void _openProduct(BuildContext context, String productId) {
    if (productId.isEmpty) return;
    Navigator.pushNamed(context, '/tienda/${widget.slug}/producto/$productId');
  }
}

class _ListProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final String slug;
  final Color primaryColor;
  final Color secondaryColor;
  final String? whatsapp;

  const _ListProductCard({
    required this.product,
    required this.slug,
    required this.primaryColor,
    required this.secondaryColor,
    required this.whatsapp,
  });

  @override
  Widget build(BuildContext context) {
    final title = product['titulo']?.toString().trim() ?? '';
    final description = StorefrontHelpers.getShortDescription(product);
    final image = StorefrontHelpers.getPrimaryImage(product);
    final price = StorefrontHelpers.getDisplayPrice(product);
    final originalPrice = StorefrontHelpers.getOriginalPrice(product);
    final productId = product['id']?.toString() ?? '';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () => Navigator.pushNamed(
          context,
          '/tienda/$slug/producto/$productId',
        ),
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE5EAF1)),
            boxShadow: StorefrontShadows.soft,
          ),
          child: Row(
            children: [
              SizedBox(
                width: 92,
                height: 92,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: StorefrontSmartImage(source: image, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.isEmpty ? 'Producto sin nombre' : title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 10),
                    StorefrontPriceWidget(
                      precio: price,
                      precioOriginal: originalPrice,
                      primaryColor: primaryColor,
                      currencyPrefix: 'RD\$',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
    );
  }
}

class _CardActionButton extends StatelessWidget {
  final Color primaryColor;
  final IconData icon;
  final VoidCallback onTap;

  const _CardActionButton({
    required this.primaryColor,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: primaryColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(icon, size: 18, color: Colors.white),
        ),
      ),
    );
  }
}
