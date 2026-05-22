import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/bot_provider.dart';
import '../../catalogo/pages/catalogo_page.dart';
import '../../clientes/pages/clientes_page.dart';
import '../../conversaciones/pages/conversaciones_page.dart';
import 'bot_selector_page.dart';
import 'bot_form_page.dart';

class BotDashboardPage extends StatefulWidget {
  const BotDashboardPage({super.key});

  @override
  State<BotDashboardPage> createState() => _BotDashboardPageState();
}

class _BotDashboardPageState extends State<BotDashboardPage> {
  int _currentIndex = 0;

  late final List<Widget> _pages = const [
    CatalogoPage(),
    ConversacionesPage(),
    ClientesPage(),
    _CotizacionesPlaceholder(),
    _ConfiguracionPlaceholder(),
  ];

  @override
  Widget build(BuildContext context) {
    final botProvider = context.watch<BotProvider>();
    final bot = botProvider.botSeleccionado;

    if (bot == null) {
      return const _SinBotSeleccionado();
    }

    final isActive = bot.estado == 'activo';

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isActive ? Colors.green.shade50 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.smart_toy_outlined,
                size: 18,
                color: isActive ? Colors.green.shade600 : Colors.grey.shade400,
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    bot.nombre,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (bot.tipoNegocio != null)
                    Text(
                      bot.tipoNegocio!,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
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
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Cambiar bot',
            onPressed: () => _cambiarBot(context),
            icon: const Icon(Icons.swap_horiz_rounded),
          ),
          PopupMenuButton<String>(
            tooltip: 'Opciones del bot',
            onSelected: (value) {
              if (value == 'edit') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BotFormPage(bot: bot),
                  ),
                );
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'edit',
                child: ListTile(
                  leading: Icon(Icons.edit_outlined, size: 20),
                  title: Text('Editar bot'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
            icon: Icon(Icons.more_vert, size: 20, color: Colors.grey.shade600),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Catálogo',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_outlined),
            selectedIcon: Icon(Icons.chat),
            label: 'Conversaciones',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Clientes',
          ),
          NavigationDestination(
            icon: Icon(Icons.request_quote_outlined),
            selectedIcon: Icon(Icons.request_quote),
            label: 'Cotizaciones',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune_outlined),
            selectedIcon: Icon(Icons.tune),
            label: 'Config.',
          ),
        ],
      ),
    );
  }

  Future<void> _cambiarBot(BuildContext context) async {
    final botProvider = context.read<BotProvider>();
    await botProvider.cargarBots();

    if (!mounted) return;

    await Navigator.push<dynamic>(
      context,
      MaterialPageRoute(
        builder: (_) => const BotSelectorPage(),
      ),
    );
  }
}

class _SinBotSeleccionado extends StatelessWidget {
  const _SinBotSeleccionado();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FullTech Bot'),
        centerTitle: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Icon(
                  Icons.smart_toy_outlined,
                  size: 50,
                  color: Colors.blue.shade300,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Selecciona un bot',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Para empezar, selecciona o crea un bot.\nCada bot tiene su propio catálogo, clientes y conversaciones.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),
              FilledButton.icon(
                onPressed: () => _irASelector(context),
                icon: const Icon(Icons.touch_app_rounded, size: 20),
                label: const Text('Seleccionar bot'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _irASelector(BuildContext context) async {
    final botProvider = context.read<BotProvider>();
    await botProvider.cargarBots();

    if (!context.mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const BotSelectorPage(),
      ),
    );
  }
}

class _CotizacionesPlaceholder extends StatelessWidget {
  const _CotizacionesPlaceholder();

  @override
  Widget build(BuildContext context) {
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
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(Icons.request_quote_outlined, size: 40, color: Colors.teal.shade300),
            ),
            const SizedBox(height: 16),
            const Text(
              'Cotizaciones',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Próximamente podrás gestionar cotizaciones\ndesde aquí.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfiguracionPlaceholder extends StatelessWidget {
  const _ConfiguracionPlaceholder();

  @override
  Widget build(BuildContext context) {
    final bot = context.watch<BotProvider>().botSeleccionado;

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
              child: Icon(Icons.tune_outlined, size: 40, color: Colors.purple.shade300),
            ),
            const SizedBox(height: 16),
            const Text(
              'Configuración del bot',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Personaliza el comportamiento y ajustes\nde ${bot?.nombre ?? "tu bot"}.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BotFormPage(bot: bot),
                  ),
                );
              },
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Editar configuración'),
            ),
          ],
        ),
      ),
    );
  }
}
