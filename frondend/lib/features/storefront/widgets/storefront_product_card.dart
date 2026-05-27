import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/storefront_api_service.dart';
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
    final precio = product['precio_oferta_web'] ?? product['precio_oferta'] ?? product['precio'] ?? 0;
    final precioOriginal = (product['precio_oferta_web'] != null || product['precio_oferta'] != null)
        ? (product['precio'] ?? 0)
        : null;
    final imagen = product['imagen_destacada_url'] ?? product['imagen1'] ?? '';
    final etiqueta = product['etiqueta'] ?? '';
    final rating = product['rating'] ?? 0;
    final tieneInstalacion = product['requiere_instalacion'] == true || product['instalacion_incluida'] == true;
    final tieneEnvio = product['envio_incluido'] == true;
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
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          width: widget.compact ? null : 200,
          transform: _isHovered ? (Matrix4.identity()..translate(0, -4)) : Matrix4.identity(),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _isHovered ? 0.08 : 0.04),
                blurRadius: _isHovered ? 20 : 12,
                offset: Offset(0, _isHovered ? 6 : 2),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: _isHovered ? 0.04 : 0.02),
                blurRadius: _isHovered ? 8 : 4,
                offset: Offset(0, _isHovered ? 3 : 1),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Imagen con overlay hover
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      color: const Color(0xFFF1F5F9),
                      child: imagen.isNotEmpty
                          ? Image.network(
                              imagen,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder: (_, __, ___) => _placeholderIcon(),
                            )
                          : _placeholderIcon(),
                    ),
                    // Overlay hover
                    if (_isHovered)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.05),
                          ),
                        ),
                      ),
                    // Etiqueta
                    if (etiqueta.isNotEmpty)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: widget.secondaryColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            etiqueta,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    // Badge oferta
                    if (tieneOferta)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFEF4444), Color(0xFFF87171)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '-${((1 - precio / precioOriginal) * 100).round()}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    // Rating
                    if (rating > 0)
                      Positioned(
                        bottom: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded, size: 12, color: Color(0xFFFBBF24)),
                              const SizedBox(width: 2),
                              Text(
                                rating.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Info
              Padding(
                padding: EdgeInsets.all(widget.compact ? 10 : 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product['titulo'] ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: widget.compact ? 13 : 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF111827),
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    StorefrontPriceWidget(
                      precio: precio,
                      precioOriginal: precioOriginal,
                      primaryColor: widget.primaryColor,
                    ),
                    const SizedBox(height: 6),
                    // Beneficios
                    Row(
                      children: [
                        if (tieneEnvio) ...[
                          _benefitChip(Icons.local_shipping_outlined, 'Envío gratis', const Color(0xFF10B981)),
                          const SizedBox(width: 4),
                        ],
                        if (tieneInstalacion)
                          _benefitChip(Icons.build_outlined, 'Instalación', const Color(0xFF2563EB)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Botones
                    Row(
                      children: [
                        Expanded(
                          child: _ActionButton(
                            icon: Icons.shopping_cart_outlined,
                            label: 'Carrito',
                            color: widget.secondaryColor,
                            onTap: () => _addToCart(context),
                          ),
                        ),
                        if (widget.whatsapp != null && product['permitir_whatsapp'] != false) ...[
                          const SizedBox(width: 6),
                          _ActionButton(
                            icon: Icons.chat_outlined,
                            label: '',
                            color: const Color(0xFF25D366),
                            isIcon: true,
                            onTap: () {
                              final num = widget.whatsapp!.replaceAll(RegExp(r'[^\d]'), '');
                              final msg = 'Hola, me interesa: ${product['titulo']} (ID: ${product['id']})';
                              launchUrl(Uri.parse('https://wa.me/$num?text=${Uri.encodeComponent(msg)}'));
                            },
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

  Widget _benefitChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addToCart(BuildContext context) async {
    final product = widget.product;
    final precio = product['precio_oferta_web'] ?? product['precio_oferta'] ?? product['precio'] ?? 0;
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionId = prefs.getString('storefront_session_${widget.slug}') ?? '';
      if (sessionId.isEmpty) return;

      await StorefrontApiService.createCart(widget.slug, sessionId);
      final res = await StorefrontApiService.addCartItem(
        widget.slug, sessionId,
        productoId: product['id'].toString(),
        nombreProducto: product['titulo'] ?? '',
        cantidad: 1,
        precioUnitario: double.tryParse(precio.toString()) ?? 0,
        imagenUrl: product['imagen_destacada_url'] ?? product['imagen1'],
      );

      if (res['ok'] == true && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${product['titulo']} agregado al carrito'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            action: SnackBarAction(
              label: 'Ver',
              onPressed: () => Navigator.pushNamed(context, '/tienda/${widget.slug}/carrito'),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _placeholderIcon() => Center(
        child: Icon(Icons.image_outlined, size: 40, color: const Color(0xFFCBD5E1)),
      );
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool isIcon;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.isIcon = false,
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
            horizontal: isIcon ? 10 : 8,
            vertical: 8,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              if (!isIcon) ...[
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
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
