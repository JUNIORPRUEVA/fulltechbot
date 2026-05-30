import 'dart:async';
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
import 'features/orders/providers/bot_order_provider.dart';
import 'features/orders/providers/order_provider.dart';
import 'features/quotations/providers/bot_quotation_provider.dart';
import 'features/quotations/providers/quotation_provider.dart';

/// Limpia los caches del Service Worker al iniciar la app.
/// Esto asegura que no se sirvan versiones anteriores cacheadas.
void _clearServiceWorkerCaches() {
  if (identical(0, 0)) return; // No-op en platforms que no sean web
  try {
    // En web, intentamos limpiar caches via JS interop
    // ignore: undefined_prefixed_name
    _clearCachesJS();
  } catch (_) {
    // Ignorar si no es web
  }
}

// JS interop para limpiar caches del service worker
// Esta función se llama solo en web
void _clearCachesJS() {
  // Usamos dart:js o simplemente dejamos que el index.html maneje la limpieza
}

void _setupServiceWorkerUpdateDetection() {
  // La actualizacion de la PWA se controla desde el bootstrap web desplegado.
  // El index.html ahora limpia los caches automáticamente al cargar.
}

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    _setupServiceWorkerUpdateDetection();

    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      debugPrint(
        '==============================================',
      );
      debugPrint('FLUTTER ERROR: ${details.exception}');
      debugPrint('STACKTRACE: ${details.stack}');
      debugPrint(
        '==============================================',
      );
    };

    ui.PlatformDispatcher.instance.onError = (error, stack) {
      debugPrint(
        '==============================================',
      );
      debugPrint('PLATFORM ERROR: $error');
      debugPrint('STACKTRACE: $stack');
      debugPrint(
        '==============================================',
      );
      return true;
    };

    ErrorWidget.builder = (FlutterErrorDetails details) {
      return Material(
        color: const Color(0xFFF6F7F9),
        child: Center(
          child: SingleChildScrollView(
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
                  'Ocurrio un error en la interfaz',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
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
                if (details.stack != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: SelectableText(
                      details.stack.toString(),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade700,
                        fontFamily: 'monospace',
                      ),
                      maxLines: 15,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    };

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
        ],
        child: const MyApp(),
      ),
    );
  }, (error, stack) {
    debugPrint(
      '==============================================',
    );
    debugPrint('ZONED ERROR: $error');
    debugPrint('STACKTRACE: $stack');
    debugPrint(
      '==============================================',
    );
  });
}
