import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../bots/providers/bot_provider.dart';
import '../models/bot_order_model.dart';
import '../providers/bot_order_provider.dart';
import 'bot_order_form_page.dart';
import 'bot_order_detail_page.dart';

class BotOrdersPage extends StatefulWidget {
  const BotOrdersPage({super.key});

  @override
  State<BotOrdersPage> createState() => _BotOrdersPageState();
}

class _BotOrdersPageState extends State<BotOrdersPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _filtroEstado = 'Todos';

  static const List<String> _estados = [
    'Todos',
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
    _cargarDatos();
  }

  void _cargarDatos() {
    final botProvider = context.read<BotProvider>();
    final bot = botProvider.botSeleccionado;
    if (bot != null) {
      context.read<BotOrderProvider>().cargarOrdenes(bot.id);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final botProvider = context.watch<BotProvider>();
    final bot = botProvider.botSeleccionado;

    if (bot == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Selecciona un bot antes de administrar órdenes.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    final provider = context.watch<BotOrderProvider>();
    final ordenesFiltradas = _filtrarOrdenes(provider.ordenes);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Órdenes',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: provider.isLoading
                ? null
                : () => context.read<BotOrderProvider>().cargarOrdenes(bot.id),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          // Banner del bot
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.smart_toy_outlined, size: 18, color: Colors.blue.shade600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Órdenes de: ${bot.nombre}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue.shade700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Barra de búsqueda
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Buscar por teléfono, nombre o producto...',
                prefixIcon: const Icon(Icons.search_rounded, size: 22),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),

          // Filtros de estado
          Container(
            height: 44,
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: _estados.map((estado) {
                final isSelected = _filtroEstado == estado;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(
                      estado == 'Todos' ? 'Todos' : estado[0].toUpperCase() + estado.substring(1),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? Colors.white : null,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => _filtroEstado = estado);
                    },
                    selectedColor: _getColorEstado(estado),
                    checkmarkColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    visualDensity: VisualDensity.compact,
                  ),
                );
              }).toList(),
            ),
          ),

          // Error banner
          if (provider.error != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline_rounded, color: Colors.red.shade400, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      provider.error!,
                      style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                    ),
                  ),
                  IconButton(
                    onPressed: () => context.read<BotOrderProvider>().limpiarError(),
                    icon: Icon(Icons.close_rounded, size: 18, color: Colors.red.shade400),
                  ),
                ],
              ),
            ),

          // Lista de órdenes
          Expanded(
            child: provider.isLoading && provider.ordenes.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(strokeWidth: 3),
                  )
                : ordenesFiltradas.isEmpty
                    ? _buildEmptyState(provider.ordenes.isEmpty)
                    : RefreshIndicator(
                        onRefresh: () =>
                            context.read<BotOrderProvider>().cargarOrdenes(bot.id),
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                          itemCount: ordenesFiltradas.length,
                          itemBuilder: (context, index) {
                            final orden = ordenesFiltradas[index];
                            return _OrdenCard(
                              orden: orden,
                              onTap: () => _abrirDetalle(context, bot.id, orden),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _crearOrden(context, bot.id, bot.nombre),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nueva orden'),
      ),
    );
  }

  Widget _buildEmptyState(bool sinOrdenes) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(Icons.receipt_long_outlined,
                  size: 40, color: Colors.orange.shade300),
            ),
            const SizedBox(height: 20),
            Text(
              sinOrdenes ? 'No hay órdenes registradas' : 'Sin resultados',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              sinOrdenes
                  ? 'Crea tu primera orden para empezar.'
                  : 'No se encontraron órdenes con ese criterio.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  List<BotOrderModel> _filtrarOrdenes(List<BotOrderModel> ordenes) {
    var result = ordenes;

    if (_filtroEstado != 'Todos') {
      result = result.where((o) => o.estadoPedido == _filtroEstado).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result.where((o) {
        return o.telefonoCliente.toLowerCase().contains(query) ||
            (o.nombreCliente?.toLowerCase().contains(query) ?? false) ||
            (o.productoServicio?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    return result;
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

  void _crearOrden(BuildContext context, String botId, String botNombre) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BotOrderFormPage(botId: botId, botNombre: botNombre),
      ),
    );
  }

  void _abrirDetalle(
      BuildContext context, String botId, BotOrderModel orden) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            BotOrderDetailPage(botId: botId, orden: orden),
      ),
    );
  }
}

class _OrdenCard extends StatelessWidget {
  final BotOrderModel orden;
  final VoidCallback onTap;

  const _OrdenCard({required this.orden, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = _getColorEstado(orden.estadoPedido ?? 'pendiente');

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        elevation: 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.grey.shade200),
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        orden.productoServicio ?? 'Sin producto',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: color.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        (orden.estadoPedido ?? 'pendiente').toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: color,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Info
                Row(
                  children: [
                    Icon(Icons.person_outline, size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(
                      orden.nombreCliente ?? orden.telefonoCliente,
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.phone_outlined, size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(
                      orden.telefonoCliente,
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Fecha deseada y tipo
                Row(
                  children: [
                    if (orden.fechaDeseada != null) ...[
                      Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        orden.fechaDeseada!,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      ),
                      const SizedBox(width: 12),
                    ],
                    if (orden.tipoServicio != null) ...[
                      Icon(Icons.build_outlined, size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        orden.tipoServicio!,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ],
                  ],
                ),

                // Resumen
                if (orden.resumenPedido != null && orden.resumenPedido!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    orden.resumenPedido!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],

                // Fecha creación
                if (orden.creadoEn != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Creado: ${_formatDate(orden.creadoEn!)}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                  ),
                ],
              ],
            ),
          ),
        ),
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
