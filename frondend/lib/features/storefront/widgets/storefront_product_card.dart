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
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isDesktop = screenWidth >= 1024;
    final isTablet = screenWidth >= 700 && screenWidth < 1024;

    // En móvil: diseño compacto estilo Temu/Shopee
    if (!isDesktop && !isTablet) {
      return _MobileProductCard(
        product: product,
        slug: slug,
        primaryColor: primaryColor,
        secondaryColor: secondaryColor,
        whatsapp: whatsapp,
      );
    }

    return _DesktopProductCard(
      product: product,
      slug: slug,
      primaryColor: primaryColor,
      secondaryColor: secondaryColor,
      whatsapp: whatsapp,
    );
  }
}

// ==========================================
// MOBILE PRODUCT CARD (estilo Temu/Shopee)
// ==========================================
class _MobileProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final String slug;
  final Color primaryColor;
  final Color secondaryColor;
  final String? whatsapp;

  const _MobileProductCard({
    required this.product,
    required this.slug,
    required this.primaryColor,
    required this.secondaryColor,
    this.whatsapp,
  });

  @override
  Widget build(BuildContext context) {
    final title = product['titulo']?.toString() ?? '';
    final price = StorefrontHelpers.getEffectivePrice(product);
    final originalPrice = StorefrontHelpers.getOriginalPrice(product);
    final image = StorefrontHelpers.getPrimaryImage(product);
    final stock = int.tryParse(product['stock']?.toString() ?? '0') ?? 0;
    final hasStock = stock > 0;
    final productId = product['id']?.toString() ?? '';

    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        '/tienda/$slug/producto/$productId',
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // IMAGEN - 65% de la card
            Expanded(
              flex: 65,
              child: Stack(
                children: [
                  // Imagen principal
                  Positioned.fill(
                    child: StorefrontSmartImage(
                      source: image,
                      fit: BoxFit.cover,
                      placeholder: Container(
                        color: const Color(0xFFF8FAFC),
                        child: const Center(
                          child: Icon(
                            Icons.image_outlined,
                            size: 32,
                            color: Color(0xFFCBD5E1),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Badge de disponibilidad
                  if (hasStock)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF22C55E).withValues(alpha: 0.90),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Disponible',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                        ),
                      ),
                    )
                  else
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.90),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Agotado',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ),
                  // Botón carrito flotante
                  Positioned(
                    bottom: 6,
                    right: 6,
                    child: Material(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(8),
                      child: InkWell(
                        onTap: () => _addToCart(context),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 30,
                          height: 30,
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.add_shopping_cart_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // INFORMACIÓN - 35% de la card
            Expanded(
              flex: 35,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Título - compacto
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                        height: 1.25,
                      ),
                    ),
                    const Spacer(),
                    // Precio - siempre visible
                    StorefrontPriceWidget(
                      precio: price,
                      precioOriginal: originalPrice,
                      primaryColor: primaryColor,
                      large: false,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addToCart(BuildContext context) async {
    try {
      final sessionId = await StorefrontHelpers.ensureSessionId(slug);
      final image = StorefrontHelpers.getPrimaryImage(product);
      final price = StorefrontHelpers.getEffectivePrice(product).toDouble();
      final title = product['titulo']?.toString() ?? '';
      final productId = product['id']?.toString() ?? '';

      await StorefrontApiService.addCartItem(
        slug,
        sessionId,
        productoId: productId,
        nombreProducto: title,
        cantidad: 1,
        precioUnitario: price,
        imagenUrl: image,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$title agregado al carrito'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al agregar al carrito'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// ==========================================
// DESKTOP PRODUCT CARD
// ==========================================
class _DesktopProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final String slug;
  final Color primaryColor;
  final Color secondaryColor;
  final String? whatsapp;

  const _DesktopProductCard({
    required this.product,
    required this.slug,
    required this.primaryColor,
    required this.secondaryColor,
    this.whatsapp,
  });

  @override
  Widget build(BuildContext context) {
    final title = product['titulo']?.toString() ?? '';
    final price = StorefrontHelpers.getEffectivePrice(product);
    final originalPrice = StorefrontHelpers.getOriginalPrice(product);
    final image = StorefrontHelpers.getPrimaryImage(product);
    final stock = int.tryParse(product['stock']?.toString() ?? '0') ?? 0;
    final hasStock = stock > 0;
    final productId = product['id']?.toString() ?? '';

    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        '/tienda/$slug/producto/$productId',
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: StorefrontShadows.soft,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 60,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: StorefrontSmartImage(
                      source: image,
                      fit: BoxFit.cover,
                      placeholder: Container(
                        color: const Color(0xFFF8FAFC),
                        child: const Center(
                          child: Icon(
                            Icons.image_outlined,
                            size: 40,
                            color: Color(0xFFCBD5E1),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (hasStock)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF22C55E).withValues(alpha: 0.90),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Disponible',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    )
                  else
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.90),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Agotado',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 40,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                        height: 1.25,
                      ),
                    ),
                    const Spacer(),
                    StorefrontPriceWidget(
                      precio: price,
                      precioOriginal: originalPrice,
                      primaryColor: primaryColor,
                      large: false,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
