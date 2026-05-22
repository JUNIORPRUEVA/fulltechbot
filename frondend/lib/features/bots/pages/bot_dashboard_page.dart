import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/bot_model.dart';
import '../providers/bot_provider.dart';
import '../../catalogo/pages/catalogo_page.dart';
import '../../clientes/pages/clientes_page.dart';
import '../../conversaciones/pages/conversaciones_page.dart';
import '../../orders/pages/orders_page.dart';
import '../../quotations/pages/quotations_page.dart';
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
    OrdersPage(),
    QuotationsPage(),
    ClientesPage(),
    ConversacionesPage(),
    _ConfiguracionPlaceholder(),
  ];

  static const List<_NavItem> _navItems = [
    _NavItem(
      icon: Icons.inventory_2_outlined,
      activeIcon: Icons.inventory_2,
      label: 'Catálogo',
    ),
    _NavItem(
      icon: Icons.receipt_long_outlined,
      activeIcon: Icons.receipt_long,
      label: 'Pedidos',
    ),
    _NavItem(
      icon: Icons.request_quote_outlined,
      activeIcon: Icons.request_quote,
      label: 'Cotizaciones',
    ),
    _NavItem(
      icon: Icons.people_outline,
      activeIcon: Icons.people,
      label: 'Clientes',
    ),
    _NavItem(
      icon: Icons.chat_outlined,
      activeIcon: Icons.chat,
      label: 'Chats',
    ),
  ];

  static const List<_NavItem> _drawerItems = [
    _NavItem(
      icon: Icons.inventory_2_outlined,
      activeIcon: Icons.inventory_2,
      label: 'Catálogo',
    ),
    _NavItem(
      icon: Icons.receipt_long_outlined,
      activeIcon: Icons.receipt_long,
      label: 'Pedidos',
    ),
    _NavItem(
      icon: Icons.request_quote_outlined,
      activeIcon: Icons.request_quote,
      label: 'Cotizaciones',
    ),
    _NavItem(
      icon: Icons.people_outline,
      activeIcon: Icons.people,
      label: 'Clientes',
    ),
    _NavItem(
      icon: Icons.chat_outlined,
      activeIcon: Icons.chat,
      label: 'Conversaciones',
    ),
    _NavItem(
      icon: Icons.tune_outlined,
      activeIcon: Icons.tune,
      label: 'Config.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final botProvider = context.watch<BotProvider>();
    final bot = botProvider.botSeleccionado;

    if (bot == null) {
      return const _SinBotSeleccionado();
    }

    final isActive = bot.estado == 'activo';
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;

    return Scaffold(
      appBar: AppBar(
        title: Column(
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
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 4),
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
          IconButton(
            tooltip: 'Cambiar bot',
            onPressed: () => _cambiarBot(context),
            icon: const Icon(Icons.swap_horiz_rounded),
          ),
        ],
      ),
      drawer: isDesktop ? null : _buildDrawer(context, bot, isActive),
      body: Row(
        children: [
          if (isDesktop) _buildSidebar(bot, isActive),
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: _pages,
            ),
          ),
        ],
      ),
      bottomNavigationBar: isDesktop
          ? null
          : NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              destinations: _navItems.map((item) {
                return NavigationDestination(
                  icon: Icon(item.icon),
                  selectedIcon: Icon(item.activeIcon),
                  label: item.label,
                );
              }).toList(),
            ),
    );
  }

  Widget _buildDrawer(BuildContext context, BotModel bot, bool isActive) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // Header del bot - flexible, sin altura fija
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isActive ? Colors.green.shade50 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.smart_toy_outlined,
                      size: 22,
                      color: isActive ? Colors.green.shade600 : Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    bot.nombre,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (bot.tipoNegocio != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      bot.tipoNegocio!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
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
            ),
            // Lista de navegación
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  for (int i = 0; i < _drawerItems.length; i++) ...[
                    if (i == 5) const Divider(height: 1),
                    ListTile(
                      leading: Icon(
                        _currentIndex == i
                            ? _drawerItems[i].activeIcon
                            : _drawerItems[i].icon,
                        color: _currentIndex == i
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                      title: Text(
                        _drawerItems[i].label,
                        style: TextStyle(
                          fontWeight:
                              _currentIndex == i ? FontWeight.w700 : FontWeight.w500,
                          color: _currentIndex == i
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                      ),
                      selected: _currentIndex == i,
                      selectedTileColor:
                          Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onTap: () {
                        setState(() {
                          _currentIndex = i;
                        });
                        Navigator.pop(context);
                      },
                    ),
                  ],
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.edit_outlined),
                    title: const Text('Editar bot'),
                    onTap: () {
                      Navigator.pop(context);
                      _editarBot(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.swap_horiz_rounded),
                    title: const Text('Cambiar bot'),
                    onTap: () {
                      Navigator.pop(context);
                      _cambiarBot(context);
                    },
                  ),
                ],
              ),
            ),
            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.smart_toy_outlined, size: 16, color: Colors.grey.shade400),
                  const SizedBox(width: 6),
                  Text(
                    'FullTech Bot',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar(BotModel bot, bool isActive) {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          right: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isActive ? Colors.green.shade50 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.smart_toy_outlined,
                    size: 18,
                    color: isActive ? Colors.green.shade600 : Colors.grey.shade400,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bot.nombre,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        bot.tipoNegocio ?? '',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                for (int i = 0; i < _navItems.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    child: ListTile(
                      dense: true,
                      leading: Icon(
                        _currentIndex == i
                            ? _navItems[i].activeIcon
                            : _navItems[i].icon,
                        size: 20,
                        color: _currentIndex == i
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey.shade600,
                      ),
                      title: Text(
                        _navItems[i].label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              _currentIndex == i ? FontWeight.w700 : FontWeight.w500,
                          color: _currentIndex == i
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey.shade700,
                        ),
                      ),
                      selected: _currentIndex == i,
                      selectedTileColor: Theme.of(context)
                          .colorScheme
                          .primaryContainer
                          .withValues(alpha: 0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      onTap: () {
                        setState(() {
                          _currentIndex = i;
                        });
                      },
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _cambiarBot(context),
                icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                label: const Text('Cambiar bot', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _editarBot(BuildContext context) {
    final bot = context.read<BotProvider>().botSeleccionado;
    if (bot == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BotFormPage(bot: bot),
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

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
