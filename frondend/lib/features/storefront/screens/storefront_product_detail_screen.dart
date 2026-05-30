import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/storefront_api_service.dart';
import '../services/storefront_helpers.dart';
import '../theme/storefront_theme.dart';
import '../widgets/storefront_error_state.dart';
import '../widgets/storefront_price_widget.dart';
import '../widgets/storefront_product_action_bar.dart';
import '../widgets/storefront_product_card.dart';
import '../widgets/storefront_product_detail_skeleton.dart';
import '../widgets/storefront_product_gallery.dart';
import '../widgets/storefront_product_info_section.dart';


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
      duration: const Duration(milliseconds: 240),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
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
          _error =
              productResponse['message']?.toString() ??
              'No se pudo cargar el producto.';
          _loading = false;
        });
        return;
      }

      final fetched = Map<String, dynamic>.from(productResponse['data'] as Map);
      final mergedProduct = {
        ...?_product,
        ...fetched,
      };

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
      
      // Precargar imágenes del producto para que carguen instantáneamente
      _precacheProductImages(mergedProduct);
    } catch (e) {
      setState(() {
        _error = 'Error de conexion: $e';
        _loading = false;
      });
    }
  }
  
  /// Precarga las imágenes del producto en cache para visualización instantánea.
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
    if (_product == null) {
      return;
    }

    final product = _product!;
    final price = StorefrontHelpers.getDisplayPrice(product);
    if (price == null || price <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Este producto requiere cotizacion'),
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

    if (!mounted) {
      return;
    }

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

  Future<void> _openWhatsApp(String whatsapp) async {
    if (_product == null) {
      return;
    }

    final product = _product!;
    final price = StorefrontHelpers.getDisplayPrice(product);
    final number = whatsapp.replaceAll(RegExp(r'[^\d]'), '');
    final productUrl = Uri.base
        .resolve('/tienda/${widget.slug}/producto/${product['id']}')
        .toString();
    final priceText = price == null
        ? 'Consultar precio'
        : 'RD\$${price.toStringAsFixed(0)}';
    final message =
        'Hola FULLTECH, estoy interesado en este producto: '
        '${product['titulo']}. Precio: $priceText. '
        'Esta disponible? $productUrl';

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
    final gallery = StorefrontHelpers.getProductImages(product);
    final price = StorefrontHelpers.getDisplayPrice(product);
    final originalPrice = StorefrontHelpers.getOriginalPrice(product);
    final stock = int.tryParse(product['stock']?.toString() ?? '0') ?? 0;
    final canBuy = stock > 0 && price != null && price > 0;
    final isDesktop = MediaQuery.sizeOf(context).width >= 1000;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F7FB),
        surfaceTintColor: Colors.transparent,
        title: const Text('Producto'),
        actions: [
          IconButton(
            tooltip: 'Ver carrito',
            onPressed: () =>
                Navigator.pushNamed(context, '/tienda/${widget.slug}/carrito'),
            icon: const Icon(Icons.shopping_cart_outlined),
          ),
        ],
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
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1280),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        isDesktop ? 24 : 12,
                        12,
                        isDesktop ? 24 : 12,
                        isDesktop ? 40 : 110,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isDesktop)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 6,
                                  child: StorefrontProductGallery(
                                    images: gallery,
                                    title: product['titulo']?.toString() ?? '',
                                    isDesktop: true,
                                    accentColor: secondaryColor,
                                    version: product['actualizadoEn']?.toString() ?? product['updatedAt']?.toString(),
                                  ),

                                ),
                                const SizedBox(width: 28),
                                Expanded(
                                  flex: 5,
                                  child: _ProductSummarySection(
                                    product: product,
                                    price: price,
                                    originalPrice: originalPrice,
                                    canBuy: canBuy,
                                    primaryColor: primaryColor,
                                    secondaryColor: secondaryColor,
                                    quantity: _quantity,
                                    whatsapp: whatsapp,
                                    isDesktop: true,
                                    onDecrease: () {
                                      if (_quantity > 1) {
                                        setState(() => _quantity--);
                                      }
                                    },
                                    onIncrease: () => setState(() => _quantity++),
                                    onAddToCart: () => _addToCart(),
                                    onBuyNow: () => _addToCart(goToCart: true),
                                    onWhatsapp: whatsapp.isEmpty
                                        ? null
                                        : () => _openWhatsApp(whatsapp),
                                  ),
                                ),
                              ],
                            )
                          else ...[
                            StorefrontProductGallery(
                              images: gallery,
                              title: product['titulo']?.toString() ?? '',
                              isDesktop: false,
                              accentColor: secondaryColor,
                              version: product['actualizadoEn']?.toString() ?? product['updatedAt']?.toString(),
                            ),

                            Padding(
                              padding: const EdgeInsets.fromLTRB(2, 14, 2, 0),
                              child: _ProductSummarySection(
                                product: product,
                                price: price,
                                originalPrice: originalPrice,
                                canBuy: canBuy,
                                primaryColor: primaryColor,
                                secondaryColor: secondaryColor,
                                quantity: _quantity,
                                whatsapp: whatsapp,
                                isDesktop: false,
                                onDecrease: () {
                                  if (_quantity > 1) {
                                    setState(() => _quantity--);
                                  }
                                },
                                onIncrease: () => setState(() => _quantity++),
                                onAddToCart: () => _addToCart(),
                                onBuyNow: () => _addToCart(goToCart: true),
                                onWhatsapp: whatsapp.isEmpty
                                    ? null
                                    : () => _openWhatsApp(whatsapp),
                              ),
                            ),
                          ],
                          const SizedBox(height: 22),
                          ..._buildInfoSections(product, secondaryColor),
                          if (_relatedProducts.isNotEmpty) ...[
                            const SizedBox(height: 30),
                            const Text(
                              'Productos relacionados',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Opciones similares dentro de la misma categoría.',
                              style: TextStyle(
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              height: isDesktop ? 370 : 308,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemBuilder: (context, index) => SizedBox(
                                  width: isDesktop ? 292 : 188,
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
                                separatorBuilder: (context, index) =>
                                    const SizedBox(width: 12),
                                itemCount: _relatedProducts.length,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: isDesktop
          ? null
          : StorefrontProductActionBar(
              isDesktop: false,
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
              onBuyNow: canBuy ? () => _addToCart(goToCart: true) : null,
              onWhatsapp: whatsapp.isEmpty
                  ? null
                  : () => _openWhatsApp(whatsapp),
            ),
    );
  }

  List<Widget> _buildInfoSections(
    Map<String, dynamic> product,
    Color secondaryColor,
  ) {
    final sections = <Widget>[];
    final description =
        StorefrontHelpers.getShortDescription(
          product,
          fallback: 'Producto disponible en tienda',
        );
    final video = product['video']?.toString().trim() ?? '';

    if (description.isNotEmpty) {
      sections.add(
        StorefrontProductInfoSection(
          title: 'Descripción del producto',
          content: description,
          accentColor: secondaryColor,
        ),
      );
      sections.add(const SizedBox(height: 20));
    }

    if (video.isNotEmpty) {
      sections.add(
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.icon(
            onPressed: () => launchUrl(Uri.parse(video)),
            style: FilledButton.styleFrom(
              backgroundColor: StorefrontColors.primary,
            ),
            icon: const Icon(Icons.play_circle_outline_rounded),
            label: const Text('Ver video del producto'),
          ),
        ),
      );
    } else if (sections.isNotEmpty) {
      sections.removeLast();
    }

    return sections;
  }
}

class _ProductSummarySection extends StatelessWidget {
  final Map<String, dynamic> product;
  final num? price;
  final num? originalPrice;
  final bool canBuy;
  final bool isDesktop;
  final int quantity;
  final String whatsapp;
  final Color primaryColor;
  final Color secondaryColor;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final VoidCallback onAddToCart;
  final VoidCallback onBuyNow;
  final VoidCallback? onWhatsapp;

  const _ProductSummarySection({
    required this.product,
    required this.price,
    required this.originalPrice,
    required this.canBuy,
    required this.isDesktop,
    required this.quantity,
    required this.whatsapp,
    required this.primaryColor,
    required this.secondaryColor,
    required this.onDecrease,
    required this.onIncrease,
    required this.onAddToCart,
    required this.onBuyNow,
    required this.onWhatsapp,
  });

  @override
  Widget build(BuildContext context) {
    final description =
        StorefrontHelpers.getShortDescription(
          product,
          fallback: 'Producto disponible en tienda',
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if ((product['categoria']?.toString().trim().isNotEmpty ?? false))
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              product['categoria'].toString(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: primaryColor,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        const SizedBox(height: 10),
        Text(
          product['titulo']?.toString() ?? '',
          maxLines: isDesktop ? 3 : 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: isDesktop ? 34 : 24,
            fontWeight: FontWeight.w900,
            height: 1.1,
            color: const Color(0xFF0F172A),
            letterSpacing: -0.8,
          ),
        ),
        if (description.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            description,
            maxLines: isDesktop ? 5 : 4,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF475569),
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
        const SizedBox(height: 18),
        if (!isDesktop) ...[
          _InlineQuantitySelector(
            quantity: quantity,
            onDecrease: onDecrease,
            onIncrease: onIncrease,
          ),
          if (onWhatsapp != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onWhatsapp,
                style: OutlinedButton.styleFrom(
                  foregroundColor: StorefrontColors.whatsapp,
                  side: const BorderSide(color: StorefrontColors.whatsapp),
                ),
                icon: const Icon(Icons.chat_outlined),
                label: const Text('Consultar por WhatsApp'),
              ),
            ),
          ],
        ],
        if (isDesktop)
          StorefrontProductActionBar(
            isDesktop: true,
            canBuy: canBuy,
            canWhatsapp: whatsapp.isNotEmpty,
            quantity: quantity,
            primaryColor: primaryColor,
            onDecrease: onDecrease,
            onIncrease: onIncrease,
            onAddToCart: onAddToCart,
            onBuyNow: onBuyNow,
            onWhatsapp: onWhatsapp,
          ),
      ],
    );
  }
}

class _InlineQuantitySelector extends StatelessWidget {
  final int quantity;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  const _InlineQuantitySelector({
    required this.quantity,
    required this.onDecrease,
    required this.onIncrease,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Cantidad',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 10),
          IconButton(
            onPressed: quantity > 1 ? onDecrease : null,
            icon: const Icon(Icons.remove_rounded),
            visualDensity: VisualDensity.compact,
          ),
          SizedBox(
            width: 20,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          IconButton(
            onPressed: onIncrease,
            icon: const Icon(Icons.add_rounded),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}
