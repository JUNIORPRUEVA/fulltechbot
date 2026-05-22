import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/bot_quotation_model.dart';
import '../providers/bot_quotation_provider.dart';

class BotQuotationFormPage extends StatefulWidget {
  final String botId;
  final String botNombre;
  final BotQuotationModel? cotizacion;

  const BotQuotationFormPage({
    super.key,
    required this.botId,
    required this.botNombre,
    this.cotizacion,
  });

  @override
  State<BotQuotationFormPage> createState() => _BotQuotationFormPageState();
}

class _BotQuotationFormPageState extends State<BotQuotationFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _numeroController;
  late final TextEditingController _telefonoController;
  late final TextEditingController _nombreController;
  late final TextEditingController _direccionController;
  late final TextEditingController _ciudadController;
  late final TextEditingController _sectorController;
  late final TextEditingController _tituloController;
  late final TextEditingController _descripcionController;
  late final TextEditingController _productosController;
  late final TextEditingController _subtotalController;
  late final TextEditingController _descuentoController;
  late final TextEditingController _totalController;
  late final TextEditingController _observacionesController;
  late final TextEditingController _condicionesController;
  late final TextEditingController _validaHastaController;
  String _moneda = 'DOP';
  String _estado = 'pendiente';
  bool _isSaving = false;

  bool get _isEditing => widget.cotizacion != null;

  static const List<String> _monedas = ['DOP', 'USD', 'EUR'];
  static const List<String> _estados = [
    'pendiente',
    'enviada',
    'aprobada',
    'rechazada',
    'vencida',
    'cancelada',
  ];

  @override
  void initState() {
    super.initState();
    final c = widget.cotizacion;
    _numeroController = TextEditingController(text: c?.numeroCotizacion ?? '');
    _telefonoController = TextEditingController(text: c?.telefonoCliente ?? '');
    _nombreController = TextEditingController(text: c?.nombreCliente ?? '');
    _direccionController = TextEditingController(text: c?.direccionCliente ?? '');
    _ciudadController = TextEditingController(text: c?.ciudad ?? '');
    _sectorController = TextEditingController(text: c?.sector ?? '');
    _tituloController = TextEditingController(text: c?.titulo ?? '');
    _descripcionController = TextEditingController(text: c?.descripcionGeneral ?? '');
    _productosController = TextEditingController(
      text: c?.productos != null ? c!.productos.toString() : '',
    );
    _subtotalController = TextEditingController(
      text: c != null ? c.subtotal.toString() : '0',
    );
    _descuentoController = TextEditingController(
      text: c != null ? c.descuento.toString() : '0',
    );
    _totalController = TextEditingController(
      text: c != null ? c.total.toString() : '0',
    );
    _observacionesController = TextEditingController(text: c?.observaciones ?? '');
    _condicionesController = TextEditingController(text: c?.condiciones ?? '');
    _validaHastaController = TextEditingController(
      text: c?.validaHasta != null
          ? '${c!.validaHasta!.year}-${c.validaHasta!.month.toString().padLeft(2, '0')}-${c.validaHasta!.day.toString().padLeft(2, '0')}'
          : '',
    );
    _moneda = c?.moneda ?? 'DOP';
    _estado = c?.estado ?? 'pendiente';
  }

  @override
  void dispose() {
    _numeroController.dispose();
    _telefonoController.dispose();
    _nombreController.dispose();
    _direccionController.dispose();
    _ciudadController.dispose();
    _sectorController.dispose();
    _tituloController.dispose();
    _descripcionController.dispose();
    _productosController.dispose();
    _subtotalController.dispose();
    _descuentoController.dispose();
    _totalController.dispose();
    _observacionesController.dispose();
    _condicionesController.dispose();
    _validaHastaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar cotización' : 'Nueva cotización'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Banner del bot
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.indigo.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.smart_toy_outlined, size: 18, color: Colors.indigo.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Cotización para: ${widget.botNombre}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.indigo.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Número de cotización
            TextFormField(
              controller: _numeroController,
              decoration: const InputDecoration(
                labelText: 'Número de cotización (opcional)',
                prefixIcon: Icon(Icons.tag_outlined),
                border: OutlineInputBorder(),
                hintText: 'Se genera automáticamente si se deja vacío',
              ),
            ),
            const SizedBox(height: 16),

            // Teléfono
            TextFormField(
              controller: _telefonoController,
              decoration: const InputDecoration(
                labelText: 'Teléfono del cliente *',
                prefixIcon: Icon(Icons.phone_outlined),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'El teléfono es obligatorio';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Nombre
            TextFormField(
              controller: _nombreController,
              decoration: const InputDecoration(
                labelText: 'Nombre del cliente',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Dirección
            TextFormField(
              controller: _direccionController,
              decoration: const InputDecoration(
                labelText: 'Dirección del cliente',
                prefixIcon: Icon(Icons.location_on_outlined),
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Ciudad y Sector
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _ciudadController,
                    decoration: const InputDecoration(
                      labelText: 'Ciudad',
                      prefixIcon: Icon(Icons.location_city_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _sectorController,
                    decoration: const InputDecoration(
                      labelText: 'Sector',
                      prefixIcon: Icon(Icons.map_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Título
            TextFormField(
              controller: _tituloController,
              decoration: const InputDecoration(
                labelText: 'Título de la cotización',
                prefixIcon: Icon(Icons.title_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Descripción
            TextFormField(
              controller: _descripcionController,
              decoration: const InputDecoration(
                labelText: 'Descripción general',
                prefixIcon: Icon(Icons.description_outlined),
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Productos (JSON)
            TextFormField(
              controller: _productosController,
              decoration: const InputDecoration(
                labelText: 'Productos (JSON o lista)',
                prefixIcon: Icon(Icons.inventory_2_outlined),
                border: OutlineInputBorder(),
                hintText: 'Ej: [{"nombre": "Cámara", "precio": 5000}]',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Subtotal, Descuento, Total
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _subtotalController,
                    decoration: const InputDecoration(
                      labelText: 'Subtotal',
                      prefixIcon: Icon(Icons.attach_money_outlined),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _calcularTotal(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _descuentoController,
                    decoration: const InputDecoration(
                      labelText: 'Descuento',
                      prefixIcon: Icon(Icons.discount_outlined),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _calcularTotal(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _totalController,
                    decoration: const InputDecoration(
                      labelText: 'Total',
                      prefixIcon: Icon(Icons.payments_outlined),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Moneda
            DropdownButtonFormField<String>(
              initialValue: _moneda,
              decoration: const InputDecoration(
                labelText: 'Moneda',
                prefixIcon: Icon(Icons.currency_exchange_outlined),
                border: OutlineInputBorder(),
              ),
              items: _monedas.map((m) {
                return DropdownMenuItem(value: m, child: Text(m));
              }).toList(),
              onChanged: (value) {
                if (value != null) setState(() => _moneda = value);
              },
            ),
            const SizedBox(height: 16),

            // Estado (solo en edición)
            if (_isEditing) ...[
              DropdownButtonFormField<String>(
                initialValue: _estado,
                decoration: const InputDecoration(
                  labelText: 'Estado',
                  prefixIcon: Icon(Icons.flag_outlined),
                  border: OutlineInputBorder(),
                ),
                items: _estados.map((e) {
                  return DropdownMenuItem(
                    value: e,
                    child: Text(e[0].toUpperCase() + e.substring(1)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _estado = value);
                },
              ),
              const SizedBox(height: 16),
            ],

            // Observaciones
            TextFormField(
              controller: _observacionesController,
              decoration: const InputDecoration(
                labelText: 'Observaciones',
                prefixIcon: Icon(Icons.notes_outlined),
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Condiciones
            TextFormField(
              controller: _condicionesController,
              decoration: const InputDecoration(
                labelText: 'Condiciones',
                prefixIcon: Icon(Icons.rule_outlined),
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Válida hasta
            TextFormField(
              controller: _validaHastaController,
              decoration: const InputDecoration(
                labelText: 'Válida hasta (YYYY-MM-DD)',
                prefixIcon: Icon(Icons.date_range_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            // Botón guardar
            FilledButton.icon(
              onPressed: _isSaving ? null : _guardar,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save_rounded),
              label: Text(_isEditing ? 'Actualizar cotización' : 'Crear cotización'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _calcularTotal() {
    final sub = double.tryParse(_subtotalController.text) ?? 0;
    final desc = double.tryParse(_descuentoController.text) ?? 0;
    _totalController.text = (sub - desc).toStringAsFixed(2);
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final sub = double.tryParse(_subtotalController.text) ?? 0;
    final desc = double.tryParse(_descuentoController.text) ?? 0;
    final total = double.tryParse(_totalController.text) ?? (sub - desc);

    final data = {
      'numero_cotizacion': _numeroController.text.trim().isEmpty
          ? null
          : _numeroController.text.trim(),
      'telefono_cliente': _telefonoController.text.trim(),
      'nombre_cliente': _nombreController.text.trim().isEmpty
          ? null
          : _nombreController.text.trim(),
      'direccion_cliente': _direccionController.text.trim().isEmpty
          ? null
          : _direccionController.text.trim(),
      'ciudad': _ciudadController.text.trim().isEmpty
          ? null
          : _ciudadController.text.trim(),
      'sector': _sectorController.text.trim().isEmpty
          ? null
          : _sectorController.text.trim(),
      'titulo': _tituloController.text.trim().isEmpty
          ? 'Cotización de servicios'
          : _tituloController.text.trim(),
      'descripcion_general': _descripcionController.text.trim().isEmpty
          ? null
          : _descripcionController.text.trim(),
      'productos': _productosController.text.trim().isEmpty
          ? []
          : _productosController.text.trim(),
      'subtotal': sub,
      'descuento': desc,
      'total': total,
      'moneda': _moneda,
      'observaciones': _observacionesController.text.trim().isEmpty
          ? null
          : _observacionesController.text.trim(),
      'condiciones': _condicionesController.text.trim().isEmpty
          ? null
          : _condicionesController.text.trim(),
      'valida_hasta': _validaHastaController.text.trim().isEmpty
          ? null
          : _validaHastaController.text.trim(),
    };

    if (_isEditing) {
      data['estado'] = _estado;
    }

    try {
      final provider = context.read<BotQuotationProvider>();
      if (_isEditing) {
        await provider.actualizarCotizacion(
            widget.botId, widget.cotizacion!.id, data);
      } else {
        await provider.crearCotizacion(widget.botId, data);
      }

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(_isEditing ? 'Cotización actualizada' : 'Cotización creada'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
