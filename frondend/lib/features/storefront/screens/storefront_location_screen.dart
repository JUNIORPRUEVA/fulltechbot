import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class StorefrontLocationScreen extends StatelessWidget {
  final String slug;

  const StorefrontLocationScreen({super.key, required this.slug});

  static const String mapUrl = 'https://maps.app.goo.gl/8ogwPYRF5gvkNEr3A';
  static const String address = 'Higuey centro, Beller 9 local 2';
  static const String whatsapp = '8494314070';
  static const String phone = '8295319442';
  static const String email = 'fulltechsd@gmail.com';

  Future<void> _openUrl(String url) async {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  Future<void> _openCall() => _openUrl('tel:$phone');
  Future<void> _openWhatsapp() => _openUrl(
    'https://wa.me/1$whatsapp?text=${Uri.encodeComponent('Hola FULLTECH SRL, quiero llegar a la tienda.')}',
  );
  Future<void> _openEmail() => _openUrl('mailto:$email');
  Future<void> _openMap() => _openUrl(mapUrl);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Ubicacion de la tienda'),
        centerTitle: false,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF07192B), Color(0xFF103354)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.18),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'FULLTECH SRL',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Visitanos en nuestra tienda fisica',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        height: 1.08,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Encuentra soporte, productos, instalacion y asesoria en una sola visita.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.78),
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _HeroLocationRow(
                      icon: Icons.location_on_rounded,
                      title: 'Direccion',
                      value: address,
                    ),
                    const SizedBox(height: 12),
                    _HeroLocationRow(
                      icon: Icons.schedule_rounded,
                      title: 'Atencion',
                      value:
                          'Contactanos por WhatsApp o llamada para coordinar tu visita.',
                    ),
                    const SizedBox(height: 22),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        FilledButton.icon(
                          onPressed: _openMap,
                          icon: const Icon(Icons.near_me_rounded),
                          label: const Text('Como llegar'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF0F172A),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 15,
                            ),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: _openWhatsapp,
                          icon: const Icon(Icons.chat_rounded),
                          label: const Text('WhatsApp'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.25),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE7EDF5)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _ContactTile(
                      icon: Icons.location_on_outlined,
                      title: 'Ubicacion exacta',
                      subtitle: address,
                      actionLabel: 'Ver mapa',
                      onTap: _openMap,
                    ),
                    _ContactTile(
                      icon: Icons.phone_outlined,
                      title: 'Telefono',
                      subtitle: phone,
                      actionLabel: 'Llamar',
                      onTap: _openCall,
                    ),
                    _ContactTile(
                      icon: Icons.chat_bubble_outline_rounded,
                      title: 'WhatsApp',
                      subtitle: whatsapp,
                      actionLabel: 'Escribir',
                      onTap: _openWhatsapp,
                    ),
                    _ContactTile(
                      icon: Icons.mail_outline_rounded,
                      title: 'Correo',
                      subtitle: email,
                      actionLabel: 'Enviar',
                      onTap: _openEmail,
                      showDivider: false,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F7FF),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFD9E9FF)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.store_mall_directory_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ve directo a la tienda',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Cuando termines de revisar la ubicacion, vuelve a explorar productos y ofertas de FULLTECH.',
                            style: TextStyle(
                              color: Color(0xFF4B5563),
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  Navigator.pushNamed(context, '/tienda/$slug'),
                              icon: const Icon(Icons.storefront_rounded),
                              label: const Text('Ir a la tienda'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (isDesktop) const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroLocationRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _HeroLocationRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.11),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.74),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ContactTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onTap;
  final bool showDivider;

  const _ContactTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onTap,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F7FB),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: const Color(0xFF0F172A)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontWeight: FontWeight.w800,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            TextButton(onPressed: onTap, child: Text(actionLabel)),
          ],
        ),
        if (showDivider)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1),
          ),
      ],
    );
  }
}
