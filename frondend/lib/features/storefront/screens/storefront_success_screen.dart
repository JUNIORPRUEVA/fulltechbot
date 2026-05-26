import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class StorefrontSuccessScreen extends StatelessWidget {
  final String slug;
  final Map<String, dynamic>? data;

  const StorefrontSuccessScreen({
    super.key,
    required this.slug,
    this.data,
  });

  @override
  Widget build(BuildContext context) {
    final pedidoId = data?['pedido_id'] ?? data?['id'] ?? '';
    final whatsappUrl = data?['whatsapp_url'] ?? '';
    final metodoPago = data?['metodo_pago'] ?? 'whatsapp';

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icono de éxito
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Icon(
                    Icons.check_circle_rounded,
                    size: 60,
                    color: Colors.green.shade500,
                  ),
                ),
                const SizedBox(height: 24),

                const Text(
                  '¡Pedido confirmado!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),

                Text(
                  'Gracias por tu compra. Te contactaremos pronto.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),

                // ID del pedido
                if (pedidoId.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Pedido #$pedidoId',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          metodoPago == 'paypal' ? 'Pago procesado vía PayPal' : 'Pendiente de confirmación',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 32),

                // Botón WhatsApp
                if (whatsappUrl.isNotEmpty)
                  OutlinedButton.icon(
                    onPressed: () => launchUrl(Uri.parse(whatsappUrl)),
                    icon: const Icon(Icons.chat, color: Color(0xFF25D366)),
                    label: const Text('Contactar por WhatsApp'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF25D366),
                      side: const BorderSide(color: Color(0xFF25D366)),
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),

                // Seguir comprando
                FilledButton.icon(
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/tienda/$slug',
                      (route) => false,
                    );
                  },
                  icon: const Icon(Icons.store_outlined),
                  label: const Text('Seguir comprando'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
