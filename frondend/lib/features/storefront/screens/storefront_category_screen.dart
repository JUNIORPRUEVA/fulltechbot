import 'package:flutter/material.dart';

import '../services/storefront_api_service.dart';
import '../widgets/storefront_empty_state.dart';
import '../widgets/storefront_product_card.dart';

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
  State<StorefrontCategoryScreen> createState() =>
      _StorefrontCategoryScreenState();
}

class _StorefrontCategoryScreenState extends State<StorefrontCategoryScreen> {
  final ScrollController _scrollController = ScrollController();
  late final TextEditingController _searchController;

  List<dynamic> _products = [];
  Map<String, dynamic>? _config;
  bool _loading = true;
  bool _loadingMore = false;
  int _page = 1;
  int _totalPages = 1;
  String _sortBy = 'featured';
  bool _filterOfertas = false;
  bool _filterInstalacion = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.busqueda ?? '');
    _scrollController.addListener(_onScroll);
    _loadData(reset: true);
  }

  Future<void> _loadData({required bool reset}) async {
    if (reset) {
      setState(() => _loading = true);
    } else {
      setState(() => _loadingMore = true);
    }

    try {
      final configFuture = _config == null
          ? StorefrontApiService.getConfig(widget.slug)
          : Future.value({'ok': true, 'data': _config});

      final response = await Future.wait([
        configFuture,
        StorefrontApiService.getProducts(
          widget.slug,
          categoria: widget.categoria,
          search: _searchController.text.trim().isEmpty
              ? null
              : _searchController.text.trim(),
          page: reset ? 1 : _page + 1,
          limit: 20,
          sort: _sortBy,
        ),
      ]);

      final configResponse = response[0];
      final productsResponse = response[1];
      var items = List<dynamic>.from(
        productsResponse['items'] as List? ?? const [],
      );

      if (_filterOfertas) {
        items = items.where((item) {
          final product = Map<String, dynamic>.from(item as Map);
          return product['precio_oferta_web'] != null ||
              product['precioOferta'] != null;
        }).toList();
      }

      if (_filterInstalacion) {
        items = items.where((item) {
          final product = Map<String, dynamic>.from(item as Map);
          return product['instalacion_incluida'] == true ||
              product['requiere_instalacion'] == true;
        }).toList();
      }

      setState(() {
        _config = Map<String, dynamic>.from(configResponse['data'] as Map);
        if (reset) {
          _products = items;
        } else {
          _products.addAll(items);
        }
        _page = productsResponse['page'] as int? ?? 1;
        _totalPages = productsResponse['totalPages'] as int? ?? 1;
        _loading = false;
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      if (!_loadingMore && _page < _totalPages) {
        _loadData(reset: false);
      }
    }
  }

  void _runSearch() {
    _loadData(reset: true);
  }

  Color _getColor(String hex) {
    var normalized = hex.replaceAll('#', '');
    if (normalized.length == 6) normalized = 'FF$normalized';
    return Color(int.parse(normalized, radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = _getColor(
      _config?['color_principal']?.toString() ?? '#0F172A',
    );
    final secondaryColor = _getColor(
      _config?['color_secundario']?.toString() ?? '#2563EB',
    );
    final whatsapp = _config?['whatsapp_numero']?.toString();
    final title = widget.busqueda != null && widget.busqueda!.isNotEmpty
        ? 'Resultados para "${widget.busqueda}"'
        : widget.categoria ?? 'Productos';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(title: Text(title)),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onSubmitted: (_) => _runSearch(),
                  decoration: InputDecoration(
                    hintText: 'Buscar por nombre, categoría o descripción',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: IconButton(
                      onPressed: _runSearch,
                      icon: const Icon(Icons.arrow_forward_rounded),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'Ofertas',
                        selected: _filterOfertas,
                        onTap: () {
                          setState(() => _filterOfertas = !_filterOfertas);
                          _loadData(reset: true);
                        },
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Instalación',
                        selected: _filterInstalacion,
                        onTap: () {
                          setState(
                            () => _filterInstalacion = !_filterInstalacion,
                          );
                          _loadData(reset: true);
                        },
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _sortBy,
                            items: const [
                              DropdownMenuItem(
                                value: 'featured',
                                child: Text('Destacados'),
                              ),
                              DropdownMenuItem(
                                value: 'newest',
                                child: Text('Más recientes'),
                              ),
                              DropdownMenuItem(
                                value: 'price_asc',
                                child: Text('Menor precio'),
                              ),
                              DropdownMenuItem(
                                value: 'price_desc',
                                child: Text('Mayor precio'),
                              ),
                              DropdownMenuItem(
                                value: 'name_asc',
                                child: Text('Nombre A-Z'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() => _sortBy = value);
                              _loadData(reset: true);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _products.isEmpty
                ? StorefrontEmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'No se encontraron productos',
                    subtitle: 'Prueba con otra categoría o búsqueda.',
                    actionLabel: 'Reintentar',
                    onAction: () => _loadData(reset: true),
                  )
                : GridView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.62,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                    itemCount: _products.length + (_loadingMore ? 2 : 0),
                    itemBuilder: (context, index) {
                      if (index >= _products.length) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      return StorefrontProductCard(
                        product: Map<String, dynamic>.from(
                          _products[index] as Map,
                        ),
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

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE0ECFF) : Colors.white,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: selected ? const Color(0xFF2563EB) : const Color(0xFFE5E7EB),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected ? const Color(0xFF2563EB) : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }
}
