import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

// ==========================================
// COLORES COMPARTIDOS DEL FOOTER
// ==========================================
class _FooterColors {
  static const Color bg = Color(0xFF071B2E);
  static const Color bgLighter = Color(0xFF0B223A);
  static const Color textWhite = Colors.white;
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textDim = Color(0xFF64748B);
  static const Color border = Color(0xFF1E3A5F);
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color whatsappGreen = Color(0xFF25D366);
}

/// Footer premium, compacto y profesional para FULLTECH SRL.
/// Diseño oscuro elegante con mini mapa integrado, contactos rápidos
/// y enlaces de políticas. Optimizado para conversión.
class StorefrontFooter extends StatelessWidget {
  final Map<String, dynamic> config;
  final Color primaryColor;
  final Color secondaryColor;
  final String slug;

  const StorefrontFooter({
    super.key,
    required this.config,
    required this.primaryColor,
    required this.secondaryColor,
    required this.slug,
  });

  // ==========================================
  // CONSTANTES DE NEGOCIO
  // ==========================================
  static const String _companyName = 'FULLTECH SRL';
  static const String _address = 'Higüey centro, Beller 9 local 2';
  static const String _mapQuery =
      'https://www.google.com/maps/search/?api=1&query=Hig%C3%BCey%20centro%20Beller%209%20local%202';
  static const String _whatsAppNumber = '8494314070';
  static const String _phoneNumber = '8295319442';
  static const String _email = 'fulltechsd@gmail.com';
  static const String _instagramHandle = 'fulltechsrl';
  static const String _facebookLabel = 'fulltech, srl';
  static const String _instagramUrl = 'https://instagram.com/fulltechsrl';
  static const String _facebookUrl =
      'https://www.facebook.com/search/top/?q=fulltech%20srl';

  Future<void> _openUrl(String url) async {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 900;
    final bottomPadding = MediaQuery.viewPaddingOf(context).bottom;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_FooterColors.bg, _FooterColors.bgLighter],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          // ==========================================
          // CONTENIDO PRINCIPAL DEL FOOTER
          // ==========================================
          Padding(
            padding: EdgeInsets.fromLTRB(
              isDesktop ? 48 : 20,
              isDesktop ? 40 : 28,
              isDesktop ? 48 : 20,
              isDesktop ? 32 : 24,
            ),
            child: isDesktop
                ? _buildDesktopLayout(context)
                : _buildMobileLayout(context),
          ),

          // ==========================================
          // BARRA INFERIOR DE COPYRIGHT
          // ==========================================
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              isDesktop ? 48 : 20,
              14,
              isDesktop ? 48 : 20,
              bottomPadding > 0 ? bottomPadding + 14 : 14,
            ),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: _FooterColors.border.withValues(alpha: 0.5),
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '© ${DateTime.now().year} $_companyName',
                  style: TextStyle(
                    color: _FooterColors.textDim,
                    fontSize: isDesktop ? 12 : 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (isDesktop)
                  Row(
                    children: [
                      _buildTrustBadge('Tienda física'),
                      const SizedBox(width: 12),
                      _buildTrustBadge('Garantía'),
                      const SizedBox(width: 12),
                      _buildTrustBadge('Instalación'),
                      const SizedBox(width: 12),
                      _buildTrustBadge('Soporte'),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // LAYOUT DESKTOP - 4 COLUMNAS
  // ==========================================
  Widget _buildDesktopLayout(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Col 1: Marca + mensaje + tags
          Expanded(
            flex: 3,
            child: _buildBrandColumn(context),
          ),
          const SizedBox(width: 40),

          // Col 2: Contacto rápido
          Expanded(
            flex: 2,
            child: _buildContactColumn(context),
          ),
          const SizedBox(width: 40),

          // Col 3: Ubicación + mapa
          Expanded(
            flex: 3,
            child: _buildLocationColumn(context),
          ),
          const SizedBox(width: 40),

          // Col 4: Políticas
          Expanded(
            flex: 2,
            child: _buildPoliciesColumn(context),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // LAYOUT MÓVIL - UNA SOLA COLUMNA
  // ==========================================
  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Marca + mensaje
        _buildBrandColumn(context),
        const SizedBox(height: 24),

        // Mini mapa + ubicación
        _buildLocationColumn(context),
        const SizedBox(height: 24),

        // Contacto rápido
        _buildContactColumn(context),
        const SizedBox(height: 24),

        // Políticas
        _buildPoliciesColumn(context),
      ],
    );
  }

  // ==========================================
  // COLUMNA 1: MARCA + MENSAJE + TAGS
  // ==========================================
  Widget _buildBrandColumn(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Logo / nombre
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    _FooterColors.accentBlue,
                    Color(0xFF60A5FA),
                  ],
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
            const SizedBox(width: 10),
            const Text(
              _companyName,
              style: TextStyle(
                color: _FooterColors.textWhite,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Mensaje principal corto y vendedor
        const Text(
          'Tecnología, seguridad e instalación profesional.',
          style: TextStyle(
            color: _FooterColors.textWhite,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 8),

        // Subtítulo
        Text(
          'Compra tus equipos, solicita soporte o visítanos en nuestra tienda física en Higüey.',
          style: TextStyle(
            color: _FooterColors.textMuted,
            fontSize: 13,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 16),

        // Tags de servicios (compactos)
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: const [
            _ServiceTag(label: 'Seguridad'),
            _ServiceTag(label: 'Cámaras'),
            _ServiceTag(label: 'Motores'),
            _ServiceTag(label: 'Software'),
            _ServiceTag(label: 'Computadoras'),
            _ServiceTag(label: 'Tecnología'),
          ],
        ),
      ],
    );
  }

  // ==========================================
  // COLUMNA 2: CONTACTO RÁPIDO
  // ==========================================
  Widget _buildContactColumn(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Contacto'),
        const SizedBox(height: 14),

        _ContactItem(
          icon: Icons.chat_rounded,
          iconColor: _FooterColors.whatsappGreen,
          label: 'WhatsApp',
          value: '849-431-4070',
          onTap: () => _openUrl(
            'https://wa.me/18494314070?text=${Uri.encodeComponent('Hola FULLTECH SRL, quiero información.')}',
          ),
        ),
        const SizedBox(height: 10),

        _ContactItem(
          icon: Icons.call_rounded,
          iconColor: _FooterColors.accentBlue,
          label: 'Teléfono',
          value: '829-531-9442',
          onTap: () => _openUrl('tel:18295319442'),
        ),
        const SizedBox(height: 10),

        _ContactItem(
          icon: Icons.email_rounded,
          iconColor: Color(0xFFF97316),
          label: 'Email',
          value: _email,
          onTap: () => _openUrl('mailto:$_email'),
        ),
        const SizedBox(height: 10),

        _ContactItem(
          icon: Icons.camera_alt_rounded,
          iconColor: Color(0xFFE1306C),
          label: 'Instagram',
          value: '@$_instagramHandle',
          onTap: () => _openUrl(_instagramUrl),
        ),
        const SizedBox(height: 10),

        _ContactItem(
          icon: Icons.thumb_up_alt_rounded,
          iconColor: Color(0xFF1877F2),
          label: 'Facebook',
          value: _facebookLabel,
          onTap: () => _openUrl(_facebookUrl),
        ),
      ],
    );
  }

  // ==========================================
  // COLUMNA 3: UBICACIÓN + MINI MAPA
  // ==========================================
  Widget _buildLocationColumn(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Ubicación'),
        const SizedBox(height: 14),

        // Dirección
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.location_on_rounded,
              size: 16,
              color: _FooterColors.accentBlue,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                _address,
                style: TextStyle(
                  color: _FooterColors.textMuted,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Mini mapa interactivo
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _openUrl(_mapQuery),
            borderRadius: BorderRadius.circular(10),
            child: Ink(
              height: 130,
              decoration: BoxDecoration(
                color: const Color(0xFF0D2A45),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _FooterColors.border.withValues(alpha: 0.6),
                ),
              ),
              child: Stack(
                children: [
                  // Grid decorativo simulando mapa
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _MapGridPainter(
                        gridColor: _FooterColors.border.withValues(alpha: 0.2),
                        accentColor: _FooterColors.accentBlue.withValues(alpha: 0.15),
                      ),
                    ),
                  ),
                  // Pin de ubicación central
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: _FooterColors.accentBlue.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.location_on_rounded,
                            size: 24,
                            color: _FooterColors.accentBlue,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF071B2E).withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: _FooterColors.border.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            'Beller 9, Higüey',
                            style: TextStyle(
                              color: _FooterColors.textMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Badge "Abrir mapa"
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF071B2E).withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _FooterColors.border.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.open_in_new_rounded,
                            size: 10,
                            color: _FooterColors.accentBlue,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Ver mapa',
                            style: TextStyle(
                              color: _FooterColors.accentBlue,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Botón "Ir a la ubicación"
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _openUrl(_mapQuery),
            icon: const Icon(Icons.near_me_rounded, size: 16),
            label: const Text('Ir a la ubicación'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _FooterColors.accentBlue,
              side: BorderSide(
                color: _FooterColors.accentBlue.withValues(alpha: 0.4),
              ),
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // COLUMNA 4: POLÍTICAS
  // ==========================================
  Widget _buildPoliciesColumn(BuildContext context) {
    final policies = [
      _PolicyLink(
        label: 'Política de privacidad',
        route: '/tienda/$slug/politica-privacidad',
      ),
      _PolicyLink(
        label: 'Términos y condiciones',
        route: '/tienda/$slug/terminos',
      ),
      _PolicyLink(
        label: 'Política de garantía',
        route: '/tienda/$slug/garantia',
      ),
      _PolicyLink(
        label: 'Política de envío',
        route: '/tienda/$slug/envios',
      ),
      _PolicyLink(
        label: 'Devoluciones',
        route: '/tienda/$slug/devoluciones',
      ),
      _PolicyLink(
        label: 'Contacto',
        route: '/tienda/$slug/contacto',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Políticas'),
        const SizedBox(height: 14),
        ...policies.map((policy) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildPolicyLink(context, policy),
            )),
      ],
    );
  }

  Widget _buildPolicyLink(BuildContext context, _PolicyLink policy) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, policy.route);
      },
      child: Text(
        policy.label,
        style: TextStyle(
          color: _FooterColors.textMuted,
          fontSize: 13,
          fontWeight: FontWeight.w500,
          height: 1.3,
        ),
      ),
    );
  }

  // ==========================================
  // WIDGETS REUTILIZABLES
  // ==========================================

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: _FooterColors.textWhite,
        fontSize: 14,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildTrustBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _FooterColors.border.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: _FooterColors.textDim,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ==========================================
// MAPA GRID PAINTER - Decoración visual del mapa
// ==========================================
class _MapGridPainter extends CustomPainter {
  final Color gridColor;
  final Color accentColor;

  _MapGridPainter({
    required this.gridColor,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5;

    // Líneas verticales
    for (double x = 0; x < size.width; x += 24) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    // Líneas horizontales
    for (double y = 0; y < size.height; y += 24) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Círculo decorativo de radar
    final radarPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(center, 40, radarPaint);
    canvas.drawCircle(center, 28, radarPaint);
  }

  @override
  bool shouldRepaint(covariant _MapGridPainter oldDelegate) {
    return oldDelegate.gridColor != gridColor ||
        oldDelegate.accentColor != accentColor;
  }
}

// ==========================================
// CONTACT ITEM COMPACTO
// ==========================================
class _ContactItem extends StatelessWidget {

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _ContactItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 14, color: iconColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: _FooterColors.textDim,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      value,
                      style: const TextStyle(
                        color: _FooterColors.textWhite,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
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
// SERVICE TAG COMPACTO
// ==========================================
class _ServiceTag extends StatelessWidget {
  final String label;

  const _ServiceTag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _FooterColors.border.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: _FooterColors.border.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: _FooterColors.textMuted.withValues(alpha: 0.8),
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

// ==========================================
// POLICY LINK DATA
// ==========================================
class _PolicyLink {
  final String label;
  final String route;

  const _PolicyLink({
    required this.label,
    required this.route,
  });
}
