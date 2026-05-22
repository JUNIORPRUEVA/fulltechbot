import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/bot_quotation_model.dart';
import '../providers/bot_quotation_provider.dart';
import 'bot_quotation_form_page.dart';

class BotQuotationDetailPage extends StatelessWidget {
  final String botId;
  final BotQuotationModel cotizacion;

  const BotQuotationDetailPage({
    super.key,
    required this.botId,
    required this.cotizacion,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getColorEstado(cotizacion.estado);

    return Scaffold(
      appBar: AppBar(
        title: Text(cotizacion.numeroCotizacion.isNotEmpty
            ? cotizacion.numeroCotizacion
            : 'Cotización'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenu(context, value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'editar', child: Text('Editar')),
              const PopupMenuItem(value: 'estado', child: Text('Cambiar estado')),
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
                cotizacion.estado.toUpperCase(),
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

          // Título
          if (cotizacion.titulo != null && cotizacion.titulo!.isNotEmpty)
            _InfoSection(
              title: 'Título',
              icon: Icons.title_outlined,
              child: Text(
                cotizacion.titulo!,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
          if (cotizacion.titulo != null && cotizacion.titulo!.isNotEmpty)
            const SizedBox(height: 16),

          // Cliente
          _InfoSection(
            title: 'Cliente',
            icon: Icons.person_outlined,
            children: [
              _InfoRow(label: 'Nombre', value: cotizacion.nombreCliente ?? 'No especificado'),
              _InfoRow(label: 'Teléfono', value: cotizacion.telefonoCliente),
              if (cotizacion.direccionCliente != null)
                _InfoRow(label: 'Dirección', value: cotizacion.direccionCliente!),
              if (cotizacion.ciudad != null)
                _InfoRow(label: 'Ciudad', value: cotizacion.ciudad!),
              if (cotizacion.sector != null)
                _InfoRow(label: 'Sector', value: cotizacion.sector!),
            ],
          ),
          const SizedBox(height: 16),

          // Descripción
          if (cotizacion.descripcionGeneral != null &&
              cotizacion.descripcionGeneral!.isNotEmpty)
            _InfoSection(
              title: 'Descripción',
              icon: Icons.description_outlined,
              child: Text(
                cotizacion.descripcionGeneral!,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              ),
            ),
          if (cotizacion.descripcionGeneral != null &&
              cotizacion.descripcionGeneral!.isNotEmpty)
            const SizedBox(height: 16),

          // Productos
          if (cotizacion.productos != null && cotizacion.productos!.isNotEmpty)
            _InfoSection(
              title: 'Productos',
              icon: Icons.inventory_2_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < cotizacion.productos!.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${i + 1}. ${cotizacion.productos![i]}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                ],
              ),
            ),
          if (cotizacion.productos != null && cotizacion.productos!.isNotEmpty)
            const SizedBox(height: 16),

          // Totales
          _InfoSection(
            title: 'Totales',
            icon: Icons.payments_outlined,
            children: [
              _InfoRow(
                label: 'Subtotal',
                value: '${cotizacion.moneda} \$${cotizacion.subtotal.toStringAsFixed(2)}',
              ),
              if (cotizacion.descuento > 0)
                _InfoRow(
                  label: 'Descuento',
                  value: '${cotizacion.moneda} \$${cotizacion.descuento.toStringAsFixed(2)}',
                ),
              const Divider(height: 16),
              _InfoRow(
                label: 'TOTAL',
                value: '${cotizacion.moneda} \$${cotizacion.total.toStringAsFixed(2)}',
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Observaciones
          if (cotizacion.observaciones != null &&
              cotizacion.observaciones!.isNotEmpty)
            _InfoSection(
              title: 'Observaciones',
              icon: Icons.notes_outlined,
              child: Text(
                cotizacion.observaciones!,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              ),
            ),
          if (cotizacion.observaciones != null &&
              cotizacion.observaciones!.isNotEmpty)
            const SizedBox(height: 16),

          // Condiciones
          if (cotizacion.condiciones != null &&
              cotizacion.condiciones!.isNotEmpty)
            _InfoSection(
              title: 'Condiciones',
              icon: Icons.rule_outlined,
              child: Text(
                cotizacion.condiciones!,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              ),
            ),
          if (cotizacion.condiciones != null &&
              cotizacion.condiciones!.isNotEmpty)
            const SizedBox(height: 16),

          // Válida hasta
          if (cotizacion.validaHasta != null)
            _InfoSection(
              title: 'Válida hasta',
              icon: Icons.date_range_outlined,
              child: Text(
                '${cotizacion.validaHasta!.day}/${cotizacion.validaHasta!.month}/${cotizacion.validaHasta!.year}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          if (cotizacion.validaHasta != null) const SizedBox(height: 16),

          // PDF URL
          if (cotizacion.pdfUrl != null && cotizacion.pdfUrl!.isNotEmpty)
            _InfoSection(
              title: 'PDF',
              icon: Icons.picture_as_pdf_outlined,
              child: Text(
                cotizacion.pdfUrl!,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.blue.shade600,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          if (cotizacion.pdfUrl != null && cotizacion.pdfUrl!.isNotEmpty)
            const SizedBox(height: 16),

          // Fechas
          _InfoSection(
            title: 'Fechas',
            icon: Icons.schedule_outlined,
            children: [
              if (cotizacion.creadoEn != null)
                _InfoRow(
                  label: 'Creado',
                  value: _formatDate(cotizacion.creadoEn!),
                ),
              if (cotizacion.actualizadoEn != null)
                _InfoRow(
                  label: 'Actualizado',
                  value: _formatDate(cotizacion.actualizadoEn!),
                ),
              if (cotizacion.creadaPor != null)
                _InfoRow(label: 'Creada por', value: cotizacion.creadaPor!),
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
        builder: (_) => BotQuotationFormPage(
          botId: botId,
          botNombre: '',
          cotizacion: cotizacion,
        ),
      ),
    );
  }

  void _cambiarEstado(BuildContext context) {
    final estados = [
      'pendiente',
      'enviada',
      'aprobada',
      'rechazada',
      'vencida',
      'cancelada',
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
                final isSelected = cotizacion.estado == estado;
                return ListTile(
                  leading: Icon(
                    isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
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
                await context
                    .read<BotQuotationProvider>()
                    .cambiarEstado(botId, cotizacion.id, nuevoEstado);
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
                  SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
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
        title: const Text('Eliminar cotización'),
        content: const Text('¿Estás seguro de eliminar esta cotización?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await context
                    .read<BotQuotationProvider>()
                    .eliminarCotizacion(botId, cotizacion.id);
                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Cotización eliminada'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  Color _getColorEstado(String estado) {
    switch (estado) {
      case 'pendiente':
        return Colors.orange;
      case 'enviada':
        return Colors.blue;
      case 'aprobada':
        return Colors.green;
      case 'rechazada':
        return Colors.red;
      case 'vencida':
        return Colors.grey;
      case 'cancelada':
        return Colors.brown;
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
          if (child != null) child!,
          if (children != null) ...children!,
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
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
