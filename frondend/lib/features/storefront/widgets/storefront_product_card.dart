import 'package:flutter/material.dart';

import '../services/storefront_api_service.dart';
import '../services/storefront_helpers.dart';
import '../theme/storefront_theme.dart';
import 'storefront_price_widget.dart';
import 'storefront_smart_image.dart';
import '../../../core/utils/image_utils.dart';

class StorefrontProductCard extends StatefulWidget {
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
  State<StorefrontProductCard> createState() => _StorefrontProductCardState();
}

class _StorefrontProductCardState extends State<StorefrontProductCard> {
  bool _isHovered = false;
  bool _adding = false;
  
  /// Versión del producto para versionado de imágenes
  String? get _imageVersion => StorefrontHelpers.getProductVersion(widget.product);


  Future<void> _addToCart() async {
    if (_adding) {
      return;
    }

    final product = widget.product;
    final productId = product['id']?.toString();
    final title = product['titulo']?.toString().trim();
    if (productId == null || productId.isEmpty || title == null || title.isEmpty) {
      return;
    }

    setState(() => _adding = true);
    try {
      final sessionId = await StorefrontHelpers.ensureSessionId(widget.slug);
      await StorefrontApiService.createCart(widget.slug, sessionId);
      final response = await StorefrontApiService.addCartItem(
        widget.slug,
        sessionId,
        productoId: productId,
        nombreProducto: title,
        cantidad: 1,
        precioUnitario: StorefrontHelpers.getEffectivePrice(product).toDouble(),
        imagenUrl: StorefrontHelpers.getPrimaryImage(product),
      );

      if (!mounted) {
        return;
      }

      final messenger = ScaffoldMessenger.of(context);
      if (response['ok'] == true) {
        messenger.showSnackBar(
          SnackBar(content: Text('$title agregado al carrito')),
        );
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text(response['message']?.toString() ?? 'No se pudo agregar al carrito')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _adding = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final price = StorefrontHelpers.getEffectivePrice(product);
    final originalPrice = StorefrontHelpers.getOriginalPrice(product);
    final image = StorefrontHelpers.getPrimaryImage(product);
    final category = product['categoria']?.toString().trim() ?? '';
    final title = product['titulo']?.toString() ?? '';
    final stock = int.tryParse(product['stock']?.toString() ?? '') ?? 0;
    final hasOffer = originalPrice != null && originalPrice > price;
    final isDesktop = MediaQuery.sizeOf(context).width >= 1024;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(
          context,
          '/tienda/${widget.slug}/producto/${product['id']}',
          arguments: {'product': product},
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          transform: _isHovered && isDesktop
              ? (Matrix4.identity()..translateByDouble(0, -4, 0, 1))
              : Matrix4.identity(),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(widget.compact ? 20 : 24),
            border: Border.all(color: const Color(0xFFE8EDF3)),
            boxShadow: _isHovered && isDesktop
                ? StorefrontShadows.medium
                : const [
                    BoxShadow(
                      color: Color(0x080F172A),
                      blurRadius: 14,
                      offset: Offset(0, 6),
                    ),
                  ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: widget.compact ? 12 : 13,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFFF8FAFD), Color(0xFFF2F5F9)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: StorefrontSmartImage(
                              source: image,
                              fit: BoxFit.contain,
                              version: _imageVersion,
                              placeholder: _placeholderImage(),
                            ),

                        ),
                      ),
                    ),
                    if (hasOffer)
                      const Positioned(
                        top: 10,
                        left: 10,
                        child: _OfferBadge(),
                      ),
                    Positioned(
                      right: 10,
                      bottom: 10,
                      child: _AddCartButton(
                        loading: _adding,
                        primaryColor: widget.primaryColor,
                        onTap: _addToCart,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: widget.compact ? 10 : 9,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    widget.compact ? 10 : 12,
                    10,
                    widget.compact ? 10 : 12,
                    widget.compact ? 10 : 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (category.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: widget.primaryColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            category,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: widget.primaryColor,
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: widget.compact ? 13.2 : 14.5,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF111827),
                          height: 1.24,
                        ),
                      ),
                      const Spacer(),
                      if (stock > 0)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              Icon(
                                Icons.verified_rounded,
                                size: 13,
                                color: widget.secondaryColor,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  stock > 9 ? 'Disponible' : 'Ultimas unidades',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      StorefrontPriceWidget(
                        precio: price,
                        precioOriginal: originalPrice,
                        primaryColor: widget.primaryColor,
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
    );
  }

  Widget _placeholderImage() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF8FAFC), Color(0xFFEAF1F9)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.image_outlined,
          size: 34,
          color: Color(0xFFCBD5E1),
        ),
      ),
    );
  }
}

class _AddCartButton extends StatelessWidget {
  final bool loading;
  final Color primaryColor;
  final VoidCallback onTap;

  const _AddCartButton({
    required this.loading,
    required this.primaryColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: primaryColor,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: loading ? null : onTap,
        borderRadius: BorderRadius.circular(999),
        child: SizedBox(
          width: 34,
          height: 34,
          child: loading
              ? const Padding(
                  padding: EdgeInsets.all(9),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(
                  Icons.add_shopping_cart_rounded,
                  size: 18,
                  color: Colors.white,
                ),
        ),
      ),
    );
  }
}

class _OfferBadge extends StatelessWidget {
  const _OfferBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF97316), Color(0xFFEA580C)],
        ),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        'Oferta',
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
