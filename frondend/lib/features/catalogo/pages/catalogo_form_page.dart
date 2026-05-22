import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../bots/providers/bot_provider.dart';
import '../models/catalogo_model.dart';
import '../providers/catalogo_provider.dart';
import '../services/storage_api_service.dart';

class CatalogoFormPage extends StatefulWidget {
  final CatalogoModel? producto;

  const CatalogoFormPage({
    super.key,
    this.producto,
  });

  @override
  State<CatalogoFormPage> createState() => _CatalogoFormPageState();
}

class _CatalogoFormPageState extends State<CatalogoFormPage> {
  final _formKey = GlobalKey<FormState>();

  final StorageApiService _storageApiService = StorageApiService();

bool _subiendoImagen1 = false;
bool _subiendoImagen2 = false;
bool _subiendoImagen3 = false;
bool _subiendoVideo = false;

  late final TextEditingController _tituloController;
  late final TextEditingController _categoriaController;
  late final TextEditingController _descripcionController;
  late final TextEditingController _informacionController;
  late final TextEditingController _precioController;
  late final TextEditingController _precioMinimoController;
  late final TextEditingController _precioOfertaController;
  late final TextEditingController _stockController;
  late final TextEditingController _imagen1Controller;
  late final TextEditingController _imagen2Controller;
  late final TextEditingController _imagen3Controller;
  late final TextEditingController _videoController;
  late final TextEditingController _palabrasClaveController;
  late final TextEditingController _reglasNegociacionController;

  String _estado = 'activo';

  bool get _isEditing => widget.producto != null;

  String? get _botId {
    try {
      return context.read<BotProvider>().botSeleccionado?.id;
    } catch (_) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();

    final producto = widget.producto;

    _tituloController = TextEditingController(text: producto?.titulo ?? '');
    _categoriaController = TextEditingController(text: producto?.categoria ?? '');
    _descripcionController =
        TextEditingController(text: producto?.descripcion ?? '');
    _informacionController =
        TextEditingController(text: producto?.informacion ?? '');
    _precioController = TextEditingController(
      text: producto != null ? producto.precio.toStringAsFixed(0) : '',
    );
    _precioMinimoController = TextEditingController(
      text: producto?.precioMinimo != null
          ? producto!.precioMinimo!.toStringAsFixed(0)
          : '',
    );
    _precioOfertaController = TextEditingController(
      text: producto?.precioOferta != null
          ? producto!.precioOferta!.toStringAsFixed(0)
          : '',
    );
    _stockController = TextEditingController(
      text: producto != null ? producto.stock.toString() : '0',
    );
    _imagen1Controller = TextEditingController(text: producto?.imagen1 ?? '');
    _imagen2Controller = TextEditingController(text: producto?.imagen2 ?? '');
    _imagen3Controller = TextEditingController(text: producto?.imagen3 ?? '');
    _videoController = TextEditingController(text: producto?.video ?? '');
    _palabrasClaveController =
        TextEditingController(text: producto?.palabrasClave ?? '');
    _reglasNegociacionController =
        TextEditingController(text: producto?.reglasNegociacion ?? '');

    _estado = producto?.estado ?? 'activo';
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _categoriaController.dispose();
    _descripcionController.dispose();
    _informacionController.dispose();
    _precioController.dispose();
    _precioMinimoController.dispose();
    _precioOfertaController.dispose();
    _stockController.dispose();
    _imagen1Controller.dispose();
    _imagen2Controller.dispose();
    _imagen3Controller.dispose();
    _videoController.dispose();
    _palabrasClaveController.dispose();
    _reglasNegociacionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CatalogoProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar producto' : 'Nuevo producto'),
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
                      title: 'Información principal',
                      children: [
                        _TextFieldApp(
                          controller: _tituloController,
                          label: 'Título',
                          requiredField: true,
                        ),
                        _TextFieldApp(
                          controller: _categoriaController,
                          label: 'Categoría',
                          requiredField: true,
                        ),
                        _TextFieldApp(
                          controller: _descripcionController,
                          label: 'Descripción corta',
                          maxLines: 2,
                        ),
                        _TextFieldApp(
                          controller: _informacionController,
                          label: 'Información completa para el bot',
                          maxLines: 4,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: 'Precios y stock',
                      children: [
                        _TextFieldApp(
                          controller: _precioController,
                          label: 'Precio',
                          requiredField: true,
                          keyboardType: TextInputType.number,
                          numberMustBePositive: true,
                        ),
                        _TextFieldApp(
                          controller: _precioMinimoController,
                          label: 'Precio mínimo de negociación',
                          keyboardType: TextInputType.number,
                        ),
                        _TextFieldApp(
                          controller: _precioOfertaController,
                          label: 'Precio de oferta',
                          keyboardType: TextInputType.number,
                        ),
                        _TextFieldApp(
                          controller: _stockController,
                          label: 'Stock',
                          keyboardType: TextInputType.number,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
  title: 'Multimedia',
  children: [
    _UploadFieldApp(
      controller: _imagen1Controller,
      label: 'Imagen 1 URL',
      isLoading: _subiendoImagen1,
      icon: Icons.image_outlined,
      onUpload: () {
        _seleccionarYSubirArchivo(
          controller: _imagen1Controller,
          tipo: 'imagen',
          setLoading: (value) => _subiendoImagen1 = value,
        );
      },
    ),
    _UploadFieldApp(
      controller: _imagen2Controller,
      label: 'Imagen 2 URL',
      isLoading: _subiendoImagen2,
      icon: Icons.image_outlined,
      onUpload: () {
        _seleccionarYSubirArchivo(
          controller: _imagen2Controller,
          tipo: 'imagen',
          setLoading: (value) => _subiendoImagen2 = value,
        );
      },
    ),
    _UploadFieldApp(
      controller: _imagen3Controller,
      label: 'Imagen 3 URL',
      isLoading: _subiendoImagen3,
      icon: Icons.image_outlined,
      onUpload: () {
        _seleccionarYSubirArchivo(
          controller: _imagen3Controller,
          tipo: 'imagen',
          setLoading: (value) => _subiendoImagen3 = value,
        );
      },
    ),
    _UploadFieldApp(
      controller: _videoController,
      label: 'Video URL',
      isLoading: _subiendoVideo,
      icon: Icons.video_file_outlined,
      onUpload: () {
        _seleccionarYSubirArchivo(
          controller: _videoController,
          tipo: 'video',
          setLoading: (value) => _subiendoVideo = value,
        );
      },
    ),
  ],
),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: 'Datos para el bot',
                      children: [
                        _TextFieldApp(
                          controller: _palabrasClaveController,
                          label: 'Palabras clave',
                          maxLines: 2,
                        ),
                        _TextFieldApp(
                          controller: _reglasNegociacionController,
                          label: 'Reglas de negociación',
                          maxLines: 3,
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
                            DropdownMenuItem(
                              value: 'agotado',
                              child: Text('Agotado'),
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
                            onPressed:
                                provider.isLoading ? null : _guardarProducto,
                            icon: provider.isLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.save_outlined),
                            label: Text(
                              _isEditing ? 'Actualizar' : 'Guardar',
                            ),
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

 Future<void> _seleccionarYSubirArchivo({
  required TextEditingController controller,
  required String tipo,
  required void Function(bool value) setLoading,
}) async {
  try {
    final XTypeGroup typeGroup = tipo == 'video'
        ? const XTypeGroup(
            label: 'Videos',
            extensions: ['mp4', 'webm', 'mov'],
          )
        : const XTypeGroup(
            label: 'Imágenes',
            extensions: ['jpg', 'jpeg', 'png', 'webp', 'gif'],
          );

    final XFile? file = await openFile(
      acceptedTypeGroups: [typeGroup],
    );

    if (file == null) {
      return;
    }

    setState(() {
      setLoading(true);
    });

    final uploadResult = await _storageApiService.subirArchivo(file);

    controller.text = uploadResult.url;

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          tipo == 'video'
              ? 'Video subido correctamente'
              : 'Imagen subida correctamente',
        ),
      ),
    );
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error al subir archivo: $e'),
        backgroundColor: Colors.red,
      ),
    );
  } finally {
    if (mounted) {
      setState(() {
        setLoading(false);
      });
    }
  }
}

  Future<void> _guardarProducto() async {
    if (!_formKey.currentState!.validate()) return;

    final producto = CatalogoModel(
      id: widget.producto?.id ?? '',
      titulo: _tituloController.text.trim(),
      categoria: _categoriaController.text.trim(),
      descripcion: _emptyToNull(_descripcionController.text),
      informacion: _emptyToNull(_informacionController.text),
      precio: double.tryParse(_precioController.text.trim()) ?? 0,
      precioMinimo: _parseNullableDouble(_precioMinimoController.text),
      precioOferta: _parseNullableDouble(_precioOfertaController.text),
      stock: int.tryParse(_stockController.text.trim()) ?? 0,
      imagen1: _emptyToNull(_imagen1Controller.text),
      imagen2: _emptyToNull(_imagen2Controller.text),
      imagen3: _emptyToNull(_imagen3Controller.text),
      video: _emptyToNull(_videoController.text),
      palabrasClave: _emptyToNull(_palabrasClaveController.text),
      reglasNegociacion: _emptyToNull(_reglasNegociacionController.text),
      estado: _estado,
      creadoEn: widget.producto?.creadoEn,
      actualizadoEn: widget.producto?.actualizadoEn,
    );

    final botId = _botId;

    try {
      if (_isEditing) {
        await context.read<CatalogoProvider>().actualizarProducto(producto, botId: botId);
      } else {
        await context.read<CatalogoProvider>().crearProducto(producto, botId: botId);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Producto actualizado correctamente'
                : 'Producto creado correctamente',
          ),
        ),
      );

      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo guardar el producto'),
        ),
      );
    }
  }

  String? _emptyToNull(String value) {
    final text = value.trim();
    return text.isEmpty ? null : text;
  }

  double? _parseNullableDouble(String value) {
    final text = value.trim();
    if (text.isEmpty) return null;
    return double.tryParse(text);
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
  final bool numberMustBePositive;
  final int maxLines;
  final TextInputType? keyboardType;

  const _TextFieldApp({
    required this.controller,
    required this.label,
    this.requiredField = false,
    this.numberMustBePositive = false,
    this.maxLines = 1,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: requiredField ? '$label *' : label,
      ),
      validator: (value) {
        final text = value?.trim() ?? '';

        if (requiredField && text.isEmpty) {
          return 'Este campo es obligatorio';
        }

        if (numberMustBePositive && text.isNotEmpty) {
          final number = double.tryParse(text);
          if (number == null || number <= 0) {
            return 'Debe ser mayor que 0';
          }
        }

        return null;
      },
    );
  }
}

class _UploadFieldApp extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool isLoading;
  final VoidCallback onUpload;
  final IconData icon;

  const _UploadFieldApp({
    required this.controller,
    required this.label,
    required this.isLoading,
    required this.onUpload,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = controller.text.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            suffixIcon: isLoading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    tooltip: 'Seleccionar y subir',
                    onPressed: onUpload,
                    icon: Icon(icon),
                  ),
          ),
        ),
        if (hasValue) ...[
          const SizedBox(height: 8),
          SelectableText(
            controller.text,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ],
    );
  }
}
