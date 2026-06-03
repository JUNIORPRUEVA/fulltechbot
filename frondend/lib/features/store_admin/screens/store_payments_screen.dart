import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/store_admin_provider.dart';

/// Pantalla de administración de pagos de la tienda.
class StorePaymentsScreen extends StatefulWidget {
  const StorePaymentsScreen({super.key});

  @override
  State<StorePaymentsScreen> createState() => _StorePaymentsScreenState();
}

class _StorePaymentsScreenState extends State<StorePaymentsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StoreAdminProvider>().loadPayments();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StoreAdminProvider>();

    if (provider.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.payments.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.payment, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('No hay pagos registrados',
                style: TextStyle(fontSize: 18, color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text('Los pagos aparecerán aquí cuando los clientes compren',
                style: TextStyle(color: Colors.grey[500])),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadPayments(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: provider.payments.length,
        itemBuilder: (context, index) {
          final payment = provider.payments[index];
          return _PaymentCard(payment: payment);
        },
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final Map<String, dynamic> payment;

  const _PaymentCard({required this.payment});

  String _formatDate(dynamic date) {
    if (date == null) return '-';
    try {
      final dt = DateTime.parse(date.toString());
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return date.toString();
    }
  }

  Color _estadoColor(String? estado) {
    switch (estado) {
      case 'completado':
      case 'completado':
        return Colors.green;
      case 'pendiente':
        return Colors.orange;
      case 'cancelado':
      case 'fallido':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final estado = payment['estado'] ?? 'pendiente';
    final monto = payment['monto'] ?? 0;
    final metodo = payment['metodo_pago'] ?? payment['metodo'] ?? '-';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _estadoColor(estado).withOpacity(0.1),
          child: Icon(Icons.payment, color: _estadoColor(estado)),
        ),
        title: Text('\$$monto',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (payment['cliente_nombre'] != null)
              Text(payment['cliente_nombre'],
                  style: TextStyle(color: Colors.grey[700], fontSize: 13)),
            Row(
              children: [
                _buildBadge(metodo, Colors.blue),
                const SizedBox(width: 8),
                _buildBadge(estado, _estadoColor(estado)),
              ],
            ),
          ],
        ),
        trailing: Text(_formatDate(payment['creado_en']),
            style: TextStyle(color: Colors.grey[500], fontSize: 12)),
        isThreeLine: true,
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(text,
          style: TextStyle(color: color, fontSize: 11)),
    );
  }
}
