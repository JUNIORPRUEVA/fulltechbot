import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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

  static const String _address = 'Higuey centro, Beller 9 local 2';
  static const String _mapUrl = 'https://maps.app.goo.gl/8ogwPYRF5gvkNEr3A';
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
    final isTablet = width >= 640;

    return Container(
      margin: const EdgeInsets.only(top: 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF061726), Color(0xFF0B223A), Color(0xFF0E2A46)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 22,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          24,
          20,
          MediaQuery.of(context).padding.bottom + 18,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 14,
              runSpacing: 14,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isDesktop ? 360 : double.infinity,
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
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'FULLTECH SRL',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Tecnologia, instalacion y soporte en un solo lugar.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          height: 1.12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Contactanos rapido, visita la tienda fisica o abre la ubicacion exacta en Google Maps.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.72),
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  constraints: BoxConstraints(
                    maxWidth: isDesktop ? 360 : double.infinity,
                  ),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: secondaryColor.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ubicacion',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _address,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.76),
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          FilledButton.icon(
                            onPressed: () => Navigator.pushNamed(
                              context,
                              '/tienda/$slug/ubicacion',
                            ),
                            icon: const Icon(Icons.location_on_rounded),
                            label: const Text('Ver ubicacion'),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: primaryColor,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 13,
                              ),
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => _openUrl(_mapUrl),
                            icon: const Icon(Icons.near_me_rounded),
                            label: const Text('Ir alla'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.18),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _ContactPill(
                  icon: Icons.chat_rounded,
                  title: 'WhatsApp',
                  value: _whatsAppNumber,
                  onTap: () => _openUrl(
                    'https://wa.me/1$_whatsAppNumber?text=${Uri.encodeComponent('Hola FULLTECH SRL, quiero informacion.')}',
                  ),
                ),
                _ContactPill(
                  icon: Icons.call_rounded,
                  title: 'Tel',
                  value: _phoneNumber,
                  onTap: () => _openUrl('tel:$_phoneNumber'),
                ),
                _ContactPill(
                  icon: Icons.email_rounded,
                  title: 'Email',
                  value: _email,
                  onTap: () => _openUrl('mailto:$_email'),
                ),
                _ContactPill(
                  icon: Icons.camera_alt_rounded,
                  title: 'Instagram',
                  value: '@$_instagramHandle',
                  onTap: () => _openUrl(_instagramUrl),
                ),
                _ContactPill(
                  icon: Icons.thumb_up_alt_rounded,
                  title: 'Facebook',
                  value: _facebookLabel,
                  onTap: () => _openUrl(_facebookUrl),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              height: 1,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.0),
                    Colors.white.withValues(alpha: 0.12),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: const [
                _ServiceChip(label: 'Seguridad'),
                _ServiceChip(label: 'Camaras'),
                _ServiceChip(label: 'Motores'),
                _ServiceChip(label: 'Software'),
                _ServiceChip(label: 'Computadoras'),
                _ServiceChip(label: 'Tecnologia'),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              '© ${DateTime.now().year} FULLTECH SRL. Todos los derechos reservados.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.42),
                fontSize: isTablet ? 11.5 : 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactPill extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;

  const _ContactPill({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.66),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
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
          width: 0.5,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.82),
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
