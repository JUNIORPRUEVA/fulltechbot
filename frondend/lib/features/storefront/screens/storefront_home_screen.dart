import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../public/widgets/public_store_layout.dart';
import '../services/storefront_api_service.dart';
import '../services/storefront_helpers.dart';
import '../theme/storefront_theme.dart';
import '../widgets/storefront_error_state.dart';
import '../widgets/storefront_footer.dart';
import '../widgets/storefront_product_card.dart';
import '../widgets/storefront_skeleton.dart' hide StorefrontColors;
import '../widgets/storefront_smart_image.dart';

class StorefrontHomeScreen extends StatefulWidget {
  final String slug;

  const StorefrontHomeScreen({super.key, required this.slug});

  @override
  State<StorefrontHomeScreen> createState() => _StorefrontHomeScreenState();
}

class _StorefrontHomeScreenState extends State<StorefrontHomeScreen> {
  Map<String, dynamic>? _config;
  List<dynamic> _banners = [];
  List<dynamic> _categories = [];
  List<dynamic> _featuredProducts = [];
  List<dynamic> _offerProducts = [];
  List<dynamic> _products = [];
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  int _page = 1;
  int _totalPages = 1;

  static final RegExp _combiningMarks = RegExp(r'[\u0300-\u036f]');

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        StorefrontApiService.getConfig(widget.slug),
        StorefrontApiService.getBanners(widget.slug),
        StorefrontApiService.getCategories(widget.slug),
        StorefrontApiService.getProducts(
          widget.slug,
          destacado: true,
          sort: 'featured',
          limit: 8,
        ),
        StorefrontApiService.getProducts(widget.slug, sort: 'offers', limit: 8),
        StorefrontApiService.getProducts(
          widget.slug,
          page: 1,
          limit: 16,
          sort: 'featured',
        ),
      ]);

      final configResponse = results[0];
      if (configResponse['ok'] != true) {
        setState(() {
          _error =
              configResponse['message']?.toString() ??
              'No se pudo cargar la tienda.';
          _loading = false;
        });
        return;
      }

      final featuredProducts = _dedupeProducts(
        List<dynamic>.from(results[3]['items'] as List? ?? const []),
      );
      final offerProducts = _dedupeProducts(
        List<dynamic>.from(results[4]['items'] as List? ?? const []).where((
          item,
        ) {
          final map = Map<String, dynamic>.from(item as Map);
          return map['precio_oferta_web'] != null ||
              map['precioOferta'] != null;
        }).toList(),
      );
      final offerIds = offerProducts
          .map((item) => (item as Map)['id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toSet();
      final productsResponse = results[5];
      final catalogProducts = _dedupeProducts(
        List<dynamic>.from(productsResponse['items'] as List? ?? const []),
      );
      final categories = _buildDisplayCategories(
        List<dynamic>.from(results[2]['data'] as List? ?? const []),
        [...featuredProducts, ...offerProducts, ...catalogProducts],
      );

      setState(() {
        _config = Map<String, dynamic>.from(configResponse['data'] as Map);
        _banners = List<dynamic>.from(results[1]['data'] as List? ?? const []);
        _categories = categories;
        _featuredProducts = featuredProducts.where((item) {
          final id = (item as Map)['id']?.toString() ?? '';
          return id.isEmpty || !offerIds.contains(id);
        }).toList();
        _offerProducts = offerProducts;
        _products = catalogProducts;
        _page = productsResponse['page'] as int? ?? 1;
        _totalPages = productsResponse['totalPages'] as int? ?? 1;
        _loading = false;
      });

      _precacheVisibleImages();
    } catch (e) {
      setState(() {
        _error = 'Error de conexión: $e';
        _loading = false;
      });
    }
  }

  void _precacheVisibleImages() {
    if (!mounted) return;

    final imagesToPrecache = <String>[];

    for (final banner in _banners) {
      final map = Map<String, dynamic>.from(banner as Map);
      final imageUrl = map['imagen_url']?.toString();
      if (imageUrl != null && imageUrl.isNotEmpty) {
        imagesToPrecache.add(imageUrl);
      }
    }

    for (final product in _offerProducts) {
      final map = Map<String, dynamic>.from(product as Map);
      final image = StorefrontHelpers.getPrimaryImage(map);
      if (image != null && image.isNotEmpty) {
        imagesToPrecache.add(image);
      }
    }

    for (final product in _featuredProducts) {
      final map = Map<String, dynamic>.from(product as Map);
      final image = StorefrontHelpers.getPrimaryImage(map);
      if (image != null && image.isNotEmpty) {
        imagesToPrecache.add(image);
      }
    }

    for (final url in imagesToPrecache.take(12)) {
      if (url.startsWith('http')) {
        precacheImage(NetworkImage(url), context);
      }
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _page >= _totalPages) return;

    setState(() => _loadingMore = true);
    try {
      final response = await StorefrontApiService.getProducts(
        widget.slug,
        page: _page + 1,
        limit: 16,
        sort: 'featured',
      );

      if (response['ok'] == true) {
        setState(() {
          _products = _dedupeProducts([
            ..._products,
            ...List<dynamic>.from(response['items'] as List? ?? const []),
          ]);
          _page = response['page'] as int? ?? _page + 1;
          _totalPages = response['totalPages'] as int? ?? _totalPages;
        });
      }
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Color _getColor(String hex) {
    var normalized = hex.replaceAll('#', '');
    if (normalized.length == 6) normalized = 'FF$normalized';
    return Color(int.parse(normalized, radix: 16));
  }

  List<Map<String, dynamic>> get _searchCatalog {
    final unique = <String, Map<String, dynamic>>{};
    for (final source in [_products, _featuredProducts, _offerProducts]) {
      for (final item in source) {
        final map = Map<String, dynamic>.from(item as Map);
        final id = map['id']?.toString() ?? map['titulo']?.toString() ?? '';
        if (id.isNotEmpty) unique[id] = map;
      }
    }
    return unique.values.toList();
  }

  void _openSearch() {
    final config = _config ?? {};
    final primaryColor = _getColor(
      config['color_principal']?.toString() ?? '#0F172A',
    );

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _StorefrontSearchSheet(
        slug: widget.slug,
        primaryColor: primaryColor,
        initialProducts: _searchCatalog,
      ),
    );
  }

  void _openCategories() {
    if (_categories.isEmpty) {
      _openSearch();
      return;
    }
    final firstCategory = _categories.first['nombre']?.toString();
    if (firstCategory == null || firstCategory.isEmpty) {
      _openSearch();
      return;
    }
    Navigator.pushNamed(
      context,
      '/tienda/${widget.slug}/categoria/${Uri.encodeComponent(firstCategory)}',
    );
  }

  void _openOffers() {
    if (_offerProducts.isNotEmpty) {
      final category = _offerProducts.first['categoria']?.toString();
      if (category != null && category.isNotEmpty) {
        Navigator.pushNamed(
          context,
          '/tienda/${widget.slug}/categoria/${Uri.encodeComponent(category)}',
        );
        return;
      }
    }
    _openSearch();
  }

  void _openWhatsapp(String whatsapp) {
    final number = whatsapp.replaceAll(RegExp(r'[^\d]'), '');
    if (number.isEmpty) return;
    launchUrl(Uri.parse('https://wa.me/$number'));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const StorefrontHomeSkeleton();

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Tienda')),
        body: StorefrontErrorState(message: _error!, onRetry: _loadInitialData),
      );
    }

    final config = _config!;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final primaryColor = _getColor(
      config['color_principal']?.toString() ?? '#0F172A',
    );
    final secondaryColor = _getColor(
      config['color_secundario']?.toString() ?? '#2563EB',
    );
    final whatsapp = config['whatsapp_numero']?.toString() ?? '';
    final storeName = config['nombre_tienda']?.toString() ?? 'FULLTECH SRL';
    final heroTitle =
        config['mensaje_principal']?.toString().trim().isNotEmpty == true
            ? config['mensaje_principal'].toString().trim()
            : 'Tecnología y seguridad para tu hogar y negocio';
    final heroSubtitle =
        config['mensaje_secundario']?.toString().trim().isNotEmpty == true
            ? config['mensaje_secundario'].toString().trim()
            : 'Compra cámaras, motores, automatización y accesorios con asesoría profesional de FULLTECH SRL.';
    final isTablet = screenWidth >= 700 && screenWidth < 1100;
    final isDesktop = screenWidth >= 1100;
    final contentPadding = math.max(14.0, ((screenWidth - 1240) / 2) + 16);
    final catalogCrossAxisCount = isDesktop ? 4 : (isTablet ? 3 : 2);
    final catalogAspectRatio = isDesktop ? 0.78 : (isTablet ? 0.70 : 0.64);

    return PublicStoreLayout(
      slug: widget.slug,
      storeName: storeName,
      logoUrl: config['logo_url'],
      primaryColor: primaryColor,
      secondaryColor: secondaryColor,
      heroTitle: heroTitle,
      heroSubtitle: heroSubtitle,
      banners: _banners,
      promotedProducts: _offerProducts.isNotEmpty
          ? _offerProducts
          : (_featuredProducts.isNotEmpty ? _featuredProducts : _products),
      onSearchTap: _openSearch,
      onCategoriesTap: _openCategories,
      onOffersTap: _openOffers,
      onAdminTap: () => Navigator.pushNamed(context, '/login?redirect=/admin'),
      onCartTap: () =>
          Navigator.pushNamed(context, '/tienda/${widget.slug}/carrito'),
      onWhatsappTap: whatsapp.isEmpty ? null : () => _openWhatsapp(whatsapp),
      slivers: [
        // ==========================================
        // BENEFITS CHIPS (scroll horizontal)
        // ==========================================
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(contentPadding, 8, contentPadding, 4),
            child: SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _BenefitChip(
                    icon: Icons.verified_rounded,
                    label: 'Garantía',
                    color: primaryColor,
                  ),
                  const SizedBox(width: 8),
                  _BenefitChip(
                    icon: Icons.store_rounded,
                    label: 'Tienda física',
                    color: primaryColor,
                  ),
                  const SizedBox(width: 8),
                  _BenefitChip(
                    icon: Icons.support_agent_rounded,
                    label: 'Soporte',
                    color: primaryColor,
                  ),
                  const SizedBox(width: 8),
                  _BenefitChip(
                    icon: Icons.build_circle_rounded,
                    label: 'Instalación',
                    color: primaryColor,
                  ),
                ],
              ),
            ),
          ),
        ),

        // ==========================================
        // CATEGORÍAS RÁPIDAS (scroll horizontal)
        // ==========================================
        if (_categories.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(contentPadding, 8, contentPadding, 4),
              child: Text(
                'Categorías',
                style: TextStyle(
                  fontSize: isDesktop ? 20 : 17,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: isDesktop ? 164 : 144,
              child: ListView.separated(
                padding: EdgeInsets.symmetric(horizontal: contentPadding),
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) {
                  final category = _categories[index] as Map<String, dynamic>;
                  return _CategoryCard(
                    width: isDesktop ? 162 : (isTablet ? 148 : 118),
                    category: category,
                    secondaryColor: secondaryColor,
                    onTap: () => Navigator.pushNamed(
                      context,
                      '/tienda/${widget.slug}/categoria/${Uri.encodeComponent(category['nombre'].toString())}',
                    ),
                  );
                },
                separatorBuilder: (_, index) => const SizedBox(width: 12),
                itemCount: _categories.length,
              ),
            ),
          ),
        ],

        // ==========================================
        // OFERTAS DEL DÍA (grid 2 columnas en móvil)
        // ==========================================
        if (_offerProducts.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(contentPadding, 16, contentPadding, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: StorefrontColors.offerGradient,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.local_fire_department_rounded, size: 16, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'Ofertas del día',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _openOffers,
                    child: Text(
                      'Ver todo',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: secondaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: contentPadding),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: catalogCrossAxisCount,
                childAspectRatio: catalogAspectRatio,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                return StorefrontProductCard(
                  product: Map<String, dynamic>.from(
                    _offerProducts[index] as Map,
                  ),
                  slug: widget.slug,
                  primaryColor: primaryColor,
                  secondaryColor: secondaryColor,
                  compact: true,
                  whatsapp: whatsapp,
                );
              }, childCount: _offerProducts.length),
            ),
          ),
        ],

        // ==========================================
        // DESTACADOS (grid 2 columnas en móvil)
        // ==========================================
        if (_featuredProducts.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(contentPadding, 16, contentPadding, 8),
              child: Row(
                children: [
                  Text(
                    'Destacados',
                    style: TextStyle(
                      fontSize: isDesktop ? 20 : 17,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      final category =
                          _featuredProducts.first['categoria']?.toString() ?? '';
                      if (category.isNotEmpty) {
                        Navigator.pushNamed(
                          context,
                          '/tienda/${widget.slug}/categoria/${Uri.encodeComponent(category)}',
                        );
                      }
                    },
                    child: Text(
                      'Ver todo',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: secondaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: contentPadding),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: catalogCrossAxisCount,
                childAspectRatio: catalogAspectRatio,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                return StorefrontProductCard(
                  product: Map<String, dynamic>.from(
                    _featuredProducts[index] as Map,
                  ),
                  slug: widget.slug,
                  primaryColor: primaryColor,
                  secondaryColor: secondaryColor,
                  compact: true,
                  whatsapp: whatsapp,
                );
              }, childCount: _featuredProducts.length),
            ),
          ),
        ],

        // ==========================================
        // TODO EL CATÁLOGO
        // ==========================================
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(contentPadding, 16, contentPadding, 8),
            child: Text(
              'Todo el catálogo',
              style: TextStyle(
                fontSize: isDesktop ? 20 : 17,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF0F172A),
              ),
            ),
          ),
        ),
        if (_products.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: contentPadding),
              child: Container(
                height: 100,
                alignment: Alignment.center,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: StorefrontShadows.soft,
                ),
                child: const Text(
                  'No hay productos visibles en la tienda.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: contentPadding),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: catalogCrossAxisCount,
                childAspectRatio: catalogAspectRatio,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                return StorefrontProductCard(
                  product: Map<String, dynamic>.from(_products[index] as Map),
                  slug: widget.slug,
                  primaryColor: primaryColor,
                  secondaryColor: secondaryColor,
                  compact: true,
                  whatsapp: whatsapp,
                );
              }, childCount: _products.length),
            ),
          ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(contentPadding, 18, contentPadding, 8),
            child: _page < _totalPages
                ? FilledButton(
                    onPressed: _loadingMore ? null : _loadMore,
                    style: FilledButton.styleFrom(
                      backgroundColor: primaryColor,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _loadingMore
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Ver más productos'),
                  )
                : const SizedBox.shrink(),
          ),
        ),
        SliverToBoxAdapter(
          child: StorefrontFooter(
            config: config,
            primaryColor: primaryColor,
            secondaryColor: secondaryColor,
          ),
        ),
      ],
      floatingActionButton: whatsapp.isEmpty
          ? null
          : Padding(
              padding: EdgeInsets.only(
                right: isDesktop ? 16 : 4,
                bottom: MediaQuery.viewPaddingOf(context).bottom + 8,
              ),
              child: isDesktop
                  ? FloatingActionButton.extended(
                      onPressed: () => _openWhatsapp(whatsapp),
                      backgroundColor: StorefrontColors.whatsapp,
                      icon: const Icon(Icons.chat_rounded, color: Colors.white),
                      label: const Text('WhatsApp'),
                    )
                  : FloatingActionButton.small(
                      onPressed: () => _openWhatsapp(whatsapp),
                      backgroundColor: StorefrontColors.whatsapp,
                      child: const Icon(Icons.chat_rounded, color: Colors.white),
                    ),
            ),
    );
  }

  List<dynamic> _dedupeProducts(List<dynamic> products) {
    final unique = <String, dynamic>{};
    for (final item in products) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);
      final id = map['id']?.toString() ?? map['titulo']?.toString() ?? '';
      if (id.isNotEmpty) unique[id] = map;
    }
    return unique.values.toList();
  }

  List<Map<String, dynamic>> _buildDisplayCategories(
    List<dynamic> rawCategories,
    List<dynamic> sourceProducts,
  ) {
    final products = sourceProducts
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    final merged = <String, Map<String, dynamic>>{};

    for (final rawCategory in rawCategories.whereType<Map>()) {
      final category = Map<String, dynamic>.from(rawCategory);
      final rawName = category['nombre']?.toString().trim() ?? '';
      if (rawName.isEmpty) continue;

      final key = _normalizeCategoryKey(rawName);
      final displayName = _displayCategoryName(rawName);
      final count = int.tryParse(category['cantidad']?.toString() ?? '0') ?? 0;
      final image = _resolveCategoryImage(category['imagen'], displayName, products);

      final existing = merged[key];
      if (existing == null) {
        merged[key] = {
          ...category,
          'nombre': displayName,
          'cantidad': count,
          'imagen': image,
        };
      } else {
        existing['cantidad'] = (existing['cantidad'] as int? ?? 0) + count;
        existing['imagen'] ??= image;
      }
    }

    if (merged.isEmpty && products.isNotEmpty) {
      for (final product in products) {
        final rawName = product['categoria']?.toString().trim() ?? '';
        if (rawName.isEmpty) continue;

        final key = _normalizeCategoryKey(rawName);
        final displayName = _displayCategoryName(rawName);
        final image = _resolveCategoryImage(null, displayName, products);

        merged.update(
          key,
          (existing) => {
            ...existing,
            'cantidad': (existing['cantidad'] as int? ?? 0) + 1,
            'imagen': existing['imagen'] ?? image,
          },
          ifAbsent: () => {
            'nombre': displayName,
            'slug': Uri.encodeComponent(displayName.toLowerCase()),
            'cantidad': 1,
            'imagen': image,
          },
        );
      }
    }

    final categories = merged.values.toList()
      ..sort((a, b) {
        final countCompare =
            (b['cantidad'] as int? ?? 0).compareTo(a['cantidad'] as int? ?? 0);
        if (countCompare != 0) return countCompare;
        return (a['nombre']?.toString() ?? '').compareTo(
          b['nombre']?.toString() ?? '',
        );
      });

    return categories;
  }

  String _resolveCategoryImage(
    dynamic currentImage,
    String categoryName,
    List<Map<String, dynamic>> products,
  ) {
    final directImage = currentImage?.toString().trim() ?? '';
    if (directImage.isNotEmpty) return directImage;

    final key = _normalizeCategoryKey(categoryName);
    for (final product in products) {
      final productCategory = product['categoria']?.toString().trim() ?? '';
      if (_normalizeCategoryKey(productCategory) != key) continue;

      final image =
          product['imagen_destacada_url'] ??
          product['imagen1'] ??
          product['imagen2'] ??
          product['imagen3'];
      final resolved = image?.toString().trim() ?? '';
      if (resolved.isNotEmpty) return resolved;
    }

    return '';
  }

  String _displayCategoryName(String value) {
    final normalized = value.trim().toLowerCase();
    return switch (normalized) {
      'camaras' => 'Cámaras',
      'camaras ip' => 'Cámaras IP',
      'dvr' => 'DVR',
      _ => value.trim(),
    };
  }

  String _normalizeCategoryKey(String value) {
    final lower = value.trim().toLowerCase();
    final decomposed = lower
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('ñ', 'n');
    return decomposed.replaceAll(_combiningMarks, '');
  }
}

// ==========================================
// BENEFIT CHIP
// ==========================================
class _BenefitChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _BenefitChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE5EAF1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// CATEGORY CARD
// ==========================================
class _CategoryCard extends StatelessWidget {
  final double width;
  final Map<String, dynamic> category;
  final Color secondaryColor;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.width,
    required this.category,
    required this.secondaryColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = category['nombre']?.toString() ?? '';
    final count = category['cantidad']?.toString() ?? '0';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE6ECF2)),
          boxShadow: StorefrontShadows.soft,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF8FAFD), Color(0xFFF1F5F9)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: StorefrontSmartImage(
                  source: category['imagen'],
                  fit: BoxFit.contain,
                  borderRadius: BorderRadius.circular(16),
                  placeholder: Center(
                    child: Icon(
                      Icons.category_outlined,
                      color: secondaryColor,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                height: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$count productos',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// SEARCH SHEET
// ==========================================
class _StorefrontSearchSheet extends StatefulWidget {
  final String slug;
  final Color primaryColor;
  final List<Map<String, dynamic>> initialProducts;

  const _StorefrontSearchSheet({
    required this.slug,
    required this.primaryColor,
    required this.initialProducts,
  });

  @override
  State<_StorefrontSearchSheet> createState() => _StorefrontSearchSheetState();
}

class _StorefrontSearchSheetState extends State<_StorefrontSearchSheet> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  List<Map<String, dynamic>> _results = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _results = widget.initialProducts.take(8).toList();
    _controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.removeListener(_onChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onChanged() {
    final query = _controller.text.trim();
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 320), () {
      _runSearch(query);
    });
  }

  Future<void> _runSearch(String query) async {
    if (!mounted) return;

    if (query.isEmpty) {
      setState(() {
        _loading = false;
        _results = widget.initialProducts.take(8).toList();
      });
      return;
    }

    final normalized = query.toLowerCase();
    final local = widget.initialProducts.where((product) {
      final haystack = [
        product['titulo'],
        product['categoria'],
        product['descripcion'],
        product['descripcion_web'],
        product['palabrasClave'],
      ].whereType<Object?>().map((item) => item.toString().toLowerCase()).join(' ');
      return haystack.contains(normalized);
    }).toList();

    setState(() {
      _results = local;
      _loading = query.length >= 2;
    });

    if (query.length < 2) return;

    try {
      final response = await StorefrontApiService.getProducts(
        widget.slug,
        search: query,
        limit: 12,
      );

      final remote = List<Map<String, dynamic>>.from(
        (response['items'] as List? ?? const []).map(
          (item) => Map<String, dynamic>.from(item as Map),
        ),
      );

      final merged = <String, Map<String, dynamic>>{};
      for (final item in [...local, ...remote]) {
        final id = item['id']?.toString() ?? item['titulo']?.toString() ?? '';
        if (id.isNotEmpty) merged[id] = item;
      }

      if (!mounted) return;

      setState(() {
        _results = merged.values.toList();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.viewPaddingOf(context).bottom;
    final isDesktop = MediaQuery.sizeOf(context).width >= 1024;

    return Container(
      height: MediaQuery.sizeOf(context).height * 0.82,
      decoration: const BoxDecoration(
        color: Color(0xFFF5F7FA),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 6),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          // Search field
          Padding(
            padding: EdgeInsets.fromLTRB(
              isDesktop ? 24 : 14,
              6,
              isDesktop ? 24 : 14,
              10,
            ),
            child: TextField(
              controller: _controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Buscar cámaras, DVR, motores...',
                prefixIcon: Icon(Icons.search_rounded, color: widget.primaryColor),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 20),
                        onPressed: () => _controller.clear(),
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: const Color(0xFFE5EAF1),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: widget.primaryColor, width: 1.5),
                ),
              ),
            ),
          ),
          // Results
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _results.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.search_off_rounded,
                              size: 48,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'No se encontraron productos',
                              style: TextStyle(
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: EdgeInsets.fromLTRB(
                          isDesktop ? 24 : 14,
                          4,
                          isDesktop ? 24 : 14,
                          bottomPadding + 16,
                        ),
                        itemBuilder: (context, index) {
                          final product = _results[index];
                          return StorefrontProductCard(
                            product: product,
                            slug: widget.slug,
                            primaryColor: widget.primaryColor,
                            secondaryColor: widget.primaryColor,
                            compact: true,
                          );
                        },
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemCount: _results.length,
                      ),
          ),
        ],
      ),
    );
  }
}
