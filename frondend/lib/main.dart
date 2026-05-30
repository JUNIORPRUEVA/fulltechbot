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

/// Oculta el splash screen de HTML cuando Flutter ya renderizó el primer frame.
void _hideSplashScreen() {
  try {
    // Usamos dart:js para llamar JS desde Flutter
    // ignore: undefined_prefixed_name
    _hideSplashJS();
  } catch (_) {
    // Ignorar si no es web
  }
}

// JS interop para ocultar el splash screen
void _hideSplashJS() {
  // Esta función se reemplaza en web con dart:js
}

// JS interop para recargar la página
void _reloadPage() {
  try {
    // ignore: undefined_prefixed_name
    _reloadPageJS();
  } catch (_) {
    // Ignorar si no es web
  }
}

void _reloadPageJS() {
  // Esta función se reemplaza en web con dart:js
}

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Ocultar splash screen inmediatamente cuando Flutter esté listo
    _hideSplashScreen();

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
                    // Recargar la página
                    // ignore: undefined_prefixed_name
                    _reloadPage();
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
