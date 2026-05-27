import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:frondend/app.dart';
import 'package:frondend/features/bots/providers/bot_provider.dart';
import 'package:frondend/features/campaigns/providers/bot_campaign_provider.dart';
import 'package:frondend/features/catalogo/providers/catalogo_provider.dart';
import 'package:frondend/features/clientes/providers/clientes_provider.dart';
import 'package:frondend/features/conversaciones/providers/conversaciones_provider.dart';
import 'package:frondend/features/followups/providers/followups_provider.dart';
import 'package:frondend/features/orders/providers/bot_order_provider.dart';
import 'package:frondend/features/orders/providers/order_provider.dart';
import 'package:frondend/features/quotations/providers/bot_quotation_provider.dart';
import 'package:frondend/features/quotations/providers/quotation_provider.dart';

void main() {
  testWidgets('App renders the public storefront entry by default', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => BotProvider()),
          ChangeNotifierProvider(create: (_) => CatalogoProvider()),
          ChangeNotifierProvider(create: (_) => BotCampaignProvider()),
          ChangeNotifierProvider(create: (_) => ConversacionesProvider()),
          ChangeNotifierProvider(create: (_) => ClientesProvider()),
          ChangeNotifierProvider(create: (_) => BotOrderProvider()),
          ChangeNotifierProvider(create: (_) => BotQuotationProvider()),
          ChangeNotifierProvider(create: (_) => OrderProvider()),
          ChangeNotifierProvider(create: (_) => QuotationProvider()),
          ChangeNotifierProvider(create: (_) => FollowupsProvider()),
        ],
        child: const MyApp(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('FULLTECH'), findsWidgets);
    expect(find.text('Iniciar sesion admin'), findsOneWidget);
  });
}
