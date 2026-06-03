import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/storefront_api_service.dart';
import '../services/storefront_helpers.dart';
import '../theme/storefront_theme.dart';
import '../widgets/storefront_error_state.dart';
import '../widgets/storefront_price_widget.dart';
import '../widgets/storefront_product_action_bar.dart';
import '../widgets/storefront_product_detail_bottom_bar.dart';
import '../widgets/storefront_product_detail_hero_image.dart';
import '../widgets/storefront_product_detail_skeleton.dart';
import '../widgets/storefront_product_info_section.dart';
import '../widgets/storefront_quantity_selector.dart';
import '../widgets/storefront_related_products_section.dart';

class StorefrontProductDetailScreen extends StatefulWidget {
  final String slug;
  final String productId;
  final Map<String, dynamic>? initialProduct;

  const StorefrontProductDetailScreen({
    super.key,
    required this.slug,
    required this.productId,
    this.initialProduct,
  });

  @override
  State<StorefrontProductDetailScreen> createState() =>
      _StorefrontProductDetailScreenState();
}

class _StorefrontProductDetailScreenState
    extends State<StorefrontProductDetailScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _product;
  Map<String, dynamic>? _config;
  List<dynamic> _relatedProducts = [];
  bool _loading = true;
  String? _error;
  int _quantity = 1;
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _product = widget.initialProduct == null
        ? null
        : Map<String, dynamic>.from(widget.initialProduct!);
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );
    if (_product != null) {
      _fadeController.value = 1;
    }
    _loadData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
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
          _error = productResponse['message']?.toString() ??
              'No se pudo cargar el producto.';
          _loading = false;
        });
        return;
      }

      final fetched = Map<String, dynamic>.from(productResponse['data'] as Map);
      final mergedProduct = {...?_product, ...fetched};

      _fadeController.reset();
      setState(() {
        _config = Map<String, dynamic>.from(configResponse['data'] as Map);
        _product = mergedProduct;
        _relatedProducts = List<dynamic>.from(
          fetched['relatedProducts'] as List? ?? const [],
        );
        _quantity = 1;
        _loading = false;
      });
      _fadeController.forward();
      _precacheProductImages(mergedProduct);
    } catch (e) {
      setState(() {
        _error = 'Error de conexion: $e';
        _loading = false;
      });
    }
  }

  void _precacheProductImages(Map<String, dynamic> product) {
    if (!mounted) return;
    final images = StorefrontHelpers.getProductImages(product);
    for (final url in images) {
      if (url.startsWith('http')) {
        precacheImage(NetworkImage(url), context);
      }
    }
  }

  Color _getColor(String hex) {
    var normalized = hex.replaceAll('#', '');
    if (normalized.length == 6) {
      normalized = 'FF$normalized';
    }
    return Color(int.parse(normalized, radix: 16));
  }

  Future<void> _addToCart({bool goToCart = false}) async {
    if (_product == null) return;

    final product = _product!;
    final price = StorefrontHelpers.getDisplayPrice(product);
    if (price == null || price <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Este producto requiere cotizacion'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

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
        Navigator.pushNamed(context, '/tienda/${widget.slug}/checkout');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${product['titulo']} agregado al carrito'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(response['message']?.toString() ?? 'No se pudo agregar'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _openWhatsApp(String whatsapp) async {
    if (_product == null) return;

    final product = _product!;
    final productName = product['titulo']?.toString() ?? 'Producto';
    final number = whatsapp.replaceAll(RegExp(r'[^\d]'), '');
    final price = StorefrontHelpers.getDisplayPrice(product);
    final imageUrl = StorefrontHelpers.getPrimaryImage(product) ?? '';
    final description = StorefrontHelpers.getShortDescription(
      product,
      fallback: '',
    );
    final category = product['categoria']?.toString().trim() ?? '';
    final includeInfo = product['incluye']?.toString().trim() ?? '';
    final extraInfo = product['informacion']?.toString().trim() ?? '';
    final stock = int.tryParse(product['stock']?.toString() ?? '0') ?? 0;
    final priceText = price != null
        ? 'RD\$${price.toStringAsFixed(2)}'
        : 'Consultar precio';

    final specs = <String>[
      if (category.isNotEmpty) '- Categoria: $category',
      '- Cantidad solicitada: $_quantity',
      '- Disponibilidad: ${stock > 0 ? 'Disponible' : 'Agotado'}',
      '- Precio: $priceText',
      if (description.isNotEmpty) '- Descripcion: $description',
      if (includeInfo.isNotEmpty) '- Incluye: $includeInfo',
      if (extraInfo.isNotEmpty) '- Especificaciones: $extraInfo',
      if (imageUrl.isNotEmpty) '- Imagen: $imageUrl',
    ];

    final message =
        'Hola FULLTECH, quiero informacion sobre este producto:\n\n'
        '*$productName*\n'
        '${specs.join('\n')}'
        '\n\nQuedo atento a su respuesta. Gracias.';

    await launchUrl(
      Uri.parse('https://wa.me/$number?text=${Uri.encodeComponent(message)}'),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _product == null) {
      return const StorefrontProductDetailSkeleton();
    }

    if (_error != null || _product == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF5F7FA),
          title: const Text('Producto'),
        ),
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
    final gallery = StorefrontHelpers.getProductImages(product);
    final price = StorefrontHelpers.getDisplayPrice(product);
    final originalPrice = StorefrontHelpers.getOriginalPrice(product);
    final stock = int.tryParse(product['stock']?.toString() ?? '0') ?? 0;
    final canBuy = stock > 0 && price != null && price > 0;
    final isDesktop = MediaQuery.sizeOf(context).width >= 1000;
    final description = StorefrontHelpers.getShortDescription(
      product,
      fallback: 'Producto disponible en tienda',
    );
    final video = product['video']?.toString().trim() ?? '';
    final category = product['categoria']?.toString().trim() ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      bottomNavigationBar: isDesktop
          ? null
          : StorefrontProductDetailBottomBar(
              canBuy: canBuy,
              canWhatsapp: whatsapp.isNotEmpty,
              primaryColor: primaryColor,
              onAddToCart: canBuy ? () => _addToCart() : null,
              onBuyNow: canBuy ? () => _addToCart(goToCart: true) : null,
              onWhatsapp: whatsapp.isEmpty
                  ? null
                  : () => _openWhatsApp(whatsapp),
            ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    StorefrontProductDetailHeroImage(
                      product: product,
                      images: gallery,
                      slug: widget.slug,
                      accentColor: secondaryColor,
                      onBack: () => Navigator.pop(context),
                      onCart: () => Navigator.pushNamed(
                        context,
                        '/tienda/${widget.slug}/carrito',
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        isDesktop ? 32 : 16,
                        20,
                        isDesktop ? 32 : 16,
                        isDesktop ? 40 : 120,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 800),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                                if (category.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: primaryColor.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        category,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: primaryColor,
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ),
                                Text(
                                  product['titulo']?.toString() ?? '',
                                  maxLines: isDesktop ? 3 : 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: isDesktop ? 34 : 24,
                                    fontWeight: FontWeight.w900,
                                    height: 1.15,
                                    color: const Color(0xFF0F172A),
                                    letterSpacing: -0.8,
                                  ),
                                ),
                                if (description.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  Text(
                                    description,
                                    maxLines: isDesktop ? 5 : 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 14.5,
                                      height: 1.55,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 16),
                                StorefrontPriceWidget(
                                  precio: price,
                                  precioOriginal: originalPrice,
                                  large: true,
                                  primaryColor: primaryColor,
                                  currencyPrefix: 'RD\$',
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    _StatusChip(
                                      label: stock > 0 ? 'Disponible' : 'Agotado',
                                      color: stock > 0
                                          ? const Color(0xFF16A34A)
                                          : const Color(0xFFDC2626),
                                    ),
                                    if (originalPrice != null &&
                                        price != null &&
                                        originalPrice > price) ...[
                                      const SizedBox(width: 8),
                                      const _StatusChip(
                                        label: 'Oferta',
                                        color: Color(0xFFEA580C),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 20),
                                if (!isDesktop) ...[
                                  Row(
                                    children: [
                                      const Text(
                                        'Cantidad',
                                        style: TextStyle(
                                          color: Color(0xFF64748B),
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      StorefrontQuantitySelector(
                                        quantity: _quantity,
                                        onDecrease: () {
                                          if (_quantity > 1) {
                                            setState(() => _quantity--);
                                          }
                                        },
                                        onIncrease: () => setState(() => _quantity++),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                ],
                                if (isDesktop) ...[
                                  StorefrontProductActionBar(
                                    isDesktop: true,
                                    canBuy: canBuy,
                                    canWhatsapp: whatsapp.isNotEmpty,
                                    quantity: _quantity,
                                    primaryColor: primaryColor,
                                    onDecrease: () {
                                      if (_quantity > 1) {
                                        setState(() => _quantity--);
                                      }
                                    },
                                    onIncrease: () => setState(() => _quantity++),
                                    onAddToCart: canBuy ? () => _addToCart() : null,
                                    onBuyNow: canBuy
                                        ? () => _addToCart(goToCart: true)
                                        : null,
                                    onWhatsapp: whatsapp.isNotEmpty
                                        ? () => _openWhatsApp(whatsapp)
                                        : null,
                                  ),
                                  const SizedBox(height: 24),
                                ],
                                if (description.isNotEmpty) ...[
                                  StorefrontProductInfoSection(
                                    title: 'Descripcion del producto',
                                    content: description,
                                    accentColor: secondaryColor,
                                  ),
                                  const SizedBox(height: 20),
                                ],
                                if (video.isNotEmpty) ...[
                                  Container(
                                    height: 1,
                                    width: double.infinity,
                                    color: const Color(0xFFE8EEF4),
                                  ),
                                  const SizedBox(height: 20),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 50,
                                    child: FilledButton.icon(
                                      onPressed: () => launchUrl(Uri.parse(video)),
                                      style: FilledButton.styleFrom(
                                        backgroundColor: StorefrontColors.primary,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                      ),
                                      icon: const Icon(
                                        Icons.play_circle_outline_rounded,
                                        size: 20,
                                      ),
                                      label: const Text(
                                        'Ver video del producto',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                ],
                                StorefrontRelatedProductsSection(
                                  products: _relatedProducts,
                                  slug: widget.slug,
                                  primaryColor: primaryColor,
                                  secondaryColor: secondaryColor,
                                  whatsapp: whatsapp,
                                ),
                                const SizedBox(height: 24),
                          ],
                        ),
                      ),
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

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
