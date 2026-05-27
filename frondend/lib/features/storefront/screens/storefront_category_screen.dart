import 'package:flutter/material.dart';
import '../services/storefront_api_service.dart';
import '../widgets/storefront_product_card.dart';
import '../widgets/storefront_empty_state.dart';

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
  final _searchController = TextEditingController();
  String _sortBy = 'relevancia';
  bool _filterOfertas = false;
  bool _filterInstalacion = false;

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.busqueda ?? '';
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
        _hasMore = _page < (productsRes['totalPages'] ?? 1);
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
        _hasMore = _page < (res['totalPages'] ?? 1);
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

  void _search(String query) {
    if (query.trim().isEmpty) return;
    Navigator.pushReplacementNamed(
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
    final primaryColor = _config != null
        ? _getColor(_config!['color_principal'] ?? '#0F172A')
        : const Color(0xFF0F172A);
    final secondaryColor = _config != null
        ? _getColor(_config!['color_secundario'] ?? '#2563EB')
        : const Color(0xFF2563EB);
    final whatsapp = _config?['whatsapp_numero'] ?? '';

    final title = widget.busqueda != null
        ? 'Resultados: "${widget.busqueda}"'
        : widget.categoria ?? 'Productos';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(title),
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Buscador y filtros premium
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Buscador
                TextField(
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
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onSubmitted: _search,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 10),
                // Filtros chips modernos
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(
                        label: 'Ofertas',
                        icon: Icons.local_fire_department_rounded,
                        selected: _filterOfertas,
                        color: const Color(0xFFEF4444),
                        onTap: () {
                          setState(() => _filterOfertas = !_filterOfertas);
                          _loadData();
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: 'Instalación',
                        icon: Icons.build_outlined,
                        selected: _filterInstalacion,
                        color: const Color(0xFF2563EB),
                        onTap: () {
                          setState(() => _filterInstalacion = !_filterInstalacion);
                          _loadData();
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildSortChip(
                        value: _sortBy,
                        onChanged: (v) {
                          setState(() => _sortBy = v!);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Productos
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(strokeWidth: 3))
                : _products.isEmpty
                    ? StorefrontEmptyState(
                        icon: Icons.search_off_rounded,
                        title: 'No se encontraron productos',
                        subtitle: 'Intenta con otros términos de búsqueda',
                        actionLabel: 'Limpiar filtros',
                        onAction: () {
                          setState(() {
                            _filterOfertas = false;
                            _filterInstalacion = false;
                            _searchController.clear();
                          });
                          _loadData();
                        },
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
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            );
                          }

                          return StorefrontProductCard(
                            product: _products[index],
                            slug: widget.slug,
                            primaryColor: primaryColor,
                            secondaryColor: secondaryColor,
                            compact: true,
                            whatsapp: whatsapp,
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required bool selected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.1) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: selected ? color.withValues(alpha: 0.3) : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? color : const Color(0xFF6B7280),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? color : const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortChip({
    required String value,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(100),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          icon: const Icon(Icons.swap_vert_rounded, size: 18),
          style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280), fontWeight: FontWeight.w600),
          items: const [
            DropdownMenuItem(value: 'relevancia', child: Text('Relevancia')),
            DropdownMenuItem(value: 'precio_asc', child: Text('Menor precio')),
            DropdownMenuItem(value: 'precio_desc', child: Text('Mayor precio')),
            DropdownMenuItem(value: 'nombre', child: Text('Nombre A-Z')),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}
