import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/storefront_api_service.dart';

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
  bool _loading = true;
  String? _error;
  final _searchController = TextEditingController();
  String _sessionId = '';

  @override
  void initState() {
    super.initState();
    _initSession();
    _loadData();
  }

  Future<void> _initSession() async {
    final prefs = await SharedPreferences.getInstance();
    String? sid = prefs.getString('storefront_session_${widget.slug}');
    if (sid == null) {
      sid = '${widget.slug}_${DateTime.now().millisecondsSinceEpoch}';
      await prefs.setString('storefront_session_${widget.slug}', sid);
    }
    _sessionId = sid;
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final configRes = await StorefrontApiService.getConfig(widget.slug);
      if (configRes['ok'] != true) {
        setState(() {
          _error = configRes['message'] ?? 'Error al cargar tienda';
          _loading = false;
        });
        return;
      }

      final bannersRes = await StorefrontApiService.getBanners(widget.slug);
      final categoriesRes = await StorefrontApiService.getCategories(widget.slug);
      final featuredRes = await StorefrontApiService.getProducts(
        widget.slug,
        destacado: true,
        limit: 8,
      );
      final recentRes = await StorefrontApiService.getProducts(
        widget.slug,
        limit: 8,
      );

      setState(() {
        _config = configRes['data'];
        _banners = bannersRes['data'] ?? [];
        _categories = categoriesRes['data'] ?? [];
        _featuredProducts = featuredRes['products'] ?? [];
        _recentProducts = recentRes['products'] ?? [];
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
      return Scaffold(
        backgroundColor: const Color(0xFFF6F7F9),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(strokeWidth: 3),
              const SizedBox(height: 16),
              Text('Cargando tienda...', style: TextStyle(color: Colors.grey.shade500)),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF6F7F9),
        appBar: AppBar(title: const Text('Tienda')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.store_mall_directory_outlined, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text(_error!, textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _loadData,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final config = _config!;
    final primaryColor = _getColor(config['color_principal'] ?? '#0F172A');
    final secondaryColor = _getColor(config['color_secundario'] ?? '#2563EB');
    final whatsapp = config['whatsapp_numero'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryColor, primaryColor.withValues(alpha: 0.85)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 16, left: 20, right: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (config['logo_url'] != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(config['logo_url'], height: 36, width: 36, fit: BoxFit.cover),
                          ),
                        if (config['logo_url'] != null) const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            config['nombre_tienda'] ?? 'Tienda',
                            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
                          onPressed: () => Navigator.pushNamed(context, '/tienda/${widget.slug}/carrito'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),

          // Buscador
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar productos...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
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
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
                onSubmitted: _search,
                onChanged: (_) => setState(() {}),
              ),
            ),
          ),

          // Mensaje principal
          if (config['mensaje_principal'] != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Text(
                  config['mensaje_principal'],
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: primaryColor),
                ),
              ),
            ),

          if (config['mensaje_secundario'] != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                child: Text(
                  config['mensaje_secundario'],
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ),
            ),

          // Banners
          if (_banners.isNotEmpty)
            SliverToBoxAdapter(
              child: SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: _banners.length,
                  itemBuilder: (context, index) {
                    final banner = _banners[index];
                    return Container(
                      width: MediaQuery.of(context).size.width - 64,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: secondaryColor.withValues(alpha: 0.1),
                        image: banner['imagen_url'] != null
                            ? DecorationImage(
                                image: NetworkImage(banner['imagen_url']),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            colors: [Colors.black.withValues(alpha: 0.3), Colors.transparent],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(banner['titulo'] ?? '',
                              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                            if (banner['subtitulo'] != null)
                              Text(banner['subtitulo'],
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14)),
                            if (banner['boton_texto'] != null) ...[
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: () {
                                  if (banner['link_url'] != null) {
                                    launchUrl(Uri.parse(banner['link_url']));
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: primaryColor,
                                ),
                                child: Text(banner['boton_texto']),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

          // Categorías
          if (_categories.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Categorías', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: primaryColor)),
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
                            child: ActionChip(
                              label: Text('${cat['categoria']} (${cat['total']})'),
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  '/tienda/${widget.slug}/categoria/${Uri.encodeComponent(cat['categoria'])}',
                                );
                              },
                              backgroundColor: secondaryColor.withValues(alpha: 0.1),
                              side: BorderSide(color: secondaryColor.withValues(alpha: 0.3)),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Productos destacados
          if (_featuredProducts.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text('Destacados',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: primaryColor)),
              ),
            ),
          if (_featuredProducts.isNotEmpty)
            SliverToBoxAdapter(
              child: SizedBox(
                height: 280,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _featuredProducts.length,
                  itemBuilder: (context, index) => _ProductCard(
                    product: _featuredProducts[index],
                    slug: widget.slug,
                    primaryColor: primaryColor,
                    secondaryColor: secondaryColor,
                  ),
                ),
              ),
            ),

          // Productos recientes
          if (_recentProducts.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text('Productos',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: primaryColor)),
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
                  (context, index) => _ProductCard(
                    product: _recentProducts[index],
                    slug: widget.slug,
                    primaryColor: primaryColor,
                    secondaryColor: secondaryColor,
                    compact: true,
                  ),
                  childCount: _recentProducts.length,
                ),
              ),
            ),

          // Footer
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  if (config['direccion'] != null)
                    Text(config['direccion'], textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                  if (config['horario'] != null)
                    Text(config['horario'], textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                  const SizedBox(height: 16),
                  Text('© ${DateTime.now().year} ${config['nombre_tienda'] ?? ''}',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                ],
              ),
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
              child: const Icon(Icons.chat, color: Colors.white),
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

class _ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final String slug;
  final Color primaryColor;
  final Color secondaryColor;
  final bool compact;

  const _ProductCard({
    required this.product,
    required this.slug,
    required this.primaryColor,
    required this.secondaryColor,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final precio = product['precio_oferta_web'] ?? product['precio_oferta'] ?? product['precio'] ?? 0;
    final precioOriginal = (product['precio_oferta_web'] != null || product['precio_oferta'] != null)
        ? (product['precio'] ?? 0)
        : null;
    final imagen = product['imagen_destacada_url'] ?? product['imagen1'] ?? '';
    final etiqueta = product['etiqueta'] ?? '';
    final tieneOferta = precioOriginal != null && precioOriginal > precio;

    final card = Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagen
          Expanded(
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  color: Colors.grey.shade100,
                  child: imagen.isNotEmpty
                      ? Image.network(imagen, fit: BoxFit.cover, width: double.infinity,
                          errorBuilder: (_, __, ___) => _placeholderIcon())
                      : _placeholderIcon(),
                ),
                // Etiqueta
                if (etiqueta.isNotEmpty)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: secondaryColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(etiqueta, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                  ),
                // Oferta
                if (tieneOferta)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('-${((1 - precio / precioOriginal) * 100).round()}%',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
          ),
          // Info
          Padding(
            padding: const EdgeInsets.all(compact ? 10 : 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product['titulo'] ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: compact ? 13 : 14, fontWeight: FontWeight.w600, height: 1.2)),
                const SizedBox(height: 4),
                if (tieneOferta)
                  Text('\$$precioOriginal',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 12, decoration: TextDecoration.lineThrough)),
                Row(
                  children: [
                    Text('\$$precio',
                      style: TextStyle(
                        fontSize: compact ? 16 : 18,
                        fontWeight: FontWeight.w800,
                        color: primaryColor,
                      )),
                    if (product['requiere_instalacion'] == true)
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Text('+inst', style: TextStyle(color: Colors.grey.shade500, fontSize: 10)),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/tienda/$slug/producto/${product['id']}'),
      child: compact ? SizedBox(child: card) : SizedBox(width: 200, child: card),
    );
  }

  Widget _placeholderIcon() => Center(
    child: Icon(Icons.image_outlined, size: 48, color: Colors.grey.shade300),
  );
}
