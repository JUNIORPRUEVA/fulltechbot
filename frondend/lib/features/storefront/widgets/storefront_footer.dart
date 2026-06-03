import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Footer premium, compacto y profesional para FULLTECH SRL.
///
/// Diseño:
/// - Desktop: 3 columnas (Marca + Contacto Grid + Ubicación/Mapa)
/// - Móvil: 1 columna con políticas en copyright bar
/// - Contacto en grid responsive de 2 columnas
/// - Políticas reducidas: Envío · Garantía · Devoluciones
/// - Mapa real de OpenStreetMap con clic para abrir Google Maps
/// - Copyright © 2026 FULLTECH SRL
class StorefrontFooter extends StatelessWidget {
  final String slug;
  final Color primaryColor;

  const StorefrontFooter({
    super.key,
    required this.slug,
    this.primaryColor = const Color(0xFF0F172A),
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 1024;
    final isTablet = MediaQuery.sizeOf(context).width >= 600;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final sidePadding = screenWidth >= 1320
        ? ((screenWidth - 1240) / 2).clamp(18.0, 9999.0)
        : screenWidth >= 700
        ? 20.0
        : 14.0;

    return Container(
      color: const Color(0xFF0F172A),
      child: Column(
        children: [
          // ==========================================
          // CUERPO DEL FOOTER
          // ==========================================
          Padding(
            padding: EdgeInsets.fromLTRB(sidePadding, 28, sidePadding, 20),
            child: isDesktop
                ? _DesktopLayout(slug: slug, primaryColor: primaryColor)
                : _MobileLayout(
                    slug: slug,
                    primaryColor: primaryColor,
                    isTablet: isTablet,
                  ),
          ),

          // ==========================================
          // DIVISOR + COPYRIGHT + POLÍTICAS
          // ==========================================
          Container(
            padding: EdgeInsets.fromLTRB(sidePadding, 14, sidePadding, 14),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Colors.white.withValues(alpha: 0.08),
                ),
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
                      const SizedBox(height: 10),
                      const _CopyrightText(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// LAYOUT DESKTOP: 3 COLUMNAS
// ==========================================
class _DesktopLayout extends StatelessWidget {
  final String slug;
  final Color primaryColor;

  const _DesktopLayout({
    required this.slug,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Columna 1: Marca
          const Expanded(child: _BrandColumn()),
          const SizedBox(width: 40),

          // Columna 2: Contacto en grid
          const Expanded(child: _ContactGrid()),
          const SizedBox(width: 40),

          // Columna 3: Ubicación / Mapa
          Expanded(child: _LocationColumn(slug: slug)),
        ],
      ),
    );
  }
}

// ==========================================
// LAYOUT MÓVIL: 1 COLUMNA
// ==========================================
class _MobileLayout extends StatelessWidget {
  final String slug;
  final Color primaryColor;
  final bool isTablet;

  const _MobileLayout({
    required this.slug,
    required this.primaryColor,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _BrandColumn(),
        const SizedBox(height: 24),
        const _ContactGrid(),
        const SizedBox(height: 24),
        _LocationColumn(slug: slug),
      ],
    );
  }
}

// ==========================================
// COLUMNA DE MARCA
// ==========================================
class _BrandColumn extends StatelessWidget {
  const _BrandColumn();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Logo / Nombre
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
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
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'FULLTECH',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'Tecnología, innovación y confianza.\nTu tienda online de confianza.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 13,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 14),
        // Redes sociales
        Row(
          children: [
            _SocialIcon(
              icon: Icons.facebook_rounded,
              url: 'https://www.facebook.com/fulltechs/',
              color: const Color(0xFF1877F2),
            ),
            const SizedBox(width: 10),
            _SocialIcon(
              icon: Icons.camera_alt_rounded,
              url:
                  'https://www.instagram.com/fulltech_srl?igsh=Z2V5NWY2MDJzNmdh',
              color: const Color(0xFFE4405F),
            ),
          ],
        ),
      ],
    );
  }
}

// ==========================================
// CONTACTO EN GRID RESPONSIVE
// ==========================================
class _ContactGrid extends StatelessWidget {
  const _ContactGrid();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Contacto',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _ContactItem(
              icon: Icons.chat_rounded,
              label: 'WhatsApp',
              value: '(849) 431-4070',
              url: 'https://wa.me/18494314070',
              iconColor: const Color(0xFF25D366),
            ),
            _ContactItem(
              icon: Icons.phone_rounded,
              label: 'Teléfono',
              value: '(829) 531-9442',
              url: 'tel:+18295319442',
              iconColor: const Color(0xFF3B82F6),
            ),
            _ContactItem(
              icon: Icons.email_rounded,
              label: 'Email',
              value: 'fulltechsd@gmail.com',
              url: 'mailto:fulltechsd@gmail.com',
              iconColor: const Color(0xFFEF4444),
            ),
            _ContactItem(
              icon: Icons.facebook_rounded,
              label: 'Facebook',
              value: 'Fulltech SRL',
              url: 'https://www.facebook.com/fulltechs/',
              iconColor: const Color(0xFF1877F2),
            ),
            _ContactItem(
              icon: Icons.camera_alt_rounded,
              label: 'Instagram',
              value: '@fulltech_srl',
              url:
                  'https://www.instagram.com/fulltech_srl?igsh=Z2V5NWY2MDJzNmdh',
              iconColor: const Color(0xFFE4405F),
            ),
          ],
        ),
      ],
    );
  }
}

// ==========================================
// ITEM DE CONTACTO COMPACTO
// ==========================================
class _ContactItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String url;
  final Color iconColor;

  const _ContactItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.url,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: () => launchUrl(Uri.parse(url)),
        borderRadius: BorderRadius.circular(10),
        splashColor: iconColor.withValues(alpha: 0.1),
        highlightColor: iconColor.withValues(alpha: 0.05),
        child: Container(
          constraints: const BoxConstraints(minWidth: 140),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.06),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// COLUMNA DE UBICACIÓN CON MAPA REAL
// ==========================================
class _LocationColumn extends StatelessWidget {
  final String slug;

  const _LocationColumn({required this.slug});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ubicación',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 12),
        // Mapa real de OpenStreetMap como imagen estática
        Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: () => launchUrl(
              Uri.parse(
                'https://www.google.com/maps/search/?api=1&query=FULLTECH+SRL+Santo+Domingo+Rep%C3%BAblica+Dominicana',
              ),
            ),
            borderRadius: BorderRadius.circular(12),
            splashColor: Colors.white.withValues(alpha: 0.08),
            highlightColor: Colors.white.withValues(alpha: 0.04),
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
                image: DecorationImage(
                  image: NetworkImage(
                    'https://tile.openstreetmap.org/static/18/-69.93,18.48,12/600x300.png',
                  ),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF0F172A).withValues(alpha: 0.3),
                      const Color(0xFF0F172A).withValues(alpha: 0.6),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        color: const Color(0xFFEF4444),
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Ver en Google Maps',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Santo Domingo, República Dominicana',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

// ==========================================
// ICONO DE RED SOCIAL
// ==========================================
class _SocialIcon extends StatelessWidget {
  final IconData icon;
  final String url;
  final Color color;

  const _SocialIcon({
    required this.icon,
    required this.url,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: () => launchUrl(Uri.parse(url)),
        borderRadius: BorderRadius.circular(10),
        splashColor: color.withValues(alpha: 0.15),
        highlightColor: color.withValues(alpha: 0.08),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: color.withValues(alpha: 0.2),
            ),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}

// ==========================================
// POLÍTICAS REDUCIDAS
// ==========================================
class _PoliciesRow extends StatelessWidget {
  final String slug;

  const _PoliciesRow({required this.slug});

  @override
  Widget build(BuildContext context) {
    final policies = [
      ('Envío', '/tienda/$slug/envios'),
      ('Garantía', '/tienda/$slug/garantia'),
      ('Devoluciones', '/tienda/$slug/devoluciones'),
    ];

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      alignment: WrapAlignment.center,
      children: policies.map((policy) {
        return _PolicyLink(label: policy.$1, route: policy.$2);
      }).toList(),
    );
  }
}

class _PolicyLink extends StatelessWidget {
  final String label;
  final String route;

  const _PolicyLink({
    required this.label,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, route),
        borderRadius: BorderRadius.circular(6),
        splashColor: Colors.white.withValues(alpha: 0.06),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// COPYRIGHT
// ==========================================
class _CopyrightText extends StatelessWidget {
  const _CopyrightText();

  @override
  Widget build(BuildContext context) {
    return Text(
      '© 2026 FULLTECH SRL',
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.35),
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
