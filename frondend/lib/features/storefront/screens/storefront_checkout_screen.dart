import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/storefront_api_service.dart';

class StorefrontCheckoutScreen extends StatefulWidget {
  final String slug;
  const StorefrontCheckoutScreen({super.key, required this.slug});

  @override
  State<StorefrontCheckoutScreen> createState() => _StorefrontCheckoutScreenState();
}

class _StorefrontCheckoutScreenState extends State<StorefrontCheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();
  final _ciudadCtrl = TextEditingController();
  final _sectorCtrl = TextEditingController();
  final _notasCtrl = TextEditingController();

  Map<String, dynamic>? _config;
  Map<String, dynamic>? _cart;
  bool _loading = true;
  bool _processing = false;
  String _sessionId = '';
  String _metodoEntrega = 'retiro_tienda';
  String _metodoPago = 'whatsapp';

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
    setState(() { _loading = true; });
    try {
      final configRes = await StorefrontApiService.getConfig(widget.slug);
      final cartRes = await StorefrontApiService.getCart(widget.slug, _sessionId);

      setState(() {
        _config = configRes['data'];
        _cart = cartRes['ok'] == true ? cartRes['data'] : null;
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

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _processing = true);

    try {
      final res = await StorefrontApiService.checkout(
        widget.slug, _sessionId,
        telefonoCliente: _telefonoCtrl.text.trim(),
        nombreCliente: _nombreCtrl.text.trim(),
        direccion: _direccionCtrl.text.trim(),
        ciudad: _ciudadCtrl.text.trim(),
        sector: _sectorCtrl.text.trim(),
        metodoEntrega: _metodoEntrega,
        metodoPago: _metodoPago,
        notas: _notasCtrl.text.trim(),
      );

      if (res['ok'] == true) {
        if (mounted) {
          Navigator.pushReplacementNamed(
            context,
            '/tienda/${widget.slug}/exito',
            arguments: res['data'],
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['message'] ?? 'Error al procesar pedido'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(title: const Text('Checkout')),
        body: const Center(child: CircularProgressIndicator(strokeWidth: 3)),
      );
    }

    final config = _config ?? {};
    final primaryColor = _getColor(config['color_principal'] ?? '#0F172A');
    final items = _cart != null ? (_cart!['items'] as List<dynamic>?) ?? [] : [];
    final total = _cart?['total'] ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Checkout'),
        centerTitle: false,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Resumen del pedido
            _buildSectionCard(
              title: 'Resumen del pedido',
              icon: Icons.receipt_long_outlined,
              primaryColor: primaryColor,
              child: Column(
                children: [
                  ...items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${item['nombre_producto']} x${item['cantidad']}',
                            style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                          ),
                        ),
                        Text(
                          '\$${item['subtotal']}',
                          style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF111827)),
                        ),
                      ],
                    ),
                  )),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: primaryColor),
                      ),
                      Text(
                        '\$$total',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: primaryColor),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Datos del cliente
            _buildSectionCard(
              title: 'Datos del cliente',
              icon: Icons.person_outline,
              primaryColor: primaryColor,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nombreCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nombre completo *',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _telefonoCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Teléfono *',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Método de entrega
            _buildSectionCard(
              title: 'Método de entrega',
              icon: Icons.local_shipping_outlined,
              primaryColor: primaryColor,
              child: Column(
                children: [
                  if (config['permitir_retiro_tienda'] == true)
                    _buildRadioTile(
                      title: 'Retiro en tienda',
                      subtitle: 'Sin costo adicional',
                      value: 'retiro_tienda',
                      groupValue: _metodoEntrega,
                      icon: Icons.store_outlined,
                      primaryColor: primaryColor,
                      onChanged: (v) => setState(() => _metodoEntrega = v!),
                    ),
                  if (config['permitir_delivery'] == true)
                    _buildRadioTile(
                      title: 'Delivery',
                      subtitle: 'Con costo adicional',
                      value: 'delivery',
                      groupValue: _metodoEntrega,
                      icon: Icons.delivery_dining_outlined,
                      primaryColor: primaryColor,
                      onChanged: (v) => setState(() => _metodoEntrega = v!),
                    ),
                  if (_metodoEntrega == 'delivery') ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _direccionCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Dirección *',
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                      validator: (v) => _metodoEntrega == 'delivery' && (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _ciudadCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Ciudad',
                        prefixIcon: Icon(Icons.location_city_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _sectorCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Sector',
                        prefixIcon: Icon(Icons.map_outlined),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Método de pago
            _buildSectionCard(
              title: 'Método de pago',
              icon: Icons.payment_outlined,
              primaryColor: primaryColor,
              child: Column(
                children: [
                  _buildRadioTile(
                    title: 'WhatsApp - Pagar al recibir',
                    subtitle: 'Te contactaremos para coordinar el pago',
                    value: 'whatsapp',
                    groupValue: _metodoPago,
                    icon: Icons.chat_rounded,
                    primaryColor: primaryColor,
                    onChanged: (v) => setState(() => _metodoPago = v!),
                  ),
                  if (config['permitir_paypal'] == true)
                    _buildRadioTile(
                      title: 'PayPal',
                      subtitle: 'Pago seguro online',
                      value: 'paypal',
                      groupValue: _metodoPago,
                      icon: Icons.account_balance_wallet_outlined,
                      primaryColor: primaryColor,
                      onChanged: (v) => setState(() => _metodoPago = v!),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Notas
            _buildSectionCard(
              title: 'Notas adicionales',
              icon: Icons.notes_rounded,
              primaryColor: primaryColor,
              child: TextFormField(
                controller: _notasCtrl,
                decoration: const InputDecoration(
                  hintText: 'Ej: Prefiero que llamen antes de enviar...',
                ),
                maxLines: 3,
              ),
            ),

            const SizedBox(height: 24),

            // Botón confirmar
            FilledButton.icon(
              onPressed: _processing ? null : _submitOrder,
              icon: _processing
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check_circle_outline),
              label: Text(_processing ? 'Procesando...' : 'Confirmar pedido'),
              style: FilledButton.styleFrom(
                backgroundColor: primaryColor,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color primaryColor,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: primaryColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: primaryColor),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildRadioTile({
    required String title,
    required String subtitle,
    required String value,
    required String groupValue,
    required IconData icon,
    required Color primaryColor,
    required ValueChanged<String?> onChanged,
  }) {
    final isSelected = value == groupValue;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected ? primaryColor.withValues(alpha: 0.04) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? primaryColor.withValues(alpha: 0.2) : const Color(0xFFE5E7EB),
        ),
      ),
      child: RadioListTile<String>(
        title: Row(
          children: [
            Icon(icon, size: 18, color: isSelected ? primaryColor : const Color(0xFF6B7280)),
            const SizedBox(width: 8),
            Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          ],
        ),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        value: value,
        groupValue: groupValue,
        onChanged: onChanged,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        activeColor: primaryColor,
        dense: true,
      ),
    );
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _telefonoCtrl.dispose();
    _direccionCtrl.dispose();
    _ciudadCtrl.dispose();
    _sectorCtrl.dispose();
    _notasCtrl.dispose();
    super.dispose();
  }
}
