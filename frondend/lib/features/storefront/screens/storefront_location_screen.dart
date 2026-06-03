import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/storefront_map_view.dart';

class StorefrontLocationScreen extends StatelessWidget {
  final String slug;

  const StorefrontLocationScreen({super.key, required this.slug});

  Future<void> _openUrl(String url) async {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 1024;
    final horizontalPadding = isDesktop ? 28.0 : 16.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Ubicacion de la tienda'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            18,
            horizontalPadding,
            28,
          ),
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
                    color: const Color(0xFF0F172A).withValues(alpha: 0.16),
                    blurRadius: 24,
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
                      storefrontLocationTitle,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Encuentranos facil y llega directo a la tienda.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      height: 1.06,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Mapa interactivo, direccion exacta y acceso rapido por llamada o WhatsApp.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.78),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: isDesktop ? 420 : 300,
              child: StorefrontMapView(
                height: isDesktop ? 420 : 300,
                borderRadius: BorderRadius.circular(24),
                onOpenExternal: StorefrontMapView.openStoreMap,
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
                    subtitle: storefrontAddress,
                    actionLabel: 'Ver mapa',
                    onTap: StorefrontMapView.openStoreMap,
                  ),
                  _ContactTile(
                    icon: Icons.phone_outlined,
                    title: 'Telefono',
                    subtitle: storefrontPhone,
                    actionLabel: 'Llamar',
                    onTap: () => _openUrl('tel:$storefrontPhone'),
                  ),
                  _ContactTile(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: 'WhatsApp',
                    subtitle: storefrontWhatsapp,
                    actionLabel: 'Escribir',
                    onTap: () => _openUrl(
                      'https://wa.me/1$storefrontWhatsapp?text=${Uri.encodeComponent('Hola FULLTECH SRL, quiero llegar a la tienda.')}',
                    ),
                  ),
                  _ContactTile(
                    icon: Icons.mail_outline_rounded,
                    title: 'Correo',
                    subtitle: storefrontEmail,
                    actionLabel: 'Enviar',
                    onTap: () => _openUrl('mailto:$storefrontEmail'),
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
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () =>
                                  Navigator.pushNamed(context, '/tienda/$slug'),
                              icon: const Icon(Icons.storefront_rounded),
                              label: const Text('Ir a la tienda'),
                            ),
                            FilledButton.icon(
                              onPressed: StorefrontMapView.openStoreMap,
                              icon: const Icon(Icons.near_me_rounded),
                              label: const Text('Como llegar'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
