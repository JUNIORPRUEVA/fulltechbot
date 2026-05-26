import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/bot_order_model.dart';
import '../providers/bot_order_provider.dart';
import 'bot_order_form_page.dart';

class BotOrderDetailPage extends StatelessWidget {
  final String botId;
  final BotOrderModel orden;

  const BotOrderDetailPage({
    super.key,
    required this.botId,
    required this.orden,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getColorEstado(orden.estadoPedido ?? 'pendiente');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de orden'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenu(context, value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'editar', child: Text('Editar')),
              const PopupMenuItem(
                value: 'estado',
                child: Text('Cambiar estado'),
              ),
              const PopupMenuItem(value: 'eliminar', child: Text('Eliminar')),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Estado
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Text(
                (orden.estadoPedido ?? 'pendiente').toUpperCase(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Producto/Servicio
          _InfoSection(
            title: 'Producto / Servicio',
            icon: Icons.shopping_bag_outlined,
            child: Text(
              orden.productoServicio ?? 'No especificado',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 16),

          // Cliente
          _InfoSection(
            title: 'Cliente',
            icon: Icons.person_outlined,
            children: [
              _InfoRow(
                label: 'Nombre',
                value: orden.nombreCliente ?? 'No especificado',
              ),
              _InfoRow(label: 'Teléfono', value: orden.telefonoCliente),
            ],
          ),
          const SizedBox(height: 16),

          // Servicio
          _InfoSection(
            title: 'Servicio',
            icon: Icons.build_outlined,
            children: [
              _InfoRow(
                label: 'Tipo',
                value: orden.tipoServicio ?? 'No especificado',
              ),
              if (orden.direccion != null)
                _InfoRow(label: 'Dirección', value: orden.direccion!),
              if (orden.fechaDeseada != null)
                _InfoRow(label: 'Fecha deseada', value: orden.fechaDeseada!),
            ],
          ),
          const SizedBox(height: 16),

          if ((orden.ubicacionGpsUrl ?? '').trim().isNotEmpty) ...[
            _InfoSection(
              title: 'Ubicacion',
              icon: Icons.map_outlined,
              child: _LocationCard(
                ubicacionUrl: orden.ubicacionGpsUrl!.trim(),
                onOpen: () =>
                    _abrirMapa(context, orden.ubicacionGpsUrl!.trim()),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Resumen
          if (orden.resumenPedido != null && orden.resumenPedido!.isNotEmpty)
            _InfoSection(
              title: 'Resumen',
              icon: Icons.notes_outlined,
              child: Text(
                orden.resumenPedido!,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              ),
            ),
          const SizedBox(height: 16),

          // Fechas
          _InfoSection(
            title: 'Fechas',
            icon: Icons.schedule_outlined,
            children: [
              if (orden.creadoEn != null)
                _InfoRow(label: 'Creado', value: _formatDate(orden.creadoEn!)),
              if (orden.actualizadoEn != null)
                _InfoRow(
                  label: 'Actualizado',
                  value: _formatDate(orden.actualizadoEn!),
                ),
            ],
          ),
          const SizedBox(height: 24),

          // Botones de acción
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _editar(context),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Editar'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _cambiarEstado(context),
                  icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                  label: const Text('Estado'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _eliminar(context),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Eliminar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleMenu(BuildContext context, String value) {
    switch (value) {
      case 'editar':
        _editar(context);
        break;
      case 'estado':
        _cambiarEstado(context);
        break;
      case 'eliminar':
        _eliminar(context);
        break;
    }
  }

  void _editar(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            BotOrderFormPage(botId: botId, botNombre: '', orden: orden),
      ),
    );
  }

  void _cambiarEstado(BuildContext context) {
    final estados = [
      'pendiente',
      'cotizado',
      'reservado',
      'confirmado',
      'completado',
      'cancelado',
    ];

    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Cambiar estado',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
              const Divider(height: 1),
              ...estados.map((estado) {
                final isSelected = orden.estadoPedido == estado;
                return ListTile(
                  leading: Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: isSelected ? _getColorEstado(estado) : null,
                  ),
                  title: Text(estado[0].toUpperCase() + estado.substring(1)),
                  selected: isSelected,
                  onTap: () {
                    Navigator.pop(ctx);
                    _confirmarCambioEstado(context, estado);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _confirmarCambioEstado(BuildContext context, String nuevoEstado) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cambiar estado'),
        content: Text('¿Cambiar estado a "$nuevoEstado"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await context.read<BotOrderProvider>().cambiarEstado(
                  botId,
                  orden.id,
                  nuevoEstado,
                );
                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Estado cambiado a "$nuevoEstado"'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  void _eliminar(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar orden'),
        content: const Text('¿Estás seguro de eliminar esta orden?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await context.read<BotOrderProvider>().eliminarOrden(
                  botId,
                  orden.id,
                );
                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Orden eliminada'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  Future<void> _abrirMapa(BuildContext context, String rawUrl) async {
    final uri = Uri.tryParse(rawUrl.trim());
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La ubicacion no tiene un enlace valido'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No se pudo abrir el mapa'),
        backgroundColor: Colors.red,
      ),
    );
  }

  Color _getColorEstado(String estado) {
    switch (estado) {
      case 'pendiente':
        return Colors.orange;
      case 'cotizado':
        return Colors.blue;
      case 'reservado':
        return Colors.purple;
      case 'confirmado':
        return Colors.teal;
      case 'completado':
        return Colors.green;
      case 'cancelado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget? child;
  final List<Widget>? children;

  const _InfoSection({
    required this.title,
    required this.icon,
    this.child,
    this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...[child, ...?children].whereType<Widget>(),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  final String ubicacionUrl;
  final VoidCallback onOpen;

  const _LocationCard({required this.ubicacionUrl, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'La ubicacion compartida en este pedido puede abrirse directo en el mapa.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 10),
          SelectableText(
            ubicacionUrl,
            style: TextStyle(
              fontSize: 13,
              color: Colors.blue.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: onOpen,
              icon: const Icon(Icons.map_rounded, size: 18),
              label: const Text('Abrir mapa'),
            ),
          ),
        ],
      ),
    );
  }
}
