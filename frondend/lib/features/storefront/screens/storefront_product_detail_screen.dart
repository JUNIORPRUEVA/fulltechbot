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
import '../widgets/storefront_trust_badges.dart';

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
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
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

      final product = Map<String, dynamic>.from(productResponse['data'] as Map);
      _fadeController.reset();
      setState(() {
        _config = Map<String, dynamic>.from(configResponse['data'] as Map);
        _product = product;
        _relatedProducts = List<dynamic>.from(
          product['relatedProducts'] as List? ?? const [],
        );
        _loading = false;
        _quantity = 1;
      });
      _fadeController.forward();
    } catch (e) {
      setState(() {
        _error = 'Error de conexión: $e';
        _loading = false;
      });
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
    final price = StorefrontHelpers.getEffectivePrice(product);
    final number = whatsapp.replaceAll(RegExp(r'[^\d]'), '');
    final productUrl = Uri.base
        .resolve('/tienda/${widget.slug}/producto/${product['id']}')
        .toString();
    final message =
        'Hola FULLTECH, estoy interesado en este producto: '
        '${product['titulo']}. Precio: RD\$${price.toStringAsFixed(0)}. '
        '¿Está disponible? $productUrl';

    await launchUrl(
      Uri.parse('https://wa.me/$number?text=${Uri.encodeComponent(message)}'),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
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
    final gallery = StorefrontHelpers.getGallery(product);
    final price = StorefrontHelpers.getEffectivePrice(product);
    final originalPrice = StorefrontHelpers.getOriginalPrice(product);
    final stock = int.tryParse(product['stock']?.toString() ?? '0') ?? 0;
    final isDesktop = MediaQuery.of(context).size.width >= 1024;
    final canBuy = stock > 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: const Text('Detalle del producto'),
        backgroundColor: const Color(0xFFF4F7FB),
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: 'Ver carrito',
            onPressed: () =>
                Navigator.pushNamed(context, '/tienda/${widget.slug}/carrito'),
            icon: const Icon(Icons.shopping_cart_outlined),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            isDesktop ? 28 : 16,
            12,
            isDesktop ? 28 : 16,
            isDesktop ? 40 : 160,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1380),
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
                          ),
                        ),
                        const SizedBox(width: 28),
                        Expanded(
                          flex: 5,
                          child: _ProductSummaryCard(
                            product: product,
                            price: price,
                            originalPrice: originalPrice,
                            stock: stock,
                            primaryColor: primaryColor,
                            secondaryColor: secondaryColor,
                            quantity: _quantity,
                            canBuy: canBuy,
                            whatsapp: whatsapp,
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
                            isDesktop: true,
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
                    ),
                    const SizedBox(height: 18),
                    _ProductSummaryCard(
                      product: product,
                      price: price,
                      originalPrice: originalPrice,
                      stock: stock,
                      primaryColor: primaryColor,
                      secondaryColor: secondaryColor,
                      quantity: _quantity,
                      canBuy: canBuy,
                      whatsapp: whatsapp,
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
                      isDesktop: false,
                    ),
                  ],
                  const SizedBox(height: 24),
                  StorefrontTrustBadges(
                    installationAvailable:
                        product['instalacion_incluida'] == true ||
                        product['requiere_instalacion'] == true,
                  ),
                  const SizedBox(height: 24),
                  ..._buildInfoSections(product),
                  if (_relatedProducts.isNotEmpty) ...[
                    const SizedBox(height: 30),
                    const Text(
                      'Productos relacionados',
                      style: TextStyle(
                        fontSize: 24,
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
                    const SizedBox(height: 16),
                    SizedBox(
                      height: isDesktop ? 340 : 300,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemBuilder: (context, index) => SizedBox(
                          width: isDesktop ? 260 : 220,
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
                            const SizedBox(width: 14),
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

  List<Widget> _buildInfoSections(Map<String, dynamic> product) {
    final sections = <Widget>[];
    final description =
        product['descripcion_web']?.toString().trim().isNotEmpty == true
        ? product['descripcion_web'].toString().trim()
        : product['descripcion']?.toString().trim().isNotEmpty == true
        ? product['descripcion'].toString().trim()
        : product['informacion']?.toString().trim() ?? '';

    final informacion = product['informacion']?.toString().trim() ?? '';
    final incluye = product['incluye']?.toString().trim() ?? '';
    final reglas = product['reglasNegociacion']?.toString().trim() ?? '';
    final video = product['video']?.toString().trim() ?? '';

    final normalizedInfo = informacion.trim();
    final normalizedDescription = description.trim();

    if (normalizedDescription.isNotEmpty) {
      sections.add(
        StorefrontProductInfoSection(
          title: 'Descripción del producto',
          content: normalizedDescription,
          icon: Icons.description_outlined,
        ),
      );
      sections.add(const SizedBox(height: 18));
    }

    if (incluye.isNotEmpty) {
      sections.add(
        StorefrontProductInfoSection(
          title: 'Qué incluye',
          content: incluye,
          icon: Icons.checklist_rounded,
        ),
      );
      sections.add(const SizedBox(height: 18));
    }

    if (normalizedInfo.isNotEmpty &&
        normalizedInfo.toLowerCase() != normalizedDescription.toLowerCase()) {
      sections.add(
        StorefrontProductInfoSection(
          title: 'Información adicional',
          content: normalizedInfo,
          icon: Icons.info_outline_rounded,
        ),
      );
      sections.add(const SizedBox(height: 18));
    }

    if (reglas.isNotEmpty) {
      sections.add(
        StorefrontProductInfoSection(
          title: 'Condiciones y negociación',
          content: reglas,
          icon: Icons.rule_folder_outlined,
        ),
      );
      sections.add(const SizedBox(height: 18));
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

class _ProductSummaryCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final num price;
  final num? originalPrice;
  final int stock;
  final int quantity;
  final bool canBuy;
  final bool isDesktop;
  final String whatsapp;
  final Color primaryColor;
  final Color secondaryColor;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final VoidCallback onAddToCart;
  final VoidCallback onBuyNow;
  final VoidCallback? onWhatsapp;

  const _ProductSummaryCard({
    required this.product,
    required this.price,
    required this.originalPrice,
    required this.stock,
    required this.quantity,
    required this.canBuy,
    required this.isDesktop,
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
    final category = product['categoria']?.toString().trim() ?? '';
    final tipoProducto = product['tipo_producto']?.toString().trim() ?? '';
    final etiqueta = product['etiqueta']?.toString().trim() ?? '';
    final installationIncluded = product['instalacion_incluida'] == true;
    final requiresInstallation = product['requiere_instalacion'] == true;

    return Container(
      padding: EdgeInsets.all(isDesktop ? 28 : 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: StorefrontShadows.card,
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (category.isNotEmpty)
                _TagChip(
                  label: category,
                  color: secondaryColor,
                  background: const Color(0xFFEFF6FF),
                ),
              if (tipoProducto.isNotEmpty)
                _TagChip(
                  label: tipoProducto,
                  color: const Color(0xFF334155),
                  background: const Color(0xFFF1F5F9),
                ),
              if (etiqueta.isNotEmpty)
                const _TagChip(
                  label: 'Oferta',
                  color: Color(0xFFDC2626),
                  background: Color(0xFFFEF2F2),
                ),
              if (installationIncluded)
                const _TagChip(
                  label: 'Instalación incluida',
                  color: Color(0xFF166534),
                  background: Color(0xFFF0FDF4),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            product['titulo']?.toString() ?? '',
            style: TextStyle(
              fontSize: isDesktop ? 34 : 28,
              fontWeight: FontWeight.w900,
              height: 1.12,
              color: const Color(0xFF0F172A),
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (etiqueta.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: StorefrontColors.offerGradient,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      etiqueta,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                const Text(
                  'Precio final',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                StorefrontPriceWidget(
                  precio: price,
                  precioOriginal: originalPrice,
                  large: true,
                  primaryColor: primaryColor,
                  currencyPrefix: 'RD\$',
                ),
                const SizedBox(height: 6),
                const Text(
                  'Precio sujeto a disponibilidad y confirmación final.',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _StatusPill(
                icon: canBuy
                    ? Icons.check_circle_outline_rounded
                    : Icons.error_outline_rounded,
                label: canBuy ? 'Disponible' : 'Agotado',
                color: canBuy
                    ? const Color(0xFF166534)
                    : const Color(0xFFB91C1C),
                background: canBuy
                    ? const Color(0xFFF0FDF4)
                    : const Color(0xFFFEF2F2),
              ),
              _StatusPill(
                icon: Icons.inventory_2_outlined,
                label: 'Stock: $stock',
                color: const Color(0xFF1D4ED8),
                background: const Color(0xFFEFF6FF),
              ),
              if (requiresInstallation)
                const _StatusPill(
                  icon: Icons.handyman_outlined,
                  label: 'Instalación disponible',
                  color: Color(0xFF7C2D12),
                  background: Color(0xFFFFF7ED),
                ),
            ],
          ),
          const SizedBox(height: 18),
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
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color background;

  const _TagChip({
    required this.label,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color background;

  const _StatusPill({
    required this.icon,
    required this.label,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
