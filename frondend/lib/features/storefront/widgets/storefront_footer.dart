import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class StorefrontFooter extends StatelessWidget {
  final Map<String, dynamic> config;
  final Color primaryColor;
  final Color secondaryColor;

  const StorefrontFooter({
    super.key,
    required this.config,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final whatsapp = config['whatsapp_numero'] ?? '';
    final direccion = config['direccion'];
    final horario = config['horario'];
    final telefono = config['telefono_contacto'] ?? config['telefono'];
    final email = config['email'];
    final facebook = config['facebook_url'];
    final instagram = config['instagram_url'];
    final nombreTienda = config['nombre_tienda'] ?? 'FULLTECH';

    return Container(
      margin: const EdgeInsets.only(top: 24),
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          32,
          24,
          MediaQuery.of(context).padding.bottom + 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo y nombre
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: config['logo_url'] != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            config['logo_url'],
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.store_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.store_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                ),
                const SizedBox(width: 12),
                Text(
                  nombreTienda,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(color: Colors.white24, height: 1),
            const SizedBox(height: 20),

            // Información de contacto
            if (direccion != null)
              _FooterInfoRow(icon: Icons.location_on_outlined, text: direccion),
            if (horario != null)
              _FooterInfoRow(icon: Icons.access_time_rounded, text: horario),
            if (telefono != null)
              _FooterInfoRow(
                icon: Icons.phone_outlined,
                text: telefono,
                onTap: () => launchUrl(Uri.parse('tel:$telefono')),
              ),
            if (email != null)
              _FooterInfoRow(
                icon: Icons.email_outlined,
                text: email,
                onTap: () => launchUrl(Uri.parse('mailto:$email')),
              ),

            const SizedBox(height: 20),

            // Redes sociales
            Row(
              children: [
                if (whatsapp.isNotEmpty)
                  _SocialButton(
                    icon: Icons.chat_rounded,
                    color: const Color(0xFF25D366),
                    onTap: () {
                      final num = whatsapp.toString().replaceAll(
                        RegExp(r'[^\d]'),
                        '',
                      );
                      launchUrl(Uri.parse('https://wa.me/$num'));
                    },
                  ),
                if (facebook != null) ...[
                  const SizedBox(width: 12),
                  _SocialButton(
                    icon: Icons.facebook_rounded,
                    color: const Color(0xFF1877F2),
                    onTap: () => launchUrl(Uri.parse(facebook)),
                  ),
                ],
                if (instagram != null) ...[
                  const SizedBox(width: 12),
                  _SocialButton(
                    icon: Icons.camera_alt_rounded,
                    color: const Color(0xFFE4405F),
                    onTap: () => launchUrl(Uri.parse(instagram)),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 24),

            // Métodos de pago
            const Text(
              'Métodos de pago',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _PaymentMethodChip(
                  icon: Icons.account_balance_rounded,
                  label: 'Transferencia',
                ),
                const SizedBox(width: 8),
                _PaymentMethodChip(
                  icon: Icons.credit_card_rounded,
                  label: 'Tarjeta',
                ),
                const SizedBox(width: 8),
                _PaymentMethodChip(icon: Icons.chat_rounded, label: 'WhatsApp'),
              ],
            ),

            const SizedBox(height: 24),

            // Copyright
            Center(
              child: Text(
                '© ${DateTime.now().year} $nombreTienda. Todos los derechos reservados.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FooterInfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback? onTap;

  const _FooterInfoRow({required this.icon, required this.text, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: Colors.white.withValues(alpha: 0.6)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 13,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SocialButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          child: Icon(icon, color: color, size: 22),
        ),
      ),
    );
  }
}

class _PaymentMethodChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _PaymentMethodChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white.withValues(alpha: 0.8)),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
