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
            tooltip: 'Actualizar lista',
            onPressed: provider.isLoading
                ? null
                : () => context.read<BotProvider>().cargarBots(),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirFormulario(context),
        icon: const Icon(Icons.add, size: 20),
        label: const Text('Crear bot'),
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
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: provider.bots.length,
        itemBuilder: (context, index) {
          final bot = provider.bots[index];
          return _BotCardProfesional(
            bot: bot,
            isSelected: provider.botSeleccionado?.id == bot.id,
            onEntrar: () {
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

class _BotCardProfesional extends StatelessWidget {
  final BotModel bot;
  final bool isSelected;
  final VoidCallback onEntrar;
  final VoidCallback onEdit;
  final VoidCallback onToggleStatus;

  const _BotCardProfesional({
    required this.bot,
    required this.isSelected,
    required this.onEntrar,
    required this.onEdit,
    required this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = bot.estado == 'activo';
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: isSelected ? 2 : 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isSelected
                ? colorScheme.primary
                : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fila superior: icono + info + estado
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icono del bot
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.green.shade50
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.smart_toy_outlined,
                      color: isActive
                          ? Colors.green.shade600
                          : Colors.grey.shade400,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Nombre, tipo, descripción
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bot.nombre,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (bot.tipoNegocio != null) ...[
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              bot.tipoNegocio!,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.blue.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                        if (bot.descripcion != null &&
                            bot.descripcion!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            bot.descripcion!,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Badge de estado
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.green.shade50
                          : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isActive
                            ? Colors.green.shade200
                            : Colors.red.shade200,
                      ),
                    ),
                    child: Text(
                      isActive ? 'Activo' : 'Inactivo',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isActive
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Slug
              Row(
                children: [
                  Icon(Icons.link, size: 13, color: Colors.grey.shade400),
                  const SizedBox(width: 4),
                  Text(
                    bot.slug,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Botones de acción
              Row(
                children: [
                  // Botón Entrar
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onEntrar,
                      icon: const Icon(Icons.login_rounded, size: 18),
                      label: const Text('Entrar'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Botón Editar
                  OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Editar'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Menú de opciones
                  PopupMenuButton<String>(
                    tooltip: 'Más opciones',
                    onSelected: (value) {
                      if (value == 'toggle') onToggleStatus();
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'toggle',
                        child: Text(
                          isActive ? 'Desactivar bot' : 'Activar bot',
                        ),
                      ),
                    ],
                    icon: Icon(
                      Icons.more_vert,
                      size: 20,
                      color: Colors.grey.shade500,
                    ),
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
