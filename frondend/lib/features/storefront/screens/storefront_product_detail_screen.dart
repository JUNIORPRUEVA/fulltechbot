import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/storefront_api_service.dart';

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
      final configRes = await StorefrontApiService.getConfig(widget.slug);
      final productRes = await StorefrontApiService.getProduct(widget.slug, widget.productId);

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

      if (res['ok'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$_quantity x ${_product!['titulo']} agregado al carrito'),
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: 'Ver carrito',
                onPressed: () => Navigator.pushNamed(context, '/tienda/${widget.slug}/carrito'),
              ),
            ),
          );
        }
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
        appBar: AppBar(title: const Text('Producto')),
        body: const Center(child: CircularProgressIndicator(strokeWidth: 3)),
      );
    }

    if (_error != null || _product == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Producto')),
        body: Center(child: Text(_error ?? 'Producto no encontrado')),
      );
    }

    final p = _product!;
    final config = _config ?? {};
    final primaryColor = _getColor(config['color_principal'] ?? '#0F172A');
    final secondaryColor = _getColor(config['color_secundario'] ?? '#2563EB');
    final precio = p['precio_oferta_web'] ?? p['precio_oferta'] ?? p['precio'] ?? 0;
    final precioOriginal = (p['precio_oferta_web'] != null || p['precio_oferta'] != null) ? p['precio'] : null;
    final tieneOferta = precioOriginal != null && precioOriginal > precio;
    final imagenes = [
      p['imagen_destacada_url'],
      p['imagen1'],
      p['imagen2'],
      p['imagen3'],
    ].where((i) => i != null && i.toString().isNotEmpty).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: imagenes.isNotEmpty
                  ? Stack(
                      children: [
                        PageView.builder(
                          itemCount: imagenes.length,
                          onPageChanged: (i) => setState(() => _currentImageIndex = i),
                          itemBuilder: (_, i) => Container(
                            color: Colors.grey.shade100,
                            child: Image.network(imagenes[i], fit: BoxFit.cover, width: double.infinity,
                              errorBuilder: (_, __, ___) => Center(
                                child: Icon(Icons.image_outlined, size: 64, color: Colors.grey.shade300),
                              )),
                          ),
                        ),
                        if (imagenes.length > 1)
                          Positioned(
                            bottom: 16,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(imagenes.length, (i) => Container(
                                width: 8, height: 8,
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: i == _currentImageIndex ? Colors.white : Colors.white.withValues(alpha: 0.5),
                                ),
                              )),
                            ),
                          ),
                      ],
                    )
                  : Container(
                      color: Colors.grey.shade100,
                      child: Center(child: Icon(Icons.image_outlined, size: 64, color: Colors.grey.shade300)),
                    ),
            ),
          ),

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
                            child: Text(p['etiqueta'], style: TextStyle(color: secondaryColor, fontWeight: FontWeight.w600, fontSize: 12)),
                          ),
                        if (p['etiqueta'] != null) const SizedBox(height: 8),

                        // Título
                        Text(p['titulo'] ?? '', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, height: 1.2)),

                        const SizedBox(height: 12),

                        // Precio
                        Row(
                          children: [
                            Text('\$$precio', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: primaryColor)),
                            if (tieneOferta) ...[
                              const SizedBox(width: 12),
                              Text('\$$precioOriginal', style: TextStyle(color: Colors.grey.shade400, fontSize: 18, decoration: TextDecoration.lineThrough)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(6)),
                                child: Text('-${((1 - precio / precioOriginal) * 100).round()}%',
                                  style: TextStyle(color: Colors.red.shade600, fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ],
                        ),

                        // Stock
                        if (p['stock'] != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              children: [
                                Icon(Icons.inventory_2_outlined, size: 16, color: Colors.grey.shade500),
                                const SizedBox(width: 4),
                                Text('Stock: ${p['stock']}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                              ],
                            ),
                          ),

                        // Instalación
                        if (p['requiere_instalacion'] == true || p['instalacion_incluida'] == true)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                Icon(Icons.build_outlined, size: 16, color: Colors.grey.shade500),
                                const SizedBox(width: 4),
                                Text(
                                  p['instalacion_incluida'] == true ? 'Instalación incluida' : 'Requiere instalación',
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Cantidad
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      children: [
                        Text('Cantidad:', style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 12),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove, size: 20),
                                onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                              ),
                              Text('$_quantity', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                              IconButton(
                                icon: const Icon(Icons.add, size: 20),
                                onPressed: () => setState(() => _quantity++),
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
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Descripción', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: primaryColor)),
                          const SizedBox(height: 8),
                          Text(
                            p['descripcion_web'] ?? p['descripcion'] ?? '',
                            style: TextStyle(color: Colors.grey.shade700, fontSize: 14, height: 1.5),
                          ),
                        ],
                      ),
                    ),

                  // Información adicional
                  if (p['informacion'] != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Información adicional', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: primaryColor)),
                          const SizedBox(height: 8),
                          Text(p['informacion'], style: TextStyle(color: Colors.grey.shade700, fontSize: 14, height: 1.5)),
                        ],
                      ),
                    ),

                  // Incluye
                  if (p['incluye'] != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Incluye', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: primaryColor)),
                          const SizedBox(height: 8),
                          Text(p['incluye'], style: TextStyle(color: Colors.grey.shade700, fontSize: 14, height: 1.5)),
                        ],
                      ),
                    ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),

      // Botones inferiores
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -2))],
        ),
        child: SafeArea(
          child: Row(
            children: [
              // WhatsApp
              if (config['whatsapp_numero'] != null && p['permitir_whatsapp'] != false)
                Container(
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF25D366),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.chat, color: Colors.white),
                    onPressed: () {
                      final num = config['whatsapp_numero'].toString().replaceAll(RegExp(r'[^\d]'), '');
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
                    icon: const Icon(Icons.shopping_cart_outlined),
                    label: const Text('Agregar al carrito'),
                    style: FilledButton.styleFrom(
                      backgroundColor: secondaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              if (p['permitir_compra_online'] != false) const SizedBox(width: 12),
              // Comprar ahora
              if (p['permitir_compra_online'] != false)
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _buyNow,
                    icon: const Icon(Icons.bolt),
                    label: const Text('Comprar'),
                    style: FilledButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
