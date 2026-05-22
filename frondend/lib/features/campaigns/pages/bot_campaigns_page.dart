import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../bots/providers/bot_provider.dart';
import '../models/bot_campaign_model.dart';
import '../providers/bot_campaign_provider.dart';
import 'bot_campaign_form_page.dart';

class BotCampaignsPage extends StatefulWidget {
  const BotCampaignsPage({super.key});

  @override
  State<BotCampaignsPage> createState() => _BotCampaignsPageState();
}

class _BotCampaignsPageState extends State<BotCampaignsPage> {
  final _searchController = TextEditingController();
  String _search = '';
  String? _lastBotId;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadData);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final bot = context.read<BotProvider>().botSeleccionado;
    if (bot == null) return;
    await context.read<BotCampaignProvider>().cargarCampanas(
          bot.id,
          search: _search.isEmpty ? null : _search,
        );
  }

  @override
  Widget build(BuildContext context) {
    final bot = context.watch<BotProvider>().botSeleccionado;
    final provider = context.watch<BotCampaignProvider>();

    if (bot == null) {
      return const SizedBox.shrink();
    }

    if (_lastBotId != bot.id) {
      _lastBotId = bot.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadData();
        }
      });
    }

    final campaigns = provider.campaigns;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Campañas',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: provider.isLoading ? null : _loadData,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nueva campaña'),
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F766E), Color(0xFF115E59)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.campaign_outlined,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Campañas de ${bot.nombre}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Cada bot detecta solo sus propias campañas, mensajes, reglas e imágenes.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.88),
                          fontSize: 13,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _search = value.trim();
                });
                _loadData();
              },
              decoration: InputDecoration(
                hintText: 'Buscar por nombre, código o producto',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _search.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _search = '';
                          });
                          _loadData();
                        },
                        icon: const Icon(Icons.clear_rounded),
                      ),
              ),
            ),
          ),
          if (provider.error != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Text(
                provider.error!,
                style: TextStyle(color: Colors.red.shade700),
              ),
            ),
          Expanded(
            child: provider.isLoading && campaigns.isEmpty
                ? const Center(child: CircularProgressIndicator(strokeWidth: 3))
                : campaigns.isEmpty
                    ? _EmptyCampaigns(onCreate: () => _openForm(context))
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                          itemCount: campaigns.length,
                          itemBuilder: (context, index) {
                            final campaign = campaigns[index];
                            return _CampaignCard(
                              campaign: campaign,
                              onEdit: () => _openForm(context, campaign: campaign),
                              onToggle: () => provider.cambiarEstado(
                                bot.id,
                                campaign.id,
                                !campaign.active,
                              ),
                              onDuplicate: () => provider.duplicarCampana(
                                bot.id,
                                campaign.id,
                              ),
                              onDelete: () => _confirmDelete(context, campaign),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Future<void> _openForm(
    BuildContext context, {
    BotCampaignModel? campaign,
  }) async {
    final bot = context.read<BotProvider>().botSeleccionado;
    if (bot == null) return;

    final payload = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => BotCampaignFormPage(
          botId: bot.id,
          campaign: campaign,
        ),
      ),
    );

    if (!mounted || payload == null) return;

    final provider = this.context.read<BotCampaignProvider>();
    if (campaign == null) {
      await provider.crearCampana(bot.id, payload);
    } else {
      await provider.actualizarCampana(bot.id, campaign.id, payload);
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    BotCampaignModel campaign,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar campaña'),
        content: Text(
          'Se eliminará la campaña "${campaign.campaignName}". Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final bot = context.read<BotProvider>().botSeleccionado;
    if (bot == null) return;
    await context.read<BotCampaignProvider>().eliminarCampana(bot.id, campaign.id);
  }
}

class _CampaignCard extends StatelessWidget {
  final BotCampaignModel campaign;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  const _CampaignCard({
    required this.campaign,
    required this.onEdit,
    required this.onToggle,
    required this.onDuplicate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          campaign.campaignName,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          campaign.campaignCode,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _StatusPill(
                    label: campaign.active ? 'Activa' : 'Inactiva',
                    color: campaign.active ? Colors.green : Colors.red,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InfoChip(
                    icon: Icons.key_rounded,
                    label: '${campaign.keywords.length} keywords',
                  ),
                  _InfoChip(
                    icon: Icons.flash_on_outlined,
                    label: '${campaign.triggerPhrases.length} triggers',
                  ),
                ],
              ),
              if (campaign.keywords.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Keywords: ${campaign.keywords.take(4).join(' · ')}'
                  '${campaign.keywords.length > 4 ? '…' : ''}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
              if ((campaign.campaignContext ?? '').isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  campaign.campaignContext!,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                    height: 1.35,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Editar'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: onDuplicate,
                    icon: const Icon(Icons.copy_outlined, size: 18),
                    label: const Text('Duplicar'),
                  ),
                  const Spacer(),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'toggle':
                          onToggle();
                          break;
                        case 'delete':
                          onDelete();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'toggle',
                        child: Text(
                          campaign.active ? 'Desactivar' : 'Activar',
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Eliminar'),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyCampaigns extends StatelessWidget {
  final VoidCallback onCreate;

  const _EmptyCampaigns({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: const Color(0xFFE6FFFA),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.campaign_outlined,
                size: 42,
                color: Color(0xFF0F766E),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Este bot todavía no tiene campañas',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Crea campañas con sus productos, frases disparadoras, reglas de venta e imágenes para que el flujo CAMPAÑA arranque desde el primer mensaje.',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Crear campaña'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade700),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade800,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
