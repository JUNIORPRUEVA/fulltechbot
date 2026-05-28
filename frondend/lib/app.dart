import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'features/auth/screens/admin_login_screen.dart';
import 'features/auth/widgets/admin_route_guard.dart';
import 'features/bots/pages/bot_dashboard_page.dart';
import 'features/bots/pages/bot_selector_page.dart';
import 'features/bots/providers/bot_provider.dart';
import 'features/public/screens/public_entry_screen.dart';
import 'features/public/screens/public_store_redirect_screen.dart';
import 'features/storefront/screens/storefront_cart_screen.dart';
import 'features/storefront/screens/storefront_category_screen.dart';
import 'features/storefront/screens/storefront_checkout_screen.dart';
import 'features/storefront/screens/storefront_home_screen.dart';
import 'features/storefront/screens/storefront_product_detail_screen.dart';
import 'features/storefront/screens/storefront_success_screen.dart';
import 'features/storefront_admin/screens/storefront_admin_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FullTech Bot',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      onGenerateRoute: _onGenerateRoute,
      home: const PublicEntryScreen(),
    );
  }

  Route<dynamic> _onGenerateRoute(RouteSettings settings) {
    final uri = Uri.parse(settings.name ?? '/');

    if (uri.path == '/' || uri.path == '/tienda') {
      return _route(
        settings,
        PublicEntryScreen(
          preferredSlug: uri.queryParameters['slug'],
        ),
      );
    }

    if (uri.path == '/login' || uri.path == '/admin/login') {
      final redirectTo = uri.queryParameters['redirect'] ?? '/admin';
      return _route(
        settings,
        AdminLoginScreen(redirectTo: redirectTo),
      );
    }

    if (uri.pathSegments.isNotEmpty && uri.pathSegments.first == 'admin') {
      return _buildAdminRoute(uri, settings);
    }

    if (uri.pathSegments.length == 2 && uri.pathSegments[0] == 'tienda') {
      return _route(
        settings,
        StorefrontHomeScreen(slug: uri.pathSegments[1]),
      );
    }

    if (uri.pathSegments.length == 4 &&
        uri.pathSegments[0] == 'tienda' &&
        uri.pathSegments[2] == 'producto') {
      final args = settings.arguments as Map<String, dynamic>?;
      return _route(
        settings,
        StorefrontProductDetailScreen(
          slug: uri.pathSegments[1],
          productId: uri.pathSegments[3],
          initialProduct: args?['product'] is Map
              ? Map<String, dynamic>.from(args!['product'] as Map)
              : null,
        ),
      );
    }

    if (uri.pathSegments.length == 2 && uri.pathSegments[0] == 'producto') {
      return _route(
        settings,
        PublicStoreRedirectScreen(
          target: PublicStoreRedirectTarget.product,
          productId: uri.pathSegments[1],
        ),
      );
    }

    if (uri.pathSegments.length == 4 &&
        uri.pathSegments[0] == 'tienda' &&
        uri.pathSegments[2] == 'categoria') {
      return _route(
        settings,
        StorefrontCategoryScreen(
          slug: uri.pathSegments[1],
          categoria: Uri.decodeComponent(uri.pathSegments[3]),
        ),
      );
    }

    if (uri.pathSegments.length == 3 &&
        uri.pathSegments[0] == 'tienda' &&
        uri.pathSegments[2] == 'busqueda') {
      final args = settings.arguments as Map<String, dynamic>?;
      return _route(
        settings,
        StorefrontCategoryScreen(
          slug: uri.pathSegments[1],
          busqueda: args?['busqueda'] as String?,
        ),
      );
    }

    if ((uri.path == '/carrito') ||
        (uri.pathSegments.length == 3 &&
            uri.pathSegments[0] == 'tienda' &&
            uri.pathSegments[2] == 'carrito')) {
      if (uri.path == '/carrito') {
        return _route(
          settings,
          const PublicStoreRedirectScreen(
            target: PublicStoreRedirectTarget.cart,
          ),
        );
      }

      return _route(
        settings,
        StorefrontCartScreen(slug: uri.pathSegments[1]),
      );
    }

    if ((uri.path == '/checkout') ||
        (uri.pathSegments.length == 3 &&
            uri.pathSegments[0] == 'tienda' &&
            uri.pathSegments[2] == 'checkout')) {
      if (uri.path == '/checkout') {
        return _route(
          settings,
          const PublicStoreRedirectScreen(
            target: PublicStoreRedirectTarget.checkout,
          ),
        );
      }

      return _route(
        settings,
        StorefrontCheckoutScreen(slug: uri.pathSegments[1]),
      );
    }

    if (uri.pathSegments.length == 3 &&
        uri.pathSegments[0] == 'tienda' &&
        uri.pathSegments[2] == 'exito') {
      final args = settings.arguments as Map<String, dynamic>?;
      return _route(
        settings,
        StorefrontSuccessScreen(
          slug: uri.pathSegments[1],
          data: args,
        ),
      );
    }

    return _route(settings, const PublicEntryScreen());
  }

  Route<dynamic> _buildAdminRoute(Uri uri, RouteSettings settings) {
    final path = uri.path;
    Widget child;

    switch (path) {
      case '/admin':
      case '/admin/catalogo':
      case '/admin/productos':
        child = const MainNavigation(initialIndex: 0);
        break;
      case '/admin/pedidos':
        child = const MainNavigation(initialIndex: 1);
        break;
      case '/admin/clientes':
        child = const MainNavigation(initialIndex: 2);
        break;
      case '/admin/bots':
        child = const MainNavigation(openBotSelectorOnStart: true);
        break;
      case '/admin/tienda':
        child = const StorefrontAdminScreen();
        break;
      case '/admin/banners':
        child = const StorefrontAdminScreen(initialTabIndex: 1);
        break;
      case '/admin/pagos':
        child = const StorefrontAdminScreen(initialTabIndex: 4);
        break;
      default:
        child = const MainNavigation();
        break;
    }

    return _route(
      settings,
      AdminRouteGuard(
        redirectPath: settings.name ?? uri.toString(),
        child: child,
      ),
    );
  }

  MaterialPageRoute<dynamic> _route(RouteSettings settings, Widget child) {
    return MaterialPageRoute(
      builder: (_) => child,
      settings: settings,
    );
  }

  ThemeData _buildTheme() {
    const primaryColor = Color(0xFF0F172A);
    const secondaryColor = Color(0xFF2563EB);
    const accentColor = Color(0xFFF97316);
    const backgroundColor = Color(0xFFF8FAFC);

    return ThemeData(
      useMaterial3: true,
      textTheme: GoogleFonts.manropeTextTheme(),
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: accentColor,
        surface: Colors.white,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: const Color(0xFF111827),
      ),
      scaffoldBackgroundColor: backgroundColor,
      splashFactory: InkRipple.splashFactory,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF111827),
        titleTextStyle: TextStyle(
          color: Color(0xFF111827),
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: secondaryColor, width: 1.5),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        labelStyle: const TextStyle(color: Color(0xFF6B7280)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE5E7EB),
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

class MainNavigation extends StatefulWidget {
  final int initialIndex;
  final bool openBotSelectorOnStart;

  const MainNavigation({
    super.key,
    this.initialIndex = 0,
    this.openBotSelectorOnStart = false,
  });

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  bool _checkingBot = true;
  bool _navigating = false;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _verificarBotInicial();
    });
  }

  Future<void> _verificarBotInicial() async {
    if (_navigating) return;
    _navigating = true;

    try {
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
      } else if (widget.openBotSelectorOnStart) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const BotSelectorPage(),
          ),
        );
      }
    } catch (e) {
      debugPrint('[MainNavigation] Error en verificacion inicial: $e');
    } finally {
      if (mounted) {
        setState(() {
          _checkingBot = false;
          _navigating = false;
        });
      }
    }
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
                  'Para empezar, selecciona o crea un bot.\nCada bot tiene su propio catalogo, clientes y conversaciones.',
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
                    if (_navigating) return;
                    _navigating = true;
                    try {
                      await botProvider.cargarBots();
                      if (!mounted) return;
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const BotSelectorPage(),
                        ),
                      );
                    } finally {
                      if (mounted) {
                        _navigating = false;
                      }
                    }
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

    return BotDashboardPage(initialIndex: _currentIndex);
  }
}
