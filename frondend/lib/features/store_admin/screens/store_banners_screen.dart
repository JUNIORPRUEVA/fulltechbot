import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/store_admin_provider.dart';

/// Pantalla de administración de banners de la tienda.
class StoreBannersScreen extends StatefulWidget {
  const StoreBannersScreen({super.key});

  @override
  State<StoreBannersScreen> createState() => _StoreBannersScreenState();
}

class _StoreBannersScreenState extends State<StoreBannersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StoreAdminProvider>().loadBanners();
    });
  }

  void _showBannerForm({Map<String, dynamic>? banner}) {
    showDialog(
      context: context,
      builder: (ctx) => _BannerFormDialog(
        banner: banner,
        onSave: (data) async {
          final provider = context.read<StoreAdminProvider>();
          bool success;
          if (banner != null) {
            success = await provider.updateBanner(banner['id'], data);
          } else {
            success = await provider.createBanner(data);
          }
          if (ctx.mounted) {
            Navigator.of(ctx).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(success ? 'Banner guardado' : 'Error: ${provider.error}'),
                backgroundColor: success ? Colors.green : Colors.red,
              ),
            );
          }
        },
      ),
    );
  }

  Future<void> _deleteBanner(Map<String, dynamic> banner) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar banner'),
        content: Text('¿Eliminar "${banner['titulo']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final provider = context.read<StoreAdminProvider>();
      final success = await provider.deleteBanner(banner['id']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Banner eliminado' : 'Error: ${provider.error}'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StoreAdminProvider>();

    return Scaffold(
      body: provider.loading
          ? const Center(child: CircularProgressIndicator())
          : provider.banners.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.view_carousel,
                          size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('No hay banners',
                          style: TextStyle(
                              fontSize: 18, color: Colors.grey[600])),
                      const SizedBox(height: 8),
                      Text('Agrega el primer banner',
                          style: TextStyle(color: Colors.grey[500])),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.banners.length,
                  itemBuilder: (context, index) {
                    final banner = provider.banners[index];
                    return _BannerCard(
                      banner: banner,
                      onEdit: () => _showBannerForm(banner: banner),
                      onDelete: () => _deleteBanner(banner),
                      onToggleActive: () async {
                        await provider.updateBanner(
                          banner['id'],
                          {'activo': !(banner['activo'] ?? false)},
                        );
                      },
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showBannerForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _BannerCard extends StatelessWidget {
  final Map<String, dynamic> banner;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleActive;

  const _BannerCard({
    required this.banner,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleActive,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = banner['activo'] ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Imagen preview
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: banner['imagen_url'] != null
                  ? Image.network(
                      banner['imagen_url'],
                      width: 80,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 80,
                        height: 60,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image),
                      ),
                    )
                  : Container(
                      width: 80,
                      height: 60,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image),
                    ),
            ),
            const SizedBox(width: 16),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    banner['titulo'] ?? 'Sin título',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  if (banner['subtitulo'] != null)
                    Text(
                      banner['subtitulo'],
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildBadge(
                        isActive ? 'Activo' : 'Inactivo',
                        isActive ? Colors.green : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      if (banner['orden'] != null)
                        Text('Orden: ${banner['orden']}',
                            style: TextStyle(
                                color: Colors.grey[500], fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            // Actions
            IconButton(
              icon: Icon(
                isActive ? Icons.visibility : Icons.visibility_off,
                size: 20,
              ),
              onPressed: onToggleActive,
            ),
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 20, color: Colors.red),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(text,
          style: TextStyle(color: color, fontSize: 11)),
    );
  }
}

class _BannerFormDialog extends StatefulWidget {
  final Map<String, dynamic>? banner;
  final Function(Map<String, dynamic>) onSave;

  const _BannerFormDialog({this.banner, required this.onSave});

  @override
  State<_BannerFormDialog> createState() => _BannerFormDialogState();
}

class _BannerFormDialogState extends State<_BannerFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _tituloController;
  late final TextEditingController _subtituloController;
  late final TextEditingController _imagenUrlController;
  late final TextEditingController _linkUrlController;
  late final TextEditingController _botonTextoController;
  late final TextEditingController _ordenController;

  @override
  void initState() {
    super.initState();
    final b = widget.banner;
    _tituloController = TextEditingController(text: b?['titulo'] ?? '');
    _subtituloController = TextEditingController(text: b?['subtitulo'] ?? '');
    _imagenUrlController = TextEditingController(text: b?['imagen_url'] ?? '');
    _linkUrlController = TextEditingController(text: b?['link_url'] ?? '');
    _botonTextoController = TextEditingController(text: b?['boton_texto'] ?? '');
    _ordenController =
        TextEditingController(text: (b?['orden'] ?? 0).toString());
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _subtituloController.dispose();
    _imagenUrlController.dispose();
    _linkUrlController.dispose();
    _botonTextoController.dispose();
    _ordenController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSave({
      'titulo': _tituloController.text.trim(),
      'subtitulo': _subtituloController.text.trim(),
      'imagen_url': _imagenUrlController.text.trim(),
      'link_url': _linkUrlController.text.trim(),
      'boton_texto': _botonTextoController.text.trim(),
      'orden': int.tryParse(_ordenController.text) ?? 0,
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.banner != null;
    return AlertDialog(
      title: Text(isEditing ? 'Editar banner' : 'Nuevo banner'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _tituloController,
                decoration: const InputDecoration(
                  labelText: 'Título',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v?.isEmpty == true ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _subtituloController,
                decoration: const InputDecoration(
                  labelText: 'Subtítulo',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _imagenUrlController,
                decoration: const InputDecoration(
                  labelText: 'URL de imagen',
                  border: OutlineInputBorder(),
                  hintText: 'https://...',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _linkUrlController,
                decoration: const InputDecoration(
                  labelText: 'Link de acción',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _botonTextoController,
                decoration: const InputDecoration(
                  labelText: 'Texto del botón',
                  border: OutlineInputBorder(),
                  hintText: 'Ver más',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ordenController,
                decoration: const InputDecoration(
                  labelText: 'Orden',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: Text(isEditing ? 'Actualizar' : 'Crear'),
        ),
      ],
    );
  }
}
