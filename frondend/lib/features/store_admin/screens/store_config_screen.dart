import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/store_admin_provider.dart';

/// Pantalla de configuración de tienda.
/// Permite editar nombre, slug, descripción, logo, contacto, etc.
class StoreConfigScreen extends StatefulWidget {
  const StoreConfigScreen({super.key});

  @override
  State<StoreConfigScreen> createState() => _StoreConfigScreenState();
}

class _StoreConfigScreenState extends State<StoreConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _initialized = false;

  final _nombreController = TextEditingController();
  final _slugController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _emailController = TextEditingController();
  final _instagramController = TextEditingController();
  final _facebookController = TextEditingController();
  final _direccionController = TextEditingController();
  final _mapsUrlController = TextEditingController();
  final _horarioController = TextEditingController();
  final _mensajeController = TextEditingController();
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadConfig();
    });
  }

  Future<void> _loadConfig() async {
    final provider = context.read<StoreAdminProvider>();
    await provider.loadConfig();
    if (mounted) {
      _populateForm(provider.config);
    }
  }

  void _populateForm(Map<String, dynamic>? config) {
    if (config == null) return;
    _nombreController.text = config['nombre_tienda'] ?? '';
    _slugController.text = config['slug'] ?? '';
    _descripcionController.text = config['descripcion'] ?? '';
    _whatsappController.text = config['whatsapp_numero'] ?? '';
    _telefonoController.text = config['telefono_contacto'] ?? '';
    _emailController.text = config['email'] ?? '';
    _instagramController.text = config['instagram'] ?? '';
    _facebookController.text = config['facebook'] ?? '';
    _direccionController.text = config['direccion'] ?? '';
    _mapsUrlController.text = config['maps_url'] ?? '';
    _horarioController.text = config['horario'] ?? '';
    _mensajeController.text = config['mensaje_principal'] ?? '';
    _isActive = config['activo'] ?? config['is_active'] ?? true;
    _initialized = true;
    setState(() {});
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final data = {
      'nombre_tienda': _nombreController.text.trim(),
      'slug': _slugController.text.trim(),
      'descripcion': _descripcionController.text.trim(),
      'whatsapp_numero': _whatsappController.text.trim(),
      'telefono_contacto': _telefonoController.text.trim(),
      'email': _emailController.text.trim(),
      'instagram': _instagramController.text.trim(),
      'facebook': _facebookController.text.trim(),
      'direccion': _direccionController.text.trim(),
      'maps_url': _mapsUrlController.text.trim(),
      'horario': _horarioController.text.trim(),
      'mensaje_principal': _mensajeController.text.trim(),
      'activo': _isActive,
    };

    final provider = context.read<StoreAdminProvider>();
    final success = await provider.saveConfig(data);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Configuración guardada' : 'Error: ${provider.error}'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _slugController.dispose();
    _descripcionController.dispose();
    _whatsappController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    _instagramController.dispose();
    _facebookController.dispose();
    _direccionController.dispose();
    _mapsUrlController.dispose();
    _horarioController.dispose();
    _mensajeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StoreAdminProvider>();

    if (provider.loading && !_initialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Información general
            _buildSectionTitle('Información de la tienda'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _nombreController,
                    label: 'Nombre de tienda',
                    icon: Icons.store,
                    validator: (v) =>
                        v?.isEmpty == true ? 'Requerido' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: _slugController,
                    label: 'Slug',
                    icon: Icons.link,
                    validator: (v) =>
                        v?.isEmpty == true ? 'Requerido' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _descripcionController,
              label: 'Descripción',
              icon: Icons.description,
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Contacto
            _buildSectionTitle('Contacto'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _whatsappController,
                    label: 'WhatsApp',
                    icon: Icons.chat,
                    hint: '8494314070',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: _telefonoController,
                    label: 'Teléfono',
                    icon: Icons.phone,
                    hint: '8295319442',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _emailController,
                    label: 'Email',
                    icon: Icons.email,
                    hint: 'fulltechsd@gmail.com',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: _instagramController,
                    label: 'Instagram',
                    icon: Icons.camera_alt,
                    hint: '@fulltechsrl',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _facebookController,
              label: 'Facebook',
              icon: Icons.facebook,
              hint: 'fulltech, srl',
            ),
            const SizedBox(height: 24),

            // Dirección
            _buildSectionTitle('Dirección'),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _direccionController,
              label: 'Dirección',
              icon: Icons.location_on,
              hint: 'Higüey centro, Beller 9 local 2',
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _mapsUrlController,
              label: 'Google Maps URL',
              icon: Icons.map,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _horarioController,
              label: 'Horario',
              icon: Icons.access_time,
              hint: 'Lun-Vie 9:00-18:00, Sáb 9:00-13:00',
            ),
            const SizedBox(height: 24),

            // Mensaje
            _buildSectionTitle('Mensaje principal'),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _mensajeController,
              label: 'Mensaje principal',
              icon: Icons.message,
              maxLines: 2,
              hint: 'Ofertas en cámaras de seguridad y tecnología',
            ),
            const SizedBox(height: 24),

            // Estado
            _buildSectionTitle('Estado'),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Tienda activa'),
              subtitle: Text(
                  _isActive ? 'Visible para clientes' : 'Oculta para clientes'),
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
            ),
            const SizedBox(height: 32),

            // Botón guardar
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: provider.loading ? null : _save,
                icon: provider.loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(provider.loading ? 'Guardando...' : 'Guardar configuración'),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    String? hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon, size: 20) : null,
        border: const OutlineInputBorder(),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      maxLines: maxLines,
      validator: validator,
    );
  }
}
