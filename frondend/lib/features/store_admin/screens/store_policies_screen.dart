import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/store_admin_provider.dart';

/// Pantalla de administración de políticas de la tienda.
class StorePoliciesScreen extends StatefulWidget {
  const StorePoliciesScreen({super.key});

  @override
  State<StorePoliciesScreen> createState() => _StorePoliciesScreenState();
}

class _StorePoliciesScreenState extends State<StorePoliciesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StoreAdminProvider>().loadPolicies();
    });
  }

  void _showPolicyEditor(Map<String, dynamic>? policy, String tipo) {
    showDialog(
      context: context,
      builder: (ctx) => _PolicyEditorDialog(
        policy: policy,
        tipo: tipo,
        onSave: (data) async {
          final provider = context.read<StoreAdminProvider>();
          final success = await provider.savePolicy(tipo, data);
          if (ctx.mounted) {
            Navigator.of(ctx).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    Text(success ? 'Política guardada' : 'Error: ${provider.error}'),
                backgroundColor: success ? Colors.green : Colors.red,
              ),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StoreAdminProvider>();

    if (provider.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final policyTypes = [
      _PolicyTypeInfo('privacy', 'Política de privacidad', Icons.privacy_tip),
      _PolicyTypeInfo('terms', 'Términos y condiciones', Icons.description),
      _PolicyTypeInfo('warranty', 'Política de garantía', Icons.verified),
      _PolicyTypeInfo('shipping', 'Política de envío', Icons.local_shipping),
      _PolicyTypeInfo('returns', 'Devoluciones', Icons.replay),
      _PolicyTypeInfo('contact', 'Contacto', Icons.contact_mail),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: policyTypes.map((info) {
        final policy = provider.policies.cast<Map<String, dynamic>?>().firstWhere(
              (p) => p?['tipo'] == info.tipo,
              orElse: () => null,
            );
        final hasContent = policy != null &&
            (policy['contenido']?.toString().isNotEmpty == true);
        final isActive = policy?['activo'] ?? false;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: hasContent
                  ? Colors.green.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
              child: Icon(
                info.icon,
                color: hasContent ? Colors.green : Colors.grey,
              ),
            ),
            title: Text(info.label,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
              hasContent
                  ? (isActive ? 'Activa' : 'Inactiva')
                  : 'Sin contenido',
              style: TextStyle(
                color: hasContent
                    ? (isActive ? Colors.green : Colors.orange)
                    : Colors.grey,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasContent)
                  IconButton(
                    icon: Icon(
                      isActive ? Icons.visibility : Icons.visibility_off,
                      size: 20,
                    ),
                    onPressed: () async {
                      await provider.savePolicy(info.tipo, {
                        'activo': !isActive,
                      });
                    },
                  ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () => _showPolicyEditor(policy, info.tipo),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _PolicyTypeInfo {
  final String tipo;
  final String label;
  final IconData icon;
  const _PolicyTypeInfo(this.tipo, this.label, this.icon);
}

class _PolicyEditorDialog extends StatefulWidget {
  final Map<String, dynamic>? policy;
  final String tipo;
  final Function(Map<String, dynamic>) onSave;

  const _PolicyEditorDialog({
    this.policy,
    required this.tipo,
    required this.onSave,
  });

  @override
  State<_PolicyEditorDialog> createState() => _PolicyEditorDialogState();
}

class _PolicyEditorDialogState extends State<_PolicyEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _tituloController;
  late final TextEditingController _contenidoController;

  @override
  void initState() {
    super.initState();
    _tituloController =
        TextEditingController(text: widget.policy?['titulo'] ?? '');
    _contenidoController =
        TextEditingController(text: widget.policy?['contenido'] ?? '');
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _contenidoController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSave({
      'titulo': _tituloController.text.trim(),
      'contenido': _contenidoController.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final tipoLabels = {
      'privacy': 'Política de privacidad',
      'terms': 'Términos y condiciones',
      'warranty': 'Política de garantía',
      'shipping': 'Política de envío',
      'returns': 'Devoluciones',
      'contact': 'Contacto',
    };

    return AlertDialog(
      title: Text(tipoLabels[widget.tipo] ?? widget.tipo),
      content: SizedBox(
        width: 500,
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
              const SizedBox(height: 16),
              TextFormField(
                controller: _contenidoController,
                decoration: const InputDecoration(
                  labelText: 'Contenido',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 12,
                validator: (v) => v?.isEmpty == true ? 'Requerido' : null,
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
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
