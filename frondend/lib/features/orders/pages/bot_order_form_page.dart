import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/bot_order_model.dart';
import '../providers/bot_order_provider.dart';

class BotOrderFormPage extends StatefulWidget {
  final String botId;
  final String botNombre;
  final BotOrderModel? orden;

  const BotOrderFormPage({
    super.key,
    required this.botId,
    required this.botNombre,
    this.orden,
  });

  @override
  State<BotOrderFormPage> createState() => _BotOrderFormPageState();
}

class _BotOrderFormPageState extends State<BotOrderFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _telefonoController;
  late final TextEditingController _nombreController;
  late final TextEditingController _productoController;
  late final TextEditingController _direccionController;
  late final TextEditingController _ubicacionController;
  late final TextEditingController _fechaController;
  late final TextEditingController _resumenController;
  String _tipoServicio = 'otro';
  String _estadoPedido = 'pendiente';
  bool _isSaving = false;

  bool get _isEditing => widget.orden != null;

  static const List<String> _tiposServicio = [
    'instalacion',
    'reparacion',
    'mantenimiento',
    'venta',
    'consultoria',
    'otro',
  ];

  static const List<String> _estados = [
    'pendiente',
    'cotizado',
    'reservado',
    'confirmado',
    'completado',
    'cancelado',
  ];

  @override
  void initState() {
    super.initState();
    _telefonoController = TextEditingController(
      text: widget.orden?.telefonoCliente ?? '',
    );
    _nombreController = TextEditingController(
      text: widget.orden?.nombreCliente ?? '',
    );
    _productoController = TextEditingController(
      text: widget.orden?.productoServicio ?? '',
    );
    _direccionController = TextEditingController(
      text: widget.orden?.direccion ?? '',
    );
    _ubicacionController = TextEditingController(
      text: widget.orden?.ubicacionGpsUrl ?? '',
    );
    _fechaController = TextEditingController(
      text: widget.orden?.fechaDeseada ?? '',
    );
    _resumenController = TextEditingController(
      text: widget.orden?.resumenPedido ?? '',
    );
    _tipoServicio = widget.orden?.tipoServicio ?? 'otro';
    _estadoPedido = widget.orden?.estadoPedido ?? 'pendiente';
  }

  @override
  void dispose() {
    _telefonoController.dispose();
    _nombreController.dispose();
    _productoController.dispose();
    _direccionController.dispose();
    _ubicacionController.dispose();
    _fechaController.dispose();
    _resumenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Editar orden' : 'Nueva orden')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Banner del bot
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.smart_toy_outlined,
                    size: 18,
                    color: Colors.blue.shade600,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Orden para: ${widget.botNombre}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

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

            // Producto/Servicio
            TextFormField(
              controller: _productoController,
              decoration: const InputDecoration(
                labelText: 'Producto / Servicio',
                prefixIcon: Icon(Icons.shopping_bag_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Tipo de servicio
            DropdownButtonFormField<String>(
              initialValue: _tipoServicio,
              decoration: const InputDecoration(
                labelText: 'Tipo de servicio',
                prefixIcon: Icon(Icons.build_outlined),
                border: OutlineInputBorder(),
              ),
              items: _tiposServicio.map((tipo) {
                return DropdownMenuItem(
                  value: tipo,
                  child: Text(tipo[0].toUpperCase() + tipo.substring(1)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) setState(() => _tipoServicio = value);
              },
            ),
            const SizedBox(height: 16),

            // Dirección
            TextFormField(
              controller: _direccionController,
              decoration: const InputDecoration(
                labelText: 'Dirección',
                prefixIcon: Icon(Icons.location_on_outlined),
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _ubicacionController,
              decoration: const InputDecoration(
                labelText: 'Link de ubicacion / mapa',
                prefixIcon: Icon(Icons.map_outlined),
                border: OutlineInputBorder(),
                hintText: 'Ej: https://maps.google.com/...',
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 16),

            // Fecha deseada
            TextFormField(
              controller: _fechaController,
              decoration: InputDecoration(
                labelText: 'Fecha deseada',
                prefixIcon: const Icon(Icons.calendar_today_outlined),
                border: const OutlineInputBorder(),
                hintText: 'Ej: 2025-06-15 o "Lo antes posible"',
              ),
            ),
            const SizedBox(height: 16),

            // Estado (solo en edición)
            if (_isEditing) ...[
              DropdownButtonFormField<String>(
                initialValue: _estadoPedido,
                decoration: const InputDecoration(
                  labelText: 'Estado del pedido',
                  prefixIcon: Icon(Icons.flag_outlined),
                  border: OutlineInputBorder(),
                ),
                items: _estados.map((estado) {
                  return DropdownMenuItem(
                    value: estado,
                    child: Text(estado[0].toUpperCase() + estado.substring(1)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _estadoPedido = value);
                },
              ),
              const SizedBox(height: 16),
            ],

            // Resumen
            TextFormField(
              controller: _resumenController,
              decoration: const InputDecoration(
                labelText: 'Resumen del pedido',
                prefixIcon: Icon(Icons.notes_outlined),
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
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
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_rounded),
              label: Text(_isEditing ? 'Actualizar orden' : 'Crear orden'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final data = {
      'telefono_cliente': _telefonoController.text.trim(),
      'nombre_cliente': _nombreController.text.trim().isEmpty
          ? null
          : _nombreController.text.trim(),
      'producto_servicio': _productoController.text.trim().isEmpty
          ? null
          : _productoController.text.trim(),
      'tipo_servicio': _tipoServicio,
      'direccion': _direccionController.text.trim().isEmpty
          ? null
          : _direccionController.text.trim(),
      'ubicacion_gps_url': _ubicacionController.text.trim().isEmpty
          ? null
          : _ubicacionController.text.trim(),
      'fecha_deseada': _fechaController.text.trim().isEmpty
          ? null
          : _fechaController.text.trim(),
      'resumen_pedido': _resumenController.text.trim().isEmpty
          ? null
          : _resumenController.text.trim(),
    };

    if (_isEditing) {
      data['estado_pedido'] = _estadoPedido;
    }

    try {
      final provider = context.read<BotOrderProvider>();
      if (_isEditing) {
        await provider.actualizarOrden(widget.botId, widget.orden!.id, data);
      } else {
        await provider.crearOrden(widget.botId, data);
      }

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'Orden actualizada' : 'Orden creada'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
