import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'features/bots/pages/bot_dashboard_page.dart';
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

    // Si no hay bot seleccionado, mostrar selector
    if (!botProvider.hayBotSeleccionado) {
      _mostrarSelector();
    }
  }

  Future<void> _mostrarSelector() async {
    final botProvider = context.read<BotProvider>();
    await botProvider.cargarBots();

    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const BotSelectorPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final botProvider = context.watch<BotProvider>();

    return BotDashboardPage(
      key: ValueKey(botProvider.botSeleccionado?.id),
    );
  }
}
