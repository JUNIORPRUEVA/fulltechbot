import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/storefront_api_service.dart';
import '../services/storefront_helpers.dart';
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
    _sessionId = await StorefrontHelpers.ensureSessionId(widget.slug);
    await _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        StorefrontApiService.getConfig(widget.slug),
        StorefrontApiService.getCart(widget.slug, _sessionId),
      ]);

      setState(() {
        _config = Map<String, dynamic>.from(results[0]['data'] as Map);
        _cart = results[1]['ok'] == true
            ? Map<String, dynamic>.from(results[1]['data'] as Map)
            : null;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Color _getColor(String hex) {
    var normalized = hex.replaceAll('#', '');
    if (normalized.length == 6) normalized = 'FF$normalized';
    return Color(int.parse(normalized, radix: 16));
  }

  Future<void> _updateQuantity(String itemId, int quantity) async {
    if (quantity < 1) return;
    final response = await StorefrontApiService.updateCartItem(
      widget.slug,
      _sessionId,
      itemId,
      cantidad: quantity,
    );
    if (!mounted) return;
    if (response['ok'] == true) {
      setState(() {
        _cart = Map<String, dynamic>.from(response['data'] as Map);
      });
    }
  }

  Future<void> _removeItem(String itemId) async {
    final response = await StorefrontApiService.deleteCartItem(
      widget.slug,
      _sessionId,
      itemId,
    );
    if (!mounted) return;
    if (response['ok'] == true) {
      setState(() {
        _cart = Map<String, dynamic>.from(response['data'] as Map);
      });
    }
  }

  Future<void> _sendWhatsAppCart() async {
    final response = await StorefrontApiService.whatsappOrder(
      widget.slug,
      _sessionId,
    );

    if (!mounted) return;
    if (response['ok'] == true && response['data']?['url'] != null) {
      launchUrl(Uri.parse(response['data']['url'].toString()));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          response['message']?.toString() ?? 'No se pudo abrir WhatsApp',
        ),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = _getColor(
      _config?['color_principal']?.toString() ?? '#0F172A',
    );
    final items = List<dynamic>.from(_cart?['items'] as List? ?? const []);
    final total = _cart?['total'] ?? 0;
    final subtotal = _cart?['subtotal'] ?? total;
    final whatsapp = _config?['whatsapp_numero']?.toString() ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(title: const Text('Carrito')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : items.isEmpty
          ? StorefrontEmptyState(
              icon: Icons.shopping_cart_outlined,
              title: 'Tu carrito está vacío',
              subtitle:
                  'Agrega productos y vuelve aquí para confirmar el pedido.',
              actionLabel: 'Seguir comprando',
              onAction: () => Navigator.pop(context),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ...items.map((item) {
                  final row = Map<String, dynamic>.from(item as Map);
                  return _CartItemCard(
                    item: row,
                    onRemove: () => _removeItem(row['id'].toString()),
                    onUpdateQuantity: (quantity) =>
                        _updateQuantity(row['id'].toString(), quantity),
                  );
                }),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: [
                      _PriceRow(label: 'Subtotal', value: subtotal.toString()),
                      const SizedBox(height: 8),
                      const _PriceRow(
                        label: 'Delivery',
                        value: 'Se calcula en checkout',
                      ),
                      const Divider(height: 24),
                      _PriceRow(
                        label: 'Total',
                        value: total.toString(),
                        strong: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => Navigator.pushNamed(
                    context,
                    '/tienda/${widget.slug}/checkout',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: primaryColor,
                    minimumSize: const Size(double.infinity, 54),
                  ),
                  icon: const Icon(Icons.shopping_bag_outlined),
                  label: const Text('Finalizar pedido'),
                ),
                if (whatsapp.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _sendWhatsAppCart,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 54),
                    ),
                    icon: const Icon(
                      Icons.chat_rounded,
                      color: Color(0xFF25D366),
                    ),
                    label: const Text('Pedir por WhatsApp'),
                  ),
                ],
              ],
            ),
    );
  }
}

class _CartItemCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final Function(int) onUpdateQuantity;
  final VoidCallback onRemove;

  const _CartItemCard({
    required this.item,
    required this.onUpdateQuantity,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final quantity = int.tryParse(item['cantidad']?.toString() ?? '1') ?? 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 84,
              height: 84,
              color: const Color(0xFFF4F7FB),
              child:
                  item['imagen_url'] != null &&
                      item['imagen_url'].toString().trim().isNotEmpty
                  ? Image.network(
                      item['imagen_url'].toString(),
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.image_outlined,
                        color: Color(0xFFCBD5E1),
                      ),
                    )
                  : const Icon(Icons.image_outlined, color: Color(0xFFCBD5E1)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['nombre_producto']?.toString() ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '\$${item['precio_unitario']}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF475569),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _QtyButton(
                      icon: Icons.remove_rounded,
                      onTap: () => onUpdateQuantity(quantity - 1),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        '$quantity',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    _QtyButton(
                      icon: Icons.add_rounded,
                      onTap: () => onUpdateQuantity(quantity + 1),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${item['subtotal']}',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 10),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QtyButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F7FB),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final bool strong;

  const _PriceRow({
    required this.label,
    required this.value,
    this.strong = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: strong ? 17 : 14,
            fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
        Text(
          '\$$value',
          style: TextStyle(
            fontSize: strong ? 20 : 15,
            fontWeight: strong ? FontWeight.w900 : FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
