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
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isDesktop = screenWidth >= 1024;
    final horizontalPadding = isDesktop ? 28.0 : 14.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Ubicacion de la tienda',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            14,
            horizontalPadding,
            22,
          ),
          children: [
            _StoreImageCard(isDesktop: isDesktop),
            const SizedBox(height: 14),
            SizedBox(
              height: isDesktop ? 410 : 280,
              child: StorefrontMapView(
                height: isDesktop ? 410 : 280,
                borderRadius: BorderRadius.circular(22),
                onOpenExternal: StorefrontMapView.openStoreMap,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFE7EDF5)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                    blurRadius: 14,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _ContactTile(
                    icon: Icons.location_on_outlined,
                    title: 'Direccion',
                    subtitle: storefrontAddress,
                    actionLabel: 'Mapa',
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
                    icon: Icons.storefront_outlined,
                    title: 'Tienda online',
                    subtitle: 'Explora productos y ofertas',
                    actionLabel: 'Entrar',
                    onTap: () => Navigator.pushNamed(context, '/tienda/$slug'),
                    showDivider: false,
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

class _StoreImageCard extends StatelessWidget {
  final bool isDesktop;

  const _StoreImageCard({required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE7EDF5)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Container(
                width: double.infinity,
                color: const Color(0xFFF8FAFC),
                child: AspectRatio(
                  aspectRatio: isDesktop ? 16 / 7 : 16 / 10,
                  child: Image.asset(
                    'assets/logo_principal.jpeg',
                    fit: BoxFit.contain,
                    alignment: Alignment.center,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              storefrontLocationTitle,
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              storefrontAddress,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.35,
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
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F7FB),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: const Color(0xFF0F172A), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: onTap,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              child: Text(
                actionLabel,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        if (showDivider)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
      ],
    );
  }
}
