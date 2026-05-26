import 'package:flutter/material.dart';
import '../services/storefront_api_service.dart';

class StorefrontCategoryScreen extends StatefulWidget {
  final String slug;
  final String? categoria;
  final String? busqueda;

  const StorefrontCategoryScreen({
    super.key,
    required this.slug,
    this.categoria,
    this.busqueda,
  });

  @override
  State<StorefrontCategoryScreen> createState() => _StorefrontCategoryScreenState();
}

class _StorefrontCategoryScreenState extends State<StorefrontCategoryScreen> {
  List<dynamic> _products = [];
  Map<String, dynamic>? _config;
  bool _loading = true;
  int _page = 1;
  bool _hasMore = true;
  bool _loadingMore = false;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadData();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _loadData() async {
    setState(() { _loading = true; });
    try {
      final configRes = await StorefrontApiService.getConfig(widget.slug);
      final productsRes = await StorefrontApiService.getProducts(
        widget.slug,
        categoria: widget.categoria,
        busqueda: widget.busqueda,
        page: 1,
        limit: 20,
      );

      setState(() {
        _config = configRes['data'];
        _products = productsRes['products'] ?? [];
        _hasMore = productsRes['hasMore'] ?? false;
        _page = 1;
        _loading = false;
      });
    } catch (e) {
      setState(() { _loading = false; });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);

    try {
      final res = await StorefrontApiService.getProducts(
        widget.slug,
        categoria: widget.categoria,
        busqueda: widget.busqueda,
        page: _page + 1,
        limit: 20,
      );
      setState(() {
        _products.addAll(res['products'] ?? []);
        _hasMore = res['hasMore'] ?? false;
        _page++;
        _loadingMore = false;
      });
    } catch (e) {
      setState(() => _loadingMore = false);
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Color _getColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = _config != null
        ? _getColor(_config!['color_principal'] ?? '#0F172A')
        : const Color(0xFF0F172A);

    final title = widget.busqueda != null
        ? 'Resultados: "${widget.busqueda}"'
        : widget.categoria ?? 'Productos';

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        title: Text(title),
        centerTitle: false,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 3))
          : _products.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text('No se encontraron productos',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                    ],
                  ),
                )
              : GridView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.65,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _products.length + (_hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= _products.length) {
                      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                    }

                    final product = _products[index];
                    final precio = product['precio_oferta_web'] ?? product['precio_oferta'] ?? product['precio'] ?? 0;
                    final precioOriginal = (product['precio_oferta_web'] != null || product['precio_oferta'] != null)
                        ? product['precio']
                        : null;
                    final imagen = product['imagen_destacada_url'] ?? product['imagen1'] ?? '';
                    final tieneOferta = precioOriginal != null && precioOriginal > precio;

                    return GestureDetector(
                      onTap: () => Navigator.pushNamed(
                        context,
                        '/tienda/${widget.slug}/producto/${product['id']}',
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Stack(
                                children: [
                                  Container(
                                    width: double.infinity,
                                    color: Colors.grey.shade100,
                                    child: imagen.isNotEmpty
                                        ? Image.network(imagen, fit: BoxFit.cover, width: double.infinity,
                                            errorBuilder: (_, __, ___) => Center(
                                              child: Icon(Icons.image_outlined, size: 40, color: Colors.grey.shade300),
                                            ))
                                        : Center(
                                            child: Icon(Icons.image_outlined, size: 40, color: Colors.grey.shade300),
                                          ),
                                  ),
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
                                        child: Text(
                                          '-${((1 - precio / precioOriginal) * 100).round()}%',
                                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(product['titulo'] ?? '',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, height: 1.2)),
                                  const SizedBox(height: 4),
                                  if (tieneOferta)
                                    Text('\$$precioOriginal',
                                      style: TextStyle(color: Colors.grey.shade400, fontSize: 11, decoration: TextDecoration.lineThrough)),
                                  Text('\$$precio',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: primaryColor)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
