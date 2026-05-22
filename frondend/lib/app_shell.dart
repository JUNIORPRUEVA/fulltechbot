import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'features/bots/providers/bot_provider.dart';
import 'features/bots/pages/bot_dashboard_page.dart';
import 'features/bots/pages/bot_selector_page.dart';
import 'features/orders/pages/orders_page.dart';
import 'features/quotations/pages/quotations_page.dart';
import 'features/clientes/pages/clientes_page.dart';
import 'features/conversaciones/pages/conversaciones_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    BotDashboardPage(),
    BotSelectorPage(),
    OrdersPage(),
    QuotationsPage(),
    ClientesPage(),
    ConversacionesPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final botProvider = context.watch<BotProvider>();
    final bot = botProvider.botSeleccionado;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          bot != null ? '${bot.nombre}' : 'FULLTECH BOT',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      drawer: _buildDrawer(context, botProvider, bot),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.smart_toy_outlined),
            selectedIcon: Icon(Icons.smart_toy),
            label: 'Bots',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Pedidos',
          ),
          NavigationDestination(
            icon: Icon(Icons.request_quote_outlined),
            selectedIcon: Icon(Icons.request_quote),
            label: 'Cotizaciones',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Clientes',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_outlined),
            selectedIcon: Icon(Icons.chat),
            label: 'Chats',
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(
      BuildContext context, BotProvider botProvider, dynamic bot) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(Icons.smart_toy_rounded, size: 48),
                const SizedBox(height: 8),
                Text(
                  'FULLTECH BOT',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                if (bot != null)
                  Text(
                    'Bot activo: ${bot.nombre}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          _drawerItem(
            icon: Icons.dashboard,
            label: 'Dashboard',
            selected: _selectedIndex == 0,
            onTap: () => _selectPage(0),
          ),
          _drawerItem(
            icon: Icons.smart_toy,
            label: 'Bots',
            selected: _selectedIndex == 1,
            onTap: () => _selectPage(1),
          ),
          const Divider(),
          _drawerItem(
            icon: Icons.receipt_long,
            label: 'Pedidos',
            selected: _selectedIndex == 2,
            onTap: () => _selectPage(2),
          ),
          _drawerItem(
            icon: Icons.request_quote,
            label: 'Cotizaciones',
            selected: _selectedIndex == 3,
            onTap: () => _selectPage(3),
          ),
          _drawerItem(
            icon: Icons.people,
            label: 'Clientes',
            selected: _selectedIndex == 4,
            onTap: () => _selectPage(4),
          ),
          _drawerItem(
            icon: Icons.chat,
            label: 'Conversaciones',
            selected: _selectedIndex == 5,
            onTap: () => _selectPage(5),
          ),
          const Divider(),
          if (bot != null) ...[
            _drawerItem(
              icon: Icons.inventory_2,
              label: 'Catálogo de ${bot.nombre}',
              selected: false,
              onTap: () {
                Navigator.pop(context);
                setState(() => _selectedIndex = 0);
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _drawerItem({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      selected: selected,
      selectedTileColor: Theme.of(context)
          .colorScheme
          .primaryContainer
          .withValues(alpha: 0.3),
      onTap: onTap,
    );
  }

  void _selectPage(int index) {
    setState(() => _selectedIndex = index);
    Navigator.pop(context);
  }
}
