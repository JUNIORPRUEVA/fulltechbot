import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/bot_model.dart';
import '../providers/bot_provider.dart';
import 'bot_form_page.dart';

class BotSelectorPage extends StatefulWidget {
  const BotSelectorPage({super.key});

  @override
  State<BotSelectorPage> createState() => _BotSelectorPageState();
}

class _BotSelectorPageState extends State<BotSelectorPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<BotProvider>().cargarBots();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BotProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccionar Bot'),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: provider.isLoading
                ? null
                : () => context.read<BotProvider>().cargarBots(),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _abrirFormulario(context),
        child: const Icon(Icons.add),
      ),
      body: _buildBody(provider),
    );
  }

  Widget _buildBody(BotProvider provider) {
    if (provider.isLoading && provider.bots.isEmpty) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 3));
    }

    if (provider.error != null && provider.bots.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded, size: 48, color: Colors.red.shade300),
              const SizedBox(height: 12),
              Text(
                'Error al cargar bots',
                style: TextStyle(color: Colors.red.shade600, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                provider.error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => context.read<BotProvider>().cargarBots(),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (provider.bots.isEmpty) {
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
                child: Icon(Icons.smart_toy_outlined, size: 40, color: Colors.blue.shade300),
              ),
              const SizedBox(height: 16),
              const Text(
                'No hay bots todavía',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                'Crea tu primer bot para empezar a administrar productos, clientes y conversaciones.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => _abrirFormulario(context),
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Crear bot'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<BotProvider>().cargarBots(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
        itemCount: provider.bots.length,
        itemBuilder: (context, index) {
          final bot = provider.bots[index];
          return _BotCard(
            bot: bot,
            isSelected: provider.botSeleccionado?.id == bot.id,
            onTap: () {
              provider.seleccionarBot(bot);
              Navigator.pop(context, bot);
            },
            onEdit: () => _abrirFormulario(context, bot: bot),
            onToggleStatus: () {
              final nuevoEstado = bot.estado == 'activo' ? 'inactivo' : 'activo';
              provider.cambiarEstado(bot.id, nuevoEstado);
            },
          );
        },
      ),
    );
  }

  Future<void> _abrirFormulario(BuildContext context, {BotModel? bot}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BotFormPage(bot: bot),
      ),
    );
  }
}

class _BotCard extends StatelessWidget {
  final BotModel bot;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onToggleStatus;

  const _BotCard({
    required this.bot,
    required this.isSelected,
    required this.onTap,
    required this.onEdit,
    required this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = bot.estado == 'activo';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue.shade50 : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? Colors.blue.shade300 : Colors.grey.shade200,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icono
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isActive ? Colors.green.shade50 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.smart_toy_outlined,
                    color: isActive ? Colors.green.shade600 : Colors.grey.shade400,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bot.nombre,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        bot.slug,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      if (bot.tipoNegocio != null) ...[
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            bot.tipoNegocio!,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.blue.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Estado
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isActive ? Colors.green.shade200 : Colors.red.shade200,
                    ),
                  ),
                  child: Text(
                    isActive ? 'Activo' : 'Inactivo',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isActive ? Colors.green.shade700 : Colors.red.shade700,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                // Menú
                PopupMenuButton<String>(
                  tooltip: 'Opciones',
                  onSelected: (value) {
                    if (value == 'edit') onEdit();
                    else if (value == 'toggle') onToggleStatus();
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'toggle',
                      child: Text(isActive ? 'Desactivar' : 'Activar'),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        leading: Icon(Icons.edit_outlined, size: 20),
                        title: Text('Editar'),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                  icon: Icon(Icons.more_vert, size: 18, color: Colors.grey.shade400),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
