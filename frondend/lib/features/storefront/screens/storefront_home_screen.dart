import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/storefront_api_service.dart';
import '../widgets/storefront_banner_slider.dart';
import '../widgets/storefront_product_card.dart';
import '../widgets/storefront_category_chip.dart';
import '../widgets/storefront_footer.dart';
import '../widgets/storefront_skeleton.dart';
import '../widgets/storefront_error_state.dart';

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
  List<dynamic> _recentProducts = [];
  List<dynamic> _offerProducts = [];
  List<dynamic> _bestSellers = [];
  bool _loading = true;
  String? _error;
  final _searchController = TextEditingController();

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
        StorefrontApiService.getBanners(widget.slug),
        StorefrontApiService.getCategories(widget.slug),
        StorefrontApiService.getProducts(widget.slug, destacado: true, limit: 10),
        StorefrontApiService.getProducts(widget.slug, limit: 10),
        StorefrontApiService.getProducts(widget.slug, limit: 10, busqueda: 'oferta'),
        StorefrontApiService.getProducts(widget.slug, limit: 10, busqueda: 'mas vendido'),
      ]);

      final configRes = results[0];
      if (configRes['ok'] != true) {
        setState(() {
          _error = configRes['message'] ?? 'Error al cargar tienda';
          _loading = false;
        });
        return;
      }

      setState(() {
        _config = configRes['data'];
        _banners = results[1]['data'] ?? [];
        _categories = results[2]['data'] ?? [];
        _featuredProducts = results[3]['products'] ?? [];
        _recentProducts = results[4]['products'] ?? [];
        _offerProducts = results[5]['products'] ?? [];
        _bestSellers = results[6]['products'] ?? [];
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error de conexión: $e';
        _loading = false;
      });
    }
  }

  void _search(String query) {
    if (query.trim().isEmpty) return;
    Navigator.pushNamed(
      context,
      '/tienda/${widget.slug}/busqueda',
      arguments: {'busqueda': query.trim()},
    );
  }

  Color _getColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const StorefrontHomeSkeleton();
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(title: const Text('Tienda')),
        body: StorefrontErrorState(
          message: _error!,
          onRetry: _loadData,
        ),
      );
    }

    final config = _config!;
    final primaryColor = _getColor(config['color_principal'] ?? '#0F172A');
    final secondaryColor = _getColor(config['color_secundario'] ?? '#2563EB');
    final whatsapp = config['whatsapp_numero'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          // ==========================================
          // HEADER PREMIUM MEJORADO
          // ==========================================
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            stretch: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryColor,
                      primaryColor.withValues(alpha: 0.92),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 12,
                  left: 16,
                  right: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (config['logo_url'] != null)
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: Colors.white.withValues(alpha: 0.15),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                config['logo_url'],
                                height: 38,
                                width: 38,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.store_rounded, color: Colors.white, size: 22,
                                ),
                              ),
                            ),
                          ),
                        if (config['logo_url'] != null) const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            config['nombre_tienda'] ?? 'FULLTECH',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                        // Botón carrito
                        Material(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            onTap: () => Navigator.pushNamed(
                              context,
                              '/tienda/${widget.slug}/carrito',
                            ),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: 40,
                              height: 40,
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.shopping_cart_outlined,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (config['mensaje_principal'] != null)
                      Text(
                        config['mensaje_principal'],
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ),
          ),

          // ==========================================
          // BUSCADOR
          // ==========================================
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar productos...',
                  prefixIcon: Icon(Icons.search_rounded, color: const Color(0xFF9CA3AF)),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: const Color(0xFFE5E7EB).withValues(alpha: 0.5),
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
                onSubmitted: _search,
                onChanged: (_) => setState(() {}),
              ),
            ),
          ),

          // ==========================================
          // BANNER SLIDER
          // ==========================================
          if (_banners.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: StorefrontBannerSlider(
                  banners: _banners,
                  primaryColor: primaryColor,
                  secondaryColor: secondaryColor,
                ),
              ),
            ),

          // ==========================================
          // CATEGORÍAS RÁPIDAS
          // ==========================================
          if (_categories.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Categorías',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: primaryColor,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.arrow_forward_ios, size: 14),
                          label: const Text('Ver todo', style: TextStyle(fontSize: 13)),
                          style: TextButton.styleFrom(
                            foregroundColor: secondaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 90,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final cat = _categories[index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: StorefrontCategoryIcon(
                              categoria: cat['categoria'] ?? '',
                              primaryColor: primaryColor,
                              secondaryColor: secondaryColor,
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  '/tienda/${widget.slug}/categoria/${Uri.encodeComponent(cat['categoria'])}',
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    // Chips de categorías
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 44,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final cat = _categories[index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: StorefrontCategoryChip(
                              categoria: cat['categoria'] ?? '',
                              total: cat['total'] ?? 0,
                              primaryColor: primaryColor,
                              secondaryColor: secondaryColor,
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  '/tienda/${widget.slug}/categoria/${Uri.encodeComponent(cat['categoria'])}',
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ==========================================
          // OFERTAS DEL DÍA
          // ==========================================
          if (_offerProducts.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFEF4444), Color(0xFFF87171)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.local_fire_department_rounded, size: 16, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'OFERTAS DEL DÍA',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.arrow_forward_ios, size: 14),
                      label: const Text('Ver todo', style: TextStyle(fontSize: 13)),
                      style: TextButton.styleFrom(foregroundColor: secondaryColor),
                    ),
                  ],
                ),
              ),
            ),
          if (_offerProducts.isNotEmpty)
            SliverToBoxAdapter(
              child: SizedBox(
                height: 340,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _offerProducts.length,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: StorefrontProductCard(
                      product: _offerProducts[index],
                      slug: widget.slug,
                      primaryColor: primaryColor,
                      secondaryColor: secondaryColor,
                      whatsapp: whatsapp,
                    ),
                  ),
                ),
              ),
            ),

          // ==========================================
          // PRODUCTOS DESTACADOS
          // ==========================================
          if (_featuredProducts.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '⭐ Destacados',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: primaryColor,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.arrow_forward_ios, size: 14),
                      label: const Text('Ver todo', style: TextStyle(fontSize: 13)),
                      style: TextButton.styleFrom(foregroundColor: secondaryColor),
                    ),
                  ],
                ),
              ),
            ),
          if (_featuredProducts.isNotEmpty)
            SliverToBoxAdapter(
              child: SizedBox(
                height: 340,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _featuredProducts.length,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: StorefrontProductCard(
                      product: _featuredProducts[index],
                      slug: widget.slug,
                      primaryColor: primaryColor,
                      secondaryColor: secondaryColor,
                      whatsapp: whatsapp,
                    ),
                  ),
                ),
              ),
            ),

          // ==========================================
          // MÁS VENDIDOS
          // ==========================================
          if (_bestSellers.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '🔥 Más vendidos',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: primaryColor,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.arrow_forward_ios, size: 14),
                      label: const Text('Ver todo', style: TextStyle(fontSize: 13)),
                      style: TextButton.styleFrom(foregroundColor: secondaryColor),
                    ),
                  ],
                ),
              ),
            ),
          if (_bestSellers.isNotEmpty)
            SliverToBoxAdapter(
              child: SizedBox(
                height: 340,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _bestSellers.length,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: StorefrontProductCard(
                      product: _bestSellers[index],
                      slug: widget.slug,
                      primaryColor: primaryColor,
                      secondaryColor: secondaryColor,
                      whatsapp: whatsapp,
                    ),
                  ),
                ),
              ),
            ),

          // ==========================================
          // PRODUCTOS RECIENTES (GRID)
          // ==========================================
          if (_recentProducts.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '🆕 Productos',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: primaryColor,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.arrow_forward_ios, size: 14),
                      label: const Text('Ver todo', style: TextStyle(fontSize: 13)),
                      style: TextButton.styleFrom(foregroundColor: secondaryColor),
                    ),
                  ],
                ),
              ),
            ),
          if (_recentProducts.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.65,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => StorefrontProductCard(
                    product: _recentProducts[index],
                    slug: widget.slug,
                    primaryColor: primaryColor,
                    secondaryColor: secondaryColor,
                    compact: true,
                    whatsapp: whatsapp,
                  ),
                  childCount: _recentProducts.length,
                ),
              ),
            ),

          // ==========================================
          // INSTALACIÓN INCLUIDA (BANNER PROMOCIONAL)
          // ==========================================
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [secondaryColor, secondaryColor.withValues(alpha: 0.85)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '🔧 Instalación incluida',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'En cámaras, motores y kits de seguridad.\nProfesionales certificados.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: secondaryColor,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'Ver kits',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.build_circle_outlined,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ==========================================
          // FOOTER ELEGANTE
          // ==========================================
          SliverToBoxAdapter(
            child: StorefrontFooter(
              config: config,
              primaryColor: primaryColor,
              secondaryColor: secondaryColor,
            ),
          ),
        ],
      ),

      // WhatsApp flotante
      floatingActionButton: whatsapp.isNotEmpty
          ? FloatingActionButton(
              onPressed: () {
                final num = whatsapp.replaceAll(RegExp(r'[^\d]'), '');
                launchUrl(Uri.parse('https://wa.me/$num'));
              },
              backgroundColor: const Color(0xFF25D366),
              child: const Icon(Icons.chat_rounded, color: Colors.white),
            )
          : null,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
