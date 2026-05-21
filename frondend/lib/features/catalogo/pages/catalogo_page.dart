import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<CatalogoProvider>().cargarProductos();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
    final provider = context.watch<CatalogoProvider>();
    final productosFiltrados = _filtrarProductos(provider.productos);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo'),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: provider.isLoading
                ? null
                : () => context.read<CatalogoProvider>().cargarProductos(),
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
          // Error banner
          if (provider.error != null)
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
                  Icon(Icons.error_outline_rounded, color: Colors.red.shade400, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      provider.error!,
                      style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                    ),
                  ),
                  IconButton(
                    onPressed: () => context.read<CatalogoProvider>().limpiarError(),
                    icon: Icon(Icons.close, size: 18, color: Colors.red.shade400),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

          // Barra de búsqueda
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

          // Estadísticas rápidas
          if (provider.productos.isNotEmpty && _searchQuery.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: SizedBox(
                height: 32,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _StatChip(
                      icon: Icons.inventory_2_rounded,
                      label: '${provider.productos.length} total',
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    _StatChip(
                      icon: Icons.check_circle_rounded,
                      label: '${provider.productos.where((p) => p.estado == 'activo').length} activos',
                      color: Colors.green,
                    ),
                    const SizedBox(width: 8),
                    _StatChip(
                      icon: Icons.shopping_cart_rounded,
                      label: '${provider.productos.where((p) => p.estado == 'agotado').length} agotados',
                      color: Colors.orange,
                    ),
                  ],
                ),
              ),
            ),

          // Lista de productos
          Expanded(
            child: provider.isLoading && provider.productos.isEmpty
                ? const Center(child: CircularProgressIndicator(strokeWidth: 3))
                : provider.productos.isEmpty
                    ? _EmptyCatalogo(onAdd: () => _abrirFormulario(context))
                    : productosFiltrados.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.shade300),
                                const SizedBox(height: 12),
                                Text(
                                  'No se encontraron productos',
                                  style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () => context.read<CatalogoProvider>().cargarProductos(),
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                              itemCount: productosFiltrados.length,
                              itemBuilder: (context, index) {
                                final producto = productosFiltrados[index];
                                return _ProductoCard(
                                  producto: producto,
                                  onTap: () => _abrirDetalle(context, producto),
                                  onEdit: () => _abrirFormulario(context, producto: producto),
                                  onDelete: () => _confirmarEliminar(context, producto),
                                  onEstadoChanged: (estado) {
                                    context.read<CatalogoProvider>().cambiarEstado(
                                          id: producto.id,
                                          estado: estado,
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

  void _abrirDetalle(BuildContext context, CatalogoModel producto) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CatalogoDetailPage(producto: producto),
      ),
    );
  }

  Future<void> _abrirFormulario(BuildContext context, {CatalogoModel? producto}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CatalogoFormPage(producto: producto),
      ),
    );
  }

  Future<void> _confirmarEliminar(BuildContext context, CatalogoModel producto) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Eliminar producto'),
        content: Text('¿Seguro que quieres eliminar "${producto.titulo}"?'),
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
      await context.read<CatalogoProvider>().eliminarProducto(producto.id);
    }
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
    final tieneImagen = producto.imagen1 != null && producto.imagen1!.isNotEmpty;
    final colorEstado = _getEstadoColor(producto.estado);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              // Imagen pequeña
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
                child: Container(
                  width: 72,
                  height: 72,
                  color: Colors.grey.shade50,
                  child: tieneImagen
                      ? Image.network(
                          producto.imagen1!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.inventory_2_outlined,
                            size: 28,
                            color: Colors.grey.shade300,
                          ),
                        )
                      : Icon(
                          Icons.inventory_2_outlined,
                          size: 28,
                          color: Colors.grey.shade300,
                        ),
                ),
              ),

              // Info
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Título
                      Text(
                        producto.titulo,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      // Categoría
                      Text(
                        producto.categoria,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Precio y estado en una línea
                      Row(
                        children: [
                          Text(
                            'RD\$${producto.precio.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Colors.green.shade700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: colorEstado.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: colorEstado.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              producto.estado.toUpperCase(),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: colorEstado,
                              ),
                            ),
                          ),
                          if (producto.stock > 0) ...[
                            const SizedBox(width: 6),
                            Text(
                              'Stock: ${producto.stock}',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.blue.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Menú
              PopupMenuButton<String>(
                tooltip: 'Opciones',
                onSelected: (value) {
                  if (value == 'edit') onEdit();
                  else if (value == 'delete') onDelete();
                  else onEstadoChanged(value);
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'activo', child: Text('Activo')),
                  const PopupMenuItem(value: 'inactivo', child: Text('Inactivo')),
                  const PopupMenuItem(value: 'agotado', child: Text('Agotado')),
                  const PopupMenuDivider(),
                  const PopupMenuItem(value: 'edit', child: ListTile(
                    leading: Icon(Icons.edit_outlined, size: 20),
                    title: Text('Editar'),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  )),
                  const PopupMenuItem(value: 'delete', child: ListTile(
                    leading: Icon(Icons.delete_outline, size: 20, color: Colors.red),
                    title: Text('Eliminar', style: TextStyle(color: Colors.red)),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  )),
                ],
                icon: Icon(Icons.more_vert, size: 18, color: Colors.grey.shade400),
              ),
            ],
          ),
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
              child: Icon(Icons.inventory_2_outlined, size: 40, color: Colors.blue.shade300),
            ),
            const SizedBox(height: 16),
            const Text(
              'No hay productos todavía',
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
