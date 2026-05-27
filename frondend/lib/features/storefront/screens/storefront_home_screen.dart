import 'dart:async';

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

      final productsResponse = results[5];
      final featuredProducts = List<dynamic>.from(
        results[3]['items'] as List? ?? const [],
      );
      final offerProducts = List<dynamic>.from(
        results[4]['items'] as List? ?? const [],
      ).where((item) {
        final map = Map<String, dynamic>.from(item as Map);
        return map['precio_oferta_web'] != null || map['precioOferta'] != null;
      }).toList();
      final catalogProducts = List<dynamic>.from(
        productsResponse['items'] as List? ?? const [],
      );
      final categories = _buildDisplayCategories(
        List<dynamic>.from(results[2]['data'] as List? ?? const []),
        [
          ...featuredProducts,
          ...offerProducts,
          ...catalogProducts,
        ],
      );

      setState(() {
        _config = Map<String, dynamic>.from(configResponse['data'] as Map);
        _banners = List<dynamic>.from(results[1]['data'] as List? ?? const []);
        _categories = categories;
        _featuredProducts = featuredProducts;
        _offerProducts = offerProducts;
        _products = catalogProducts;
        _page = productsResponse['page'] as int? ?? 1;
        _totalPages = productsResponse['totalPages'] as int? ?? 1;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error de conexión: $e';
        _loading = false;
      });
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
          _products.addAll(
            List<dynamic>.from(response['items'] as List? ?? const []),
          );
          _page = response['page'] as int? ?? _page + 1;
          _totalPages = response['totalPages'] as int? ?? _totalPages;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _loadingMore = false);
      }
    }
  }

  Color _getColor(String hex) {
    var normalized = hex.replaceAll('#', '');
    if (normalized.length == 6) normalized = 'FF$normalized';
    return Color(int.parse(normalized, radix: 16));
  }

  List<Map<String, dynamic>> get _searchCatalog {
    final unique = <String, Map<String, dynamic>>{};
    for (final source in [
      _products,
      _featuredProducts,
      _offerProducts,
    ]) {
      for (final item in source) {
        final map = Map<String, dynamic>.from(item as Map);
        final id = map['id']?.toString() ?? map['titulo']?.toString() ?? '';
        if (id.isNotEmpty) {
          unique[id] = map;
        }
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
      builder: (sheetContext) {
        return _StorefrontSearchSheet(
          slug: widget.slug,
          primaryColor: primaryColor,
          initialProducts: _searchCatalog,
        );
      },
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const StorefrontHomeSkeleton();
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Tienda')),
        body: StorefrontErrorState(message: _error!, onRetry: _loadInitialData),
      );
    }

    final config = _config!;
    final primaryColor = _getColor(
      config['color_principal']?.toString() ?? '#0F172A',
    );
    final secondaryColor = _getColor(
      config['color_secundario']?.toString() ?? '#2563EB',
    );
    final whatsapp = config['whatsapp_numero']?.toString() ?? '';
    final logoUrl = config['logo_url'];
    final heroTitle = config['mensaje_principal']?.toString().trim().isNotEmpty == true
        ? config['mensaje_principal'].toString().trim()
        : 'Tecnología y seguridad para tu hogar y negocio';
    final heroSubtitle =
        config['mensaje_secundario']?.toString().trim().isNotEmpty == true
        ? config['mensaje_secundario'].toString().trim()
        : 'Compra cámaras, motores, automatización y accesorios con asesoría profesional de FULLTECH SRL.';
    final isSmallDevice = MediaQuery.of(context).size.width < 370;

    return PublicStoreLayout(
      slug: widget.slug,
      storeName: config['nombre_tienda']?.toString() ?? 'FULLTECH SRL',
      logoUrl: logoUrl,
      primaryColor: primaryColor,
      secondaryColor: secondaryColor,
      heroTitle: heroTitle,
      heroSubtitle: heroSubtitle,
      banners: _banners,
      onSearchTap: _openSearch,
      onCategoriesTap: _openCategories,
      onOffersTap: _openOffers,
      onAdminTap: () =>
          Navigator.pushNamed(context, '/login?redirect=/admin'),
      onCartTap: () =>
          Navigator.pushNamed(context, '/tienda/${widget.slug}/carrito'),
      slivers: [
          SliverToBoxAdapter(
            child: _SectionHeader(
              title: 'Categorías rápidas',
              subtitle: 'Encuentra lo que necesitas en segundos.',
              actionLabel: _categories.isEmpty ? null : 'Explorar',
              onTap: _categories.isEmpty
                  ? null
                  : () {
                      Navigator.pushNamed(
                        context,
                        '/tienda/${widget.slug}/categoria/${Uri.encodeComponent(_categories.first['nombre'].toString())}',
                      );
                    },
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 156,
              child: _categories.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: _InlineEmptyState(
                        title: 'No hay categorías visibles todavía.',
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (context, index) {
                        final category =
                            _categories[index] as Map<String, dynamic>;
                        return _CategoryCard(
                          category: category,
                          secondaryColor: secondaryColor,
                          onTap: () => Navigator.pushNamed(
                            context,
                            '/tienda/${widget.slug}/categoria/${Uri.encodeComponent(category['nombre'].toString())}',
                          ),
                        );
                      },
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemCount: _categories.length,
                    ),
            ),
          ),
          SliverToBoxAdapter(
            child: _SectionHeader(
              title: 'Ofertas del día',
              subtitle: 'Promociones pensadas para vender hoy.',
              actionLabel: _offerProducts.isEmpty ? null : 'Ver productos',
              onTap: _offerProducts.isEmpty ? null : _openSearch,
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 348,
              child: _offerProducts.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: _InlineEmptyState(
                        title:
                            'Las ofertas aparecerán aquí cuando existan precios especiales.',
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (context, index) => StorefrontProductCard(
                        product: Map<String, dynamic>.from(
                          _offerProducts[index] as Map,
                        ),
                        slug: widget.slug,
                        primaryColor: primaryColor,
                        secondaryColor: secondaryColor,
                        whatsapp: whatsapp,
                      ),
                      separatorBuilder: (_, __) => const SizedBox(width: 14),
                      itemCount: _offerProducts.length,
                    ),
            ),
          ),
          SliverToBoxAdapter(
            child: _SectionHeader(
              title: 'Destacados',
              subtitle: 'Lo más buscado por nuestros clientes.',
              actionLabel: _featuredProducts.isEmpty ? null : 'Ver más',
              onTap: _featuredProducts.isEmpty
                  ? null
                  : () => Navigator.pushNamed(
                      context,
                      '/tienda/${widget.slug}/categoria/${Uri.encodeComponent(_featuredProducts.first['categoria'].toString())}',
                    ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 348,
              child: _featuredProducts.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: _InlineEmptyState(
                        title: 'Los productos destacados aparecerán aquí.',
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (context, index) => StorefrontProductCard(
                        product: Map<String, dynamic>.from(
                          _featuredProducts[index] as Map,
                        ),
                        slug: widget.slug,
                        primaryColor: primaryColor,
                        secondaryColor: secondaryColor,
                        whatsapp: whatsapp,
                      ),
                      separatorBuilder: (_, __) => const SizedBox(width: 14),
                      itemCount: _featuredProducts.length,
                    ),
            ),
          ),
          SliverToBoxAdapter(
            child: _SectionHeader(
              title: 'Todo el catálogo',
              subtitle: 'Explora la tienda completa de FULLTECH SRL.',
            ),
          ),
          if (_products.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: _InlineEmptyState(
                  title: 'No hay productos visibles en la tienda.',
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.61,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
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
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
              child: _page < _totalPages
                  ? FilledButton(
                      onPressed: _loadingMore ? null : _loadMore,
                      style: FilledButton.styleFrom(
                        backgroundColor: primaryColor,
                        minimumSize: const Size(double.infinity, 54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
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
              padding: const EdgeInsets.only(bottom: 8),
              child: FloatingActionButton.extended(
                onPressed: () {
                  final number = whatsapp.replaceAll(RegExp(r'[^\d]'), '');
                  launchUrl(Uri.parse('https://wa.me/$number'));
                },
                backgroundColor: StorefrontColors.whatsapp,
                icon: const Icon(Icons.chat_rounded, color: Colors.white),
                label: Text(isSmallDevice ? 'Chat' : 'WhatsApp'),
              ),
            ),
    );
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
      if (rawName.isEmpty) {
        continue;
      }

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
        if (rawName.isEmpty) {
          continue;
        }

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
        if (countCompare != 0) {
          return countCompare;
        }
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
    if (directImage.isNotEmpty) {
      return directImage;
    }

    final key = _normalizeCategoryKey(categoryName);
    for (final product in products) {
      final productCategory = product['categoria']?.toString().trim() ?? '';
      if (_normalizeCategoryKey(productCategory) != key) {
        continue;
      }

      final image =
          product['imagen_destacada_url'] ??
          product['imagen1'] ??
          product['imagen2'] ??
          product['imagen3'];
      final resolved = image?.toString().trim() ?? '';
      if (resolved.isNotEmpty) {
        return resolved;
      }
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

class _PremiumHero extends StatelessWidget {
  final String slug;
  final String storeName;
  final dynamic logoUrl;
  final Color primaryColor;
  final Color secondaryColor;
  final String heroTitle;
  final String heroSubtitle;
  final VoidCallback onSearchTap;

  const _PremiumHero({
    required this.slug,
    required this.storeName,
    required this.logoUrl,
    required this.primaryColor,
    required this.secondaryColor,
    required this.heroTitle,
    required this.heroSubtitle,
    required this.onSearchTap,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final canPop = Navigator.of(context).canPop();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      padding: EdgeInsets.fromLTRB(18, topPadding + 10, 18, 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          colors: [primaryColor, secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: StorefrontShadows.strong,
      ),
      child: Stack(
        children: [
          Positioned(
            right: -40,
            top: -20,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            left: -30,
            bottom: -55,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (canPop)
                    _GlassIconButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                  if (canPop) const SizedBox(width: 10),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: StorefrontSmartImage(
                      source: logoUrl,
                      fit: BoxFit.cover,
                      borderRadius: BorderRadius.circular(16),
                      placeholder: const Center(
                        child: Icon(
                          Icons.shield_moon_outlined,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          storeName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Tienda oficial FULLTECH',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.78),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _GlassIconButton(
                    icon: Icons.search_rounded,
                    onTap: onSearchTap,
                  ),
                  const SizedBox(width: 8),
                  _GlassIconButton(
                    icon: Icons.shopping_cart_outlined,
                    onTap: () =>
                        Navigator.pushNamed(context, '/tienda/$slug/carrito'),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Garantía, soporte e instalación profesional',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.94),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                heroTitle,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  height: 1.04,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: Text(
                  heroSubtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.84),
                    fontSize: 15,
                    height: 1.55,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  FilledButton.icon(
                    onPressed: onSearchTap,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    icon: const Icon(Icons.flash_on_rounded),
                    label: const Text('Buscar productos'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      '/tienda/$slug/categoria/${Uri.encodeComponent('Cámaras')}',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    icon: const Icon(Icons.play_circle_outline_rounded),
                    label: const Text('Ver ofertas'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GlassIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: Colors.white),
        ),
      ),
    );
  }
}

class _SearchShortcutCard extends StatelessWidget {
  final VoidCallback onTap;

  const _SearchShortcutCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: StorefrontShadows.card,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.search_rounded,
                  color: Color(0xFF2563EB),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Buscar productos',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Toca para ver sugerencias en vivo por nombre, categoría o descripción.',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Color(0xFF94A3B8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BenefitStrip extends StatelessWidget {
  final Color secondaryColor;

  const _BenefitStrip({required this.secondaryColor});

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.verified_outlined, 'Garantía'),
      (Icons.storefront_outlined, 'Tienda física'),
      (Icons.support_agent_outlined, 'Soporte'),
      (Icons.handyman_outlined, 'Instalación'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final item in items) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: StorefrontShadows.soft,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(item.$1, size: 18, color: secondaryColor),
                  const SizedBox(width: 8),
                  Text(
                    item.$2,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
          ],
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onTap;

  const _SectionHeader({
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.6,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (actionLabel != null)
            TextButton(onPressed: onTap, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final Map<String, dynamic> category;
  final Color secondaryColor;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.category,
    required this.secondaryColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = category['nombre']?.toString() ?? '';
    final normalizedName = switch (name.toLowerCase()) {
      'camaras' => 'Cámaras',
      _ => name,
    };
    final count = category['cantidad']?.toString() ?? '0';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: StorefrontShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF7FAFE), Color(0xFFEFF6FF)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: StorefrontSmartImage(
                  source: category['imagen'],
                  fit: BoxFit.cover,
                  borderRadius: BorderRadius.circular(18),
                  placeholder: Center(
                    child: Icon(
                      Icons.category_outlined,
                      color: secondaryColor,
                      size: 26,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              normalizedName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$count productos',
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

class _FallbackPromoCard extends StatelessWidget {
  final Color primaryColor;
  final Color secondaryColor;

  const _FallbackPromoCard({
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: StorefrontShadows.strong,
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tecnología lista para instalar',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  height: 1.05,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Compra cámaras, motores, accesorios y kits con soporte, garantía y acompañamiento comercial de FULLTECH.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: () {},
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: primaryColor,
                ),
                child: const Text('Ver catálogo'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InlineEmptyState extends StatelessWidget {
  final String title;

  const _InlineEmptyState({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 132,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: StorefrontShadows.soft,
      ),
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFF64748B),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

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

    if (query.length < 1) {
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

    if (query.length < 2) {
      return;
    }

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
        if (id.isNotEmpty) {
          merged[id] = item;
        }
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
    return SafeArea(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.88,
        decoration: const BoxDecoration(
          color: Color(0xFFF8FAFC),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Buscar productos',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
              child: TextField(
                controller: _controller,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Busca cámaras, motores, routers y más',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _controller.text.trim().isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            _controller.clear();
                            _runSearch('');
                          },
                          icon: const Icon(Icons.close_rounded),
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _results.isEmpty
                  ? const _SearchEmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                      itemBuilder: (context, index) {
                        final product = _results[index];
                        final image = StorefrontHelpers.getPrimaryImage(product);
                        final price = StorefrontHelpers.getEffectivePrice(product);
                        final hasOffer =
                            StorefrontHelpers.getOriginalPrice(product) != null;

                        return Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () {
                              Navigator.of(context).pop();
                              Navigator.pushNamed(
                                context,
                                '/tienda/${widget.slug}/producto/${product['id']}',
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 72,
                                    height: 72,
                                    child: StorefrontSmartImage(
                                      source: image,
                                      fit: BoxFit.contain,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          product['categoria']?.toString() ?? '',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Color(0xFF64748B),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          product['titulo']?.toString() ?? '',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF0F172A),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Text(
                                              'RD\$${price.toStringAsFixed(0)}',
                                              style: TextStyle(
                                                color: widget.primaryColor,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                            if (hasOffer) ...[
                                              const SizedBox(width: 8),
                                              const Text(
                                                'Oferta',
                                                style: TextStyle(
                                                  color: Color(0xFFDC2626),
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 16,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemCount: _results.length,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchEmptyState extends StatelessWidget {
  const _SearchEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(
              Icons.search_off_rounded,
              size: 40,
              color: Color(0xFF94A3B8),
            ),
            SizedBox(height: 12),
            Text(
              'No encontramos productos con esa búsqueda.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
