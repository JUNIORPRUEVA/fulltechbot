import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/store_admin_provider.dart';

/// Pantalla de administración de carritos de la tienda.
class StoreCartsScreen extends StatefulWidget {
  const StoreCartsScreen({super.key});

  @override
  State<StoreCartsScreen> createState() => _StoreCartsScreenState();
}

class _StoreCartsScreenState extends State<StoreCartsScreen> {
  String _filterEstado = 'activo';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCarts();
    });
  }

  void _loadCarts() {
    context.read<StoreAdminProvider>().loadCarts(estado: _filterEstado);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StoreAdminProvider>();

    return Column(
      children: [
        // Filtros
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _buildFilterChip('Activos', 'activo'),
              const SizedBox(width: 8),
              _buildFilterChip('Abandonados', 'abandonado'),
              const SizedBox(width: 8),
              _buildFilterChip('Completados', 'completado'),
              const SizedBox(width: 8),
              _buildFilterChip('Todos', null),
            ],
          ),
        ),
        const Divider(height: 1),
        // Lista
        Expanded(
          child: provider.loading
              ? const Center(child: CircularProgressIndicator())
              : provider.carts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.shopping_cart,
                              size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text('No hay carritos $_filterEstado',
                              style: TextStyle(
                                  fontSize: 18, color: Colors.grey[600])),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () async => _loadCarts(),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: provider.carts.length,
                        itemBuilder: (context, index) {
                          final cart = provider.carts[index];
                          return _CartCard(cart: cart);
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String? estado) {
    final isSelected = _filterEstado == estado;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() => _filterEstado = estado ?? '');
        _loadCarts();
      },
    );
  }
}

class _CartCard extends StatelessWidget {
  final Map<String, dynamic> cart;

  const _CartCard({required this.cart});

  String _formatDate(dynamic date) {
    if (date == null) return '-';
    try {
      final dt = DateTime.parse(date.toString());
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return date.toString();
    }
  }

  Color _estadoColor(String? estado) {
    switch (estado) {
      case 'activo':
        return Colors.blue;
      case 'abandonado':
        return Colors.orange;
      case 'completado':
        return Colors.green;
      case 'cancelado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = List<Map<String, dynamic>>.from(cart['items'] ?? []);
    final total = cart['total'] ?? 0;
    final estado = cart['estado'] ?? 'activo';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Icon(Icons.shopping_cart, color: _estadoColor(estado)),
        title: Text(
          cart['session_id']?.toString().substring(0, 12) ?? 'Sin sesión',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(
          '${items.length} productos | \$${total}',
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildEstadoBadge(estado, _estadoColor(estado)),
            const SizedBox(width: 8),
            Text(_formatDate(cart['creado_en']),
                style: TextStyle(color: Colors.grey[500], fontSize: 11)),
          ],
        ),
        children: [
          if (cart['nombre_cliente'] != null ||
              cart['telefono_cliente'] != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  if (cart['nombre_cliente'] != null)
                    Chip(
                      avatar: const Icon(Icons.person, size: 16),
                      label: Text(cart['nombre_cliente'],
                          style: const TextStyle(fontSize: 12)),
                    ),
                  if (cart['telefono_cliente'] != null)
                    Chip(
                      avatar: const Icon(Icons.phone, size: 16),
                      label: Text(cart['telefono_cliente'],
                          style: const TextStyle(fontSize: 12)),
                    ),
                ],
              ),
            ),
          const Divider(),
          ...items.map((item) => ListTile(
                dense: true,
                leading: item['imagen_url'] != null
                    ? Image.network(item['imagen_url'],
                        width: 40, height: 40, fit: BoxFit.cover)
                    : const Icon(Icons.inventory),
                title: Text(item['nombre_producto'] ?? 'Producto',
                    style: const TextStyle(fontSize: 13)),
                trailing: Text(
                  'x${item['cantidad']} = \$${item['subtotal']}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              )),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total: \$$total',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                if (cart['telefono_cliente'] != null)
                  ElevatedButton.icon(
                    onPressed: () {
                      // Abrir WhatsApp
                      final phone = cart['telefono_cliente'].toString();
                      final url =
                          'https://wa.me/${phone.replaceAll(RegExp(r'[^\d]'), '')}';
                      // Lanzar URL
                    },
                    icon: const Icon(Icons.chat, size: 16),
                    label: const Text('WhatsApp', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstadoBadge(String? estado, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(estado ?? 'desconocido',
          style: TextStyle(color: color, fontSize: 11)),
    );
  }
}
