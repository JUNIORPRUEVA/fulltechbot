import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../bots/providers/bot_provider.dart';
import '../models/bot_quotation_model.dart';
import '../providers/bot_quotation_provider.dart';
import 'bot_quotation_form_page.dart';
import 'bot_quotation_detail_page.dart';

class BotQuotationsPage extends StatefulWidget {
  const BotQuotationsPage({super.key});

  @override
  State<BotQuotationsPage> createState() => _BotQuotationsPageState();
}

class _BotQuotationsPageState extends State<BotQuotationsPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _filtroEstado = 'Todas';

  static const List<String> _estados = [
    'Todas',
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
    _cargarDatos();
  }

  void _cargarDatos() {
    final botProvider = context.read<BotProvider>();
    final bot = botProvider.botSeleccionado;
    if (bot != null) {
      context.read<BotQuotationProvider>().cargarCotizaciones(bot.id);
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
              Icon(Icons.description_outlined, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Selecciona un bot antes de administrar cotizaciones.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    final provider = context.watch<BotQuotationProvider>();
    final cotizacionesFiltradas = _filtrarCotizaciones(provider.cotizaciones);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Cotizaciones',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: provider.isLoading
                ? null
                : () =>
                    context.read<BotQuotationProvider>().cargarCotizaciones(bot.id),
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
              color: Colors.indigo.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.indigo.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.smart_toy_outlined, size: 18, color: Colors.indigo.shade600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Cotizaciones de: ${bot.nombre}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.indigo.shade700,
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
                hintText: 'Buscar por número, teléfono, nombre o título...',
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
                      estado == 'Todas'
                          ? 'Todas'
                          : estado[0].toUpperCase() + estado.substring(1),
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
                    onPressed: () =>
                        context.read<BotQuotationProvider>().limpiarError(),
                    icon: Icon(Icons.close_rounded, size: 18, color: Colors.red.shade400),
                  ),
                ],
              ),
            ),

          // Lista de cotizaciones
          Expanded(
            child: provider.isLoading && provider.cotizaciones.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(strokeWidth: 3),
                  )
                : cotizacionesFiltradas.isEmpty
                    ? _buildEmptyState(provider.cotizaciones.isEmpty)
                    : RefreshIndicator(
                        onRefresh: () => context
                            .read<BotQuotationProvider>()
                            .cargarCotizaciones(bot.id),
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                          itemCount: cotizacionesFiltradas.length,
                          itemBuilder: (context, index) {
                            final cot = cotizacionesFiltradas[index];
                            return _CotizacionCard(
                              cotizacion: cot,
                              onTap: () => _abrirDetalle(context, bot.id, cot),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _crearCotizacion(context, bot.id, bot.nombre),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nueva cotización'),
      ),
    );
  }

  Widget _buildEmptyState(bool sinCotizaciones) {
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
                color: Colors.indigo.shade50,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(Icons.description_outlined,
                  size: 40, color: Colors.indigo.shade300),
            ),
            const SizedBox(height: 20),
            Text(
              sinCotizaciones ? 'No hay cotizaciones registradas' : 'Sin resultados',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              sinCotizaciones
                  ? 'Crea tu primera cotización para empezar.'
                  : 'No se encontraron cotizaciones con ese criterio.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  List<BotQuotationModel> _filtrarCotizaciones(List<BotQuotationModel> cotizaciones) {
    var result = cotizaciones;

    if (_filtroEstado != 'Todas') {
      result = result.where((c) => c.estado == _filtroEstado).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result.where((c) {
        return c.numeroCotizacion.toLowerCase().contains(query) ||
            c.telefonoCliente.toLowerCase().contains(query) ||
            (c.nombreCliente?.toLowerCase().contains(query) ?? false) ||
            (c.titulo?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    return result;
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

  void _crearCotizacion(BuildContext context, String botId, String botNombre) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            BotQuotationFormPage(botId: botId, botNombre: botNombre),
      ),
    );
  }

  void _abrirDetalle(
      BuildContext context, String botId, BotQuotationModel cotizacion) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            BotQuotationDetailPage(botId: botId, cotizacion: cotizacion),
      ),
    );
  }
}

class _CotizacionCard extends StatelessWidget {
  final BotQuotationModel cotizacion;
  final VoidCallback onTap;

  const _CotizacionCard({required this.cotizacion, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = _getColorEstado(cotizacion.estado);

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
                        cotizacion.numeroCotizacion.isNotEmpty
                            ? cotizacion.numeroCotizacion
                            : 'Sin número',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.indigo,
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
                        cotizacion.estado.toUpperCase(),
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
                const SizedBox(height: 6),

                // Título
                if (cotizacion.titulo != null && cotizacion.titulo!.isNotEmpty)
                  Text(
                    cotizacion.titulo!,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 6),

                // Cliente
                Row(
                  children: [
                    Icon(Icons.person_outline, size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(
                      cotizacion.nombreCliente ?? cotizacion.telefonoCliente,
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.phone_outlined, size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(
                      cotizacion.telefonoCliente,
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Total y moneda
                Row(
                  children: [
                    Icon(Icons.attach_money_outlined, size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(
                      '${cotizacion.moneda} \$${cotizacion.total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),

                // Fecha creación
                if (cotizacion.creadoEn != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Creado: ${_formatDate(cotizacion.creadoEn!)}',
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
