import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'features/bots/pages/bot_selector_page.dart';
import 'features/bots/providers/bot_provider.dart';
import 'app_shell.dart';

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
  bool _checkingBot = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _verificarBotInicial();
    });
  }

  Future<void> _verificarBotInicial() async {
    final botProvider = context.read<BotProvider>();
    await botProvider.cargarBots();

    if (!mounted) return;

    if (!botProvider.hayBotSeleccionado) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const BotSelectorPage(),
        ),
      );
    }

    if (!mounted) return;
    setState(() {
      _checkingBot = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final botProvider = context.watch<BotProvider>();

    if (_checkingBot && !botProvider.hayBotSeleccionado) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(strokeWidth: 3),
              const SizedBox(height: 16),
              Text(
                'Cargando...',
                style: TextStyle(color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      );
    }

    if (!botProvider.hayBotSeleccionado) {
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
                  onPressed: () async {
                    await botProvider.cargarBots();
                    if (!mounted) return;
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const BotSelectorPage(),
                      ),
                    );
                  },
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

    return const AppShell();
  }
}
