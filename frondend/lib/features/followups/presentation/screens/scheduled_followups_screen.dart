import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/scheduled_followup_model.dart';
import '../../providers/followups_provider.dart';
import '../widgets/followup_empty_state.dart';
import '../widgets/followup_filter_bar.dart';
import '../widgets/followup_list_tile.dart';
import 'followup_detail_screen.dart';

class ScheduledFollowupsScreen extends StatefulWidget {
  final String botId;

  const ScheduledFollowupsScreen({super.key, required this.botId});

  @override
  State<ScheduledFollowupsScreen> createState() =>
      _ScheduledFollowupsScreenState();
}

class _ScheduledFollowupsScreenState extends State<ScheduledFollowupsScreen> {
  final _scrollController = ScrollController();

  String? _estado;
  String? _tipoSeguimiento;
  String? _nivel;
  String? _clienteCompro;
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
      if (!provider.isLoadingScheduled && provider.hasMoreScheduled) {
        _cargar(refresh: false);
      }
    }
  }

  Future<void> _cargar({required bool refresh}) async {
    await context.read<FollowupsProvider>().cargarScheduled(
      botId: widget.botId,
      refresh: refresh,
      estado: _estado,
      tipoSeguimiento: _tipoSeguimiento,
      nivel: _nivel,
      clienteCompro: _clienteCompro,
      fecha: _fecha,
      search: _search,
    );
  }

  void _onEstadoChanged(String? value) {
    setState(() => _estado = value);
    _cargar(refresh: true);
  }

  void _onTipoChanged(String? value) {
    setState(() => _tipoSeguimiento = value);
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
      _tipoSeguimiento = null;
      _nivel = null;
      _clienteCompro = null;
      _fecha = null;
      _search = null;
      _isSearching = false;
    });
    _cargar(refresh: true);
  }

  void _abrirDetalle(ScheduledFollowupModel followup) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FollowupDetailScreen(
          scheduled: followup,
          onAbrirCRM: () {
            // TODO: Integrar con módulo CRM si existe
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
        title: const Text('Seguimientos Programados'),
        actions: [
          Consumer<FollowupsProvider>(
            builder: (context, provider, _) {
              if (provider.isLoadingScheduled) {
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
                FilterOption(label: 'Finalizado', value: 'finalizado'),
                FilterOption(label: 'Cancelado', value: 'cancelado'),
              ],
              secondaryOptions: const [
                FilterOption(label: 'Fecha futura', value: 'fecha_futura'),
                FilterOption(
                  label: 'Reserva instalación',
                  value: 'reserva_instalacion',
                ),
                FilterOption(
                  label: 'Seg. cotización',
                  value: 'seguimiento_cotizacion',
                ),
                FilterOption(label: 'Esperando pago', value: 'esperando_pago'),
                FilterOption(
                  label: 'Coord. visita',
                  value: 'coordinacion_visita',
                ),
                FilterOption(
                  label: 'Cliente interesado',
                  value: 'cliente_interesado',
                ),
                FilterOption(
                  label: 'Seg. instalación',
                  value: 'seguimiento_instalacion',
                ),
                FilterOption(label: 'Seg. motor', value: 'seguimiento_motor'),
                FilterOption(
                  label: 'Seg. cámaras',
                  value: 'seguimiento_camaras',
                ),
                FilterOption(
                  label: 'Seg. componente',
                  value: 'seguimiento_componente',
                ),
                FilterOption(
                  label: 'Seg. confirmación',
                  value: 'seguimiento_confirmacion',
                ),
              ],
              secondaryLabel: 'Tipo',
              fechaOptions: const [
                FilterOption(label: 'Hoy', value: 'hoy'),
                FilterOption(label: 'Vencidos', value: 'vencidos'),
                FilterOption(label: 'Próximos', value: 'proximos'),
                FilterOption(label: 'Esta semana', value: 'semana'),
              ],
              selectedEstado: _estado,
              selectedSecondary: _tipoSeguimiento,
              selectedFecha: _fecha,
              searchQuery: _search,
              onEstadoChanged: _onEstadoChanged,
              onSecondaryChanged: _onTipoChanged,
              onFechaChanged: _onFechaChanged,
              onSearchChanged: _onSearchChanged,
              onClear: _onClearFilters,
            ),
          ),
          // Content
          Expanded(
            child: Consumer<FollowupsProvider>(
              builder: (context, provider, _) {
                if (provider.isLoadingScheduled &&
                    provider.scheduledFollowups.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.errorScheduled != null &&
                    provider.scheduledFollowups.isEmpty) {
                  return FollowupEmptyState(
                    icon: Icons.error_outline_rounded,
                    title: 'Error al cargar',
                    subtitle: provider.errorScheduled!,
                    onRefresh: () => _cargar(refresh: true),
                  );
                }

                if (provider.scheduledFollowups.isEmpty) {
                  return FollowupEmptyState(
                    icon: Icons.checklist_rounded,
                    title: 'Sin seguimientos',
                    subtitle: _isSearching
                        ? 'No se encontraron seguimientos con los filtros aplicados'
                        : 'No hay seguimientos programados pendientes.',
                    onRefresh: () => _cargar(refresh: true),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => _cargar(refresh: true),
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(top: 4, bottom: 80),
                    itemCount:
                        provider.scheduledFollowups.length +
                        (provider.hasMoreScheduled ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= provider.scheduledFollowups.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final followup = provider.scheduledFollowups[index];
                      return ScheduledFollowupTile(
                        followup: followup,
                        onTap: () => _abrirDetalle(followup),
                        onFinalizar: () => _confirmAction(
                          '¿Finalizar este seguimiento?',
                          () => provider.finalizarScheduled(
                            widget.botId,
                            followup.id,
                          ),
                        ),
                        onCancelar: () => _confirmAction(
                          '¿Cancelar este seguimiento?',
                          () => provider.cancelarScheduled(
                            widget.botId,
                            followup.id,
                          ),
                        ),
                        onReactivar: () => _confirmAction(
                          '¿Reactivar este seguimiento?',
                          () => provider.reactivarScheduled(
                            widget.botId,
                            followup.id,
                          ),
                        ),
                        onAbrirCRM: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Módulo CRM próximamente'),
                            ),
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
