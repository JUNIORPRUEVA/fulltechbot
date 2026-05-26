import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/storefront_api_service.dart';

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
  String? _error;
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

    setState(() { _loading = true; _error = null; });

    try {
      final configRes = await StorefrontApiService.getConfig(widget.slug);
      final cartRes = await StorefrontApiService.getCart(widget.slug, _sessionId);

      setState(() {
        _config = configRes['data'];
        _cart = cartRes['ok'] == true ? cartRes['data'] : null;
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = 'Error: $e'; _loading = false; });
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
      backgroundColor: const Color(0xFFF6F7F9),
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
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text('Tu carrito está vacío', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Seguir comprando'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length + 1,
                  itemBuilder: (context, index) {
                    if (index == items.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Column(
                          children: [
                            // Total
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: primaryColor)),
                                  Text('\$$total', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: primaryColor)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Botón checkout
                            FilledButton.icon(
                              onPressed: () => Navigator.pushNamed(context, '/tienda/${widget.slug}/checkout'),
                              icon: const Icon(Icons.shopping_bag_outlined),
                              label: const Text('Proceder al checkout'),
                              style: FilledButton.styleFrom(
                                backgroundColor: primaryColor,
                                minimumSize: const Size(double.infinity, 56),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                                icon: const Icon(Icons.chat, color: Color(0xFF25D366)),
                                label: const Text('Pedir por WhatsApp'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF25D366),
                                  side: const BorderSide(color: Color(0xFF25D366)),
                                  minimumSize: const Size(double.infinity, 56),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                              ),
                          ],
                        ),
                      );
                    }

                    final item = items[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            // Imagen
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: 80, height: 80,
                                color: Colors.grey.shade100,
                                child: item['imagen_url'] != null
                                    ? Image.network(item['imagen_url'], fit: BoxFit.cover)
                                    : Icon(Icons.image_outlined, color: Colors.grey.shade300),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item['nombre_producto'] ?? '',
                                    maxLines: 2, overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 4),
                                  Text('\$${item['precio_unitario']}',
                                    style: TextStyle(fontWeight: FontWeight.w700, color: primaryColor)),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(color: Colors.grey.shade300),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          children: [
                                            InkWell(
                                              onTap: () => _updateQuantity(item['id'], (item['cantidad'] as num).toInt() - 1),
                                              child: const Padding(
                                                padding: EdgeInsets.all(6),
                                                child: Icon(Icons.remove, size: 16),
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 8),
                                              child: Text('${item['cantidad']}', style: const TextStyle(fontWeight: FontWeight.w600)),
                                            ),
                                            InkWell(
                                              onTap: () => _updateQuantity(item['id'], (item['cantidad'] as num).toInt() + 1),
                                              child: const Padding(
                                                padding: EdgeInsets.all(6),
                                                child: Icon(Icons.add, size: 16),
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
                                Text('\$${item['subtotal']}', style: TextStyle(fontWeight: FontWeight.w700, color: secondaryColor)),
                                IconButton(
                                  icon: Icon(Icons.delete_outline, size: 20, color: Colors.red.shade300),
                                  onPressed: () => _removeItem(item['id']),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
