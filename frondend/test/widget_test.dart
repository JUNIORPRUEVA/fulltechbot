import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:frondend/app.dart';
import 'package:frondend/features/catalogo/providers/catalogo_provider.dart';
import 'package:frondend/features/conversaciones/providers/conversaciones_provider.dart';
import 'package:frondend/features/clientes/providers/clientes_provider.dart';

void main() {
  testWidgets('App renders bottom navigation', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => CatalogoProvider()),
          ChangeNotifierProvider(create: (_) => ConversacionesProvider()),
          ChangeNotifierProvider(create: (_) => ClientesProvider()),
        ],
        child: const MyApp(),
      ),
    );

    // Verify that the bottom navigation is present
    expect(find.text('Catálogo'), findsWidgets);
    expect(find.text('Conversaciones'), findsWidgets);
    expect(find.text('Clientes'), findsWidgets);
  });
}
