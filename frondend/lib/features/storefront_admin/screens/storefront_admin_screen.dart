import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../bots/providers/bot_provider.dart';
import '../../storefront/services/storefront_api_service.dart';
import '../../../core/constants/api_config.dart';

class StorefrontAdminScreen extends StatefulWidget {
  const StorefrontAdminScreen({super.key});

  @override
  State<StorefrontAdminScreen> createState() => _StorefrontAdminScreenState();
}

class _StorefrontAdminScreenState extends State<StorefrontAdminScreen> {
  Map<String, dynamic>? _config;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  // Controladores
  final _nombreCtrl = TextEditingController();
  final _slugCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  final _logoUrlCtrl = TextEditingController();
  final _whatsappCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();
  final _horarioCtrl = TextEditingController();
  final _mensajePrincipalCtrl = TextEditingController();
  final _mensajeSecundarioCtrl = TextEditingController();
  final _colorPrincipalCtrl = TextEditingController();
  final _colorSecundarioCtrl = TextEditingController();

  bool _activo = true;
  bool _permitirPaypal = false;
  bool _permitirWhatsapp = true;
  bool _permitirRetiroTienda = true;
  bool _permitirDelivery = false;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  String get _botId {
    final botProvider = context.read<BotProvider>();
    return botProvider.botSeleccionado?.id ?? '';
  }

  Future<void> _loadConfig() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await StorefrontApiService.getAdminConfig(_botId);
      if (res['ok'] == true && res['data'] != null) {
        final c = res['data'];
        _nombreCtrl.text = c['nombre_tienda'] ?? '';
        _slugCtrl.text = c['slug'] ?? '';
        _descripcionCtrl.text = c['descripcion'] ?? '';
        _logoUrlCtrl.text = c['logo_url'] ?? '';
        _whatsappCtrl.text = c['whatsapp_numero'] ?? '';
        _telefonoCtrl.text = c['telefono_contacto'] ?? '';
        _direccionCtrl.text = c['direccion'] ?? '';
        _horarioCtrl.text = c['horario'] ?? '';
        _mensajePrincipalCtrl.text = c['mensaje_principal'] ?? '';
        _mensajeSecundarioCtrl.text = c['mensaje_secundario'] ?? '';
        _colorPrincipalCtrl.text = c['color_principal'] ?? '#0F172A';
        _colorSecundarioCtrl.text = c['color_secundario'] ?? '#2563EB';
        _activo = c['activo'] ?? true;
        _permitirPaypal = c['permitir_paypal'] ?? false;
        _permitirWhatsapp = c['permitir_whatsapp'] ?? true;
        _permitirRetiroTienda = c['permitir_retiro_tienda'] ?? true;
        _permitirDelivery = c['permitir_delivery'] ?? false;
        _config = c;
      }
    } catch (e) {
      _error = 'Error: $e';
    }
    setState(() => _loading = false);
  }

  Future<void> _saveConfig() async {
    setState(() => _saving = true);
    try {
      final data = {
        'nombre_tienda': _nombreCtrl.text.trim(),
        'slug': _slugCtrl.text.trim(),
        'descripcion': _descripcionCtrl.text.trim(),
        'logo_url': _logoUrlCtrl.text.trim(),
        'whatsapp_numero': _whatsappCtrl.text.trim(),
        'telefono_contacto': _telefonoCtrl.text.trim(),
        'direccion': _direccionCtrl.text.trim(),
        'horario': _horarioCtrl.text.trim(),
        'mensaje_principal': _mensajePrincipalCtrl.text.trim(),
        'mensaje_secundario': _mensajeSecundarioCtrl.text.trim(),
        'color_principal': _colorPrincipalCtrl.text.trim(),
        'color_secundario': _colorSecundarioCtrl.text.trim(),
        'activo': _activo,
        'permitir_paypal': _permitirPaypal,
        'permitir_whatsapp': _permitirWhatsapp,
        'permitir_retiro_tienda': _permitirRetiroTienda,
        'permitir_delivery': _permitirDelivery,
      };

      final res = await StorefrontApiService.updateAdminConfig(_botId, data);
      if (res['ok'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Configuración guardada'), backgroundColor: Colors.green),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['message'] ?? 'Error al guardar'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
    setState(() => _saving = false);
  }

  /// Construye la URL pública de la tienda
  String _getStoreUrl() {
    final slug = _slugCtrl.text.trim().isNotEmpty ? _slugCtrl.text.trim() : 'fulltech';
    // Detectar si es web
    final isWeb = identical(0, 0.0); // En web esto es true
    if (isWeb) {
      // En web, navegar dentro de la misma app
      return '/tienda/$slug';
    }
    // En desktop/mobile, abrir en navegador
    return '${ApiConfig.baseUrl}/tienda/$slug';
  }

  /// Abre la tienda online
  Future<void> _openStore() async {
    final url = _getStoreUrl();
    final isWeb = identical(0, 0.0);
    if (isWeb) {
      // En web, navegar dentro de la app
      if (mounted) {
        Navigator.pushNamed(context, url);
      }
    } else {
      // En desktop/mobile, abrir en navegador
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  /// Copia el enlace al portapapeles
  Future<void> _copyStoreLink() async {
    final url = _getStoreUrl();
    await Clipboard.setData(ClipboardData(text: url));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Enlace copiado al portapapeles'),
            ],
          ),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Administrar Tienda'),
          centerTitle: false,
          actions: [
            // Botón Copiar enlace
            IconButton(
              onPressed: _copyStoreLink,
              icon: const Icon(Icons.link, size: 20),
              tooltip: 'Copiar enlace',
            ),
            // Botón Ver tienda online
            FilledButton.icon(
              onPressed: _openStore,
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('Ver tienda online', style: TextStyle(fontSize: 13)),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(width: 8),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Configuración'),
              Tab(text: 'Banners'),
              Tab(text: 'Productos'),
              Tab(text: 'Carritos'),
              Tab(text: 'Pagos'),
            ],
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator(strokeWidth: 3))
            : TabBarView(
                children: [
                  _buildConfigTab(),
                  const _BannersTab(),
                  const _ProductSettingsTab(),
                  const _CartsTab(),
                  const _PaymentsTab(),
                ],
              ),
      ),
    );
  }

  Widget _buildConfigTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Información general
          _sectionTitle('Información de la tienda'),
          const SizedBox(height: 12),
          TextField(controller: _nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre de la tienda *', prefixIcon: Icon(Icons.store))),
          const SizedBox(height: 12),
          TextField(controller: _slugCtrl, decoration: const InputDecoration(labelText: 'Slug (URL única) *', prefixIcon: Icon(Icons.link), helperText: 'Ej: mi-tienda')),
          const SizedBox(height: 12),
          TextField(controller: _descripcionCtrl, decoration: const InputDecoration(labelText: 'Descripción', prefixIcon: Icon(Icons.description)), maxLines: 3),
          const SizedBox(height: 12),
          TextField(controller: _logoUrlCtrl, decoration: const InputDecoration(labelText: 'URL del logo', prefixIcon: Icon(Icons.image))),

          const SizedBox(height: 24),
          _sectionTitle('Colores'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _colorPrincipalCtrl,
                  decoration: const InputDecoration(labelText: 'Color principal', prefixIcon: Icon(Icons.color_lens), helperText: 'Ej: #0F172A'),
                ),
              ),
              const SizedBox(width: 12),
              Container(width: 40, height: 40, decoration: BoxDecoration(
                color: _parseColor(_colorPrincipalCtrl.text),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              )),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _colorSecundarioCtrl,
                  decoration: const InputDecoration(labelText: 'Color secundario', prefixIcon: Icon(Icons.color_lens), helperText: 'Ej: #2563EB'),
                ),
              ),
              const SizedBox(width: 12),
              Container(width: 40, height: 40, decoration: BoxDecoration(
                color: _parseColor(_colorSecundarioCtrl.text),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              )),
            ],
          ),

          const SizedBox(height: 24),
          _sectionTitle('Contacto'),
          const SizedBox(height: 12),
          TextField(controller: _whatsappCtrl, decoration: const InputDecoration(labelText: 'Número WhatsApp', prefixIcon: Icon(Icons.chat), helperText: 'Ej: 18091234567')),
          const SizedBox(height: 12),
          TextField(controller: _telefonoCtrl, decoration: const InputDecoration(labelText: 'Teléfono de contacto', prefixIcon: Icon(Icons.phone))),
          const SizedBox(height: 12),
          TextField(controller: _direccionCtrl, decoration: const InputDecoration(labelText: 'Dirección', prefixIcon: Icon(Icons.location_on))),
          const SizedBox(height: 12),
          TextField(controller: _horarioCtrl, decoration: const InputDecoration(labelText: 'Horario', prefixIcon: Icon(Icons.access_time))),

          const SizedBox(height: 24),
          _sectionTitle('Mensajes'),
          const SizedBox(height: 12),
          TextField(controller: _mensajePrincipalCtrl, decoration: const InputDecoration(labelText: 'Mensaje principal', prefixIcon: Icon(Icons.format_quote))),
          const SizedBox(height: 12),
          TextField(controller: _mensajeSecundarioCtrl, decoration: const InputDecoration(labelText: 'Mensaje secundario', prefixIcon: Icon(Icons.format_quote))),

          const SizedBox(height: 24),
          _sectionTitle('Opciones'),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('Tienda activa'),
            value: _activo,
            onChanged: (v) => setState(() => _activo = v),
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            title: const Text('Permitir PayPal'),
            value: _permitirPaypal,
            onChanged: (v) => setState(() => _permitirPaypal = v),
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            title: const Text('Permitir WhatsApp'),
            value: _permitirWhatsapp,
            onChanged: (v) => setState(() => _permitirWhatsapp = v),
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            title: const Text('Permitir retiro en tienda'),
            value: _permitirRetiroTienda,
            onChanged: (v) => setState(() => _permitirRetiroTienda = v),
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            title: const Text('Permitir delivery'),
            value: _permitirDelivery,
            onChanged: (v) => setState(() => _permitirDelivery = v),
            contentPadding: EdgeInsets.zero,
          ),

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _saving ? null : _saveConfig,
              icon: _saving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save),
              label: Text(_saving ? 'Guardando...' : 'Guardar configuración'),
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700));
  }

  Color _parseColor(String hex) {
    try {
      hex = hex.replaceAll('#', '');
      if (hex.length == 6) hex = 'FF$hex';
      return Color(int.parse(hex, radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _slugCtrl.dispose();
    _descripcionCtrl.dispose();
    _logoUrlCtrl.dispose();
    _whatsappCtrl.dispose();
    _telefonoCtrl.dispose();
    _direccionCtrl.dispose();
    _horarioCtrl.dispose();
    _mensajePrincipalCtrl.dispose();
    _mensajeSecundarioCtrl.dispose();
    _colorPrincipalCtrl.dispose();
    _colorSecundarioCtrl.dispose();
    super.dispose();
  }
}

// ============================================
// TAB: BANNERS
// ============================================
class _BannersTab extends StatefulWidget {
  const _BannersTab();
  @override
  State<_BannersTab> createState() => _BannersTabState();
}

class _BannersTabState extends State<_BannersTab> {
  List<dynamic> _banners = [];
  bool _loading = true;

  String get _botId => context.read<BotProvider>().botSeleccionado?.id ?? '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await StorefrontApiService.getAdminBanners(_botId);
      setState(() {
        _banners = res['data'] ?? [];
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _createOrEdit(Map<String, dynamic>? banner) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => _BannerFormDialog(banner: banner),
    );
    if (result != null) {
      if (banner == null) {
        await StorefrontApiService.createAdminBanner(_botId, result);
      } else {
        await StorefrontApiService.updateAdminBanner(_botId, banner['id'], result);
      }
      _load();
    }
  }

  Future<void> _delete(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar banner'),
        content: const Text('¿Estás seguro?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirm == true) {
      await StorefrontApiService.deleteAdminBanner(_botId, id);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(strokeWidth: 3));

    return Scaffold(
      body: _banners.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.view_carousel_outlined, size: 48, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Text('Sin banners', style: TextStyle(color: Colors.grey.shade500)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _banners.length,
              itemBuilder: (_, i) {
                final b = _banners[i];
                return Card(
                  child: ListTile(
                    leading: b['imagen_url'] != null
                        ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(b['imagen_url'], width: 48, height: 48, fit: BoxFit.cover))
                        : const Icon(Icons.image_outlined),
                    title: Text(b['titulo'] ?? ''),
                    subtitle: Text('Orden: ${b['orden'] ?? 0} | ${b['activo'] == true ? "Activo" : "Inactivo"}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: const Icon(Icons.edit, size: 20), onPressed: () => _createOrEdit(b)),
                        IconButton(icon: Icon(Icons.delete, size: 20, color: Colors.red.shade300), onPressed: () => _delete(b['id'])),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createOrEdit(null),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _BannerFormDialog extends StatefulWidget {
  final Map<String, dynamic>? banner;
  const _BannerFormDialog({this.banner});
  @override
  State<_BannerFormDialog> createState() => _BannerFormDialogState();
}

class _BannerFormDialogState extends State<_BannerFormDialog> {
  final _tituloCtrl = TextEditingController();
  final _subtituloCtrl = TextEditingController();
  final _imagenUrlCtrl = TextEditingController();
  final _linkUrlCtrl = TextEditingController();
  final _botonTextoCtr = TextEditingController();
  final _ordenCtrl = TextEditingController(text: '0');
  bool _activo = true;

  @override
  void initState() {
    super.initState();
    if (widget.banner != null) {
      final b = widget.banner!;
      _tituloCtrl.text = b['titulo'] ?? '';
      _subtituloCtrl.text = b['subtitulo'] ?? '';
      _imagenUrlCtrl.text = b['imagen_url'] ?? '';
      _linkUrlCtrl.text = b['link_url'] ?? '';
      _botonTextoCtr.text = b['boton_texto'] ?? '';
      _ordenCtrl.text = '${b['orden'] ?? 0}';
      _activo = b['activo'] ?? true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.banner == null ? 'Nuevo banner' : 'Editar banner'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _tituloCtrl, decoration: const InputDecoration(labelText: 'Título *')),
            const SizedBox(height: 8),
            TextField(controller: _subtituloCtrl, decoration: const InputDecoration(labelText: 'Subtítulo')),
            const SizedBox(height: 8),
            TextField(controller: _imagenUrlCtrl, decoration: const InputDecoration(labelText: 'URL de imagen')),
            const SizedBox(height: 8),
            TextField(controller: _linkUrlCtrl, decoration: const InputDecoration(labelText: 'URL de enlace')),
            const SizedBox(height: 8),
            TextField(controller: _botonTextoCtr, decoration: const InputDecoration(labelText: 'Texto del botón')),
            const SizedBox(height: 8),
            TextField(controller: _ordenCtrl, decoration: const InputDecoration(labelText: 'Orden'), keyboardType: TextInputType.number),
            const SizedBox(height: 8),
            SwitchListTile(title: const Text('Activo'), value: _activo, onChanged: (v) => setState(() => _activo = v), contentPadding: EdgeInsets.zero),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () {
            Navigator.pop(context, {
              'titulo': _tituloCtrl.text,
              'subtitulo': _subtituloCtrl.text,
              'imagen_url': _imagenUrlCtrl.text,
              'link_url': _linkUrlCtrl.text,
              'boton_texto': _botonTextoCtr.text,
              'orden': int.tryParse(_ordenCtrl.text) ?? 0,
              'activo': _activo,
            });
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _subtituloCtrl.dispose();
    _imagenUrlCtrl.dispose();
    _linkUrlCtrl.dispose();
    _botonTextoCtr.dispose();
    _ordenCtrl.dispose();
    super.dispose();
  }
}

// ============================================
// TAB: PRODUCTOS
// ============================================
class _ProductSettingsTab extends StatefulWidget {
  const _ProductSettingsTab();
  @override
  State<_ProductSettingsTab> createState() => _ProductSettingsTabState();
}

class _ProductSettingsTabState extends State<_ProductSettingsTab> {
  List<dynamic> _products = [];
  bool _loading = true;

  String get _botId => context.read<BotProvider>().botSeleccionado?.id ?? '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await StorefrontApiService.getAdminProductSettings(_botId);
      setState(() {
        _products = res['data'] ?? [];
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _editProduct(Map<String, dynamic> product) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => _ProductSettingDialog(product: product),
    );
    if (result != null) {
      await StorefrontApiService.updateAdminProductSetting(_botId, product['id'].toString(), result);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(strokeWidth: 3));

    return _products.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text('No hay productos en el catálogo', style: TextStyle(color: Colors.grey.shade500)),
              ],
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _products.length,
            itemBuilder: (_, i) {
              final p = _products[i];
              return Card(
                child: ListTile(
                  leading: p['imagen1'] != null
                      ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(p['imagen1'], width: 48, height: 48, fit: BoxFit.cover))
                      : const Icon(Icons.image_outlined),
                  title: Text(p['titulo'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(
                    '${p['visible_en_tienda'] == true ? "Visible" : "Oculto"} | ${p['destacado'] == true ? "Destacado" : ""} | \$${p['precio'] ?? 0}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.settings, size: 20),
                    onPressed: () => _editProduct(p),
                  ),
                ),
              );
            },
          );
  }
}

class _ProductSettingDialog extends StatefulWidget {
  final Map<String, dynamic> product;
  const _ProductSettingDialog({required this.product});
  @override
  State<_ProductSettingDialog> createState() => _ProductSettingDialogState();
}

class _ProductSettingDialogState extends State<_ProductSettingDialog> {
  late bool _visibleEnTienda;
  late bool _destacado;
  late int _orden;
  late String _etiqueta;
  late String _precioOfertaWeb;
  late String _descripcionWeb;
  late String _imagenDestacadaUrl;
  late bool _permitirCompraOnline;
  late bool _permitirWhatsapp;
  late bool _requiereInstalacion;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _visibleEnTienda = p['visible_en_tienda'] == true;
    _destacado = p['destacado'] == true;
    _orden = p['orden'] ?? 0;
    _etiqueta = p['etiqueta'] ?? '';
    _precioOfertaWeb = '${p['precio_oferta_web'] ?? ''}';
    _descripcionWeb = p['descripcion_web'] ?? '';
    _imagenDestacadaUrl = p['imagen_destacada_url'] ?? '';
    _permitirCompraOnline = p['permitir_compra_online'] != false;
    _permitirWhatsapp = p['permitir_whatsapp'] != false;
    _requiereInstalacion = p['requiere_instalacion'] == true;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Configurar: ${widget.product['titulo']}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(title: const Text('Visible en tienda'), value: _visibleEnTienda, onChanged: (v) => setState(() => _visibleEnTienda = v), contentPadding: EdgeInsets.zero),
            SwitchListTile(title: const Text('Destacado'), value: _destacado, onChanged: (v) => setState(() => _destacado = v), contentPadding: EdgeInsets.zero),
            SwitchListTile(title: const Text('Permitir compra online'), value: _permitirCompraOnline, onChanged: (v) => setState(() => _permitirCompraOnline = v), contentPadding: EdgeInsets.zero),
            SwitchListTile(title: const Text('Permitir WhatsApp'), value: _permitirWhatsapp, onChanged: (v) => setState(() => _permitirWhatsapp = v), contentPadding: EdgeInsets.zero),
            SwitchListTile(title: const Text('Requiere instalación'), value: _requiereInstalacion, onChanged: (v) => setState(() => _requiereInstalacion = v), contentPadding: EdgeInsets.zero),
            const SizedBox(height: 8),
            TextField(controller: TextEditingController.fromValue(TextEditingValue(text: _etiqueta)), decoration: const InputDecoration(labelText: 'Etiqueta'), onChanged: (v) => _etiqueta = v),
            const SizedBox(height: 8),
            TextField(controller: TextEditingController.fromValue(TextEditingValue(text: _precioOfertaWeb)), decoration: const InputDecoration(labelText: 'Precio oferta web'), keyboardType: TextInputType.number, onChanged: (v) => _precioOfertaWeb = v),
            const SizedBox(height: 8),
            TextField(controller: TextEditingController.fromValue(TextEditingValue(text: _descripcionWeb)), decoration: const InputDecoration(labelText: 'Descripción web'), maxLines: 3, onChanged: (v) => _descripcionWeb = v),
            const SizedBox(height: 8),
            TextField(controller: TextEditingController.fromValue(TextEditingValue(text: _imagenDestacadaUrl)), decoration: const InputDecoration(labelText: 'URL imagen destacada'), onChanged: (v) => _imagenDestacadaUrl = v),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () {
            Navigator.pop(context, {
              'visible_en_tienda': _visibleEnTienda,
              'destacado': _destacado,
              'orden': _orden,
              'etiqueta': _etiqueta,
              'precio_oferta_web': _precioOfertaWeb.isNotEmpty ? double.tryParse(_precioOfertaWeb) : null,
              'descripcion_web': _descripcionWeb,
              'imagen_destacada_url': _imagenDestacadaUrl,
              'permitir_compra_online': _permitirCompraOnline,
              'permitir_whatsapp': _permitirWhatsapp,
              'requiere_instalacion': _requiereInstalacion,
            });
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

// ============================================
// TAB: CARRITOS
// ============================================
class _CartsTab extends StatefulWidget {
  const _CartsTab();
  @override
  State<_CartsTab> createState() => _CartsTabState();
}

class _CartsTabState extends State<_CartsTab> {
  List<dynamic> _carts = [];
  bool _loading = true;
  String _filtro = 'activo';

  String get _botId => context.read<BotProvider>().botSeleccionado?.id ?? '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await StorefrontApiService.getAdminCarts(_botId, estado: _filtro);
      setState(() {
        _carts = res['data'] ?? [];
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _filterChip('Activos', 'activo'),
                const SizedBox(width: 8),
                _filterChip('Abandonados', 'abandonado'),
                const SizedBox(width: 8),
                _filterChip('Completados', 'completado'),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(strokeWidth: 3))
                : _carts.isEmpty
                    ? Center(child: Text('Sin carritos', style: TextStyle(color: Colors.grey.shade500)))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _carts.length,
                        itemBuilder: (_, i) {
                          final c = _carts[i];
                          return Card(
                            child: ListTile(
                              title: Text('Carrito #${c['id']}'),
                              subtitle: Text('Total: \$${c['total'] ?? 0} | ${c['telefono_cliente'] ?? "Sin cliente"}'),
                              trailing: Text(c['estado'] ?? ''),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final selected = _filtro == value;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        setState(() => _filtro = value);
        _load();
      },
    );
  }
}

// ============================================
// TAB: PAGOS
// ============================================
class _PaymentsTab extends StatefulWidget {
  const _PaymentsTab();
  @override
  State<_PaymentsTab> createState() => _PaymentsTabState();
}

class _PaymentsTabState extends State<_PaymentsTab> {
  List<dynamic> _payments = [];
  bool _loading = true;

  String get _botId => context.read<BotProvider>().botSeleccionado?.id ?? '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await StorefrontApiService.getAdminPayments(_botId);
      setState(() {
        _payments = res['data'] ?? [];
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(strokeWidth: 3));

    return _payments.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.payments_outlined, size: 48, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text('Sin pagos registrados', style: TextStyle(color: Colors.grey.shade500)),
              ],
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _payments.length,
            itemBuilder: (_, i) {
              final p = _payments[i];
              return Card(
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: p['estado'] == 'pagado' ? Colors.green.shade50 : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      p['estado'] == 'pagado' ? Icons.check_circle : Icons.pending,
                      color: p['estado'] == 'pagado' ? Colors.green : Colors.orange,
                    ),
                  ),
                  title: Text('\$${p['monto'] ?? 0}'),
                  subtitle: Text('${p['metodo_pago']} | ${p['estado']} | Pedido: ${p['pedido_id'] ?? "-"}'),
                ),
              );
            },
          );
  }
}
