import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'features/catalogo/providers/catalogo_provider.dart';
import 'features/conversaciones/providers/conversaciones_provider.dart';
import 'features/clientes/providers/clientes_provider.dart';
import 'features/bots/providers/bot_provider.dart';
import 'features/orders/providers/bot_order_provider.dart';
import 'features/quotations/providers/bot_quotation_provider.dart';
import 'features/orders/providers/order_provider.dart';
import 'features/quotations/providers/quotation_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

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
      ],
      child: const MyApp(),
    ),
  );
}
