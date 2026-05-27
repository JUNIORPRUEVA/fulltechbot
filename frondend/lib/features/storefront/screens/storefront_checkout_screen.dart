import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/storefront_api_service.dart';
import '../services/storefront_helpers.dart';
import '../widgets/storefront_empty_state.dart';

class StorefrontCheckoutScreen extends StatefulWidget {
  final String slug;

  const StorefrontCheckoutScreen({super.key, required this.slug});

  @override
  State<StorefrontCheckoutScreen> createState() =>
      _StorefrontCheckoutScreenState();
}

class _StorefrontCheckoutScreenState extends State<StorefrontCheckoutScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreCtrl = TextEditingController();
  final TextEditingController _telefonoCtrl = TextEditingController();
  final TextEditingController _direccionCtrl = TextEditingController();
  final TextEditingController _ciudadCtrl = TextEditingController();
  final TextEditingController _sectorCtrl = TextEditingController();
  final TextEditingController _notasCtrl = TextEditingController();

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

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _processing = true);

    try {
      if (_metodoPago == 'paypal' && (_config?['permitir_paypal'] != true)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'PayPal no está configurado. Usa WhatsApp o pedido pendiente.',
            ),
          ),
        );
        setState(() => _metodoPago = 'whatsapp');
      }

      final response = await StorefrontApiService.checkout(
        widget.slug,
        _sessionId,
        telefonoCliente: _telefonoCtrl.text.trim(),
        nombreCliente: _nombreCtrl.text.trim(),
        direccion: _direccionCtrl.text.trim(),
        ciudad: _ciudadCtrl.text.trim(),
        sector: _sectorCtrl.text.trim(),
        metodoEntrega: _metodoEntrega,
        metodoPago: _metodoPago,
        notas: _notasCtrl.text.trim(),
      );

      if (!mounted) return;
      if (response['ok'] == true) {
        Navigator.pushReplacementNamed(
          context,
          '/tienda/${widget.slug}/exito',
          arguments: response['data'],
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response['message']?.toString() ?? 'No se pudo procesar',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _checkoutByWhatsApp() async {
    final response = await StorefrontApiService.whatsappOrder(
      widget.slug,
      _sessionId,
      nombreCliente: _nombreCtrl.text.trim().isEmpty
          ? null
          : _nombreCtrl.text.trim(),
      telefonoCliente: _telefonoCtrl.text.trim().isEmpty
          ? null
          : _telefonoCtrl.text.trim(),
      direccion: _direccionCtrl.text.trim().isEmpty
          ? null
          : _direccionCtrl.text.trim(),
      ciudad: _ciudadCtrl.text.trim().isEmpty ? null : _ciudadCtrl.text.trim(),
      sector: _sectorCtrl.text.trim().isEmpty ? null : _sectorCtrl.text.trim(),
      metodoEntrega: _metodoEntrega,
      notas: _notasCtrl.text.trim().isEmpty ? null : _notasCtrl.text.trim(),
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

  Color _getColor(String hex) {
    var normalized = hex.replaceAll('#', '');
    if (normalized.length == 6) normalized = 'FF$normalized';
    return Color(int.parse(normalized, radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Checkout')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final items = List<dynamic>.from(_cart?['items'] as List? ?? const []);
    if (items.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Checkout')),
        body: StorefrontEmptyState(
          icon: Icons.shopping_cart_outlined,
          title: 'No hay productos en el carrito',
          subtitle: 'Agrega productos antes de finalizar la compra.',
          actionLabel: 'Volver a la tienda',
          onAction: () => Navigator.pop(context),
        ),
      );
    }

    final primaryColor = _getColor(
      _config?['color_principal']?.toString() ?? '#0F172A',
    );
    final allowWhatsapp = _config?['permitir_whatsapp'] == true;
    final allowPaypal = _config?['permitir_paypal'] == true;
    final allowRetiro = _config?['permitir_retiro_tienda'] == true;
    final allowDelivery = _config?['permitir_delivery'] == true;
    final total = _cart?['total'] ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(title: const Text('Checkout')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _CardSection(
              title: 'Resumen del pedido',
              child: Column(
                children: [
                  ...items.map((item) {
                    final row = Map<String, dynamic>.from(item as Map);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${row['nombre_producto']} x${row['cantidad']}',
                              style: const TextStyle(color: Color(0xFF475569)),
                            ),
                          ),
                          Text(
                            '\$${row['subtotal']}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    );
                  }),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: primaryColor,
                        ),
                      ),
                      Text(
                        '\$$total',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _CardSection(
              title: 'Tus datos',
              child: Column(
                children: [
                  TextFormField(
                    controller: _nombreCtrl,
                    decoration: const InputDecoration(labelText: 'Nombre *'),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Requerido'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _telefonoCtrl,
                    decoration: const InputDecoration(labelText: 'Teléfono *'),
                    keyboardType: TextInputType.phone,
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Requerido'
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _CardSection(
              title: 'Entrega',
              child: Column(
                children: [
                  if (allowRetiro)
                    RadioListTile<String>(
                      value: 'retiro_tienda',
                      groupValue: _metodoEntrega,
                      onChanged: (value) => setState(
                        () => _metodoEntrega = value ?? 'retiro_tienda',
                      ),
                      title: const Text('Retiro en tienda'),
                    ),
                  if (allowDelivery)
                    RadioListTile<String>(
                      value: 'delivery',
                      groupValue: _metodoEntrega,
                      onChanged: (value) =>
                          setState(() => _metodoEntrega = value ?? 'delivery'),
                      title: const Text('Delivery'),
                    ),
                  if (_metodoEntrega == 'delivery') ...[
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _direccionCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Dirección *',
                      ),
                      validator: (value) =>
                          _metodoEntrega == 'delivery' &&
                              (value == null || value.trim().isEmpty)
                          ? 'Requerido'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _ciudadCtrl,
                      decoration: const InputDecoration(labelText: 'Ciudad'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _sectorCtrl,
                      decoration: const InputDecoration(labelText: 'Sector'),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            _CardSection(
              title: 'Pago',
              child: Column(
                children: [
                  if (allowWhatsapp)
                    RadioListTile<String>(
                      value: 'whatsapp',
                      groupValue: _metodoPago,
                      onChanged: (value) =>
                          setState(() => _metodoPago = value ?? 'whatsapp'),
                      title: const Text('WhatsApp / pago coordinado'),
                    ),
                  RadioListTile<String>(
                    value: 'pendiente',
                    groupValue: _metodoPago,
                    onChanged: (value) =>
                        setState(() => _metodoPago = value ?? 'pendiente'),
                    title: const Text('Pedido pendiente'),
                  ),
                  if (allowPaypal)
                    RadioListTile<String>(
                      value: 'paypal',
                      groupValue: _metodoPago,
                      onChanged: (value) =>
                          setState(() => _metodoPago = value ?? 'paypal'),
                      title: const Text('PayPal'),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _CardSection(
              title: 'Notas',
              child: TextFormField(
                controller: _notasCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Instrucciones de entrega, referencia, etc.',
                ),
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _processing ? null : _submitOrder,
              style: FilledButton.styleFrom(
                backgroundColor: primaryColor,
                minimumSize: const Size(double.infinity, 56),
              ),
              icon: _processing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_circle_outline),
              label: Text(_processing ? 'Procesando...' : 'Confirmar pedido'),
            ),
            if (allowWhatsapp) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _checkoutByWhatsApp,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 54),
                ),
                icon: const Icon(Icons.chat_rounded),
                label: const Text('Enviar por WhatsApp'),
              ),
            ],
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

class _CardSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _CardSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
