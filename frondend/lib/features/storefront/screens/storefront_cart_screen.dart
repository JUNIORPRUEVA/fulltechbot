import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/storefront_api_service.dart';
import '../widgets/storefront_empty_state.dart';

class StorefrontCartScreen extends StatefulWidget {
  final String slug;
  const StorefrontCartScreen({super.key, required this.slug});

  @override
  State<StorefrontCartScreen> createState() => _StorefrontCartScreenState();
}

class _StorefrontCartScreenState extends State<StorefrontCartScreen> {
  Map<String, dynamic>? _cart;
  Map<String, dynamic>? _config;
  bool _loading = true;
  String _sessionId = '';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _sessionId = prefs.getString('storefront_session_${widget.slug}') ?? '';
    await _loadData();
  }

  Future<void> _loadData() async {
    if (_sessionId.isEmpty) {
      setState(() { _loading = false; _cart = null; });
      return;
    }

    setState(() { _loading = true; });

    try {
      final results = await Future.wait([
        StorefrontApiService.getConfig(widget.slug),
        StorefrontApiService.getCart(widget.slug, _sessionId),
      ]);

      setState(() {
        _config = results[0]['data'];
        _cart = results[1]['ok'] == true ? results[1]['data'] : null;
        _loading = false;
      });
    } catch (e) {
      setState(() { _loading = false; });
    }
  }

  Color _getColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  Future<void> _updateQuantity(int itemId, int cantidad) async {
    if (cantidad < 1) return;
    try {
      final res = await StorefrontApiService.updateCartItem(widget.slug, _sessionId, itemId, cantidad: cantidad);
      if (res['ok'] == true) {
        setState(() => _cart = res['data']);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _removeItem(int itemId) async {
    try {
      final res = await StorefrontApiService.deleteCartItem(widget.slug, _sessionId, itemId);
      if (res['ok'] == true) {
        setState(() => _cart = res['data']);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = _config != null ? _getColor(_config!['color_principal'] ?? '#0F172A') : const Color(0xFF0F172A);
    final secondaryColor = _config != null ? _getColor(_config!['color_secundario'] ?? '#2563EB') : const Color(0xFF2563EB);
    final whatsapp = _config?['whatsapp_numero'] ?? '';

    final items = _cart != null ? (_cart!['items'] as List<dynamic>?) ?? [] : [];
    final total = _cart?['total'] ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Carrito'),
        centerTitle: false,
        actions: [
          if (items.isNotEmpty)
            TextButton(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Vaciar carrito'),
                    content: const Text('¿Eliminar todos los productos?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Vaciar')),
                    ],
                  ),
                );
                if (confirm == true) {
                  for (final item in items) {
                    await _removeItem(item['id']);
                  }
                }
              },
              child: const Text('Vaciar'),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 3))
          : items.isEmpty
              ? StorefrontEmptyState(
                  icon: Icons.shopping_cart_outlined,
                  title: 'Tu carrito está vacío',
                  subtitle: 'Explora nuestros productos y agrega los que más te gusten',
                  actionLabel: 'Seguir comprando',
                  onAction: () => Navigator.pop(context),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Items del carrito
                    ...items.map((item) => _CartItemCard(
                      item: item,
                      primaryColor: primaryColor,
                      secondaryColor: secondaryColor,
                      onUpdateQuantity: (q) => _updateQuantity(item['id'], q),
                      onRemove: () => _removeItem(item['id']),
                    )),

                    const SizedBox(height: 16),

                    // Resumen premium
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Subtotal',
                                style: TextStyle(fontSize: 15, color: Color(0xFF6B7280)),
                              ),
                              Text(
                                '\$${_cart?['subtotal'] ?? total}',
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Delivery',
                                style: TextStyle(fontSize: 15, color: Color(0xFF6B7280)),
                              ),
                              Text(
                                _cart?['delivery'] != null ? '\$${_cart!['delivery']}' : 'Por calcular',
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: primaryColor),
                              ),
                              Text(
                                '\$$total',
                                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: primaryColor),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Botón checkout
                    FilledButton.icon(
                      onPressed: () => Navigator.pushNamed(context, '/tienda/${widget.slug}/checkout'),
                      icon: const Icon(Icons.shopping_bag_outlined, size: 20),
                      label: const Text('Finalizar pedido'),
                      style: FilledButton.styleFrom(
                        backgroundColor: primaryColor,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Botón WhatsApp
                    if (whatsapp.isNotEmpty)
                      OutlinedButton.icon(
                        onPressed: () async {
                          try {
                            final res = await StorefrontApiService.whatsappOrder(widget.slug, _sessionId);
                            if (res['ok'] == true && res['data']['url'] != null) {
                              launchUrl(Uri.parse(res['data']['url']));
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        },
                        icon: const Icon(Icons.chat_rounded, color: Color(0xFF25D366)),
                        label: const Text('Pedir por WhatsApp'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF25D366),
                          side: const BorderSide(color: Color(0xFF25D366)),
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),

                    const SizedBox(height: 32),
                  ],
                ),
    );
  }
}

class _CartItemCard extends StatelessWidget {
  final dynamic item;
  final Color primaryColor;
  final Color secondaryColor;
  final Function(int) onUpdateQuantity;
  final VoidCallback onRemove;

  const _CartItemCard({
    required this.item,
    required this.primaryColor,
    required this.secondaryColor,
    required this.onUpdateQuantity,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Imagen
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 80,
                height: 80,
                color: const Color(0xFFF1F5F9),
                child: item['imagen_url'] != null
                    ? Image.network(item['imagen_url'], fit: BoxFit.cover)
                    : Icon(Icons.image_outlined, color: const Color(0xFFCBD5E1)),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['nombre_producto'] ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${item['precio_unitario']}',
                    style: TextStyle(fontWeight: FontWeight.w700, color: primaryColor, fontSize: 15),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            InkWell(
                              onTap: () => onUpdateQuantity((item['cantidad'] as num).toInt() - 1),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                child: Icon(Icons.remove_rounded, size: 16, color: const Color(0xFF6B7280)),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                '${item['cantidad']}',
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                              ),
                            ),
                            InkWell(
                              onTap: () => onUpdateQuantity((item['cantidad'] as num).toInt() + 1),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                child: Icon(Icons.add_rounded, size: 16, color: const Color(0xFF6B7280)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Subtotal y eliminar
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${item['subtotal']}',
                  style: TextStyle(fontWeight: FontWeight.w700, color: secondaryColor, fontSize: 15),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: onRemove,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red.shade400),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
