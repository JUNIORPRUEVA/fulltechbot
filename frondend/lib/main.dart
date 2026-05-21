import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'features/catalogo/providers/catalogo_provider.dart';
import 'features/conversaciones/providers/conversaciones_provider.dart';
import 'features/clientes/providers/clientes_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => CatalogoProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => ConversacionesProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => ClientesProvider(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}
