import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/storefront_api_service.dart';
import '../widgets/storefront_banner_slider.dart';
import '../widgets/storefront_error_state.dart';
import '../widgets/storefront_footer.dart';
import '../widgets/storefront_product_card.dart';
import '../widgets/storefront_skeleton.dart';

class StorefrontHomeScreen extends StatefulWidget {
  final String slug;

  const StorefrontHomeScreen({super.key, required this.slug});

  @override
  State<StorefrontHomeScreen> createState() => _StorefrontHomeScreenState();
}

class _StorefrontHomeScreenState extends State<StorefrontHomeScreen> {
  final TextEditingController _searchController = TextEditingController();

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
      setState(() {
        _config = Map<String, dynamic>.from(configResponse['data'] as Map);
        _banners = List<dynamic>.from(results[1]['data'] as List? ?? const []);
        _categories = List<dynamic>.from(
          results[2]['data'] as List? ?? const [],
        );
        _featuredProducts = List<dynamic>.from(
          results[3]['items'] as List? ?? const [],
        );
        _offerProducts =
            List<dynamic>.from(results[4]['items'] as List? ?? const []).where((
              item,
            ) {
              final map = Map<String, dynamic>.from(item as Map);
              return map['precio_oferta_web'] != null ||
                  map['precioOferta'] != null;
            }).toList();
        _products = List<dynamic>.from(
          productsResponse['items'] as List? ?? const [],
        );
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

  void _search() {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    Navigator.pushNamed(
      context,
      '/tienda/${widget.slug}/busqueda',
      arguments: {'busqueda': query},
    );
  }

  Color _getColor(String hex) {
    var normalized = hex.replaceAll('#', '');
    if (normalized.length == 6) normalized = 'FF$normalized';
    return Color(int.parse(normalized, radix: 16));
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

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 150,
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
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
              background: Container(
                padding: EdgeInsets.fromLTRB(
                  18,
                  MediaQuery.of(context).padding.top + 18,
                  18,
                  18,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryColor, secondaryColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Spacer(),
                    Text(
                      config['nombre_tienda']?.toString() ?? 'FULLTECH',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      config['mensaje_principal']?.toString() ??
                          'Tecnología, seguridad e instalación profesional.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
              child: TextField(
                controller: _searchController,
                onSubmitted: (_) => _search(),
                decoration: InputDecoration(
                  hintText: 'Busca cámaras, motores, accesorios y más',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: IconButton(
                    onPressed: _search,
                    icon: const Icon(Icons.arrow_forward_rounded),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _TrustStrip(secondaryColor: secondaryColor),
            ),
          ),
          if (_banners.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 14),
                child: StorefrontBannerSlider(
                  banners: _banners,
                  primaryColor: primaryColor,
                  secondaryColor: secondaryColor,
                ),
              ),
            )
          else
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: _FallbackPromoCard(
                  primaryColor: primaryColor,
                  secondaryColor: secondaryColor,
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: _SectionHeader(
              title: 'Categorías rápidas',
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
              height: 112,
              child: _categories.isEmpty
                  ? const _InlineEmptyState(
                      title: 'No hay categorías visibles todavía.',
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
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemCount: _categories.length,
                    ),
            ),
          ),
          SliverToBoxAdapter(
            child: _SectionHeader(
              title: 'Ofertas del día',
              actionLabel: _offerProducts.isEmpty ? null : 'Ver productos',
              onTap: _offerProducts.isEmpty ? null : _search,
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 330,
              child: _offerProducts.isEmpty
                  ? const _InlineEmptyState(
                      title:
                          'Las ofertas aparecerán aquí cuando existan precios especiales.',
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
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemCount: _offerProducts.length,
                    ),
            ),
          ),
          SliverToBoxAdapter(
            child: _SectionHeader(
              title: 'Destacados',
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
              height: 330,
              child: _featuredProducts.isEmpty
                  ? const _InlineEmptyState(
                      title: 'Los productos destacados aparecerán aquí.',
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
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemCount: _featuredProducts.length,
                    ),
            ),
          ),
          SliverToBoxAdapter(
            child: _SectionHeader(
              title: 'Todos los productos',
              actionLabel: null,
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
                  childAspectRatio: 0.62,
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
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: _page < _totalPages
                  ? FilledButton(
                      onPressed: _loadingMore ? null : _loadMore,
                      style: FilledButton.styleFrom(
                        backgroundColor: primaryColor,
                        minimumSize: const Size(double.infinity, 52),
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
      ),
      floatingActionButton: whatsapp.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () {
                final number = whatsapp.replaceAll(RegExp(r'[^\d]'), '');
                launchUrl(Uri.parse('https://wa.me/$number'));
              },
              backgroundColor: const Color(0xFF25D366),
              icon: const Icon(Icons.chat_rounded, color: Colors.white),
              label: const Text('WhatsApp'),
            ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onTap;

  const _SectionHeader({required this.title, this.actionLabel, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
          ),
          if (actionLabel != null)
            TextButton(onPressed: onTap, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}

class _TrustStrip extends StatelessWidget {
  final Color secondaryColor;

  const _TrustStrip({required this.secondaryColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _TrustItem(
            icon: Icons.verified_outlined,
            label: 'Garantía',
            color: secondaryColor,
          ),
          _TrustItem(
            icon: Icons.store_mall_directory_outlined,
            label: 'Tienda física',
            color: secondaryColor,
          ),
          _TrustItem(
            icon: Icons.support_agent_outlined,
            label: 'Soporte',
            color: secondaryColor,
          ),
          _TrustItem(
            icon: Icons.build_circle_outlined,
            label: 'Instalación',
            color: secondaryColor,
          ),
        ],
      ),
    );
  }
}

class _TrustItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _TrustItem({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        ),
      ],
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
    final image = category['imagen']?.toString();
    final count = category['cantidad']?.toString() ?? '0';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 104,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F7FB),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: image != null && image.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.network(
                          image,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.category_outlined,
                            color: secondaryColor,
                          ),
                        ),
                      )
                    : Icon(Icons.category_outlined, color: secondaryColor),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            Text(
              '$count productos',
              style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280)),
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
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tecnología lista para instalar',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Compra cámaras, motores, accesorios y kits con soporte de FULLTECH.',
            style: TextStyle(color: Colors.white, height: 1.4),
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
      height: 120,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFF6B7280),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
