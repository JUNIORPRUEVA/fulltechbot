import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../bots/models/bot_model.dart';
import '../../bots/providers/bot_provider.dart';
import '../../storefront/services/storefront_helpers.dart';
import '../../storefront/widgets/storefront_smart_image.dart';
import '../models/catalogo_model.dart';
import '../providers/catalogo_provider.dart';
import 'catalogo_detail_page.dart';
import 'catalogo_form_page.dart';

class CatalogoPage extends StatefulWidget {
  const CatalogoPage({super.key});

  @override
  State<CatalogoPage> createState() => _CatalogoPageState();
}

class _CatalogoPageState extends State<CatalogoPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _lastBotId;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarSiHayBot();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _verificarCambioDeBot();
    });
  }

  void _verificarCambioDeBot() {
    final botId = _botId;
    if (botId != null && botId != _lastBotId) {
      _lastBotId = botId;
      _cargarProductos();
    } else if (botId == null && _lastBotId != null) {
      _lastBotId = null;
      context.read<CatalogoProvider>().cargarProductos(botId: null);
    }
  }

  String? get _botId {
    try {
      return context.read<BotProvider>().botSeleccionado?.id;
    } catch (_) {
      return null;
    }
  }

  void _cargarSiHayBot() {
    final botId = _botId;
    if (botId != null) {
      _lastBotId = botId;
      context.read<CatalogoProvider>().cargarProductos(botId: botId);
    }
  }

  void _cargarProductos() {
    final botId = _botId;
    if (botId != null) {
      context.read<CatalogoProvider>().cargarProductos(botId: botId);
    }
  }

  List<CatalogoModel> _filtrarProductos(List<CatalogoModel> productos) {
    if (_searchQuery.isEmpty) return productos;
    final query = _searchQuery.toLowerCase();
    return productos.where((p) {
      return p.titulo.toLowerCase().contains(query) ||
          p.categoria.toLowerCase().contains(query) ||
          (p.descripcion?.toLowerCase().contains(query) ?? false) ||
          (p.palabrasClave?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final botProvider = context.watch<BotProvider>();
    final catalogoProvider = context.watch<CatalogoProvider>();
    final bot = botProvider.botSeleccionado;
    final productosFiltrados = _filtrarProductos(catalogoProvider.productos);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 700;
    final isTablet = screenWidth >= 700 && screenWidth < 1100;
    final crossAxisCount = isMobile ? 2 : (isTablet ? 3 : 4);
    final aspectRatio = isMobile ? 0.67 : (isTablet ? 0.72 : 0.78);

    if (bot == null) {
      return _buildSinBotSeleccionado();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catalogo'),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: catalogoProvider.isLoading ? null : _cargarProductos,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _abrirFormulario(context),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          _BotBanner(bot: bot),
          if (catalogoProvider.productos.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _CatalogHighlightsSlider(
                productos: catalogoProvider.productos,
                onTapProduct: (producto) => _abrirDetalle(context, producto),
              ),
            ),
          if (catalogoProvider.error != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    color: Colors.red.shade400,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      catalogoProvider.error!,
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () =>
                        context.read<CatalogoProvider>().limpiarError(),
                    icon: Icon(
                      Icons.close,
                      size: 18,
                      color: Colors.red.shade400,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Buscar productos...',
                prefixIcon: const Icon(Icons.search_rounded, size: 22),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          if (catalogoProvider.productos.isNotEmpty && _searchQuery.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: SizedBox(
                height: 32,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _StatChip(
                      icon: Icons.inventory_2_rounded,
                      label: '${catalogoProvider.productos.length} total',
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    _StatChip(
                      icon: Icons.check_circle_rounded,
                      label:
                          '${catalogoProvider.productos.where((p) => p.estado == 'activo').length} activos',
                      color: Colors.green,
                    ),
                    const SizedBox(width: 8),
                    _StatChip(
                      icon: Icons.shopping_cart_rounded,
                      label:
                          '${catalogoProvider.productos.where((p) => p.estado == 'agotado').length} agotados',
                      color: Colors.orange,
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: catalogoProvider.isLoading &&
                    catalogoProvider.productos.isEmpty
                ? const Center(child: CircularProgressIndicator(strokeWidth: 3))
                : catalogoProvider.productos.isEmpty
                    ? _EmptyCatalogo(onAdd: () => _abrirFormulario(context))
                    : productosFiltrados.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off_rounded,
                                  size: 48,
                                  color: Colors.grey.shade300,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No se encontraron productos',
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () async => _cargarProductos(),
                            child: GridView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                childAspectRatio: aspectRatio,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                              ),
                              itemCount: productosFiltrados.length,
                              itemBuilder: (context, index) {
                                final producto = productosFiltrados[index];
                                return _ProductoCard(
                                  producto: producto,
                                  onTap: () => _abrirDetalle(context, producto),
                                  onEdit: () => _abrirFormulario(
                                    context,
                                    producto: producto,
                                  ),
                                  onDelete: () =>
                                      _confirmarEliminar(context, producto),
                                  onEstadoChanged: (estado) {
                                    context.read<CatalogoProvider>().cambiarEstado(
                                          id: producto.id,
                                          estado: estado,
                                          botId: _botId,
                                        );
                                  },
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildSinBotSeleccionado() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catalogo'),
        centerTitle: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  Icons.inventory_2_outlined,
                  size: 40,
                  color: Colors.orange.shade300,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Selecciona un bot',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'Selecciona un bot antes de administrar el catalogo.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _abrirDetalle(BuildContext context, CatalogoModel producto) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CatalogoDetailPage(producto: producto),
      ),
    );
  }

  Future<void> _abrirFormulario(
    BuildContext context, {
    CatalogoModel? producto,
  }) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CatalogoFormPage(producto: producto),
      ),
    );
  }

  Future<void> _confirmarEliminar(
    BuildContext context,
    CatalogoModel producto,
  ) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Eliminar producto'),
        content: Text('Seguro que quieres eliminar "${producto.titulo}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true && context.mounted) {
      await context.read<CatalogoProvider>().eliminarProducto(
            producto.id,
            botId: _botId,
          );
    }
  }
}

class _BotBanner extends StatelessWidget {
  final BotModel bot;

  const _BotBanner({required this.bot});

  @override
  Widget build(BuildContext context) {
    final isActive = bot.estado == 'activo';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.smart_toy_outlined, size: 18, color: Colors.blue.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Catalogo de: ${bot.nombre}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.blue.shade700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isActive ? Colors.green.shade50 : Colors.red.shade50,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isActive
                    ? Colors.green.shade200
                    : Colors.red.shade200,
              ),
            ),
            child: Text(
              isActive ? 'Activo' : 'Inactivo',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: isActive
                    ? Colors.green.shade700
                    : Colors.red.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductoCard extends StatelessWidget {
  final CatalogoModel producto;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<String> onEstadoChanged;

  const _ProductoCard({
    required this.producto,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onEstadoChanged,
  });

  @override
  Widget build(BuildContext context) {
    final images = _getImages(producto);
    final colorEstado = _getEstadoColor(producto.estado);
    final isMobile = MediaQuery.sizeOf(context).width < 700;
    final displayPrice =
        producto.precioOferta != null &&
                producto.precioOferta! > 0 &&
                producto.precioOferta! < producto.precio
            ? producto.precioOferta!
            : producto.precio;
    final originalPrice =
        displayPrice < producto.precio ? producto.precio : null;
    final description = [
      producto.descripcion,
      producto.informacion,
      producto.palabrasClave,
    ].firstWhere(
      (value) => value != null && value.trim().isNotEmpty,
      orElse: () => 'Producto disponible en catalogo',
    )!;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 56,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _ProductImageCarousel(images: images),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colorEstado.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        producto.estado.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Material(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(12),
                      child: PopupMenuButton<String>(
                        tooltip: 'Opciones',
                        onSelected: (value) {
                          if (value == 'edit') {
                            onEdit();
                          } else if (value == 'delete') {
                            onDelete();
                          } else {
                            onEstadoChanged(value);
                          }
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                            value: 'activo',
                            child: Text('Activo'),
                          ),
                          const PopupMenuItem(
                            value: 'inactivo',
                            child: Text('Inactivo'),
                          ),
                          const PopupMenuItem(
                            value: 'agotado',
                            child: Text('Agotado'),
                          ),
                          const PopupMenuDivider(),
                          const PopupMenuItem(
                            value: 'edit',
                            child: ListTile(
                              leading: Icon(Icons.edit_outlined, size: 20),
                              title: Text('Editar'),
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: ListTile(
                              leading: Icon(
                                Icons.delete_outline,
                                size: 20,
                                color: Colors.red,
                              ),
                              title: Text(
                                'Eliminar',
                                style: TextStyle(color: Colors.red),
                              ),
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                        icon: Icon(
                          Icons.more_vert,
                          size: 18,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 44,
              child: Padding(
                padding: EdgeInsets.all(isMobile ? 8 : 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      producto.titulo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: isMobile ? 12 : 13.5,
                        fontWeight: FontWeight.w700,
                        height: 1.18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      producto.categoria,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: isMobile ? 10 : 11,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: isMobile ? 10 : 11,
                        color: Colors.grey.shade600,
                        height: 1.25,
                      ),
                    ),
                    const Spacer(),
                    if (originalPrice != null)
                      Text(
                        'RD\$${originalPrice.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: isMobile ? 10 : 11,
                          color: Colors.grey.shade400,
                          decoration: TextDecoration.lineThrough,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    Text(
                      'RD\$${displayPrice.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: isMobile ? 14 : 15.5,
                        fontWeight: FontWeight.w900,
                        color: Colors.green.shade700,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            producto.stock > 0
                                ? 'Stock: ${producto.stock}'
                                : 'Sin stock',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: isMobile ? 9.5 : 10.5,
                              color: producto.stock > 0
                                  ? Colors.blue.shade600
                                  : Colors.orange.shade700,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.swipe_rounded,
                          size: 15,
                          color: images.length > 1
                              ? Colors.grey.shade500
                              : Colors.grey.shade300,
                        ),
                      ],
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

  Color _getEstadoColor(String estado) {
    switch (estado) {
      case 'activo':
        return Colors.green;
      case 'agotado':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  List<String> _getImages(CatalogoModel producto) {
    final raw = [producto.imagen1, producto.imagen2, producto.imagen3];
    return raw
        .map(
          (value) => StorefrontHelpers.normalizeImageUrl(
            value,
            version: producto.actualizadoEn?.toIso8601String(),
          ),
        )
        .whereType<String>()
        .where((value) => value.trim().isNotEmpty)
        .toList();
  }
}

class _CatalogHighlightsSlider extends StatefulWidget {
  final List<CatalogoModel> productos;
  final ValueChanged<CatalogoModel> onTapProduct;

  const _CatalogHighlightsSlider({
    required this.productos,
    required this.onTapProduct,
  });

  @override
  State<_CatalogHighlightsSlider> createState() =>
      _CatalogHighlightsSliderState();
}

class _CatalogHighlightsSliderState extends State<_CatalogHighlightsSlider> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  List<CatalogoModel> get _slides => widget.productos
      .where(
        (item) => [item.imagen1, item.imagen2, item.imagen3]
            .any((image) => image != null && image.trim().isNotEmpty),
      )
      .take(5)
      .toList();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_slides.isEmpty) return const SizedBox.shrink();

    final height = MediaQuery.sizeOf(context).width < 700 ? 188.0 : 230.0;

    return SizedBox(
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: _slides.length,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemBuilder: (context, index) {
                final producto = _slides[index];
                final image = StorefrontHelpers.normalizeImageUrl(
                  producto.imagen1 ?? producto.imagen2 ?? producto.imagen3,
                  version: producto.actualizadoEn?.toIso8601String(),
                );
                final price =
                    producto.precioOferta != null &&
                            producto.precioOferta! > 0 &&
                            producto.precioOferta! < producto.precio
                        ? producto.precioOferta!
                        : producto.precio;

                return GestureDetector(
                  onTap: () => widget.onTapProduct(producto),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      StorefrontSmartImage(source: image, fit: BoxFit.cover),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withValues(alpha: 0.08),
                              Colors.black.withValues(alpha: 0.18),
                              Colors.black.withValues(alpha: 0.68),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                producto.categoria,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              producto.titulo,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                height: 1.05,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'RD\$${price.toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 12,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_slides.length, (index) {
                  final active = index == _currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: active ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: active
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.38),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductImageCarousel extends StatefulWidget {
  final List<String> images;

  const _ProductImageCarousel({required this.images});

  @override
  State<_ProductImageCarousel> createState() => _ProductImageCarouselState();
}

class _ProductImageCarouselState extends State<_ProductImageCarousel> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      return Container(
        color: Colors.grey.shade100,
        child: Center(
          child: Icon(
            Icons.inventory_2_outlined,
            size: 34,
            color: Colors.grey.shade300,
          ),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          controller: _pageController,
          itemCount: widget.images.length,
          onPageChanged: (index) => setState(() => _currentPage = index),
          itemBuilder: (context, index) {
            return StorefrontSmartImage(
              source: widget.images[index],
              fit: BoxFit.cover,
            );
          },
        ),
        if (widget.images.length > 1)
          Positioned(
            left: 0,
            right: 0,
            bottom: 8,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.images.length, (index) {
                final active = index == _currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: active ? 16 : 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: active
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(999),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }
}

class _EmptyCatalogo extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyCatalogo({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.inventory_2_outlined,
                size: 40,
                color: Colors.blue.shade300,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No hay productos todavia',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Agrega el primer producto para que el bot pueda vender con datos reales.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Agregar producto'),
            ),
          ],
        ),
      ),
    );
  }
}
