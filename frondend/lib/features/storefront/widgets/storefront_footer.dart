import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'storefront_map_view.dart';

class StorefrontFooter extends StatelessWidget {
  final String slug;
  final Color primaryColor;

  const StorefrontFooter({
    super.key,
    required this.slug,
    this.primaryColor = const Color(0xFF0F172A),
  });

  static const String _instagramUrl =
      'https://www.instagram.com/fulltech_srl?igsh=Z2V5NWY2MDJzNmdh';
  static const String _facebookUrl = 'https://www.facebook.com/fulltechs/';

  Future<void> _openUrl(String url) async {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 1024;
    final isTablet = width >= 700;
    final sidePadding = width >= 1320
        ? ((width - 1240) / 2).clamp(18.0, 9999.0)
        : isTablet
        ? 20.0
        : 14.0;

    return Container(
      margin: const EdgeInsets.only(top: 26),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF07192B), Color(0xFF0C243D), Color(0xFF11304F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              sidePadding,
              22,
              sidePadding,
              isDesktop ? 18 : 14,
            ),
            child: isDesktop
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 4,
                        child: _BrandColumn(primaryColor: primaryColor),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        flex: 5,
                        child: _ContactColumn(openUrl: _openUrl),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        flex: 5,
                        child: _LocationColumn(slug: slug, openUrl: _openUrl),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _BrandColumn(primaryColor: primaryColor),
                      const SizedBox(height: 18),
                      _LocationColumn(slug: slug, openUrl: _openUrl),
                      const SizedBox(height: 18),
                      _ContactColumn(openUrl: _openUrl),
                    ],
                  ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(
              sidePadding,
              12,
              sidePadding,
              MediaQuery.viewPaddingOf(context).bottom + 12,
            ),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
              ),
            ),
            child: isDesktop
                ? Row(
                    children: [
                      const _CopyrightText(),
                      const Spacer(),
                      _PoliciesRow(slug: slug),
                    ],
                  )
                : Column(
                    children: [
                      _PoliciesRow(slug: slug),
                      const SizedBox(height: 8),
                      const _CopyrightText(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _BrandColumn extends StatelessWidget {
  final Color primaryColor;

  const _BrandColumn({required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Logo real de FULLTECH
        Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/logo_principal_small.png',
                width: 36,
                height: 36,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'F',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'FULLTECH SRL',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const Text(
          'Tecnologia, instalacion y soporte en un solo lugar.',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            height: 1.08,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Compra online, contacta por WhatsApp y visita nuestra tienda con una ruta clara y rapida.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.72),
            fontSize: 13,
            height: 1.55,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: const [
            _ServiceChip(label: 'Seguridad'),
            _ServiceChip(label: 'Camaras'),
            _ServiceChip(label: 'Motores'),
            _ServiceChip(label: 'Tecnologia'),
          ],
        ),
      ],
    );
  }
}

class _ContactColumn extends StatelessWidget {
  final Future<void> Function(String url) openUrl;

  const _ContactColumn({required this.openUrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Contacto',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.92),
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _ContactCard(
              icon: Icons.call_rounded,
              title: 'Tel',
              value: storefrontPhone,
              color: const Color(0xFF3B82F6),
              onTap: () => openUrl('tel:+1$storefrontPhone'),
            ),
            _ContactCard(
              icon: Icons.email_rounded,
              title: 'Correo',
              value: storefrontEmail,
              color: const Color(0xFFF97316),
              onTap: () => openUrl('mailto:$storefrontEmail'),
            ),
            _ContactCard(
              icon: Icons.location_on_rounded,
              title: 'Ubicacion',
              value: 'Ver mapa',
              color: const Color(0xFFEF4444),
              onTap: StorefrontMapView.openStoreMap,
            ),
            _ContactCard(
              icon: Icons.camera_alt_rounded,
              title: 'Instagram',
              value: '@$storefrontInstagramHandle',
              color: const Color(0xFFE4405F),
              onTap: () => openUrl(StorefrontFooter._instagramUrl),
            ),
            _ContactCard(
              icon: Icons.thumb_up_alt_rounded,
              title: 'Facebook',
              value: storefrontFacebookLabel,
              color: const Color(0xFF1877F2),
              onTap: () => openUrl(StorefrontFooter._facebookUrl),
            ),
          ],
        ),
      ],
    );
  }
}

class _LocationColumn extends StatelessWidget {
  final String slug;
  final Future<void> Function(String url) openUrl;

  const _LocationColumn({required this.slug, required this.openUrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ubicacion',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.92),
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 190,
          child: StorefrontMapView(
            height: 190,
            compact: true,
            borderRadius: BorderRadius.circular(20),
            onOpenExternal: StorefrontMapView.openStoreMap,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          storefrontAddress,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.76),
            fontSize: 12.5,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            FilledButton.icon(
              onPressed: () =>
                  Navigator.pushNamed(context, '/tienda/$slug/ubicacion'),
              icon: const Icon(Icons.map_rounded),
              label: const Text('Ver ubicacion'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF0F172A),
              ),
            ),
            OutlinedButton.icon(
              onPressed: StorefrontMapView.openStoreMap,
              icon: const Icon(Icons.near_me_rounded),
              label: const Text('Ir alla'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ContactCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;
  final VoidCallback onTap;

  const _ContactCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 164),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.60),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
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
    );
  }
}

class _ServiceChip extends StatelessWidget {
  final String label;

  const _ServiceChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 0.6,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.82),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PoliciesRow extends StatelessWidget {
  final String slug;

  const _PoliciesRow({required this.slug});

  @override
  Widget build(BuildContext context) {
    final policies = [
      ('Envio', '/tienda/$slug/envios'),
      ('Garantia', '/tienda/$slug/garantia'),
      ('Devoluciones', '/tienda/$slug/devoluciones'),
    ];

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      alignment: WrapAlignment.center,
      children: policies
          .map((policy) => _PolicyLink(label: policy.$1, route: policy.$2))
          .toList(),
    );
  }
}

class _PolicyLink extends StatelessWidget {
  final String label;
  final String route;

  const _PolicyLink({required this.label, required this.route});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, route),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.52),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _CopyrightText extends StatelessWidget {
  const _CopyrightText();

  @override
  Widget build(BuildContext context) {
    return Text(
      '© ${DateTime.now().year} FULLTECH SRL',
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.38),
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
