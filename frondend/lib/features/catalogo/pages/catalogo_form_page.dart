import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../bots/providers/bot_provider.dart';
import '../models/catalogo_model.dart';
import '../models/catalogo_kit_componente_model.dart';
import '../providers/catalogo_provider.dart';
import '../services/catalogo_kit_componentes_api_service.dart';
import '../services/storage_api_service.dart';
import '../widgets/kit_componentes_section.dart';
import '../../../shared/widgets/image_upload_field.dart';

class CatalogoFormPage extends StatefulWidget {
  final CatalogoModel? producto;

  const CatalogoFormPage({super.key, this.producto});

  @override
  State<CatalogoFormPage> createState() => _CatalogoFormPageState();
}

class _CatalogoFormPageState extends State<CatalogoFormPage> {
  final _formKey = GlobalKey<FormState>();

  final StorageApiService _storageApiService = StorageApiService();

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

  // === CAMPOS NUEVOS ===
  String _tipoProducto = 'producto';
  bool _esCotizable = true;
  bool _permiteAdicionales = false;
  late final TextEditingController _ordenController;
  late final TextEditingController _incluyeController;
  bool _instalacionIncluida = false;
  bool _permiteCalculoAdicional = false;
  late final TextEditingController _cantidadBaseController;
  late final TextEditingController _unidadAdicionalController;
  late final TextEditingController _precioAdicionalController;
  late final TextEditingController _precioMinimoAdicionalController;
  late final TextEditingController _ciudadBaseController;
  bool _aplicaCargoFueraCiudad = false;
  late final TextEditingController _cargoFueraCiudadController;

  // === COMPONENTES DEL KIT ===
  final CatalogoKitComponentesApiService _kitComponentesService =
      CatalogoKitComponentesApiService();
  List<CatalogoKitComponenteModel> _componentesKit = [];
  bool _cargandoComponentes = false;

  // === SIMULADOR ===
  late final TextEditingController _simCantidadController;
  bool _simFueraCiudad = false;

  String _estado = 'activo';

  bool get _isEditing => widget.producto != null;

  String? get _botId {
    try {
      return context.read<BotProvider>().botSeleccionado?.id;
    } catch (_) {
      return null;
    }
  }

  String? get _botNombre {
    try {
      return context.read<BotProvider>().botSeleccionado?.nombre;
    } catch (_) {
      return null;
    }
  }

  bool get _hayBotSeleccionado {
    try {
      return context.read<BotProvider>().hayBotSeleccionado;
    } catch (_) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();

    final producto = widget.producto;

    _tituloController = TextEditingController(text: producto?.titulo ?? '');
    _categoriaController = TextEditingController(
      text: producto?.categoria ?? '',
    );
    _descripcionController = TextEditingController(
      text: producto?.descripcion ?? '',
    );
    _informacionController = TextEditingController(
      text: producto?.informacion ?? '',
    );
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
    _palabrasClaveController = TextEditingController(
      text: producto?.palabrasClave ?? '',
    );
    _reglasNegociacionController = TextEditingController(
      text: producto?.reglasNegociacion ?? '',
    );

    // Campos nuevos
    _tipoProducto = producto?.tipoProducto ?? 'producto';
    _esCotizable = producto?.esCotizable ?? true;
    _permiteAdicionales = producto?.permiteAdicionales ?? false;
    _ordenController = TextEditingController(
      text: producto != null ? producto.orden.toString() : '0',
    );
    _incluyeController = TextEditingController(text: producto?.incluye ?? '');
    _instalacionIncluida = producto?.instalacionIncluida ?? false;
    _permiteCalculoAdicional = producto?.permiteCalculoAdicional ?? false;
    _cantidadBaseController = TextEditingController(
      text: producto != null ? producto.cantidadBase.toString() : '1',
    );
    _unidadAdicionalController = TextEditingController(
      text: producto?.unidadAdicionalNombre ?? '',
    );
    _precioAdicionalController = TextEditingController(
      text: producto != null && producto.precioAdicional > 0
          ? producto.precioAdicional.toStringAsFixed(0)
          : '',
    );
    _precioMinimoAdicionalController = TextEditingController(
      text: producto != null && producto.precioMinimoAdicional > 0
          ? producto.precioMinimoAdicional.toStringAsFixed(0)
          : '',
    );
    _ciudadBaseController = TextEditingController(
      text: producto?.ciudadBase ?? 'Higüey',
    );
    _aplicaCargoFueraCiudad = producto?.aplicaCargoFueraCiudad ?? false;
    _cargoFueraCiudadController = TextEditingController(
      text: producto != null && producto.cargoFueraCiudad > 0
          ? producto.cargoFueraCiudad.toStringAsFixed(0)
          : '',
    );

    // Simulador
    _simCantidadController = TextEditingController(text: '');
    _simFueraCiudad = false;

    _estado = producto?.estado ?? 'activo';

    // Cargar componentes si es edición de un kit
    if (_isEditing && _tipoProducto == 'kit' && producto!.id.isNotEmpty) {
      _cargarComponentesKit(producto.id);
    }
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
    _ordenController.dispose();
    _incluyeController.dispose();
    _cantidadBaseController.dispose();
    _unidadAdicionalController.dispose();
    _precioAdicionalController.dispose();
    _precioMinimoAdicionalController.dispose();
    _ciudadBaseController.dispose();
    _cargoFueraCiudadController.dispose();
    _simCantidadController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CatalogoProvider>();
    final botNombre = _botNombre;
    final hayBot = _hayBotSeleccionado;

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
                    // Banner del bot actual
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: hayBot
                            ? Colors.blue.shade50
                            : Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: hayBot
                              ? Colors.blue.shade200
                              : Colors.orange.shade200,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            hayBot
                                ? Icons.smart_toy_outlined
                                : Icons.warning_amber_rounded,
                            size: 18,
                            color: hayBot
                                ? Colors.blue.shade600
                                : Colors.orange.shade600,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              hayBot
                                  ? 'Producto para: $botNombre'
                                  : 'No hay bot seleccionado. Selecciona un bot primero.',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: hayBot
                                    ? Colors.blue.shade700
                                    : Colors.orange.shade700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // === SECCIÓN 1: Información principal ===
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

                    // === SECCIÓN 2: Tipo y clasificación ===
                    _SectionCard(
                      title: 'Tipo y clasificación',
                      children: [
                        DropdownButtonFormField<String>(
                          value: _tipoProducto,
                          decoration: const InputDecoration(
                            labelText: 'Tipo de producto *',
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'producto',
                              child: Text('Producto'),
                            ),
                            DropdownMenuItem(value: 'kit', child: Text('Kit')),
                            DropdownMenuItem(
                              value: 'componente',
                              child: Text('Componente'),
                            ),
                            DropdownMenuItem(
                              value: 'accesorio',
                              child: Text('Accesorio'),
                            ),
                            DropdownMenuItem(
                              value: 'repuesto',
                              child: Text('Repuesto'),
                            ),
                            DropdownMenuItem(
                              value: 'servicio',
                              child: Text('Servicio'),
                            ),
                            DropdownMenuItem(
                              value: 'extra',
                              child: Text('Extra'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _tipoProducto = value);
                            }
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Selecciona un tipo de producto';
                            }
                            return null;
                          },
                        ),
                        SwitchListTile(
                          title: const Text('Es cotizable'),
                          subtitle: const Text('Permite generar cotización'),
                          value: _esCotizable,
                          onChanged: (value) =>
                              setState(() => _esCotizable = value),
                          contentPadding: EdgeInsets.zero,
                        ),
                        SwitchListTile(
                          title: const Text('Permite adicionales'),
                          subtitle: const Text(
                            'Se pueden agregar unidades extra',
                          ),
                          value: _permiteAdicionales,
                          onChanged: (value) =>
                              setState(() => _permiteAdicionales = value),
                          contentPadding: EdgeInsets.zero,
                        ),
                        _TextFieldApp(
                          controller: _ordenController,
                          label: 'Orden',
                          keyboardType: TextInputType.number,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // === SECCIÓN 3: Precios y stock ===
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

                    // === SECCIÓN 4: Reglas de cálculo ===
                    _SectionCard(
                      title: 'Reglas de cálculo',
                      children: [
                        SwitchListTile(
                          title: const Text('Permitir cálculo adicional'),
                          subtitle: const Text(
                            'Habilitar cálculo de unidades extras sobre cantidad base',
                          ),
                          value: _permiteCalculoAdicional,
                          onChanged: (value) =>
                              setState(() => _permiteCalculoAdicional = value),
                          contentPadding: EdgeInsets.zero,
                        ),
                        if (_permiteCalculoAdicional) ...[
                          _TextFieldApp(
                            controller: _cantidadBaseController,
                            label: 'Cantidad base incluida',
                            keyboardType: TextInputType.number,
                            helperText:
                                'Ejemplo: 4 (cámaras incluidas en el precio base)',
                          ),
                          _TextFieldApp(
                            controller: _unidadAdicionalController,
                            label: 'Unidad adicional',
                            helperText:
                                'Ejemplo: cámara adicional, control adicional, usuario adicional',
                          ),
                          _TextFieldApp(
                            controller: _precioAdicionalController,
                            label: 'Precio adicional por unidad',
                            keyboardType: TextInputType.number,
                            helperText: 'Ejemplo: 3500',
                          ),
                          _TextFieldApp(
                            controller: _precioMinimoAdicionalController,
                            label: 'Precio mínimo adicional por unidad',
                            keyboardType: TextInputType.number,
                          ),
                        ],
                        const Divider(height: 24),
                        _TextFieldApp(
                          controller: _ciudadBaseController,
                          label: 'Ciudad base',
                          helperText: 'Ejemplo: Higüey',
                        ),
                        SwitchListTile(
                          title: const Text('Aplicar cargo fuera de ciudad'),
                          subtitle: const Text(
                            'Agregar cargo adicional si el cliente está fuera de la ciudad base',
                          ),
                          value: _aplicaCargoFueraCiudad,
                          onChanged: (value) =>
                              setState(() => _aplicaCargoFueraCiudad = value),
                          contentPadding: EdgeInsets.zero,
                        ),
                        if (_aplicaCargoFueraCiudad)
                          _TextFieldApp(
                            controller: _cargoFueraCiudadController,
                            label: 'Cargo fuera de ciudad',
                            keyboardType: TextInputType.number,
                            helperText: 'Ejemplo: 1500',
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // === SECCIÓN 5: Multimedia ===
                    _SectionCard(
                      title: 'Multimedia',
                      children: [
                        ImageUploadField(
                          controller: _imagen1Controller,
                          label: 'Imagen 1',
                          folder: 'catalogo/productos',
                          context: 'catalogo-imagen-1',
                          botId: _botId,
                          aspectRatio: 1,
                          hintText: 'https://...',
                        ),
                        ImageUploadField(
                          controller: _imagen2Controller,
                          label: 'Imagen 2',
                          folder: 'catalogo/productos',
                          context: 'catalogo-imagen-2',
                          botId: _botId,
                          aspectRatio: 1,
                          hintText: 'https://...',
                        ),
                        ImageUploadField(
                          controller: _imagen3Controller,
                          label: 'Imagen 3',
                          folder: 'catalogo/productos',
                          context: 'catalogo-imagen-3',
                          botId: _botId,
                          aspectRatio: 1,
                          hintText: 'https://...',
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

                    // === SECCIÓN 6: Datos para el bot ===
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
                    const SizedBox(height: 16),

                    // === SECCIÓN 7: Componentes del kit ===
                    _buildSeccionComponentesKit(),
                    const SizedBox(height: 16),

                    // === SECCIÓN 8: Simulador de precio ===
                    _buildSimuladorPrecio(),
                    const SizedBox(height: 24),

                    // Botones
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
                            onPressed: provider.isLoading || !hayBot
                                ? null
                                : _guardarProducto,
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
                    if (!hayBot)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Debes seleccionar un bot antes de guardar un producto.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade700,
                          ),
                          textAlign: TextAlign.center,
                        ),
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

  // ============================================================
  // COMPONENTES DEL KIT
  // ============================================================
  Future<void> _cargarComponentesKit(String kitId) async {
    setState(() => _cargandoComponentes = true);
    final componentes = await _kitComponentesService.obtenerComponentesKit(
      kitId,
    );
    if (mounted) {
      setState(() {
        _componentesKit = componentes;
        _cargandoComponentes = false;
      });
    }
  }

  Widget _buildSeccionComponentesKit() {
    if (_tipoProducto != 'kit') return const SizedBox.shrink();

    final kitId = widget.producto?.id ?? '';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Colors.teal.shade200),
      ),
      color: Colors.teal.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.inventory_2_rounded, color: Colors.teal.shade700),
                const SizedBox(width: 8),
                Text(
                  'Componentes del kit',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.teal.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Agrega los productos que incluye este kit o los extras opcionales que el cliente puede sumar.',
              style: TextStyle(fontSize: 12, color: Colors.teal.shade600),
            ),
            const SizedBox(height: 16),

            // Lista de componentes
            if (_cargandoComponentes)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_componentesKit.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.teal.shade100),
                ),
                child: Center(
                  child: Text(
                    'Aún no hay componentes agregados a este kit.',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
              )
            else
              ..._componentesKit.map((comp) => _buildComponenteCard(comp)),

            const SizedBox(height: 16),

            // Botones para agregar
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: kitId.isNotEmpty
                        ? () => _abrirModalAgregarComponente(
                            kitId,
                            incluido: true,
                          )
                        : null,
                    icon: const Icon(Icons.add_circle_outline, size: 18),
                    label: const Text('Agregar componente'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.teal,
                      side: const BorderSide(color: Colors.teal),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: kitId.isNotEmpty
                        ? () => _abrirModalAgregarComponente(
                            kitId,
                            incluido: false,
                            esOpcional: true,
                          )
                        : null,
                    icon: const Icon(Icons.add_circle_outline, size: 18),
                    label: const Text('Agregar extra opcional'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange,
                      side: const BorderSide(color: Colors.orange),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (kitId.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Guarda el producto primero para poder agregar componentes.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildComponenteCard(CatalogoKitComponenteModel comp) {
    final esOpcional = comp.esOpcional;
    final color = esOpcional ? Colors.orange : Colors.teal;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.shade200),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Imagen del componente
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 56,
                height: 56,
                child: comp.imagen1 != null && comp.imagen1!.isNotEmpty
                    ? Image.network(
                        comp.imagen1!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey.shade100,
                          child: Icon(
                            Icons.inventory_2_outlined,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      )
                    : Container(
                        color: Colors.grey.shade100,
                        child: Icon(
                          Icons.inventory_2_outlined,
                          color: Colors.grey.shade400,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            // Información
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    comp.titulo ?? 'Sin título',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (comp.tipoProducto != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            comp.tipoProducto!,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                      Text(
                        'Cant: ${comp.cantidad.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  if (comp.precio != null && comp.precio! > 0)
                    Text(
                      'RD\$${comp.precio!.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade700,
                      ),
                    ),
                  if (comp.nota != null && comp.nota!.isNotEmpty)
                    Text(
                      comp.nota!,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            // Chip incluido/opcional
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Text(
                esOpcional ? 'Opcional' : 'Incluido',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: color.shade700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Botones editar/quitar
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 18),
              onPressed: comp.id.isNotEmpty
                  ? () => _abrirModalEditarComponente(widget.producto!.id, comp)
                  : null,
              visualDensity: VisualDensity.compact,
            ),
            IconButton(
              icon: Icon(
                Icons.delete_outline,
                size: 18,
                color: Colors.red.shade400,
              ),
              onPressed: comp.id.isNotEmpty
                  ? () =>
                        _confirmarEliminarComponente(widget.producto!.id, comp)
                  : null,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _abrirModalAgregarComponente(
    String kitId, {
    bool incluido = true,
    bool esOpcional = false,
  }) async {
    final botId = _botId;
    if (botId == null) return;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _AgregarComponenteDialog(
        kitComponentesService: _kitComponentesService,
        botId: botId,
        kitId: kitId,
        incluidoInicial: incluido,
        esOpcionalInicial: esOpcional,
      ),
    );

    if (result != null && mounted) {
      await _cargarComponentesKit(kitId);
    }
  }

  Future<void> _abrirModalEditarComponente(
    String kitId,
    CatalogoKitComponenteModel comp,
  ) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _EditarComponenteDialog(componente: comp),
    );

    if (result != null && mounted) {
      await _kitComponentesService.actualizarComponenteKit(
        kitId,
        comp.id,
        result,
      );
      await _cargarComponentesKit(kitId);
    }
  }

  Future<void> _confirmarEliminarComponente(
    String kitId,
    CatalogoKitComponenteModel comp,
  ) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Eliminar componente'),
        content: Text('¿Quitar "${comp.titulo ?? 'este componente'}" del kit?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true && mounted) {
      await _kitComponentesService.eliminarComponenteKit(kitId, comp.id);
      await _cargarComponentesKit(kitId);
    }
  }

  Widget _buildSimuladorPrecio() {
    final precioBase = double.tryParse(_precioController.text.trim()) ?? 0;
    final cantidadBase = int.tryParse(_cantidadBaseController.text.trim()) ?? 1;
    final precioAdicional =
        double.tryParse(_precioAdicionalController.text.trim()) ?? 0;
    final cargoFuera =
        double.tryParse(_cargoFueraCiudadController.text.trim()) ?? 0;
    final cantidadSolicitada =
        int.tryParse(_simCantidadController.text.trim()) ?? 0;

    final unidadesAdicionales = cantidadSolicitada > cantidadBase
        ? cantidadSolicitada - cantidadBase
        : 0;
    final subtotalAdicionales = unidadesAdicionales * precioAdicional;
    final cargoAplica = _simFueraCiudad && _aplicaCargoFueraCiudad
        ? cargoFuera
        : 0.0;
    final total = precioBase + subtotalAdicionales + cargoAplica;

    // Resumen de componentes del kit
    final componentesIncluidos = _componentesKit
        .where((c) => !c.esOpcional)
        .toList();
    final componentesOpcionales = _componentesKit
        .where((c) => c.esOpcional)
        .toList();
    final esKit = _tipoProducto == 'kit';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Colors.blue.shade200),
      ),
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calculate_rounded, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(
                  'Simulador de precio',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.blue.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Prueba cómo se calculará el precio final según la cantidad y ubicación.',
              style: TextStyle(fontSize: 12, color: Colors.blue.shade600),
            ),
            const SizedBox(height: 16),

            // === Resumen de componentes del kit ===
            if (esKit && _componentesKit.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.teal.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.widgets_outlined,
                          size: 16,
                          color: Colors.teal.shade600,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Componentes configurados',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.teal.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 14,
                          color: Colors.teal.shade400,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Incluidos: ${componentesIncluidos.length}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.add_circle_outline,
                          size: 14,
                          color: Colors.orange.shade400,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Opcionales: ${componentesOpcionales.length}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                    if (componentesIncluidos.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      const Divider(height: 1),
                      const SizedBox(height: 6),
                      ...componentesIncluidos.map(
                        (c) => Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Row(
                            children: [
                              const SizedBox(width: 8),
                              Text(
                                '${c.cantidad.toStringAsFixed(0)}x ${c.titulo ?? ''}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            Row(
              children: [
                Expanded(
                  child: _TextFieldApp(
                    controller: _simCantidadController,
                    label: 'Cantidad solicitada',
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                if (_aplicaCargoFueraCiudad)
                  Expanded(
                    child: SwitchListTile(
                      title: const Text(
                        'Fuera de ciudad',
                        style: TextStyle(fontSize: 13),
                      ),
                      value: _simFueraCiudad,
                      onChanged: (value) =>
                          setState(() => _simFueraCiudad = value),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (cantidadSolicitada > 0) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Column(
                  children: [
                    _SimRow(
                      label: 'Precio base',
                      value: 'RD\$${precioBase.toStringAsFixed(0)}',
                    ),
                    if (_permiteCalculoAdicional) ...[
                      _SimRow(
                        label: 'Cantidad base incluida',
                        value: '$cantidadBase',
                      ),
                      _SimRow(
                        label: 'Cantidad solicitada',
                        value: '$cantidadSolicitada',
                      ),
                      if (unidadesAdicionales > 0) ...[
                        _SimRow(
                          label: 'Unidades adicionales',
                          value: '$unidadesAdicionales',
                        ),
                        _SimRow(
                          label: 'Precio adicional',
                          value:
                              'RD\$${precioAdicional.toStringAsFixed(0)} c/u',
                        ),
                        _SimRow(
                          label: 'Subtotal adicionales',
                          value:
                              'RD\$${subtotalAdicionales.toStringAsFixed(0)}',
                        ),
                      ],
                    ],
                    if (cargoAplica > 0)
                      _SimRow(
                        label: 'Cargo fuera de ciudad',
                        value: 'RD\$${cargoAplica.toStringAsFixed(0)}',
                      ),
                    const Divider(),
                    _SimRow(
                      label: 'Total estimado',
                      value: 'RD\$${total.toStringAsFixed(0)}',
                      isTotal: true,
                    ),
                  ],
                ),
              ),
            ] else
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'Ingresa una cantidad solicitada para ver el cálculo.',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ),
          ],
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

      final XFile? file = await openFile(acceptedTypeGroups: [typeGroup]);

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

    final botId = _botId;
    if (botId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay bot seleccionado. Selecciona un bot primero.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

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
      // Campos nuevos
      tipoProducto: _tipoProducto,
      incluye: _emptyToNull(_incluyeController.text),
      permiteAdicionales: _permiteAdicionales,
      esCotizable: _esCotizable,
      orden: int.tryParse(_ordenController.text.trim()) ?? 0,
      cantidadBase: int.tryParse(_cantidadBaseController.text.trim()) ?? 1,
      unidadAdicionalNombre: _emptyToNull(_unidadAdicionalController.text),
      precioAdicional:
          double.tryParse(_precioAdicionalController.text.trim()) ?? 0,
      precioMinimoAdicional:
          double.tryParse(_precioMinimoAdicionalController.text.trim()) ?? 0,
      permiteCalculoAdicional: _permiteCalculoAdicional,
      ciudadBase: _ciudadBaseController.text.trim().isEmpty
          ? 'Higüey'
          : _ciudadBaseController.text.trim(),
      cargoFueraCiudad:
          double.tryParse(_cargoFueraCiudadController.text.trim()) ?? 0,
      aplicaCargoFueraCiudad: _aplicaCargoFueraCiudad,
      instalacionIncluida: _instalacionIncluida,
    );

    try {
      if (_isEditing) {
        await context.read<CatalogoProvider>().actualizarProducto(
          producto,
          botId: botId,
        );
      } else {
        await context.read<CatalogoProvider>().crearProducto(
          producto,
          botId: botId,
        );
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
        const SnackBar(content: Text('No se pudo guardar el producto')),
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

  const _SectionCard({required this.title, required this.children});

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
  final String? helperText;

  const _TextFieldApp({
    required this.controller,
    required this.label,
    this.requiredField = false,
    this.numberMustBePositive = false,
    this.maxLines = 1,
    this.keyboardType,
    this.helperText,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: requiredField ? '$label *' : label,
        helperText: helperText,
        helperMaxLines: 3,
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
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
        ],
      ],
    );
  }
}

// ============================================================
// DIÁLOGO: Agregar componente al kit
// ============================================================
class _AgregarComponenteDialog extends StatefulWidget {
  final CatalogoKitComponentesApiService kitComponentesService;
  final String botId;
  final String kitId;
  final bool incluidoInicial;
  final bool esOpcionalInicial;

  const _AgregarComponenteDialog({
    required this.kitComponentesService,
    required this.botId,
    required this.kitId,
    this.incluidoInicial = true,
    this.esOpcionalInicial = false,
  });

  @override
  State<_AgregarComponenteDialog> createState() =>
      _AgregarComponenteDialogState();
}

class _AgregarComponenteDialogState extends State<_AgregarComponenteDialog> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _resultados = [];
  bool _buscando = false;
  bool _guardando = false;

  String? _selectedComponenteId;
  String? _selectedTitulo;
  double _cantidad = 1;
  bool _incluido = true;
  bool _esOpcional = false;
  final _notaController = TextEditingController();
  int _orden = 0;

  @override
  void initState() {
    super.initState();
    _incluido = widget.incluidoInicial;
    _esOpcional = widget.esOpcionalInicial;
    _buscarProductos('');
  }

  @override
  void dispose() {
    _searchController.dispose();
    _notaController.dispose();
    super.dispose();
  }

  Future<void> _buscarProductos(String query) async {
    setState(() => _buscando = true);
    final resultados = await widget.kitComponentesService
        .buscarProductosParaComponente(botId: widget.botId, query: query);
    if (mounted) {
      setState(() {
        _resultados = resultados;
        _buscando = false;
      });
    }
  }

  Future<void> _guardar() async {
    if (_selectedComponenteId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Selecciona un producto')));
      return;
    }

    setState(() => _guardando = true);

    final data = {
      'componente_id': _selectedComponenteId,
      'cantidad': _cantidad,
      'incluido': _incluido,
      'es_opcional': _esOpcional,
      'nota': _notaController.text.trim().isEmpty
          ? null
          : _notaController.text.trim(),
      'orden': _orden,
    };

    final result = await widget.kitComponentesService.agregarComponenteKit(
      widget.kitId,
      data,
    );

    if (mounted) {
      setState(() => _guardando = false);
      if (result != null) {
        Navigator.pop(context, data);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al agregar componente'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _esOpcional
                        ? Icons.add_circle_outline
                        : Icons.inventory_2_outlined,
                    color: _esOpcional ? Colors.orange : Colors.teal,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _esOpcional
                        ? 'Agregar extra opcional'
                        : 'Agregar componente',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Buscador
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Buscar producto',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _buscando
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : null,
                ),
                onChanged: (value) {
                  _buscarProductos(value);
                },
              ),
              const SizedBox(height: 12),

              // Resultados
              if (_resultados.isEmpty && !_buscando)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      'No se encontraron productos disponibles.',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                )
              else
                SizedBox(
                  height: 200,
                  child: ListView.separated(
                    itemCount: _resultados.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, index) {
                      final item = _resultados[index];
                      final id = item['id'] as String? ?? '';
                      final titulo = item['titulo'] as String? ?? 'Sin título';
                      final precio = item['precio'];
                      final imagen = item['imagen1'] as String?;
                      final isSelected = _selectedComponenteId == id;

                      return ListTile(
                        selected: isSelected,
                        selectedTileColor: Colors.teal.shade50,
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            width: 40,
                            height: 40,
                            child: imagen != null && imagen.isNotEmpty
                                ? Image.network(
                                    imagen,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      color: Colors.grey.shade100,
                                      child: Icon(
                                        Icons.inventory_2_outlined,
                                        size: 20,
                                        color: Colors.grey.shade400,
                                      ),
                                    ),
                                  )
                                : Container(
                                    color: Colors.grey.shade100,
                                    child: Icon(
                                      Icons.inventory_2_outlined,
                                      size: 20,
                                      color: Colors.grey.shade400,
                                    ),
                                  ),
                          ),
                        ),
                        title: Text(
                          titulo,
                          style: const TextStyle(fontSize: 14),
                        ),
                        subtitle: precio != null
                            ? Text(
                                'RD\$${(precio is double ? precio : double.tryParse(precio.toString()) ?? 0).toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              )
                            : null,
                        onTap: () {
                          setState(() {
                            _selectedComponenteId = id;
                            _selectedTitulo = titulo;
                          });
                        },
                      );
                    },
                  ),
                ),

              if (_selectedComponenteId != null) ...[
                const Divider(height: 24),
                Text(
                  'Configurar: $_selectedTitulo',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Cantidad',
                        ),
                        keyboardType: TextInputType.number,
                        controller: TextEditingController(
                          text: _cantidad.toStringAsFixed(0),
                        ),
                        onChanged: (value) {
                          _cantidad = double.tryParse(value) ?? 1;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(labelText: 'Orden'),
                        keyboardType: TextInputType.number,
                        controller: TextEditingController(
                          text: _orden.toString(),
                        ),
                        onChanged: (value) {
                          _orden = int.tryParse(value) ?? 0;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _notaController,
                  decoration: const InputDecoration(
                    labelText: 'Nota (opcional)',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: SwitchListTile(
                        title: const Text(
                          'Incluido',
                          style: TextStyle(fontSize: 13),
                        ),
                        value: _incluido,
                        onChanged: (value) => setState(() {
                          _incluido = value;
                          if (value) _esOpcional = false;
                        }),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    Expanded(
                      child: SwitchListTile(
                        title: const Text(
                          'Opcional',
                          style: TextStyle(fontSize: 13),
                        ),
                        value: _esOpcional,
                        onChanged: (value) => setState(() {
                          _esOpcional = value;
                          if (value) _incluido = false;
                        }),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _guardando ? null : _guardar,
                      icon: _guardando
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.add_circle_outline, size: 18),
                      label: const Text('Agregar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// DIÁLOGO: Editar componente del kit
// ============================================================
class _EditarComponenteDialog extends StatefulWidget {
  final CatalogoKitComponenteModel componente;

  const _EditarComponenteDialog({required this.componente});

  @override
  State<_EditarComponenteDialog> createState() =>
      _EditarComponenteDialogState();
}

class _EditarComponenteDialogState extends State<_EditarComponenteDialog> {
  late final TextEditingController _cantidadController;
  late final TextEditingController _notaController;
  late final TextEditingController _ordenController;
  late bool _incluido;
  late bool _esOpcional;

  @override
  void initState() {
    super.initState();
    _cantidadController = TextEditingController(
      text: widget.componente.cantidad.toStringAsFixed(0),
    );
    _notaController = TextEditingController(text: widget.componente.nota ?? '');
    _ordenController = TextEditingController(
      text: widget.componente.orden.toString(),
    );
    _incluido = widget.componente.incluido;
    _esOpcional = widget.componente.esOpcional;
  }

  @override
  void dispose() {
    _cantidadController.dispose();
    _notaController.dispose();
    _ordenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.edit_outlined, color: Colors.teal.shade700),
                const SizedBox(width: 8),
                Text(
                  'Editar componente',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              widget.componente.titulo ?? 'Sin título',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _cantidadController,
                    decoration: const InputDecoration(labelText: 'Cantidad'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _ordenController,
                    decoration: const InputDecoration(labelText: 'Orden'),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notaController,
              decoration: const InputDecoration(labelText: 'Nota (opcional)'),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: SwitchListTile(
                    title: const Text(
                      'Incluido',
                      style: TextStyle(fontSize: 13),
                    ),
                    value: _incluido,
                    onChanged: (value) => setState(() {
                      _incluido = value;
                      if (value) _esOpcional = false;
                    }),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                Expanded(
                  child: SwitchListTile(
                    title: const Text(
                      'Opcional',
                      style: TextStyle(fontSize: 13),
                    ),
                    value: _esOpcional,
                    onChanged: (value) => setState(() {
                      _esOpcional = value;
                      if (value) _incluido = false;
                    }),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(context, {
                        'cantidad':
                            double.tryParse(_cantidadController.text.trim()) ??
                            1,
                        'incluido': _incluido,
                        'es_opcional': _esOpcional,
                        'nota': _notaController.text.trim().isEmpty
                            ? null
                            : _notaController.text.trim(),
                        'orden':
                            int.tryParse(_ordenController.text.trim()) ?? 0,
                      });
                    },
                    icon: const Icon(Icons.save_outlined, size: 18),
                    label: const Text('Guardar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SimRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;

  const _SimRow({
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.w800 : FontWeight.w500,
              color: isTotal ? Colors.blue.shade800 : Colors.grey.shade700,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.w800 : FontWeight.w600,
              color: isTotal ? Colors.blue.shade800 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
