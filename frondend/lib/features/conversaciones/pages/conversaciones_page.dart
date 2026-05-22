import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../bots/providers/bot_provider.dart';
import '../../clientes/models/cliente_model.dart';
import '../../clientes/providers/clientes_provider.dart';
import '../models/conversacion_model.dart';
import '../providers/conversaciones_provider.dart';
import 'chat_detail_page.dart';

class ConversacionesPage extends StatefulWidget {
  const ConversacionesPage({super.key});

  @override
  State<ConversacionesPage> createState() => _ConversacionesPageState();
}

class _ConversacionesPageState extends State<ConversacionesPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  /// Rol del usuario actual. En producción esto debe venir del sistema de autenticación.
  String get _userRole => 'admin';

  /// Determina si el usuario puede eliminar conversaciones.
  bool get _canDelete => ['admin', 'owner', 'superadmin'].contains(_userRole);

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final bot = context.read<BotProvider>().botSeleccionado;
      context.read<ConversacionesProvider>().listarConversaciones(botId: bot?.id);
      context.read<ClientesProvider>().cargarClientes(botId: bot?.id);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final conversacionesProvider = context.watch<ConversacionesProvider>();
    final clientesProvider = context.watch<ClientesProvider>();
    final conversaciones = conversacionesProvider.conversaciones;
    final clientes = clientesProvider.clientes;

    // Agrupar conversaciones por sessionId y obtener la última
    final conversacionesAgrupadas = _agruparConversaciones(conversaciones);

    // Filtrar por búsqueda
    final filtradas = _filtrarConversaciones(conversacionesAgrupadas, clientes);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Conversaciones',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: conversacionesProvider.cargando
                ? null
                : () {
                    final bot = context.read<BotProvider>().botSeleccionado;
                    context.read<ConversacionesProvider>().listarConversaciones(
                          botId: bot?.id,
                        );
                    context.read<ClientesProvider>().cargarClientes(
                          botId: bot?.id,
                        );
                  },
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Buscar conversación...',
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

          // Error banner
          if (conversacionesProvider.error != null)
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
                      conversacionesProvider.error!,
                      style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      final bot = context.read<BotProvider>().botSeleccionado;
                      context.read<ConversacionesProvider>().listarConversaciones(
                            botId: bot?.id,
                          );
                    },
                    icon: Icon(Icons.close_rounded, size: 18, color: Colors.red.shade400),
                  ),
                ],
              ),
            ),

          // Estadísticas
          if (filtradas.isNotEmpty && !conversacionesProvider.cargando)
            _buildStatsRow(filtradas),

          // Lista
          Expanded(
            child: conversacionesProvider.cargando && conversaciones.isEmpty
                ? const Center(child: CircularProgressIndicator(strokeWidth: 3))
                : filtradas.isEmpty
                    ? _buildEmptyState(conversaciones.isEmpty)
                    : RefreshIndicator(
                        onRefresh: () async {
                          final bot = context.read<BotProvider>().botSeleccionado;
                          await context.read<ConversacionesProvider>().listarConversaciones(
                                botId: bot?.id,
                              );
                          await context.read<ClientesProvider>().cargarClientes(
                                botId: bot?.id,
                              );
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                          itemCount: filtradas.length,
                          itemBuilder: (context, index) {
                            final entry = filtradas.entries.elementAt(index);
                            final sessionId = entry.key;
                            final ultimoMensaje = entry.value;
                            final cliente = _buscarCliente(sessionId, clientes);

                            return _ConversacionCard(
                              sessionId: sessionId,
                              ultimoMensaje: ultimoMensaje,
                              cliente: cliente,
                              canDelete: _canDelete,
                              onTap: () => _abrirChat(context, sessionId, cliente),
                              onDelete: () => _confirmarEliminarConversacion(context, sessionId, cliente),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(Map<String, ConversacionModel> conversaciones) {
    final total = conversaciones.length;
    final hoy = conversaciones.values.where((c) {
      if (c.createdAt == null) return false;
      return DateTime.now().difference(c.createdAt!).inDays == 0;
    }).length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          _StatChip(label: '$total conversaciones', color: Colors.blue),
          const SizedBox(width: 8),
          _StatChip(label: '$hoy activas hoy', color: Colors.green),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool sinConversaciones) {
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
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(Icons.chat_outlined, size: 40, color: Colors.purple.shade300),
            ),
            const SizedBox(height: 20),
            Text(
              sinConversaciones ? 'Sin conversaciones' : 'Sin resultados',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              sinConversaciones
                  ? 'Las conversaciones con clientes aparecerán aquí cuando el bot interactúe con ellos.'
                  : 'No se encontraron conversaciones con ese criterio.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, ConversacionModel> _agruparConversaciones(List<ConversacionModel> conversaciones) {
    final Map<String, ConversacionModel> agrupadas = {};

    for (final conv in conversaciones) {
      final sessionId = conv.sessionId;
      final existente = agrupadas[sessionId];

      if (existente == null || (conv.createdAt != null && existente.createdAt != null && conv.createdAt!.isAfter(existente.createdAt!))) {
        agrupadas[sessionId] = conv;
      }
    }

    // Ordenar por fecha descendente
    final sorted = agrupadas.entries.toList()
      ..sort((a, b) {
        final dateA = a.value.createdAt;
        final dateB = b.value.createdAt;
        if (dateA == null && dateB == null) return 0;
        if (dateA == null) return 1;
        if (dateB == null) return -1;
        return dateB.compareTo(dateA);
      });

    return Map.fromEntries(sorted);
  }

  Map<String, ConversacionModel> _filtrarConversaciones(
    Map<String, ConversacionModel> conversaciones,
    List<ClienteModel> clientes,
  ) {
    if (_searchQuery.isEmpty) return conversaciones;
    final query = _searchQuery.toLowerCase();

    final Map<String, ConversacionModel> filtradas = {};
    for (final entry in conversaciones.entries) {
      final sessionId = entry.key;
      final cliente = _buscarCliente(sessionId, clientes);
      final nombre = cliente?.nombre ?? sessionId.replaceAll('@s.whatsapp.net', '');

      if (nombre.toLowerCase().contains(query) ||
          sessionId.contains(query) ||
          entry.value.content.toLowerCase().contains(query)) {
        filtradas[entry.key] = entry.value;
      }
    }

    return filtradas;
  }

  ClienteModel? _buscarCliente(String sessionId, List<ClienteModel> clientes) {
    // Buscar por chatid o por teléfono
    return clientes.cast<ClienteModel?>().firstWhere(
      (c) => c!.chatid == sessionId || c.telefono == sessionId || sessionId.startsWith(c.telefono),
      orElse: () => null,
    );
  }

  void _abrirChat(BuildContext context, String sessionId, ClienteModel? cliente) {
    final nombre = cliente?.nombre ?? sessionId.replaceAll('@s.whatsapp.net', '');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatDetailPage(
          sessionId: sessionId,
          nombreCliente: nombre,
        ),
      ),
    );
  }

  /// Muestra diálogo de confirmación para eliminar conversación.
  Future<void> _confirmarEliminarConversacion(
    BuildContext context, String sessionId, ClienteModel? cliente,
  ) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('¿Eliminar conversación?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (cliente != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.person_off_rounded, color: Colors.red.shade400, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        cliente.nombre ?? sessionId,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
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
                  Icon(Icons.warning_amber_rounded, color: Colors.orange.shade600, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Se eliminarán todos los mensajes de esta conversación. '
                      'El bot perderá la memoria de este cliente y empezará desde cero.\n\n'
                      'Nota: El cliente NO será eliminado.',
                      style: TextStyle(color: Colors.orange.shade800, fontSize: 13),
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
            label: const Text('Eliminar conversación'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (confirmado == true && mounted) {
      await _ejecutarEliminacionConversacion(context, sessionId, cliente);
    }
  }

  /// Ejecuta la eliminación de la conversación con feedback visual.
  Future<void> _ejecutarEliminacionConversacion(
    BuildContext context, String sessionId, ClienteModel? cliente,
  ) async {
    final provider = context.read<ConversacionesProvider>();
    final botId =
        context.read<BotProvider>().botSeleccionado?.id ?? cliente?.botId;
    final messenger = ScaffoldMessenger.of(context);

    // Mostrar loading
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            const SizedBox(width: 12),
            const Text('Eliminando conversación...'),
          ],
        ),
        duration: const Duration(seconds: 30),
      ),
    );

    try {
      await provider.eliminarConversaciones(
        sessionId,
        botId: botId,
        userRole: _userRole,
      );

      // Cerrar loading y mostrar éxito
      messenger.hideCurrentSnackBar();
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Conversación de ${cliente?.nombre ?? sessionId} eliminada correctamente.'),
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
            content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
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

  const _StatChip({required this.label, required this.color});

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

class _ConversacionCard extends StatelessWidget {
  final String sessionId;
  final ConversacionModel ultimoMensaje;
  final ClienteModel? cliente;
  final bool canDelete;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ConversacionCard({
    required this.sessionId,
    required this.ultimoMensaje,
    this.cliente,
    required this.canDelete,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final nombre = cliente?.nombre ?? sessionId.replaceAll('@s.whatsapp.net', '');
    final color = _getAvatarColor(nombre);
    final esAdmin = ultimoMensaje.role == 'assistant' || ultimoMensaje.role == 'admin';
    final esTool = ultimoMensaje.role == 'tool';

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
                // Avatar
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

                // Info
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
                          if (ultimoMensaje.createdAt != null)
                            Text(
                              _formatFecha(ultimoMensaje.createdAt!),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            esAdmin
                                ? Icons.smart_toy_rounded
                                : esTool
                                    ? Icons.build_rounded
                                    : Icons.person_rounded,
                            size: 14,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              ultimoMensaje.content,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (cliente != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _MiniTag(
                              icon: Icons.phone_outlined,
                              label: cliente!.telefono,
                            ),
                            const SizedBox(width: 8),
                            _MiniTag(
                              icon: Icons.flag_outlined,
                              label: cliente!.estadoCliente,
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // Botón eliminar (solo visible para admin/owner)
                if (canDelete)
                  IconButton(
                    tooltip: 'Eliminar conversación',
                    icon: Icon(Icons.delete_outline_rounded, color: Colors.red.shade300, size: 20),
                    onPressed: onDelete,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    splashRadius: 18,
                  ),
                if (canDelete) const SizedBox(width: 4),

                // Flecha
                Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
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
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  String _formatFecha(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${date.day}/${date.month}';
  }
}

class _MiniTag extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MiniTag({required this.icon, required this.label});

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
