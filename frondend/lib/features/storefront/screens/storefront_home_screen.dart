import 'dart:async';
import 'dart:js' as js;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../public/widgets/public_store_layout.dart';
import '../services/storefront_api_service.dart';
import '../services/storefront_helpers.dart';
import '../theme/storefront_theme.dart';
import '../widgets/storefront_footer.dart';
import '../widgets/storefront_product_card.dart';
import '../widgets/storefront_smart_image.dart';
import '../widgets/storefront_trust_chips.dart';

/// Pantalla principal optimizada de la tienda FULLTECH SRL.
/// Diseño mobile-first, premium, tecnológico y persuasivo.
class StorefrontHomeScreen extends StatefulWidget {
  final String slug;

  const StorefrontHomeScreen({super.key, required this.slug});

  @override
  State<StorefrontHomeScreen> createState() => _StorefrontHomeScreenState();
}

class _StorefrontHomeScreenState extends State<StorefrontHomeScreen> {
  static const Map<String, dynamic> _fallbackConfig = {
    'nombre_tienda': 'FULLTECH SRL',
    'color_principal': '#0F172A',
    'color_secundario': '#2563EB',
    'whatsapp_numero': '',
    'mensaje_principal': 'Tienda oficial FULLTECH SRL',
    'mensaje_secundario': 'Explora ofertas, productos y soluciones.',
  };

  // ==========================================
  // PERF LOGGING CON STOPWATCH
  // ==========================================
  final Stopwatch _perfSw = Stopwatch()..start();
  void _perfLog(String message) {
    debugPrint('[PERF] ${_perfSw.elapsedMilliseconds}ms - $message');
  }

  Map<String, dynamic>? _config;
  List<dynamic> _banners = [];
  List<dynamic> _categories = [];
  List<dynamic> _featuredProducts = [];
  List<dynamic> _offerProducts = [];
  List<dynamic> _products = [];

  static final RegExp _combiningMarks = RegExp(r'[\u0300-\u036f]');

  @override
  void initState() {
    super.initState();
    _perfLog('StorefrontHomeScreen.initState');
    _config = Map<String, dynamic>.from(_fallbackConfig);

    // ==========================================
    // PASO 1: Mostrar Home INMEDIATAMENTE con skeleton
    // Sin esperar NADA de API
    // El skeleton se muestra en el primer frame porque _loading=true
    // ==========================================
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _perfLog('StorefrontHomeScreen.firstFrame - Home visible');

      // Ocultar splash HTML de inmediato
      _hideHtmlSplash();

      // Iniciar carga en segundo plano inmediatamente
      unawaited(_loadHomeDataInBackground());
    });
  }

  /// Oculta el splash HTML del index.html llamando a window.fulltechHideSplash()
  void _hideHtmlSplash() {
    try {
      js.context.callMethod('fulltechHideSplash');
    } catch (e) {
      debugPrint('[PERF] Error ocultando splash HTML: $e');
    }
  }

  /// Carga progresiva en segundo plano sin bloquear la UI
  Future<void> _loadHomeDataInBackground() async {
    _perfLog('_loadHomeDataInBackground started');

    Future.microtask(() async {
      _perfLog('config loading started');
      try {
        final configResponse = await StorefrontApiService.getConfig(
          widget.slug,
        ).timeout(const Duration(seconds: 10));

        if (configResponse['ok'] == true && mounted) {
          setState(() {
            _config = Map<String, dynamic>.from(configResponse['data'] as Map);
          });
          _perfLog('config loaded');
        }
      } catch (e) {
        _perfLog('config failed: $e');
      }
    });

    // ==========================================
    // PASO 3: Cargar banners (no crítico)
    // ==========================================
    Future.microtask(() async {
      _perfLog('banners loading started');
      try {
        final bannersResponse = await StorefrontApiService.getBanners(
          widget.slug,
        ).timeout(const Duration(seconds: 10));
        if (mounted) {
          setState(() {
            _banners = List<dynamic>.from(
              bannersResponse['data'] as List? ?? const [],
            );
          });
          _perfLog('banners loaded');
        }
      } catch (e) {
        _perfLog('banners failed: $e');
      }
    });

    // ==========================================
    // PASO 4: Cargar categorías (no crítico)
    // ==========================================
    Future.microtask(() async {
      _perfLog('categories loading started');
      try {
        final categoriesResponse = await StorefrontApiService.getCategories(
          widget.slug,
        ).timeout(const Duration(seconds: 10));
        if (mounted) {
          setState(() {
            final rawCategories = List<dynamic>.from(
              categoriesResponse['data'] as List? ?? const [],
            );
            _categories = _buildDisplayCategories(rawCategories, []);
          });
          _perfLog('categories loaded');
        }
      } catch (e) {
        _perfLog('categories failed: $e');
      }
    });

    // ==========================================
    // PASO 5: Cargar productos (lo más pesado, al final)
    // ==========================================
    Future.microtask(() async {
      _perfLog('products loading started');
      try {
        final productResults = await Future.wait([
          StorefrontApiService.getProducts(
            widget.slug,
            destacado: true,
            sort: 'featured',
            limit: 8,
          ).timeout(const Duration(seconds: 12)),
          StorefrontApiService.getProducts(
            widget.slug,
            sort: 'offers',
            limit: 8,
          ).timeout(const Duration(seconds: 12)),
          StorefrontApiService.getProducts(
            widget.slug,
            page: 1,
            limit: 16,
            sort: 'featured',
          ).timeout(const Duration(seconds: 12)),
        ]);

        if (!mounted) return;

        final featuredProducts = _dedupeProducts(
          List<dynamic>.from(productResults[0]['items'] as List? ?? const []),
        );
        final offerProducts = _dedupeProducts(
          List<dynamic>.from(
            productResults[1]['items'] as List? ?? const [],
          ).where((item) {
            final map = Map<String, dynamic>.from(item as Map);
            return map['precio_oferta_web'] != null ||
                map['precioOferta'] != null;
          }).toList(),
        );
        final offerIds = offerProducts
            .map((item) => (item as Map)['id']?.toString() ?? '')
            .where((id) => id.isNotEmpty)
            .toSet();
        final featuredIds = featuredProducts
            .map((item) => (item as Map)['id']?.toString() ?? '')
            .where((id) => id.isNotEmpty)
            .toSet();
        final highlightedIds = {...offerIds, ...featuredIds};
        final productsResponse = productResults[2];
        final catalogProducts = _dedupeProducts(
          List<dynamic>.from(productsResponse['items'] as List? ?? const []),
        );
        final catalogOnlyProducts = catalogProducts.where((item) {
          final id = (item as Map)['id']?.toString() ?? '';
          return id.isEmpty || !highlightedIds.contains(id);
        }).toList();
        final categories = _buildDisplayCategories(List<dynamic>.from([]), [
          ...featuredProducts,
          ...offerProducts,
          ...catalogProducts,
        ]);

        setState(() {
          _categories = categories;
          _featuredProducts = featuredProducts.where((item) {
            final id = (item as Map)['id']?.toString() ?? '';
            return id.isEmpty || !offerIds.contains(id);
          }).toList();
          _offerProducts = offerProducts;
          _products = catalogOnlyProducts;
        });
        _perfLog('products loaded');
      } catch (e) {
        _perfLog('products failed: $e');
      }
    });

    _perfLog('_loadHomeDataInBackground finished - Home ya visible');
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

  List<dynamic> get _heroProducts {
    final catalog = _dedupeProducts([
      ..._offerProducts,
      ..._featuredProducts,
      ..._products,
    ]);

    final serviceKits = catalog
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .where(_isHeroServiceKit)
        .toList();

    if (serviceKits.isEmpty) {
      return _offerProducts.isNotEmpty
          ? _offerProducts
          : (_featuredProducts.isNotEmpty ? _featuredProducts : _products);
    }

    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final product in serviceKits) {
      final family = _heroFamily(product);
      grouped.putIfAbsent(family, () => []).add(product);
    }

    for (final family in grouped.keys) {
      grouped[family]!.sort(
        (a, b) => _heroPriorityScore(b).compareTo(_heroPriorityScore(a)),
      );
    }

    final selected = <Map<String, dynamic>>[];
    for (final family in const ['motor', 'camaras', 'punto_venta']) {
      final items = grouped[family];
      if (items != null && items.isNotEmpty) {
        selected.add(items.first);
      }
    }

    final remaining = serviceKits
      ..sort((a, b) => _heroPriorityScore(b).compareTo(_heroPriorityScore(a)));

    for (final product in remaining) {
      final id = product['id']?.toString() ?? '';
      final exists = selected.any((item) => item['id']?.toString() == id);
      if (!exists) {
        selected.add(product);
      }
      if (selected.length >= 4) break;
    }

    return selected;
  }

  List<Map<String, dynamic>> get _categoryShowcases {
    final allProducts = _dedupeProducts([
      ..._offerProducts,
      ..._featuredProducts,
      ..._products,
    ]).whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList();

    final grouped = <String, List<Map<String, dynamic>>>{};
    final displayNames = <String, String>{};

    for (final product in allProducts) {
      final rawCategory = product['categoria']?.toString().trim() ?? '';
      if (rawCategory.isEmpty) continue;

      final key = _normalizeCategoryKey(rawCategory);
      grouped.putIfAbsent(key, () => []).add(product);
      displayNames[key] = _displayCategoryName(rawCategory);
    }

    final orderedKeys = <String>[
      ..._categories
          .whereType<Map>()
          .map(
            (item) => _normalizeCategoryKey(item['nombre']?.toString() ?? ''),
          )
          .where((key) => key.isNotEmpty),
      ...grouped.keys,
    ];

    final seen = <String>{};
    final showcases = <Map<String, dynamic>>[];

    for (final key in orderedKeys) {
      if (!seen.add(key)) continue;
      final items = grouped[key];
      if (items == null || items.length < 2) continue;

      items.sort((a, b) {
        final scoreCompare = _productShelfScore(
          b,
        ).compareTo(_productShelfScore(a));
        if (scoreCompare != 0) return scoreCompare;
        return (a['titulo']?.toString() ?? '').compareTo(
          b['titulo']?.toString() ?? '',
        );
      });

      showcases.add({
        'name': displayNames[key] ?? 'Categoria',
        'products': items.take(10).toList(),
      });
    }

    return showcases.take(5).toList();
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

  /// Puntúa un producto para ordenamiento por relevancia en vitrinas.
  /// Prioriza: tiene precio > tiene oferta > tiene stock > tiene imagen > tiene descripción
  int _productShelfScore(Map<String, dynamic> product) {
    int score = 0;
    if (StorefrontHelpers.getDisplayPrice(product) != null) score += 100;
    if (product['precio_oferta_web'] != null ||
        product['precioOferta'] != null) {
      score += 50;
    }
    final stock = int.tryParse(product['stock']?.toString() ?? '0') ?? 0;
    if (stock > 0) score += 30;
    if (StorefrontHelpers.getPrimaryImage(product) != null) score += 20;
    if (StorefrontHelpers.getShortDescription(product).isNotEmpty) score += 10;
    return score;
  }

  void _openWhatsapp(String whatsapp) {
    final number = whatsapp.replaceAll(RegExp(r'[^\d]'), '');
    if (number.isEmpty) return;
    launchUrl(Uri.parse('https://wa.me/$number'));
  }

  @override
  Widget build(BuildContext context) {
    // ==========================================
    // Home visible INMEDIATAMENTE con fallbacks
    // No espera NADA: ni productos, ni banners, ni categorías, ni config
    // Los datos se cargan en segundo plano y actualizan la UI progresivamente
    // ==========================================
    final config = _config ?? _fallbackConfig;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final primaryColor = _getColor(
      config['color_principal']?.toString() ?? '#0F172A',
    );
    final secondaryColor = _getColor(
      config['color_secundario']?.toString() ?? '#2563EB',
    );
    final whatsapp = config['whatsapp_numero']?.toString() ?? '';
    final storeName = _normalizeStoreName(config['nombre_tienda']?.toString());
    final isTablet = screenWidth >= 700 && screenWidth < 1100;
    final isDesktop = screenWidth >= 1100;
    final contentPadding = math.max(14.0, ((screenWidth - 1240) / 2) + 16);
    return PublicStoreLayout(
      slug: widget.slug,
      storeName: storeName,
      logoUrl: config['logo_url'],
      primaryColor: primaryColor,
      secondaryColor: secondaryColor,
      heroTitle:
          config['mensaje_principal']?.toString().trim().isNotEmpty == true
          ? config['mensaje_principal'].toString().trim()
          : 'Tienda oficial FULLTECH SRL',
      heroSubtitle:
          config['mensaje_secundario']?.toString().trim().isNotEmpty == true
          ? config['mensaje_secundario'].toString().trim()
          : 'Explora ofertas, productos y soluciones para tu hogar, empresa y proyectos.',
      banners: _banners,
      promotedProducts: _heroProducts,
      onSearchTap: _openSearch,
      onCategoriesTap: _openCategories,
      onOffersTap: _openOffers,
      onAdminTap: () => Navigator.pushNamed(context, '/login?redirect=/admin'),
      onCartTap: () =>
          Navigator.pushNamed(context, '/tienda/${widget.slug}/carrito'),
      onWhatsappTap: () =>
          _openWhatsapp(whatsapp.isEmpty ? '18494314070' : whatsapp),
      slivers: [
        // ==========================================
        // CHIPS DE CONFIANZA (Garantía, Tienda física, Soporte, Instalación, etc.)
        // ==========================================
        SliverToBoxAdapter(
          child: StorefrontTrustChips(
            primaryColor: primaryColor,
            onLocationTap: () => Navigator.pushNamed(
              context,
              '/tienda/${widget.slug}/ubicacion',
            ),
          ),
        ),

        // ==========================================
        // OFERTAS DEL DÍA (scroll horizontal con tarjetas premium)
        // ==========================================
        if (_offerProducts.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                contentPadding,
                16,
                contentPadding,
                8,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFDC2626), Color(0xFFF97316)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFDC2626).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.local_fire_department_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Ofertas del día',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _openOffers,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: secondaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Ver todo',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: secondaryColor,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 10,
                            color: secondaryColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: isDesktop ? 340 : (isTablet ? 320 : 290),
              child: ListView.separated(
                padding: EdgeInsets.symmetric(horizontal: contentPadding),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  return _OfferProductCard(
                    product: Map<String, dynamic>.from(
                      _offerProducts[index] as Map,
                    ),
                    slug: widget.slug,
                    primaryColor: primaryColor,
                    secondaryColor: secondaryColor,
                    whatsapp: whatsapp,
                    width: isDesktop ? 240 : (isTablet ? 220 : 190),
                  );
                },
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemCount: _offerProducts.length,
              ),
            ),
          ),
        ],

        // ==========================================
        // CATEGORÍAS (scroll horizontal)
        // ==========================================
        if (_categories.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                contentPadding,
                18,
                contentPadding,
                4,
              ),
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
                physics: const BouncingScrollPhysics(),
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
        // PRODUCTOS POR CATEGORÍA (scroll horizontal)
        // Solo muestra productos que pertenecen a cada categoría
        // ==========================================
        if (_categoryShowcases.isNotEmpty) ...[
          for (final showcase in _categoryShowcases) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  contentPadding,
                  14,
                  contentPadding,
                  4,
                ),
                child: Row(
                  children: [
                    Text(
                      '${showcase['name']}',
                      style: TextStyle(
                        fontSize: isDesktop ? 18 : 15,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        final categoryName = showcase['name']?.toString() ?? '';
                        if (categoryName.isNotEmpty) {
                          Navigator.pushNamed(
                            context,
                            '/tienda/${widget.slug}/categoria/${Uri.encodeComponent(categoryName)}',
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: secondaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Ver todo',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: secondaryColor,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 9,
                              color: secondaryColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: isDesktop ? 336 : (isTablet ? 314 : 292),
                child: ListView.separated(
                  padding: EdgeInsets.fromLTRB(
                    contentPadding,
                    6,
                    contentPadding,
                    0,
                  ),
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount:
                      (showcase['products'] as List<dynamic>? ?? const [])
                          .length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final products =
                        showcase['products'] as List<dynamic>? ?? const [];
                    return SizedBox(
                      width: isDesktop ? 232 : (isTablet ? 214 : 184),
                      child: StorefrontProductCard(
                        product: Map<String, dynamic>.from(
                          products[index] as Map,
                        ),
                        slug: widget.slug,
                        primaryColor: primaryColor,
                        secondaryColor: secondaryColor,
                        whatsapp: whatsapp,
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ],

        // ==========================================
        // FOOTER
        // ==========================================
        SliverToBoxAdapter(
          child: StorefrontFooter(
            slug: widget.slug,
            primaryColor: primaryColor,
          ),
        ),
      ],
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
      final image = _resolveCategoryImage(
        category['imagen'],
        displayName,
        products,
      );

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
        final countCompare = (b['cantidad'] as int? ?? 0).compareTo(
          a['cantidad'] as int? ?? 0,
        );
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
      'camaras de seguridad' => 'Cámaras de Seguridad',
      'camaras seguridad' => 'Cámaras de Seguridad',
      'dvr' => 'DVR',
      'nvr' => 'NVR',
      'accesorios' => 'Accesorios',
      'alarmas' => 'Alarmas',
      'alarma' => 'Alarmas',
      'motores' => 'Motores',
      'motor' => 'Motores',
      'motor de porton' => 'Motores para Portones',
      'motores para portones' => 'Motores para Portones',
      'computadoras' => 'Computadoras',
      'computadora' => 'Computadoras',
      'laptops' => 'Laptops',
      'laptop' => 'Laptops',
      'software' => 'Software',
      'sistemas de seguridad' => 'Sistemas de Seguridad',
      'sistema de seguridad' => 'Sistemas de Seguridad',
      'seguridad' => 'Seguridad',
      'electronica' => 'Electrónica',
      'electronico' => 'Electrónica',
      'redes' => 'Redes',
      'red' => 'Redes',
      'cables' => 'Cables y Conexiones',
      'cable' => 'Cables y Conexiones',
      'instalacion' => 'Instalación',
      'instalaciones' => 'Instalación',
      'servicios' => 'Servicios',
      'servicio' => 'Servicios',
      'soporte tecnico' => 'Soporte Técnico',
      'soporte' => 'Soporte Técnico',
      'punto de venta' => 'Punto de Venta',
      'pos' => 'Punto de Venta',
      'facturacion' => 'Facturación',
      'variedades' => 'Variedades',
      'variedad' => 'Variedades',
      'productos varios' => 'Productos Varios',
      'varios' => 'Productos Varios',
      'hogar' => 'Hogar',
      'empresa' => 'Empresa',
      'oficina' => 'Oficina',
      'kit' => 'Kits',
      'kits' => 'Kits',
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

  bool _isHeroServiceKit(Map<String, dynamic> product) {
    final text = _heroSearchText(product);
    final hasImage =
        (StorefrontHelpers.getPrimaryImage(product)?.trim().isNotEmpty ??
        false);
    if (!hasImage) return false;

    final isKitService =
        text.contains('kit servicio') ||
        text.contains('kit de servicio') ||
        text.contains('servicio completo');

    final isMotor =
        text.contains('motor de porton') ||
        text.contains('motor para porton') ||
        text.contains('motores de porton') ||
        text.contains('motor corredizo') ||
        text.contains('motor abatible');
    final motorWithInstallation =
        isMotor && (text.contains('instalacion') || text.contains('incluye'));

    final isCameraSystem =
        (text.contains('sistema de 4 camaras') ||
            text.contains('sistema 4 camaras') ||
            text.contains('kit 4 camaras') ||
            text.contains('sistema de 8 camaras') ||
            text.contains('sistema 8 camaras') ||
            text.contains('kit 8 camaras') ||
            text.contains('sistema de camaras') ||
            text.contains('camaras con instalacion')) &&
        (text.contains('instalacion') ||
            text.contains('incluye') ||
            text.contains('completo'));

    final isPosSystem =
        (text.contains('punto de venta') ||
            text.contains('pos') ||
            text.contains('facturacion')) &&
        (text.contains('incluye') ||
            text.contains('sistema completo') ||
            text.contains('completo'));

    return isKitService ||
        motorWithInstallation ||
        isCameraSystem ||
        isPosSystem;
  }

  String _heroFamily(Map<String, dynamic> product) {
    final text = _heroSearchText(product);
    if (text.contains('motor')) return 'motor';
    if (text.contains('camara')) return 'camaras';
    if (text.contains('punto de venta') ||
        text.contains('pos') ||
        text.contains('facturacion')) {
      return 'punto_venta';
    }
    return 'otros';
  }

  int _heroPriorityScore(Map<String, dynamic> product) {
    final text = _heroSearchText(product);
    var score = 0;

    if (text.contains('kit servicio') || text.contains('kit de servicio')) {
      score += 120;
    }
    if (text.contains('motor')) score += 90;
    if (text.contains('sistema de camaras') ||
        text.contains('sistema 4 camaras') ||
        text.contains('sistema 8 camaras') ||
        text.contains('kit 4 camaras') ||
        text.contains('kit 8 camaras')) {
      score += 85;
    }
    if (text.contains('punto de venta') || text.contains('pos')) {
      score += 80;
    }
    if (text.contains('instalacion')) score += 30;
    if (text.contains('incluye')) score += 20;
    if (text.contains('completo')) score += 15;
    if (product['requiere_instalacion'] == true ||
        product['instalacion_incluida'] == true) {
      score += 20;
    }
    if ((product['precio_oferta_web'] ?? product['precioOferta']) != null) {
      score += 8;
    }
    return score;
  }

  String _heroSearchText(Map<String, dynamic> product) {
    final raw = [
      product['titulo'],
      product['categoria'],
      product['subcategoria'],
      product['descripcion'],
      product['descripcion_web'],
      product['informacion'],
      product['incluye'],
      product['palabrasClave'],
    ].where((value) => value != null).join(' ');

    return _normalizeCategoryKey(raw);
  }

  String _normalizeStoreName(String? raw) {
    final value = raw?.trim() ?? '';
    if (value.isEmpty) return 'FULLTECH';

    final normalized = value.toLowerCase();
    if (normalized.contains('fulltech')) {
      return 'FULLTECH';
    }

    return value;
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
                  gradient: LinearGradient(
                    colors: [
                      secondaryColor.withValues(alpha: 0.16),
                      const Color(0xFFF1F5F9),
                      Colors.white,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Positioned(
                      right: -18,
                      top: -10,
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.42),
                        ),
                      ),
                    ),
                    StorefrontSmartImage(
                      source: category['imagen'],
                      fit: BoxFit.cover,
                      borderRadius: BorderRadius.circular(16),
                      placeholder: Center(
                        child: Icon(
                          Icons.category_outlined,
                          color: secondaryColor,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
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
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// OFFER PRODUCT CARD (Tarjeta premium para Ofertas del día)
// ==========================================
class _OfferProductCard extends StatefulWidget {
  final Map<String, dynamic> product;
  final String slug;
  final Color primaryColor;
  final Color secondaryColor;
  final String? whatsapp;
  final double width;

  const _OfferProductCard({
    required this.product,
    required this.slug,
    required this.primaryColor,
    required this.secondaryColor,
    required this.whatsapp,
    required this.width,
  });

  @override
  State<_OfferProductCard> createState() => _OfferProductCardState();
}

class _OfferProductCardState extends State<_OfferProductCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.product['titulo']?.toString().trim() ?? '';
    final description = StorefrontHelpers.getShortDescription(widget.product);
    final price = StorefrontHelpers.getDisplayPrice(widget.product);
    final originalPrice = StorefrontHelpers.getOriginalPrice(widget.product);
    final gallery = StorefrontHelpers.getGallery(widget.product);
    final productId = widget.product['id']?.toString() ?? '';
    final stock = int.tryParse(widget.product['stock']?.toString() ?? '0') ?? 0;
    final hasStock = stock > 0;
    final hasPrice = price != null && price > 0;
    final discount = originalPrice != null && hasPrice
        ? ((originalPrice - price) / originalPrice * 100).round()
        : 0;

    return GestureDetector(
      onTap: () {
        if (productId.isNotEmpty) {
          Navigator.pushNamed(
            context,
            '/tienda/${widget.slug}/producto/$productId',
          );
        }
      },
      child: Container(
        width: widget.width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFDC2626).withValues(alpha: 0.15),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFDC2626).withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // === IMAGE SECTION ===
            Expanded(
              flex: 58,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFFFF1F0), Color(0xFFFEF2F2)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: StorefrontSmartImage(
                        source: gallery.isNotEmpty ? gallery.first : null,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  // Badge "Disponible"
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: hasStock
                            ? const Color(0xFF16A34A)
                            : const Color(0xFFDC2626),
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF16A34A,
                            ).withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        hasStock ? 'Disponible' : 'Agotado',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                  // Badge de descuento con animación
                  if (discount > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseAnimation.value,
                            child: child,
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFDC2626), Color(0xFFF97316)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFFDC2626,
                                ).withValues(alpha: 0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.local_fire_department_rounded,
                                size: 11,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '-$discount%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  height: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  // Botón de acción
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: Material(
                      color: widget.primaryColor,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: () => _addToCart(context),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 34,
                          height: 34,
                          alignment: Alignment.center,
                          child: Icon(
                            hasPrice
                                ? Icons.add_shopping_cart_rounded
                                : Icons.chat_bubble_outline_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // === INFO SECTION ===
            Expanded(
              flex: 42,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nombre del producto
                    Text(
                      title.isEmpty ? 'Producto sin nombre' : title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Descripción
                    Text(
                      description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                        height: 1.2,
                      ),
                    ),
                    const Spacer(),
                    // Precios
                    if (originalPrice != null && hasPrice)
                      Text(
                        'RD\$${originalPrice.toStringAsFixed(0)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF94A3B8),
                          decoration: TextDecoration.lineThrough,
                          fontWeight: FontWeight.w500,
                          height: 1.2,
                        ),
                      ),
                    if (hasPrice)
                      Text(
                        'RD\$${price.toStringAsFixed(0)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: widget.primaryColor,
                          height: 1.2,
                          letterSpacing: -0.3,
                        ),
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
    final hasPrice = StorefrontHelpers.getDisplayPrice(widget.product) != null;
    if (!hasPrice) {
      final phone = widget.whatsapp?.replaceAll(RegExp(r'[^\d]'), '') ?? '';
      if (phone.isNotEmpty) {
        final title = widget.product['titulo']?.toString() ?? 'Producto';
        final url =
            'https://wa.me/$phone?text=${Uri.encodeComponent('Hola FULLTECH, quiero cotizar: $title')}';
        await launchUrl(Uri.parse(url));
      }
      return;
    }

    try {
      final sessionId = await StorefrontHelpers.ensureSessionId(widget.slug);
      final image = StorefrontHelpers.getPrimaryImage(widget.product);
      final price = StorefrontHelpers.getDisplayPrice(widget.product) ?? 0;
      final title = widget.product['titulo']?.toString() ?? 'Producto';
      final productId = widget.product['id']?.toString() ?? '';

      await StorefrontApiService.addCartItem(
        widget.slug,
        sessionId,
        productoId: productId,
        nombreProducto: title,
        cantidad: 1,
        precioUnitario: price.toDouble(),
        imagenUrl: image,
      );

      if (!context.mounted) return;
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
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al agregar al carrito'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  List<Map<String, dynamic>> _filteredProducts = [];
  bool _showResults = false;

  @override
  void initState() {
    super.initState();
    _filteredProducts = widget.initialProducts;
    _searchFocus.requestFocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    final trimmed = query.trim().toLowerCase();
    setState(() {
      _showResults = trimmed.isNotEmpty;
      if (trimmed.isEmpty) {
        _filteredProducts = widget.initialProducts;
      } else {
        _filteredProducts = widget.initialProducts.where((product) {
          final title = (product['titulo']?.toString() ?? '').toLowerCase();
          final desc = (product['descripcion']?.toString() ?? '').toLowerCase();
          final category = (product['categoria']?.toString() ?? '')
              .toLowerCase();
          return title.contains(trimmed) ||
              desc.contains(trimmed) ||
              category.contains(trimmed);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.viewPaddingOf(context).bottom;
    final screenHeight = MediaQuery.sizeOf(context).height;

    return Container(
      height: screenHeight * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFD1D5DB),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocus,
              onChanged: _onSearchChanged,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Buscar productos...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: widget.primaryColor.withValues(alpha: 0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFE5EAF1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: widget.primaryColor,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
          // Results count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  _showResults
                      ? '${_filteredProducts.length} resultados'
                      : '${widget.initialProducts.length} productos',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Results list
          Expanded(
            child: _filteredProducts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 48,
                          color: const Color(0xFF94A3B8),
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
                    padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPadding + 16),
                    itemCount: _filteredProducts.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final product = _filteredProducts[index];
                      final title = product['titulo']?.toString() ?? '';
                      final price = StorefrontHelpers.getDisplayPrice(product);
                      final image = StorefrontHelpers.getPrimaryImage(product);
                      final productId = product['id']?.toString() ?? '';

                      return Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(
                              context,
                              '/tienda/${widget.slug}/producto/$productId',
                            );
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: SizedBox(
                                    width: 64,
                                    height: 64,
                                    child: StorefrontSmartImage(
                                      source: image,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title.isEmpty
                                            ? 'Producto sin nombre'
                                            : title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      if (price != null && price > 0)
                                        Text(
                                          'RD\$${price.toStringAsFixed(0)}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w900,
                                            color: widget.primaryColor,
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
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
