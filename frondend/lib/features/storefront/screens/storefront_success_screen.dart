import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class StorefrontSuccessScreen extends StatefulWidget {
  final String slug;
  final Map<String, dynamic>? data;
  const StorefrontSuccessScreen({super.key, required this.slug, this.data});

  @override
  State<StorefrontSuccessScreen> createState() => _StorefrontSuccessScreenState();
}

class _StorefrontSuccessScreenState extends State<StorefrontSuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _scaleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.elasticOut),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pedido = widget.data;
    final pedidoId = pedido?['pedido_id'] ?? pedido?['id'] ?? '';
    final whatsapp = pedido?['whatsapp_numero'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: AnimatedBuilder(
              animation: _animController,
              builder: (context, child) => Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animación de check
                  Transform.scale(
                    scale: _scaleAnim.value,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF10B981), Color(0xFF34D399)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Texto con fade
                  FadeTransition(
                    opacity: _fadeAnim,
                    child: Column(
                      children: [
                        const Text(
                          '¡Pedido recibido!',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Gracias por tu compra. Te contactaremos pronto para coordinar la entrega.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: const Color(0xFF6B7280),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ID del pedido
                        if (pedidoId.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.receipt_outlined, size: 18, color: Color(0xFF6B7280)),
                                const SizedBox(width: 8),
                                Text(
                                  'Pedido #$pedidoId',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 32),

                        // Botón WhatsApp
                        if (whatsapp.isNotEmpty)
                          FilledButton.icon(
                            onPressed: () {
                              final num = whatsapp.replaceAll(RegExp(r'[^\d]'), '');
                              final msg = 'Hola, quiero dar seguimiento a mi pedido #$pedidoId';
                              launchUrl(Uri.parse('https://wa.me/$num?text=${Uri.encodeComponent(msg)}'));
                            },
                            icon: const Icon(Icons.chat_rounded),
                            label: const Text('Contactar por WhatsApp'),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF25D366),
                              minimumSize: const Size(260, 52),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ),

                        const SizedBox(height: 16),

                        // Volver a tienda
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              '/tienda/${widget.slug}',
                              (route) => false,
                            );
                          },
                          icon: const Icon(Icons.store_outlined),
                          label: const Text('Seguir comprando'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(260, 52),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
