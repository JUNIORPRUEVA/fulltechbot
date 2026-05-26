import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/conversation_recovery_model.dart';
import '../../providers/followups_provider.dart';
import '../widgets/followup_empty_state.dart';
import '../widgets/followup_filter_bar.dart';
import '../widgets/followup_list_tile.dart';
import 'followup_detail_screen.dart';

class ConversationRecoveryScreen extends StatefulWidget {
  final String botId;

  const ConversationRecoveryScreen({
    super.key,
    required this.botId,
  });

  @override
  State<ConversationRecoveryScreen> createState() => _ConversationRecoveryScreenState();
}

class _ConversationRecoveryScreenState extends State<ConversationRecoveryScreen> {
  final _scrollController = ScrollController();

  String? _estado;
  String? _etapa;
  String? _nivel;
  String? _fecha;
  String? _search;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargar(refresh: true);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final provider = context.read<FollowupsProvider>();
      if (!provider.isLoadingRecovery && provider.hasMoreRecovery) {
        _cargar(refresh: false);
      }
    }
  }

  Future<void> _cargar({required bool refresh}) async {
    await context.read<FollowupsProvider>().cargarRecovery(
          botId: widget.botId,
          refresh: refresh,
          estado: _estado,
          etapa: _etapa,
          nivel: _nivel,
          fecha: _fecha,
          search: _search,
        );
  }

  void _onEstadoChanged(String? value) {
    setState(() => _estado = value);
    _cargar(refresh: true);
  }

  void _onEtapaChanged(String? value) {
    setState(() => _etapa = value);
    _cargar(refresh: true);
  }

  void _onFechaChanged(String? value) {
    setState(() => _fecha = value);
    _cargar(refresh: true);
  }

  void _onSearchChanged(String value) {
    _search = value.isEmpty ? null : value;
    _isSearching = value.isNotEmpty;
    _cargar(refresh: true);
  }

  void _onClearFilters() {
    setState(() {
      _estado = null;
      _etapa = null;
      _nivel = null;
      _fecha = null;
      _search = null;
      _isSearching = false;
    });
    _cargar(refresh: true);
  }

  void _abrirDetalle(ConversationRecoveryModel followup) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FollowupDetailScreen(
          recovery: followup,
          onAbrirCRM: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Módulo CRM próximamente')),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recuperación de Conversaciones'),
        actions: [
          Consumer<FollowupsProvider>(
            builder: (context, provider, _) {
              if (provider.isLoadingRecovery) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
              }
              return IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: () => _cargar(refresh: true),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: FollowupFilterBar(
              estadoOptions: const [
                FilterOption(label: 'Pendiente', value: 'pendiente'),
                FilterOption(label: 'Recuperado', value: 'recuperado'),
                FilterOption(label: 'Finalizado', value: 'finalizado'),
                FilterOption(label: 'Cancelado', value: 'cancelado'),
              ],
              secondaryOptions: const [
                FilterOption(label: 'Interés inicial', value: 'interes_inicial'),
                FilterOption(label: 'Cotización enviada', value: 'cotizacion_enviada'),
                FilterOption(label: 'Seguimiento', value: 'seguimiento'),
                FilterOption(label: 'Negociación', value: 'negociacion'),
                FilterOption(label: 'Cierre', value: 'cierre'),
              ],
              secondaryLabel: 'Etapa',
              fechaOptions: const [
                FilterOption(label: 'Hoy', value: 'hoy'),
                FilterOption(label: 'Vencidos', value: 'vencidos'),
                FilterOption(label: 'Próximos', value: 'proximos'),
              ],
              selectedEstado: _estado,
              selectedSecondary: _etapa,
              selectedFecha: _fecha,
              searchQuery: _search,
              onEstadoChanged: _onEstadoChanged,
              onSecondaryChanged: _onEtapaChanged,
              onFechaChanged: _onFechaChanged,
              onSearchChanged: _onSearchChanged,
              onClear: _onClearFilters,
            ),
          ),
          // Content
          Expanded(
            child: Consumer<FollowupsProvider>(
              builder: (context, provider, _) {
                if (provider.isLoadingRecovery && provider.recoveryFollowups.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.errorRecovery != null && provider.recoveryFollowups.isEmpty) {
                  return FollowupEmptyState(
                    icon: Icons.error_outline_rounded,
                    title: 'Error al cargar',
                    subtitle: provider.errorRecovery!,
                    onRefresh: () => _cargar(refresh: true),
                  );
                }

                if (provider.recoveryFollowups.isEmpty) {
                  return FollowupEmptyState(
                    icon: Icons.restore_page_rounded,
                    title: 'Sin recuperaciones',
                    subtitle: _isSearching
                        ? 'No se encontraron recuperaciones con los filtros aplicados'
                        : 'No hay conversaciones en recuperación para este bot',
                    onRefresh: () => _cargar(refresh: true),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => _cargar(refresh: true),
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(top: 4, bottom: 80),
                    itemCount: provider.recoveryFollowups.length +
                        (provider.hasMoreRecovery ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= provider.recoveryFollowups.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final followup = provider.recoveryFollowups[index];
                      return RecoveryFollowupTile(
                        followup: followup,
                        onTap: () => _abrirDetalle(followup),
                        onFinalizar: () => _confirmAction(
                          '¿Marcar como recuperado?',
                          () => provider.finalizarRecovery(widget.botId, followup.id),
                        ),
                        onCancelar: () => _confirmAction(
                          '¿Cancelar esta recuperación?',
                          () => provider.cancelarRecovery(widget.botId, followup.id),
                        ),
                        onReactivar: () => _confirmAction(
                          '¿Reactivar esta recuperación?',
                          () => provider.reactivarRecovery(widget.botId, followup.id),
                        ),
                        onAbrirCRM: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Módulo CRM próximamente')),
                          );
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _confirmAction(String message, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar acción'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }
}
