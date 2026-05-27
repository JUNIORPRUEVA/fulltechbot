import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/storefront_api_service.dart';
import '../services/storefront_helpers.dart';
import '../widgets/storefront_error_state.dart';
import '../widgets/storefront_price_widget.dart';
import '../widgets/storefront_product_card.dart';

class StorefrontProductDetailScreen extends StatefulWidget {
  final String slug;
  final String productId;

  const StorefrontProductDetailScreen({
    super.key,
    required this.slug,
    required this.productId,
  });

  @override
  State<StorefrontProductDetailScreen> createState() =>
      _StorefrontProductDetailScreenState();
}

class _StorefrontProductDetailScreenState
    extends State<StorefrontProductDetailScreen> {
  Map<String, dynamic>? _product;
  Map<String, dynamic>? _config;
  List<dynamic> _relatedProducts = [];
  bool _loading = true;
  String? _error;
  int _quantity = 1;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        StorefrontApiService.getConfig(widget.slug),
        StorefrontApiService.getProduct(widget.slug, widget.productId),
      ]);

      final configResponse = results[0];
      final productResponse = results[1];
      if (configResponse['ok'] != true || productResponse['ok'] != true) {
        setState(() {
          _error =
              productResponse['message']?.toString() ??
              'No se pudo cargar el producto.';
          _loading = false;
        });
        return;
      }

      final product = Map<String, dynamic>.from(productResponse['data'] as Map);
      setState(() {
        _config = Map<String, dynamic>.from(configResponse['data'] as Map);
        _product = product;
        _relatedProducts = List<dynamic>.from(
          product['relatedProducts'] as List? ?? const [],
        );
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error de conexión: $e';
        _loading = false;
      });
    }
  }

  Color _getColor(String hex) {
    var normalized = hex.replaceAll('#', '');
    if (normalized.length == 6) normalized = 'FF$normalized';
    return Color(int.parse(normalized, radix: 16));
  }

  Future<void> _addToCart({bool goToCart = false}) async {
    if (_product == null) return;

    final product = _product!;
    final price = StorefrontHelpers.getEffectivePrice(product);
    final sessionId = await StorefrontHelpers.ensureSessionId(widget.slug);
    await StorefrontApiService.createCart(widget.slug, sessionId);

    final response = await StorefrontApiService.addCartItem(
      widget.slug,
      sessionId,
      productoId: product['id'].toString(),
      nombreProducto: product['titulo']?.toString() ?? '',
      cantidad: _quantity,
      precioUnitario: price.toDouble(),
      imagenUrl: StorefrontHelpers.getPrimaryImage(product),
    );

    if (!mounted) return;
    if (response['ok'] == true) {
      if (goToCart) {
        Navigator.pushNamed(context, '/tienda/${widget.slug}/carrito');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${product['titulo']} agregado al carrito')),
        );
      }
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(response['message']?.toString() ?? 'No se pudo agregar'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _abrirWhatsAppProducto(String whatsapp) {
    final product = _product!;
    final price = StorefrontHelpers.getEffectivePrice(product);
    final number = whatsapp.replaceAll(RegExp(r'[^\d]'), '');
    final productUrl = Uri.base
        .resolve('/tienda/${widget.slug}/producto/${product['id']}')
        .toString();
    final message =
        'Hola FULLTECH, estoy interesado en: ${product['titulo']}. '
        'Precio: \$${price.toStringAsFixed(0)}. '
        'Link: $productUrl';
    launchUrl(
      Uri.parse('https://wa.me/$number?text=${Uri.encodeComponent(message)}'),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Producto')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _product == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Producto')),
        body: StorefrontErrorState(
          message: _error ?? 'Producto no encontrado',
          onRetry: _loadData,
        ),
      );
    }

    final product = _product!;
    final config = _config ?? {};
    final primaryColor = _getColor(
      config['color_principal']?.toString() ?? '#0F172A',
    );
    final secondaryColor = _getColor(
      config['color_secundario']?.toString() ?? '#2563EB',
    );
    final whatsapp = config['whatsapp_numero']?.toString() ?? '';
    final gallery = StorefrontHelpers.getGallery(product);
    final price = StorefrontHelpers.getEffectivePrice(product);
    final originalPrice = StorefrontHelpers.getOriginalPrice(product);
    final stock = int.tryParse(product['stock']?.toString() ?? '0') ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 340,
            actions: [
              IconButton(
                onPressed: () => Navigator.pushNamed(
                  context,
                  '/tienda/${widget.slug}/carrito',
                ),
                icon: const Icon(Icons.shopping_cart_outlined),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  Positioned.fill(
                    child: Container(
                      color: const Color(0xFFF4F7FB),
                      child: gallery.isEmpty
                          ? const Center(
                              child: Icon(
                                Icons.image_outlined,
                                size: 72,
                                color: Color(0xFFCBD5E1),
                              ),
                            )
                          : PageView.builder(
                              onPageChanged: (value) {
                                setState(() => _currentImageIndex = value);
                              },
                              itemCount: gallery.length,
                              itemBuilder: (context, index) => Padding(
                                padding: const EdgeInsets.all(20),
                                child: Image.network(
                                  gallery[index],
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => const Center(
                                    child: Icon(
                                      Icons.image_outlined,
                                      size: 72,
                                      color: Color(0xFFCBD5E1),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ),
                  if (gallery.length > 1)
                    Positioned(
                      bottom: 16,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(gallery.length, (index) {
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            width: _currentImageIndex == index ? 24 : 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              color: _currentImageIndex == index
                                  ? secondaryColor
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          );
                        }),
                      ),
                    ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if ((product['categoria']?.toString() ?? '').isNotEmpty)
                    Text(
                      product['categoria'].toString(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  const SizedBox(height: 6),
                  Text(
                    product['titulo']?.toString() ?? '',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 14),
                  StorefrontPriceWidget(
                    precio: price,
                    precioOriginal: originalPrice,
                    large: true,
                    primaryColor: primaryColor,
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _Pill(
                        icon: Icons.inventory_2_outlined,
                        label: stock > 0
                            ? 'Stock disponible: $stock'
                            : 'Stock no disponible',
                      ),
                      if (product['instalacion_incluida'] == true)
                        const _Pill(
                          icon: Icons.build_circle_outlined,
                          label: 'Instalación incluida',
                        ),
                      if (product['requiere_instalacion'] == true)
                        const _Pill(
                          icon: Icons.handyman_outlined,
                          label: 'Requiere instalación',
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Text(
                        'Cantidad',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 14),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: _quantity > 1
                                  ? () => setState(() => _quantity--)
                                  : null,
                              icon: const Icon(Icons.remove_rounded),
                            ),
                            Text(
                              '$_quantity',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            IconButton(
                              onPressed: () => setState(() => _quantity++),
                              icon: const Icon(Icons.add_rounded),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if ((product['descripcion_web']?.toString() ?? '')
                          .isNotEmpty ||
                      (product['descripcion']?.toString() ?? '')
                          .isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const _BlockTitle('Descripción'),
                    const SizedBox(height: 8),
                    Text(
                      product['descripcion_web']?.toString() ??
                          product['descripcion']?.toString() ??
                          '',
                      style: const TextStyle(
                        color: Color(0xFF475569),
                        height: 1.55,
                      ),
                    ),
                  ],
                  if ((product['informacion']?.toString() ?? '')
                      .isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const _BlockTitle('Información'),
                    const SizedBox(height: 8),
                    Text(
                      product['informacion'].toString(),
                      style: const TextStyle(
                        color: Color(0xFF475569),
                        height: 1.55,
                      ),
                    ),
                  ],
                  if ((product['incluye']?.toString() ?? '').isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const _BlockTitle('Incluye'),
                    const SizedBox(height: 8),
                    Text(
                      product['incluye'].toString(),
                      style: const TextStyle(
                        color: Color(0xFF475569),
                        height: 1.55,
                      ),
                    ),
                  ],
                  if ((product['reglasNegociacion']?.toString() ?? '')
                      .isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const _BlockTitle('Condiciones y negociación'),
                    const SizedBox(height: 8),
                    Text(
                      product['reglasNegociacion'].toString(),
                      style: const TextStyle(
                        color: Color(0xFF475569),
                        height: 1.55,
                      ),
                    ),
                  ],
                  if ((product['video']?.toString() ?? '').isNotEmpty) ...[
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () =>
                          launchUrl(Uri.parse(product['video'].toString())),
                      icon: const Icon(Icons.play_circle_outline),
                      label: const Text('Ver video'),
                    ),
                  ],
                  if (_relatedProducts.isNotEmpty) ...[
                    const SizedBox(height: 26),
                    const _BlockTitle('Productos relacionados'),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 320,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemBuilder: (context, index) => SizedBox(
                          width: 210,
                          child: StorefrontProductCard(
                            product: Map<String, dynamic>.from(
                              _relatedProducts[index] as Map,
                            ),
                            slug: widget.slug,
                            primaryColor: primaryColor,
                            secondaryColor: secondaryColor,
                            whatsapp: whatsapp,
                          ),
                        ),
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemCount: _relatedProducts.length,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          MediaQuery.of(context).padding.bottom + 12,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            if (whatsapp.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(right: 10),
                child: OutlinedButton(
                  onPressed: () => _abrirWhatsAppProducto(whatsapp),
                  child: const Icon(Icons.chat_rounded),
                ),
              ),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: stock <= 0 ? null : () => _addToCart(),
                icon: const Icon(Icons.shopping_cart_outlined),
                label: const Text('Agregar'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: stock <= 0 ? null : () => _addToCart(goToCart: true),
                icon: const Icon(Icons.bolt_rounded),
                label: const Text('Comprar ahora'),
                style: FilledButton.styleFrom(backgroundColor: primaryColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BlockTitle extends StatelessWidget {
  final String text;

  const _BlockTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Pill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FB),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF2563EB)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
