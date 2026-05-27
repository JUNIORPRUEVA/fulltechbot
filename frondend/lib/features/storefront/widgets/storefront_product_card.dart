import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/storefront_api_service.dart';
import '../services/storefront_helpers.dart';
import 'storefront_price_widget.dart';

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
    final categoria = product['categoria']?.toString() ?? '';
    final etiqueta = product['etiqueta']?.toString() ?? '';
    final stock = int.tryParse(product['stock']?.toString() ?? '0') ?? 0;
    final tieneInstalacion =
        product['requiere_instalacion'] == true ||
        product['instalacion_incluida'] == true;
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
          width: widget.compact ? null : 212,
          transform: _isHovered
              ? (Matrix4.identity()..translate(0, -4))
              : Matrix4.identity(),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _isHovered ? 0.08 : 0.04),
                blurRadius: _isHovered ? 18 : 10,
                offset: Offset(0, _isHovered ? 8 : 3),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Container(
                        color: const Color(0xFFF4F7FB),
                        padding: const EdgeInsets.all(14),
                        child: imagen != null
                            ? Image.network(
                                imagen,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) =>
                                    _placeholderIcon(),
                              )
                            : _placeholderIcon(),
                      ),
                    ),
                    if (etiqueta.isNotEmpty)
                      Positioned(
                        top: 10,
                        left: 10,
                        child: _TopBadge(
                          label: etiqueta,
                          background: widget.secondaryColor,
                          foreground: Colors.white,
                        ),
                      ),
                    if (tieneOferta)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: _TopBadge(
                          label: 'Oferta',
                          background: const Color(0xFFEF4444),
                          foreground: Colors.white,
                        ),
                      ),
                    if (stock > 0)
                      Positioned(
                        bottom: 10,
                        left: 10,
                        child: _TopBadge(
                          label: 'Stock $stock',
                          background: Colors.black.withValues(alpha: 0.72),
                          foreground: Colors.white,
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.all(widget.compact ? 10 : 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (categoria.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          categoria,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    Text(
                      product['titulo']?.toString() ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: widget.compact ? 13 : 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111827),
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 8),
                    StorefrontPriceWidget(
                      precio: precio,
                      precioOriginal: precioOriginal,
                      primaryColor: widget.primaryColor,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (tieneOferta)
                          _benefitChip(
                            Icons.local_offer_outlined,
                            'Oferta',
                            const Color(0xFFEF4444),
                          ),
                        if (tieneInstalacion)
                          _benefitChip(
                            Icons.build_outlined,
                            'Instalación',
                            const Color(0xFF2563EB),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _ActionButton(
                            icon: Icons.shopping_cart_outlined,
                            label: widget.compact ? '' : 'Agregar',
                            color: widget.secondaryColor,
                            onTap: () => _addToCart(context),
                            compact: widget.compact,
                          ),
                        ),
                        if (widget.whatsapp != null &&
                            product['permitir_whatsapp'] != false) ...[
                          const SizedBox(width: 6),
                          _ActionButton(
                            icon: Icons.chat_outlined,
                            label: '',
                            color: const Color(0xFF25D366),
                            onTap: _abrirWhatsAppProducto,
                            compact: true,
                          ),
                        ],
                      ],
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

  Future<void> _addToCart(BuildContext context) async {
    final product = widget.product;
    final precio = StorefrontHelpers.getEffectivePrice(product);

    try {
      final sessionId = await StorefrontHelpers.ensureSessionId(widget.slug);
      await StorefrontApiService.createCart(widget.slug, sessionId);
      final response = await StorefrontApiService.addCartItem(
        widget.slug,
        sessionId,
        productoId: product['id'].toString(),
        nombreProducto: product['titulo']?.toString() ?? '',
        cantidad: 1,
        precioUnitario: precio.toDouble(),
        imagenUrl: StorefrontHelpers.getPrimaryImage(product),
      );

      if (!context.mounted) return;
      if (response['ok'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${product['titulo']} agregado al carrito'),
            action: SnackBarAction(
              label: 'Ver',
              onPressed: () => Navigator.pushNamed(
                context,
                '/tienda/${widget.slug}/carrito',
              ),
            ),
          ),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response['message']?.toString() ?? 'No se pudo agregar',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _abrirWhatsAppProducto() {
    final number = widget.whatsapp?.replaceAll(RegExp(r'[^\d]'), '') ?? '';
    if (number.isEmpty) return;

    final product = widget.product;
    final precio = StorefrontHelpers.getEffectivePrice(product);
    final productUrl = Uri.base
        .resolve('/tienda/${widget.slug}/producto/${product['id']}')
        .toString();
    final msg =
        'Hola FULLTECH, estoy interesado en: ${product['titulo']}. '
        'Precio: \$${precio.toStringAsFixed(0)}. '
        'Link: $productUrl';
    launchUrl(
      Uri.parse('https://wa.me/$number?text=${Uri.encodeComponent(msg)}'),
    );
  }

  Widget _benefitChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholderIcon() {
    return const Center(
      child: Icon(Icons.image_outlined, size: 40, color: Color(0xFFCBD5E1)),
    );
  }
}

class _TopBadge extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;

  const _TopBadge({
    required this.label,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool compact;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 8,
            vertical: 9,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              if (!compact && label.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
