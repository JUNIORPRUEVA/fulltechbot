import 'dart:async';
import 'dart:html' as html;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'features/bots/providers/bot_provider.dart';
import 'features/campaigns/providers/bot_campaign_provider.dart';
import 'features/catalogo/providers/catalogo_provider.dart';
import 'features/clientes/providers/clientes_provider.dart';
import 'features/conversaciones/providers/conversaciones_provider.dart';
import 'features/followups/providers/followups_provider.dart';
import 'features/store_admin/providers/store_admin_provider.dart';
import 'features/orders/providers/bot_order_provider.dart';
import 'features/orders/providers/order_provider.dart';
import 'features/quotations/providers/bot_quotation_provider.dart';
import 'features/quotations/providers/quotation_provider.dart';

void main() {
  final DateTime appStart = DateTime.now();
  debugPrint('[PERF] main started - ${appStart.millisecondsSinceEpoch}');

  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    debugPrint('[PERF] WidgetsFlutterBinding.ensureInitialized completed - ${DateTime.now().difference(appStart).inMilliseconds}ms');

    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      debugPrint('==============================================');
      debugPrint('FLUTTER ERROR: ${details.exception}');
      debugPrint('STACKTRACE: ${details.stack}');
      debugPrint('==============================================');
    };

    ui.PlatformDispatcher.instance.onError = (error, stack) {
      debugPrint('==============================================');
      debugPrint('PLATFORM ERROR: $error');
      debugPrint('STACKTRACE: $stack');
      debugPrint('==============================================');
      return true;
    };

    ErrorWidget.builder = (FlutterErrorDetails details) {
      return Material(
        color: const Color(0xFF0F172A),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(
                    Icons.error_outline_rounded,
                    size: 40,
                    color: Colors.red.shade400,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Ocurrió un error',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: SelectableText(
                    details.exceptionAsString(),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.red.shade800,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () {
                    // Recargar la página usando window.location
                    try {
                      // ignore: undefined_prefixed_name
                      _reloadPage();
                    } catch (_) {}
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Recargar tienda'),
                ),
              ],
            ),
          ),
        ),
      );
    };

    // NO cargar nada aquí - los providers se crean sin await
    // NO google_fonts - eliminado para evitar descarga de fuentes
    // NO splash screen - Flutter renderiza inmediatamente
    debugPrint('[PERF] Starting runApp...');
    
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => BotProvider(),
          ),
          ChangeNotifierProvider(
            create: (_) => CatalogoProvider(),
          ),
          ChangeNotifierProvider(
            create: (_) => BotCampaignProvider(),
          ),
          ChangeNotifierProvider(
            create: (_) => ConversacionesProvider(),
          ),
          ChangeNotifierProvider(
            create: (_) => ClientesProvider(),
          ),
          ChangeNotifierProvider(
            create: (_) => BotOrderProvider(),
          ),
          ChangeNotifierProvider(
            create: (_) => BotQuotationProvider(),
          ),
          ChangeNotifierProvider(
            create: (_) => OrderProvider(),
          ),
          ChangeNotifierProvider(
            create: (_) => QuotationProvider(),
          ),
          ChangeNotifierProvider(
            create: (_) => FollowupsProvider(),
          ),
          ChangeNotifierProvider(
            create: (_) => StoreAdminProvider(),
          ),
        ],
        child: const MyApp(),
      ),
    );

    final elapsed = DateTime.now().difference(appStart).inMilliseconds;
    debugPrint('[PERF] runApp executed - ${elapsed}ms desde main()');
    debugPrint('[PERF] Primer frame de Flutter renderizado - splash oculto');
  }, (error, stack) {
    debugPrint('==============================================');
    debugPrint('ZONED ERROR: $error');
    debugPrint('STACKTRACE: $stack');
    debugPrint('==============================================');
  });
}

void _reloadPage() {
  try {
    html.window.location.reload();
  } catch (e) {
    debugPrint('[PERF] Error recargando página: $e');
  }
}
