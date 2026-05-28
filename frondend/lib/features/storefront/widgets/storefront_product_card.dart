import 'package:flutter/material.dart';

import '../services/storefront_helpers.dart';
import '../theme/storefront_theme.dart';
import 'storefront_price_widget.dart';
import 'storefront_smart_image.dart';

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

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final precio = StorefrontHelpers.getEffectivePrice(product);
    final precioOriginal = StorefrontHelpers.getOriginalPrice(product);
    final imagen = StorefrontHelpers.getPrimaryImage(product);
    final descripcion =
        product['descripcion_web']?.toString().trim().isNotEmpty == true
        ? product['descripcion_web'].toString().trim()
        : product['descripcion']?.toString().trim().isNotEmpty == true
        ? product['descripcion'].toString().trim()
        : product['informacion']?.toString().trim() ?? '';
    final tieneOferta = precioOriginal != null && precioOriginal > precio;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(
          context,
          '/tienda/${widget.slug}/producto/${product['id']}',
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          transform: _isHovered
              ? (Matrix4.identity()..translate(0, -4))
              : Matrix4.identity(),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: _isHovered
                ? StorefrontShadows.soft
                : const [
                    BoxShadow(
                      color: Color(0x0A0F172A),
                      blurRadius: 18,
                      offset: Offset(0, 8),
                    ),
                  ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: widget.compact ? 1.02 : 1.06,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFFF7FAFE), Color(0xFFF1F5F9)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        child: StorefrontSmartImage(
                          source: imagen,
                          fit: BoxFit.cover,
                          placeholder: _placeholderImage(),
                        ),
                      ),
                    ),
                    if (tieneOferta)
                      const Positioned(
                        top: 10,
                        left: 10,
                        child: _OfferBadge(),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  widget.compact ? 12 : 14,
                  12,
                  widget.compact ? 12 : 14,
                  widget.compact ? 14 : 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product['titulo']?.toString() ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: widget.compact ? 14 : 15,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF111827),
                        height: 1.25,
                      ),
                    ),
                    if (descripcion.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        descripcion,
                        maxLines: widget.compact ? 2 : 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          height: 1.4,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    StorefrontPriceWidget(
                      precio: precio,
                      precioOriginal: precioOriginal,
                      primaryColor: widget.primaryColor,
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

  Widget _placeholderImage() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF8FAFC), Color(0xFFE2E8F0)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.image_outlined,
          size: 40,
          color: Color(0xFFCBD5E1),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        'Oferta',
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
