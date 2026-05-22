import 'package:flutter/material.dart';
import '../models/catalogo_kit_componente_model.dart';
import '../services/catalogo_kit_componentes_api_service.dart';

/// Sección visual para gestionar componentes de un kit.
/// Solo debe mostrarse cuando tipoProducto == 'kit'.
class KitComponentesSection extends StatefulWidget {
  final String kitId;
  final String botId;
  final CatalogoKitComponentesApiService apiService;
  final List<CatalogoKitComponenteModel> componentesIniciales;

  const KitComponentesSection({
    super.key,
    required this.kitId,
    required this.botId,
    required this.apiService,
    this.componentesIniciales = const [],
  });

  @override
  State<KitComponentesSection> createState() => _KitComponentesSectionState();
}

class _KitComponentesSectionState extends State<KitComponentesSection> {
  late List<CatalogoKitComponenteModel> _componentes;
  bool _cargando = false;

  @override
  void initState() {
    super.initState();
    _componentes = List.from(widget.componentesIniciales);
  }

  Future<void> _recargarComponentes() async {
    if (widget.kitId.isEmpty) return;
    setState(() => _cargando = true);
    final componentes =
        await widget.apiService.obtenerComponentesKit(widget.kitId);
    if (mounted) {
      setState(() {
        _componentes = componentes;
        _cargando = false;
      });
    }
  }

  Future<void> _abrirModalAgregar({bool esOpcional = false}) async {
    if (widget.kitId.isEmpty) return;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _AgregarComponenteDialog(
        apiService: widget.apiService,
        botId: widget.botId,
        kitId: widget.kitId,
        esOpcionalInicial: esOpcional,
        componentesExistentes: _componentes,
      ),
    );

    if (result != null && mounted) {
      await _recargarComponentes();
    }
  }

  Future<void> _abrirModalEditar(CatalogoKitComponenteModel comp) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _EditarComponenteDialog(componente: comp),
    );

    if (result != null && mounted) {
      await widget.apiService
          .actualizarComponenteKit(widget.kitId, comp.id, result);
      await _recargarComponentes();
    }
  }

  Future<void> _confirmarEliminar(CatalogoKitComponenteModel comp) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Icons.remove_circle_outline,
                color: Colors.red.shade600, size: 22),
            const SizedBox(width: 8),
            const Text('Quitar componente'),
          ],
        ),
        content: Text(
          '¿Seguro que deseas quitar "${comp.titulo ?? 'este componente'}" del kit? '
          'El producto seguirá existiendo en el catálogo, solo se eliminará la relación con este kit.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Quitar'),
          ),
        ],
      ),
    );

    if (confirmar == true && mounted) {
      await widget.apiService.eliminarComponenteKit(widget.kitId, comp.id);
      await _recargarComponentes();
    }
  }

  @override
  Widget build(BuildContext context) {
    final incluidos = _componentes.where((c) => !c.esOpcional).toList();
    final opcionales = _componentes.where((c) => c.esOpcional).toList();

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
            // Título
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.inventory_2_rounded,
                    color: Colors.teal.shade700,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Componentes del kit',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.teal.shade800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Selecciona productos reales del catálogo para indicar qué incluye este kit y qué extras puede agregar el cliente.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.teal.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Estado de carga
            if (_cargando)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              )
            else ...[
              // Lista de componentes
              if (_componentes.isEmpty)
                _buildEmptyState()
              else ...[
                // Incluidos
                if (incluidos.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle,
                            size: 16, color: Colors.teal.shade600),
                        const SizedBox(width: 6),
                        Text(
                          'Incluidos en el kit',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.teal.shade700,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${incluidos.length} producto${incluidos.length != 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.teal.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...incluidos.map((comp) => _buildComponenteCard(comp)),
                ],
                // Extras opcionales
                if (opcionales.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(Icons.add_circle_outline,
                            size: 16, color: Colors.orange.shade600),
                        const SizedBox(width: 6),
                        Text(
                          'Extras opcionales',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange.shade700,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${opcionales.length} extra${opcionales.length != 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.orange.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...opcionales.map((comp) => _buildComponenteCard(comp)),
                ],
              ],
              const SizedBox(height: 16),

              // Botones
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: widget.kitId.isNotEmpty
                          ? () => _abrirModalAgregar()
                          : null,
                      icon: const Icon(Icons.add_circle_outline, size: 18),
                      label: const Text('Agregar componente incluido'),
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
                      onPressed: widget.kitId.isNotEmpty
                          ? () => _abrirModalAgregar(esOpcional: true)
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
              if (widget.kitId.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Guarda el producto primero para poder agregar componentes.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal.shade100),
      ),
      child: Column(
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 48,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 12),
          Text(
            'No hay componentes agregados todavía.',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Agrega los productos que incluye este kit.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade500,
            ),
          ),
        ],
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen del producto
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
                          child: Icon(Icons.inventory_2_outlined,
                              color: Colors.grey.shade400),
                        ),
                      )
                    : Container(
                        color: Colors.grey.shade100,
                        child: Icon(Icons.inventory_2_outlined,
                            color: Colors.grey.shade400),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            // Información
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título
                  Text(
                    comp.titulo ?? 'Sin título',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Categoría y tipo
                  Row(
                    children: [
                      if (comp.categoria != null && comp.categoria!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            comp.categoria!,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      if (comp.tipoProducto != null) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            comp.tipoProducto!,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.blue.shade600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Cantidad y precio
                  Row(
                    children: [
                      Icon(Icons.production_quantity_limits,
                          size: 12, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        'Cant: ${comp.cantidad.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (comp.precio != null && comp.precio! > 0) ...[
                        const SizedBox(width: 12),
                        Icon(Icons.attach_money,
                            size: 12, color: Colors.green.shade600),
                        const SizedBox(width: 2),
                        Text(
                          'RD\$${comp.precio!.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ],
                  ),
                  // Nota
                  if (comp.nota != null && comp.nota!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        comp.nota!,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
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
            const SizedBox(width: 4),
            // Botones
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  onPressed: comp.id.isNotEmpty
                      ? () => _abrirModalEditar(comp)
                      : null,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 28,
                    minHeight: 28,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline,
                      size: 16, color: Colors.red.shade400),
                  onPressed: comp.id.isNotEmpty
                      ? () => _confirmarEliminar(comp)
                      : null,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 28,
                    minHeight: 28,
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

// ============================================================
// DIÁLOGO: Agregar componente al kit
// ============================================================
class _AgregarComponenteDialog extends StatefulWidget {
  final CatalogoKitComponentesApiService apiService;
  final String botId;
  final String kitId;
  final bool esOpcionalInicial;
  final List<CatalogoKitComponenteModel> componentesExistentes;

  const _AgregarComponenteDialog({
    required this.apiService,
    required this.botId,
    required this.kitId,
    this.esOpcionalInicial = false,
    this.componentesExistentes = const [],
  });

  @override
  State<_AgregarComponenteDialog> createState() =>
      _AgregarComponenteDialogState();
}

class _AgregarComponenteDialogState
    extends State<_AgregarComponenteDialog> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _resultados = [];
  bool _buscando = false;
  bool _guardando = false;

  String? _selectedComponenteId;
  String? _selectedTitulo;
  String? _selectedCategoria;
  String? _selectedTipoProducto;
  double? _selectedPrecio;
  String? _selectedImagen;
  double _cantidad = 1;
  bool _incluido = true;
  bool _esOpcional = false;
  final _notaController = TextEditingController();
  int _orden = 0;

  // Filtro por tipo
  String _filtroTipo = 'todos';

  @override
  void initState() {
    super.initState();
    _esOpcional = widget.esOpcionalInicial;
    _incluido = !widget.esOpcionalInicial;
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
    final resultados = await widget.apiService.buscarProductosParaComponente(
      botId: widget.botId,
      query: query,
      excludeKitId: widget.kitId,
    );
    if (mounted) {
      setState(() {
        _resultados = resultados;
        _buscando = false;
      });
    }
  }

  List<Map<String, dynamic>> get _resultadosFiltrados {
    if (_filtroTipo == 'todos') return _resultados;
    return _resultados.where((r) {
      final tipo = (r['tipoProducto'] as String? ??
              r['tipo_producto'] as String? ??
              '')
          .toLowerCase();
      return tipo == _filtroTipo.toLowerCase();
    }).toList();
  }

  bool _esDuplicado(String componenteId) {
    return widget.componentesExistentes
        .any((c) => c.componenteId == componenteId);
  }

  Future<void> _guardar() async {
    if (_selectedComponenteId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un producto')),
      );
      return;
    }

    if (_cantidad <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La cantidad debe ser mayor que 0')),
      );
      return;
    }

    if (_esDuplicado(_selectedComponenteId!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Este producto ya está en el kit. Edita la cantidad en su lugar.'),
        ),
      );
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

    final result =
        await widget.apiService.agregarComponenteKit(widget.kitId, data);

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
    final resultadosFiltrados = _resultadosFiltrados;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _esOpcional
                          ? Colors.orange.shade100
                          : Colors.teal.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _esOpcional
                          ? Icons.add_circle_outline
                          : Icons.inventory_2_outlined,
                      color: _esOpcional ? Colors.orange : Colors.teal,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _esOpcional
                              ? 'Agregar extra opcional'
                              : 'Agregar componente al kit',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          _esOpcional
                              ? 'Selecciona un producto como extra opcional'
                              : 'Selecciona un producto del catálogo',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
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
                  hintText:
                      'Buscar cámara, DVR, disco, fuente, instalación...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _buscando
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _buscarProductos('');
                              },
                            )
                          : null,
                ),
                onChanged: (value) {
                  _buscarProductos(value);
                },
              ),
              const SizedBox(height: 12),

              // Filtros por tipo
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    'todos',
                    'componente',
                    'accesorio',
                    'repuesto',
                    'servicio',
                    'extra',
                    'producto',
                  ]
                      .map((tipo) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(
                                tipo == 'todos'
                                    ? 'Todos'
                                    : tipo[0].toUpperCase() +
                                        tipo.substring(1),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight:
                                      _filtroTipo == tipo
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                ),
                              ),
                              selected: _filtroTipo == tipo,
                              onSelected: (selected) {
                                setState(() => _filtroTipo = tipo);
                              },
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                          ))
                      .toList(),
                ),
              ),
              const SizedBox(height: 12),

              // Resultados
              if (_buscando)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (resultadosFiltrados.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.search_off,
                            size: 40, color: Colors.grey.shade300),
                        const SizedBox(height: 8),
                        Text(
                          'No se encontraron productos disponibles.',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SizedBox(
                  height: 220,
                  child: ListView.separated(
                    itemCount: resultadosFiltrados.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1),
                    itemBuilder: (_, index) {
                      final item = resultadosFiltrados[index];
                      final id = item['id'] as String? ?? '';
                      final titulo =
                          item['titulo'] as String? ?? 'Sin título';
                      final categoria =
                          item['categoria'] as String?;
                      final tipoProducto = (item['tipoProducto'] ??
                              item['tipo_producto'])
                          as String?;
                      final precio = item['precio'];
                      final imagen = item['imagen1'] as String?;
                      final stock = item['stock'];
                      final isSelected = _selectedComponenteId == id;
                      final esDuplicado = _esDuplicado(id);

                      return Opacity(
                        opacity: esDuplicado ? 0.5 : 1.0,
                        child: ListTile(
                          selected: isSelected,
                          selectedTileColor:
                              Colors.teal.shade50,
                          leading: ClipRRect(
                            borderRadius:
                                BorderRadius.circular(8),
                            child: SizedBox(
                              width: 44,
                              height: 44,
                              child: imagen != null &&
                                      imagen.isNotEmpty
                                  ? Image.network(
                                      imagen,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (_, __, ___) =>
                                              Container(
                                        color: Colors
                                            .grey.shade100,
                                        child: Icon(
                                            Icons
                                                .inventory_2_outlined,
                                            size: 20,
                                            color: Colors
                                                .grey
                                                .shade400),
                                      ),
                                    )
                                  : Container(
                                      color: Colors
                                          .grey.shade100,
                                      child: Icon(
                                          Icons
                                              .inventory_2_outlined,
                                          size: 20,
                                          color: Colors
                                              .grey
                                              .shade400),
                                    ),
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  titulo,
                                  style: const TextStyle(
                                      fontSize: 13),
                                  overflow:
                                      TextOverflow.ellipsis,
                                ),
                              ),
                              if (esDuplicado)
                                Container(
                                  padding: const EdgeInsets
                                      .symmetric(
                                      horizontal: 6,
                                      vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors
                                        .grey.shade100,
                                    borderRadius:
                                        BorderRadius.circular(
                                            4),
                                  ),
                                  child: Text(
                                    'Ya agregado',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color:
                                          Colors.grey.shade600,
                                      fontWeight:
                                          FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Row(
                            children: [
                              if (categoria != null)
                                Text(
                                  categoria,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color:
                                        Colors.grey.shade600,
                                  ),
                                ),
                              if (tipoProducto != null) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets
                                      .symmetric(
                                      horizontal: 4,
                                      vertical: 1),
                                  decoration: BoxDecoration(
                                    color: Colors
                                        .blue.shade50,
                                    borderRadius:
                                        BorderRadius.circular(
                                            3),
                                  ),
                                  child: Text(
                                    tipoProducto,
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: Colors
                                          .blue.shade600,
                                    ),
                                  ),
                                ),
                              ],
                              const Spacer(),
                              if (precio != null)
                                Text(
                                  'RD\$${(precio is double
                                          ? precio
                                          : double.tryParse(
                                                  precio
                                                      .toString()) ??
                                              0)
                                      .toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color:
                                        Colors.green.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              if (stock != null &&
                                  stock is int &&
                                  stock > 0) ...[
                                const SizedBox(width: 4),
                                Text(
                                  'Stock: $stock',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color:
                                        Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          onTap: esDuplicado
                              ? null
                              : () {
                                  setState(() {
                                    _selectedComponenteId =
                                        id;
                                    _selectedTitulo = titulo;
                                    _selectedCategoria =
                                        categoria;
                                    _selectedTipoProducto =
                                        tipoProducto;
                                    _selectedPrecio =
                                        precio is double
                                            ? precio
                                            : double.tryParse(
                                                    precio
                                                            ?.toString() ??
                                                        '') ??
                                                0;
                                    _selectedImagen = imagen;
                                  });
                                },
                        ),
                      );
                    },
                  ),
                ),

              // Configuración del componente seleccionado
              if (_selectedComponenteId != null) ...[
                const Divider(height: 24),
                // Producto seleccionado
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Colors.teal.shade200),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius:
                            BorderRadius.circular(8),
                        child: SizedBox(
                          width: 40,
                          height: 40,
                          child: _selectedImagen != null &&
                                  _selectedImagen!.isNotEmpty
                              ? Image.network(
                                  _selectedImagen!,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (_, __, ___) =>
                                          Container(
                                    color: Colors
                                        .grey.shade100,
                                    child: Icon(
                                        Icons
                                            .inventory_2_outlined,
                                        size: 18,
                                        color: Colors
                                            .grey
                                            .shade400),
                                  ),
                                )
                              : Container(
                                  color: Colors
                                      .grey.shade100,
                                  child: Icon(
                                      Icons
                                          .inventory_2_outlined,
                                      size: 18,
                                      color: Colors
                                          .grey
                                          .shade400),
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedTitulo ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            if (_selectedCategoria != null)
                              Text(
                                _selectedCategoria!,
                                style: TextStyle(
                                  fontSize: 11,
                                  color:
                                      Colors.grey.shade600,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (_selectedPrecio != null &&
                          _selectedPrecio! > 0)
                        Text(
                          'RD\$${_selectedPrecio!.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.green.shade700,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Cantidad y orden
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Cantidad *',
                          helperText:
                              'Debe ser mayor que 0',
                        ),
                        keyboardType: TextInputType.number,
                        controller: TextEditingController(
                          text: _cantidad
                              .toStringAsFixed(0),
                        ),
                        onChanged: (value) {
                          _cantidad =
                              double.tryParse(value) ?? 1;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Orden',
                          helperText:
                              'Posición en el kit',
                        ),
                        keyboardType: TextInputType.number,
                        controller: TextEditingController(
                          text: _orden.toString(),
                        ),
                        onChanged: (value) {
                          _orden =
                              int.tryParse(value) ?? 0;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Nota
                TextField(
                  controller: _notaController,
                  decoration: const InputDecoration(
                    labelText: 'Nota (opcional)',
                    helperText:
                        'Ej: Incluye cableado básico',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),

                // Tipo de relación
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tipo de relación',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _TipoRelacionChip(
                              icon: Icons.check_circle,
                              label: 'Incluido en el kit',
                              selected: _incluido &&
                                  !_esOpcional,
                              color: Colors.teal,
                              onTap: () => setState(() {
                                _incluido = true;
                                _esOpcional = false;
                              }),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _TipoRelacionChip(
                              icon: Icons.add_circle_outline,
                              label: 'Extra opcional',
                              selected: _esOpcional,
                              color: Colors.orange,
                              onTap: () => setState(() {
                                _esOpcional = true;
                                _incluido = false;
                              }),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),
              // Botones
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
            // Título
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.edit_outlined,
                    color: Colors.teal.shade700,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Editar componente del kit',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        widget.componente.titulo ?? 'Sin título',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Cantidad y orden
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _cantidadController,
                    decoration: const InputDecoration(
                      labelText: 'Cantidad',
                      helperText: 'Debe ser mayor que 0',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _ordenController,
                    decoration: const InputDecoration(
                      labelText: 'Orden',
                      helperText: 'Posición en el kit',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Nota
            TextField(
              controller: _notaController,
              decoration: const InputDecoration(
                labelText: 'Nota (opcional)',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),

            // Tipo de relación
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tipo de relación',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _TipoRelacionChip(
                          icon: Icons.check_circle,
                          label: 'Incluido en el kit',
                          selected: _incluido && !_esOpcional,
                          color: Colors.teal,
                          onTap: () => setState(() {
                            _incluido = true;
                            _esOpcional = false;
                          }),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _TipoRelacionChip(
                          icon: Icons.add_circle_outline,
                          label: 'Extra opcional',
                          selected: _esOpcional,
                          color: Colors.orange,
                          onTap: () => setState(() {
                            _esOpcional = true;
                            _incluido = false;
                          }),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Botones
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
                    label: const Text('Guardar cambios'),
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

// ============================================================
// WIDGET: Chip de tipo de relación
// ============================================================
class _TipoRelacionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _TipoRelacionChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.1)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? color : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? color : Colors.grey.shade500,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? color : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
