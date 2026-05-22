import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'features/catalogo/pages/catalogo_page.dart';
import 'features/conversaciones/pages/conversaciones_page.dart';
import 'features/clientes/pages/clientes_page.dart';
import 'features/bots/pages/bot_selector_page.dart';
import 'features/bots/providers/bot_provider.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FullTech Bot',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFF6F7F9),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
        ),
      ),
      home: const MainNavigation(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  late final List<Widget> _pages = [
    const CatalogoPage(),
    const ConversacionesPage(),
    const ClientesPage(),
  ];

  void _seleccionarBot(BuildContext context) async {
    final botProvider = context.read<BotProvider>();
    await botProvider.cargarBots();

    if (!mounted) return;

    final botSeleccionado = await Navigator.push<dynamic>(
      context,
      MaterialPageRoute(
        builder: (_) => const BotSelectorPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final botProvider = context.watch<BotProvider>();
    final botNombre = botProvider.botSeleccionado?.nombre ?? 'Sin bot seleccionado';

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () => _seleccionarBot(context),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.smart_toy_outlined,
                size: 20,
                color: botProvider.hayBotSeleccionado
                    ? Colors.green.shade600
                    : Colors.grey.shade400,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  botNombre,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: botProvider.hayBotSeleccionado
                        ? null
                        : Colors.grey.shade500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.arrow_drop_down_rounded, size: 20, color: Colors.grey.shade500),
            ],
          ),
        ),
        actions: [
          if (botProvider.hayBotSeleccionado)
            IconButton(
              tooltip: 'Cambiar bot',
              onPressed: () => _seleccionarBot(context),
              icon: const Icon(Icons.swap_horiz_rounded),
            ),
        ],
      ),
      body: botProvider.hayBotSeleccionado
          ? IndexedStack(
              index: _currentIndex,
              children: _pages,
            )
          : _SinBotSeleccionado(onSelectBot: () => _seleccionarBot(context)),
      bottomNavigationBar: botProvider.hayBotSeleccionado
          ? NavigationBar(
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
              ],
            )
          : null,
    );
  }
}

class _SinBotSeleccionado extends StatelessWidget {
  final VoidCallback onSelectBot;

  const _SinBotSeleccionado({required this.onSelectBot});

  @override
  Widget build(BuildContext context) {
    return Center(
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
              onPressed: onSelectBot,
              icon: const Icon(Icons.touch_app_rounded, size: 20),
              label: const Text('Seleccionar bot'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
