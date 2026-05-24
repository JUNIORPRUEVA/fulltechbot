import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../bots/providers/bot_provider.dart';
import '../models/cliente_model.dart';
import '../providers/clientes_provider.dart';
import 'cliente_detail_page.dart';

class ClientesPage extends StatefulWidget {
  const ClientesPage({super.key});

  @override
  State<ClientesPage> createState() => _ClientesPageState();
}

class _ClientesPageState extends State<ClientesPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  /// Rol del usuario actual.
  /// En producción debe venir del login/token.
  String get _userRole => 'admin';

  bool get _canDelete => ['admin', 'owner', 'superadmin'].contains(_userRole);

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      _cargarClientesDesdeCloud();
    });
  }

  @override
void dispose() {
  _searchController.dispose();
  super.dispose();
}

Future<void> _cargarClientesDesdeCloud() async {
  if (!mounted) return;

  final botProvider = context.read<BotProvider>();
  final clientesProvider = context.read<ClientesProvider>();
  final messenger = ScaffoldMessenger.of(context);

  final bot = botProvider.botSeleccionado;
  final botId = bot?.id;

  debugPrint('[ClientesPage] Bot seleccionado: ${bot?.nombre ?? 'SIN BOT'}');
  debugPrint('[ClientesPage] botId usado para cargar clientes: $botId');

  if (botId == null || botId.isEmpty) {
    debugPrint(
      '[ClientesPage] No hay un bot seleccionado. No se pueden cargar clientes.',
    );

    messenger.showSnackBar(
      SnackBar(
        content: const Text(
          'No hay un bot seleccionado. Selecciona un bot para cargar los clientes.',
        ),
        backgroundColor: Colors.red.shade600,
        duration: const Duration(seconds: 4),
      ),
    );

    return;
  }

  await clientesProvider.cargarClientes(botId: botId);
}

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ClientesProvider>();
    final bot = context.watch<BotProvider>().botSeleccionado;
    final clientesFiltrados = _filtrarClientes(provider.clientes);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Clientes',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            if (bot != null)
              Text(
                bot.nombre ?? 'Bot seleccionado',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w400,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Actualizar desde la nube',
            onPressed: provider.isLoading ? null : _cargarClientesDesdeCloud,
            icon: provider.isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
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
                hintText: 'Buscar cliente...',
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
                  Icon(
                    Icons.error_outline_rounded,
                    color: Colors.red.shade400,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      provider.error!,
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      context.read<ClientesProvider>().limpiarError();
                    },
                    icon: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: Colors.red.shade400,
                    ),
                  ),
                ],
              ),
            ),

          if (provider.clientes.isNotEmpty && !provider.isLoading)
            _buildStatsRow(provider.clientes),

          Expanded(
            child: provider.isLoading && provider.clientes.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(strokeWidth: 3),
                  )
                : clientesFiltrados.isEmpty
                    ? _buildEmptyState(provider.clientes.isEmpty)
                    : RefreshIndicator(
                        onRefresh: _cargarClientesDesdeCloud,
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                          itemCount: clientesFiltrados.length,
                          itemBuilder: (context, index) {
                            final cliente = clientesFiltrados[index];

                            return _ClienteCard(
                              cliente: cliente,
                              canDelete: _canDelete,
                              onTap: () => _abrirDetalle(context, cliente),
                              onDelete: () {
                                _confirmarEliminarCliente(context, cliente);
                              },
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(List<ClienteModel> clientes) {
    final total = clientes.length;
    final prospectos =
        clientes.where((c) => c.estadoCliente == 'prospecto').length;
    final seguimiento =
        clientes.where((c) => c.estadoCliente == 'seguimiento').length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          _StatChip(label: '$total total', color: Colors.blue),
          const SizedBox(width: 8),
          _StatChip(label: '$prospectos prospectos', color: Colors.orange),
          const SizedBox(width: 8),
          _StatChip(label: '$seguimiento seguimiento', color: Colors.teal),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool sinClientes) {
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
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.people_outline_rounded,
                size: 40,
                color: Colors.blue.shade300,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              sinClientes ? 'No hay clientes registrados' : 'Sin resultados',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              sinClientes
                  ? 'Los clientes aparecerán aquí cuando se sincronicen desde el bot.'
                  : 'No se encontraron clientes con ese criterio de búsqueda.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: _cargarClientesDesdeCloud,
              icon: const Icon(Icons.cloud_sync_rounded),
              label: const Text('Actualizar desde la nube'),
            ),
          ],
        ),
      ),
    );
  }

  List<ClienteModel> _filtrarClientes(List<ClienteModel> clientes) {
    if (_searchQuery.trim().isEmpty) return clientes;

    final query = _searchQuery.toLowerCase().trim();

    return clientes.where((c) {
      return (c.nombre?.toLowerCase().contains(query) ?? false) ||
          c.telefono.toLowerCase().contains(query) ||
          (c.interesPrincipal?.toLowerCase().contains(query) ?? false) ||
          (c.ciudad?.toLowerCase().contains(query) ?? false) ||
          c.estadoCliente.toLowerCase().contains(query);
    }).toList();
  }

  void _abrirDetalle(BuildContext context, ClienteModel cliente) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ClienteDetailPage(cliente: cliente),
      ),
    );
  }

  Future<void> _confirmarEliminarCliente(
    BuildContext context,
    ClienteModel cliente,
  ) async {
    if (!_canDelete) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No tienes permiso para eliminar clientes.'),
          backgroundColor: Colors.red.shade600,
        ),
      );
      return;
    }

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar cliente?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Se eliminará este cliente de la nube:',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.person_off_rounded,
                    color: Colors.red.shade400,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      cliente.nombre ?? cliente.telefono,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange.shade600,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'También se marcarán como eliminados sus datos relacionados para que no vuelvan a aparecer en la sincronización.',
                      style: TextStyle(
                        color: Colors.orange.shade800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton.tonalIcon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.delete_forever_rounded, size: 18),
            label: const Text('Eliminar'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (confirmado == true && mounted) {
      await _ejecutarEliminacion(context, cliente);
    }
  }

  Future<void> _ejecutarEliminacion(
    BuildContext context,
    ClienteModel cliente,
  ) async {
    final provider = context.read<ClientesProvider>();
    final botSeleccionado = context.read<BotProvider>().botSeleccionado;
    final botId = botSeleccionado?.id ?? cliente.botId;
    final messenger = ScaffoldMessenger.of(context);

    debugPrint('[ClientesPage] Eliminando cliente: ${cliente.telefono}');
    debugPrint('[ClientesPage] botId usado para eliminar: $botId');

    if (botId == null || botId.isEmpty) {
      messenger.showSnackBar(
        SnackBar(
          content: const Text(
            'No se pudo eliminar: no hay botId válido para este cliente.',
          ),
          backgroundColor: Colors.red.shade600,
        ),
      );
      return;
    }

    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Eliminando ${cliente.nombre ?? cliente.telefono}...',
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 30),
      ),
    );

    try {
      await provider.eliminarCliente(
        cliente.telefono,
        botId: botId,
        chatid: cliente.chatid,
        userRole: _userRole,
      );

      await provider.cargarClientes(botId: botId);

      messenger.hideCurrentSnackBar();

      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              '${cliente.nombre ?? cliente.telefono} eliminado correctamente.',
            ),
            backgroundColor: Colors.green.shade600,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      messenger.hideCurrentSnackBar();

      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Error: ${e.toString().replaceAll('Exception: ', '')}',
            ),
            backgroundColor: Colors.red.shade600,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatChip({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _ClienteCard extends StatelessWidget {
  final ClienteModel cliente;
  final bool canDelete;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ClienteCard({
    required this.cliente,
    required this.canDelete,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final nombre = cliente.nombre ?? cliente.telefono;
    final color = _getAvatarColor(nombre);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.04),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.grey.shade200),
            ),
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      _getInitials(nombre),
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              nombre,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          _EstadoBadge(estado: cliente.estadoCliente),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (cliente.telefono.isNotEmpty)
                        _InfoText(
                          icon: Icons.phone_outlined,
                          text: cliente.telefono,
                        ),
                      if (cliente.interesPrincipal != null &&
                          cliente.interesPrincipal!.trim().isNotEmpty)
                        _InfoText(
                          icon: Icons.shopping_bag_outlined,
                          text: cliente.interesPrincipal!,
                        ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _MiniTag(
                            icon: Icons.chat_bubble_outline_rounded,
                            label: '${cliente.totalMensajes} msgs',
                          ),
                          _MiniTag(
                            icon: Icons.trending_up_rounded,
                            label: cliente.etapa,
                          ),
                          if (cliente.ciudad != null &&
                              cliente.ciudad!.trim().isNotEmpty)
                            _MiniTag(
                              icon: Icons.location_on_outlined,
                              label: cliente.ciudad!,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (canDelete)
                  IconButton(
                    tooltip: 'Eliminar cliente',
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.red.shade300,
                      size: 22,
                    ),
                    onPressed: onDelete,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                  ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getAvatarColor(String name) {
    const colors = [
      Color(0xFF2563EB),
      Color(0xFF0D9488),
      Color(0xFFEA580C),
      Color(0xFF7C3AED),
      Color(0xFFDB2777),
      Color(0xFF4F46E5),
      Color(0xFF059669),
      Color(0xFF0891B2),
    ];

    return colors[name.hashCode.abs() % colors.length];
  }

  String _getInitials(String name) {
    final clean = name.trim();

    if (clean.isEmpty) return '?';

    final parts = clean.split(RegExp(r'\s+'));

    if (parts.length >= 2 &&
        parts.first.isNotEmpty &&
        parts[1].isNotEmpty) {
      return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
    }

    return clean[0].toUpperCase();
  }
}

class _InfoText extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoText({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade500),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MiniTag({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _EstadoBadge extends StatelessWidget {
  final String estado;

  const _EstadoBadge({
    required this.estado,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getColor();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        estado.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Color _getColor() {
    switch (estado) {
      case 'prospecto':
        return const Color(0xFF2563EB);
      case 'seguimiento':
        return const Color(0xFF0D9488);
      case 'activo':
        return const Color(0xFF059669);
      case 'inactivo':
        return Colors.grey;
      case 'perdido':
        return const Color(0xFFDC2626);
      default:
        return Colors.grey;
    }
  }
}