import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/bot_model.dart';
import '../providers/bot_provider.dart';

class BotFormPage extends StatefulWidget {
  final BotModel? bot;

  const BotFormPage({
    super.key,
    this.bot,
  });

  @override
  State<BotFormPage> createState() => _BotFormPageState();
}

class _BotFormPageState extends State<BotFormPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nombreController;
  late final TextEditingController _slugController;
  late final TextEditingController _descripcionController;
  late final TextEditingController _tipoNegocioController;
  late final TextEditingController _promptBaseController;
  late final TextEditingController _tonoController;
  late final TextEditingController _instruccionesController;
  late final TextEditingController _reglasNegocioController;
  late final TextEditingController _instanciaWhatsappController;
  late final TextEditingController _telefonoWhatsappController;

  String _estado = 'activo';

  bool get _isEditing => widget.bot != null;

  @override
  void initState() {
    super.initState();
    final bot = widget.bot;

    _nombreController = TextEditingController(text: bot?.nombre ?? '');
    _slugController = TextEditingController(text: bot?.slug ?? '');
    _descripcionController = TextEditingController(text: bot?.descripcion ?? '');
    _tipoNegocioController = TextEditingController(text: bot?.tipoNegocio ?? '');
    _promptBaseController = TextEditingController(text: bot?.promptBase ?? '');
    _tonoController = TextEditingController(text: bot?.tono ?? '');
    _instruccionesController = TextEditingController(text: bot?.instrucciones ?? '');
    _reglasNegocioController = TextEditingController(text: bot?.reglasNegocio ?? '');
    _instanciaWhatsappController = TextEditingController(text: bot?.instanciaWhatsapp ?? '');
    _telefonoWhatsappController = TextEditingController(text: bot?.telefonoWhatsapp ?? '');
    _estado = bot?.estado ?? 'activo';
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _slugController.dispose();
    _descripcionController.dispose();
    _tipoNegocioController.dispose();
    _promptBaseController.dispose();
    _tonoController.dispose();
    _instruccionesController.dispose();
    _reglasNegocioController.dispose();
    _instanciaWhatsappController.dispose();
    _telefonoWhatsappController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BotProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar bot' : 'Nuevo bot'),
      ),
      body: AbsorbPointer(
        absorbing: provider.isLoading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 850),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionCard(
                      title: 'Información general',
                      children: [
                        _TextFieldApp(
                          controller: _nombreController,
                          label: 'Nombre del bot',
                          requiredField: true,
                        ),
                        _TextFieldApp(
                          controller: _slugController,
                          label: 'Slug (identificador único)',
                          requiredField: true,
                          helperText: 'Ej: fulltech-seguridad, emagryfit-rd',
                          onChanged: _onSlugChanged,
                          validator: _validarSlug,
                        ),
                        _TextFieldApp(
                          controller: _descripcionController,
                          label: 'Descripción',
                          maxLines: 2,
                        ),
                        _TextFieldApp(
                          controller: _tipoNegocioController,
                          label: 'Tipo de negocio',
                          helperText: 'Ej: seguridad, punto-venta, herramientas, suplementos',
                        ),
                        DropdownButtonFormField<String>(
                          value: _estado,
                          decoration: const InputDecoration(
                            labelText: 'Estado',
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'activo',
                              child: Text('Activo'),
                            ),
                            DropdownMenuItem(
                              value: 'inactivo',
                              child: Text('Inactivo'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _estado = value;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: 'Configuración del bot',
                      children: [
                        _TextFieldApp(
                          controller: _promptBaseController,
                          label: 'Prompt base',
                          maxLines: 4,
                          helperText: 'Instrucciones principales para el comportamiento del bot',
                        ),
                        _TextFieldApp(
                          controller: _tonoController,
                          label: 'Tono de comunicación',
                          maxLines: 2,
                          helperText: 'Ej: formal, casual, técnico, amigable',
                        ),
                        _TextFieldApp(
                          controller: _instruccionesController,
                          label: 'Instrucciones adicionales',
                          maxLines: 3,
                        ),
                        _TextFieldApp(
                          controller: _reglasNegocioController,
                          label: 'Reglas de negocio',
                          maxLines: 3,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: 'WhatsApp',
                      children: [
                        _TextFieldApp(
                          controller: _instanciaWhatsappController,
                          label: 'Instancia de WhatsApp',
                          helperText: 'ID de la instancia en Evolution API o similar',
                        ),
                        _TextFieldApp(
                          controller: _telefonoWhatsappController,
                          label: 'Teléfono de WhatsApp',
                          helperText: 'Número conectado a la instancia',
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: provider.isLoading
                                ? null
                                : () => Navigator.pop(context),
                            child: const Text('Cancelar'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: provider.isLoading ? null : _guardarBot,
                            icon: provider.isLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.save_outlined),
                            label: Text(_isEditing ? 'Actualizar' : 'Guardar'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onSlugChanged(String value) {
    // Auto-formatear slug: minúsculas, sin espacios, guiones
    final formateado = value
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'[^a-z0-9\-]'), '');
    if (formateado != value) {
      _slugController.value = TextEditingValue(
        text: formateado,
        selection: TextSelection.collapsed(offset: formateado.length),
      );
    }
  }

  String? _validarSlug(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'El slug es obligatorio';
    if (text.contains(' ')) return 'El slug no debe contener espacios';
    if (text != text.toLowerCase()) return 'El slug debe estar en minúsculas';
    if (!RegExp(r'^[a-z0-9\-]+$').hasMatch(text)) {
      return 'Solo letras minúsculas, números y guiones';
    }
    return null;
  }

  Future<void> _guardarBot() async {
    if (!_formKey.currentState!.validate()) return;

    final data = {
      'nombre': _nombreController.text.trim(),
      'slug': _slugController.text.trim(),
      'descripcion': _emptyToNull(_descripcionController.text),
      'tipoNegocio': _emptyToNull(_tipoNegocioController.text),
      'estado': _estado,
      'promptBase': _emptyToNull(_promptBaseController.text),
      'tono': _emptyToNull(_tonoController.text),
      'instrucciones': _emptyToNull(_instruccionesController.text),
      'reglasNegocio': _emptyToNull(_reglasNegocioController.text),
      'instanciaWhatsapp': _emptyToNull(_instanciaWhatsappController.text),
      'telefonoWhatsapp': _emptyToNull(_telefonoWhatsappController.text),
    };

    try {
      if (_isEditing) {
        await context.read<BotProvider>().actualizarBot(widget.bot!.id, data);
      } else {
        await context.read<BotProvider>().crearBot(data);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Bot actualizado correctamente'
                : 'Bot creado correctamente',
          ),
        ),
      );

      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo guardar el bot'),
        ),
      );
    }
  }

  String? _emptyToNull(String value) {
    final text = value.trim();
    return text.isEmpty ? null : text;
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 650;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: children.map((child) {
                    return SizedBox(
                      width: isWide
                          ? (constraints.maxWidth - 12) / 2
                          : constraints.maxWidth,
                      child: child,
                    );
                  }).toList(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TextFieldApp extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool requiredField;
  final int maxLines;
  final String? helperText;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;

  const _TextFieldApp({
    required this.controller,
    required this.label,
    this.requiredField = false,
    this.maxLines = 1,
    this.helperText,
    this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: requiredField ? '$label *' : label,
        helperText: helperText,
      ),
      validator: validator ?? (value) {
        final text = value?.trim() ?? '';
        if (requiredField && text.isEmpty) {
          return 'Este campo es obligatorio';
        }
        return null;
      },
    );
  }
}
