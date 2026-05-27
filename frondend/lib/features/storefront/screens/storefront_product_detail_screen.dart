import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/storefront_api_service.dart';
import '../widgets/storefront_price_widget.dart';
import '../widgets/storefront_product_card.dart';
import '../widgets/storefront_error_state.dart';

class StorefrontProductDetailScreen extends StatefulWidget {
  final String slug;
  final String productId;
  const StorefrontProductDetailScreen({
    super.key,
    required this.slug,
    required this.productId,
  });

  @override
  State<StorefrontProductDetailScreen> createState() => _StorefrontProductDetailScreenState();
}

class _StorefrontProductDetailScreenState extends State<StorefrontProductDetailScreen> {
  Map<String, dynamic>? _product;
  Map<String, dynamic>? _config;
  List<dynamic> _relatedProducts = [];
  bool _loading = true;
  String? _error;
  int _quantity = 1;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        StorefrontApiService.getConfig(widget.slug),
        StorefrontApiService.getProduct(widget.slug, widget.productId),
        StorefrontApiService.getProducts(widget.slug, limit: 6),
      ]);

      final configRes = results[0];
      final productRes = results[1];

      if (configRes['ok'] != true || productRes['ok'] != true) {
        setState(() {
          _error = 'Error al cargar datos';
          _loading = false;
        });
        return;
      }

      setState(() {
        _config = configRes['data'];
        _product = productRes['data'];
        _relatedProducts = results[2]['products'] ?? [];
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = 'Error de conexión: $e'; _loading = false; });
    }
  }

  Color _getColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  Future<String> _getSessionId() async {
    final prefs = await SharedPreferences.getInstance();
    String? sid = prefs.getString('storefront_session_${widget.slug}');
    if (sid == null) {
      sid = '${widget.slug}_${DateTime.now().millisecondsSinceEpoch}';
      await prefs.setString('storefront_session_${widget.slug}', sid);
    }
    return sid;
  }

  Future<void> _addToCart() async {
    if (_product == null) return;
    final sessionId = await _getSessionId();
    final precio = _product!['precio_oferta_web'] ?? _product!['precio_oferta'] ?? _product!['precio'] ?? 0;

    try {
      await StorefrontApiService.createCart(widget.slug, sessionId);
      final res = await StorefrontApiService.addCartItem(
        widget.slug, sessionId,
        productoId: _product!['id'].toString(),
        nombreProducto: _product!['titulo'] ?? '',
        cantidad: _quantity,
        precioUnitario: double.tryParse(precio.toString()) ?? 0,
        imagenUrl: _product!['imagen_destacada_url'] ?? _product!['imagen1'],
      );

      if (res['ok'] == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$_quantity x ${_product!['titulo']} agregado al carrito'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            action: SnackBarAction(
              label: 'Ver carrito',
              onPressed: () => Navigator.pushNamed(context, '/tienda/${widget.slug}/carrito'),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al agregar: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _buyNow() async {
    await _addToCart();
    if (mounted) {
      Navigator.pushNamed(context, '/tienda/${widget.slug}/carrito');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(title: const Text('Producto')),
        body: const Center(child: CircularProgressIndicator(strokeWidth: 3)),
      );
    }

    if (_error != null || _product == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(title: const Text('Producto')),
        body: StorefrontErrorState(
          message: _error ?? 'Producto no encontrado',
          onRetry: _loadData,
        ),
      );
    }

    final p = _product!;
    final config = _config ?? {};
    final primaryColor = _getColor(config['color_principal'] ?? '#0F172A');
    final secondaryColor = _getColor(config['color_secundario'] ?? '#2563EB');
    final whatsapp = config['whatsapp_numero'] ?? '';
    final precio = p['precio_oferta_web'] ?? p['precio_oferta'] ?? p['precio'] ?? 0;
    final precioOriginal = (p['precio_oferta_web'] != null || p['precio_oferta'] != null) ? p['precio'] : null;
    final imagenes = [
      p['imagen_destacada_url'],
      p['imagen1'],
      p['imagen2'],
      p['imagen3'],
    ].where((i) => i != null && i.toString().isNotEmpty).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          // Galería de imágenes premium
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: imagenes.isNotEmpty
                  ? Stack(
                      children: [
                        PageView.builder(
                          itemCount: imagenes.length,
                          onPageChanged: (i) => setState(() => _currentImageIndex = i),
                          itemBuilder: (_, i) => Container(
                            color: const Color(0xFFF1F5F9),
                            child: Image.network(
                              imagenes[i],
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder: (_, __, ___) => Center(
                                child: Icon(Icons.image_outlined, size: 64, color: const Color(0xFFCBD5E1)),
                              ),
                            ),
                          ),
                        ),
                        // Indicadores modernos
                        if (imagenes.length > 1)
                          Positioned(
                            bottom: 16,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(imagenes.length, (i) => AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: i == _currentImageIndex ? 24 : 8,
                                height: 8,
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  color: i == _currentImageIndex
                                      ? secondaryColor
                                      : Colors.white.withValues(alpha: 0.5),
                                ),
                              )),
                            ),
                          ),
                        // Badge oferta
                        if (precioOriginal != null && precioOriginal > precio)
                          Positioned(
                            top: 16,
                            right: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFEF4444), Color(0xFFF87171)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '-${((1 - precio / precioOriginal) * 100).round()}%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                      ],
                    )
                  : Container(
                      color: const Color(0xFFF1F5F9),
                      child: Center(
                        child: Icon(Icons.image_outlined, size: 64, color: const Color(0xFFCBD5E1)),
                      ),
                    ),
            ),
          ),

          // Contenido del producto
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Etiqueta
                        if (p['etiqueta'] != null && p['etiqueta'].toString().isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: secondaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              p['etiqueta'],
                              style: TextStyle(color: secondaryColor, fontWeight: FontWeight.w600, fontSize: 12),
                            ),
                          ),
                        if (p['etiqueta'] != null) const SizedBox(height: 12),

                        // Título
                        Text(
                          p['titulo'] ?? '',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, height: 1.2),
                        ),

                        const SizedBox(height: 16),

                        // Precio
                        StorefrontPriceWidget(
                          precio: precio,
                          precioOriginal: precioOriginal,
                          large: true,
                          primaryColor: primaryColor,
                        ),

                        const SizedBox(height: 12),

                        // Beneficios
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (p['envio_incluido'] == true)
                              _benefitBadge(Icons.local_shipping_outlined, 'Envío gratis', const Color(0xFF10B981)),
                            if (p['requiere_instalacion'] == true || p['instalacion_incluida'] == true)
                              _benefitBadge(
                                Icons.build_outlined,
                                p['instalacion_incluida'] == true ? 'Instalación incluida' : 'Requiere instalación',
                                const Color(0xFF2563EB),
                              ),
                            if (p['garantia'] != null)
                              _benefitBadge(Icons.verified_outlined, 'Garantía: ${p['garantia']}', const Color(0xFFF59E0B)),
                            if (p['soporte_tecnico'] == true)
                              _benefitBadge(Icons.support_agent_outlined, 'Soporte técnico', const Color(0xFF8B5CF6)),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Stock
                        if (p['stock'] != null)
                          Row(
                            children: [
                              Icon(Icons.inventory_2_outlined, size: 16, color: const Color(0xFF6B7280)),
                              const SizedBox(width: 4),
                              Text(
                                'Stock: ${p['stock']}',
                                style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),

                  // Selector de cantidad
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Row(
                      children: [
                        const Text(
                          'Cantidad:',
                          style: TextStyle(
                            color: Color(0xFF111827),
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              InkWell(
                                onTap: _quantity > 1 ? () => setState(() => _quantity--) : null,
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  child: Icon(
                                    Icons.remove_rounded,
                                    size: 20,
                                    color: _quantity > 1 ? const Color(0xFF111827) : const Color(0xFFD1D5DB),
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  '$_quantity',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                                ),
                              ),
                              InkWell(
                                onTap: () => setState(() => _quantity++),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  child: const Icon(Icons.add_rounded, size: 20, color: Color(0xFF111827)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Descripción
                  if (p['descripcion_web'] != null || p['descripcion'] != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Descripción',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            p['descripcion_web'] ?? p['descripcion'] ?? '',
                            style: const TextStyle(color: Color(0xFF6B7280), fontSize: 14, height: 1.6),
                          ),
                        ],
                      ),
                    ),

                  // Información adicional
                  if (p['informacion'] != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Información adicional',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            p['informacion'],
                            style: const TextStyle(color: Color(0xFF6B7280), fontSize: 14, height: 1.6),
                          ),
                        ],
                      ),
                    ),

                  // Incluye
                  if (p['incluye'] != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Incluye',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            p['incluye'],
                            style: const TextStyle(color: Color(0xFF6B7280), fontSize: 14, height: 1.6),
                          ),
                        ],
                      ),
                    ),

                  // Productos relacionados
                  if (_relatedProducts.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                      child: Text(
                        'Productos relacionados',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: primaryColor),
                      ),
                    ),
                    SizedBox(
                      height: 300,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _relatedProducts.length,
                        itemBuilder: (context, index) => Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: SizedBox(
                            width: 180,
                            child: StorefrontProductCard(
                              product: _relatedProducts[index],
                              slug: widget.slug,
                              primaryColor: primaryColor,
                              secondaryColor: secondaryColor,
                              compact: true,
                              whatsapp: whatsapp,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),

      // Botones inferiores fijos premium
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              // WhatsApp
              if (whatsapp.isNotEmpty && p['permitir_whatsapp'] != false)
                Container(
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF25D366),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.chat_rounded, color: Colors.white),
                    onPressed: () {
                      final num = whatsapp.replaceAll(RegExp(r'[^\d]'), '');
                      final msg = 'Hola, me interesa: ${p['titulo']} (ID: ${p['id']})';
                      launchUrl(Uri.parse('https://wa.me/$num?text=${Uri.encodeComponent(msg)}'));
                    },
                  ),
                ),
              // Agregar al carrito
              if (p['permitir_compra_online'] != false)
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _addToCart,
                    icon: const Icon(Icons.shopping_cart_outlined, size: 20),
                    label: const Text('Agregar al carrito'),
                    style: FilledButton.styleFrom(
                      backgroundColor: secondaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              if (p['permitir_compra_online'] != false) const SizedBox(width: 12),
              // Comprar ahora
              if (p['permitir_compra_online'] != false)
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _buyNow,
                    icon: const Icon(Icons.bolt, size: 20),
                    label: const Text('Comprar'),
                    style: FilledButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _benefitBadge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
