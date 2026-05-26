import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
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
        appBar: AppBar(title: const Text('Checkout')),
        body: const Center(child: CircularProgressIndicator(strokeWidth: 3)),
      );
    }

    final config = _config ?? {};
    final primaryColor = _getColor(config['color_principal'] ?? '#0F172A');
    final secondaryColor = _getColor(config['color_secundario'] ?? '#2563EB');
    final items = _cart != null ? (_cart!['items'] as List<dynamic>?) ?? [] : [];
    final total = _cart?['total'] ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        title: const Text('Checkout'),
        centerTitle: false,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Resumen del carrito
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Resumen del pedido', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: primaryColor)),
                  const SizedBox(height: 12),
                  ...items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text('${item['nombre_producto']} x${item['cantidad']}',
                            style: const TextStyle(fontSize: 14)),
                        ),
                        Text('\$${item['subtotal']}', style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  )),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: primaryColor)),
                      Text('\$$total', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: primaryColor)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Datos del cliente
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Datos del cliente', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: primaryColor)),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nombreCtrl,
                    decoration: const InputDecoration(labelText: 'Nombre completo *', prefixIcon: Icon(Icons.person_outline)),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _telefonoCtrl,
                    decoration: const InputDecoration(labelText: 'Teléfono *', prefixIcon: Icon(Icons.phone_outlined)),
                    keyboardType: TextInputType.phone,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Método de entrega
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Método de entrega', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: primaryColor)),
                  const SizedBox(height: 12),
                  if (config['permitir_retiro_tienda'] == true)
                    RadioListTile(
                      title: const Text('Retiro en tienda'),
                      value: 'retiro_tienda',
                      groupValue: _metodoEntrega,
                      onChanged: (v) => setState(() => _metodoEntrega = v!),
                      contentPadding: EdgeInsets.zero,
                    ),
                  if (config['permitir_delivery'] == true)
                    RadioListTile(
                      title: const Text('Delivery'),
                      subtitle: const Text('Con costo adicional'),
                      value: 'delivery',
                      groupValue: _metodoEntrega,
                      onChanged: (v) => setState(() => _metodoEntrega = v!),
                      contentPadding: EdgeInsets.zero,
                    ),

                  // Dirección para delivery
                  if (_metodoEntrega == 'delivery') ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _direccionCtrl,
                      decoration: const InputDecoration(labelText: 'Dirección *', prefixIcon: Icon(Icons.location_on_outlined)),
                      validator: (v) => _metodoEntrega == 'delivery' && (v == null || v.trim().isEmpty) ? 'Requerido para delivery' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _ciudadCtrl,
                      decoration: const InputDecoration(labelText: 'Ciudad', prefixIcon: Icon(Icons.location_city_outlined)),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _sectorCtrl,
                      decoration: const InputDecoration(labelText: 'Sector', prefixIcon: Icon(Icons.map_outlined)),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Método de pago
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Método de pago', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: primaryColor)),
                  const SizedBox(height: 12),
                  RadioListTile(
                    title: const Text('WhatsApp - Pagar al recibir'),
                    subtitle: const Text('Te contactaremos para coordinar el pago'),
                    value: 'whatsapp',
                    groupValue: _metodoPago,
                    onChanged: (v) => setState(() => _metodoPago = v!),
                    contentPadding: EdgeInsets.zero,
                  ),
                  if (config['permitir_paypal'] == true)
                    RadioListTile(
                      title: const Text('PayPal'),
                      subtitle: const Text('Pago seguro online'),
                      value: 'paypal',
                      groupValue: _metodoPago,
                      onChanged: (v) => setState(() => _metodoPago = v!),
                      contentPadding: EdgeInsets.zero,
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Notas
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Notas adicionales', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: primaryColor)),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notasCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Ej: Prefiero que llamen antes de enviar...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ],
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
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
