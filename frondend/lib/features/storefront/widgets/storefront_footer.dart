import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Footer premium y compacto de FULLTECH SRL.
/// Diseño elegante, moderno, tecnológico y profesional.
/// Sin tarjetas internas pesadas, con estructura limpia y bien jerarquizada.
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
    final whatsapp = config['whatsapp_numero']?.toString() ?? '';
    final direccion =
        config['direccion']?.toString().trim().isNotEmpty == true
            ? config['direccion'].toString().trim()
            : 'Higüey centro, Beller 9 local 2';
    final telefono =
        (config['telefono_contacto'] ?? config['telefono'])?.toString().trim();
    final email = config['email']?.toString().trim();
    final horario = config['horario']?.toString().trim();

    const nombreTienda = 'FULLTECH SRL';
    const businessLines = <String>[
      'Seguridad',
      'Cámaras',
      'Motores',
      'Software',
      'Computadoras',
      'Tecnología',
    ];

    return Container(
      margin: const EdgeInsets.only(top: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF061726),
            const Color(0xFF0A1E33),
            const Color(0xFF0D2440),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          24,
          20,
          MediaQuery.of(context).padding.bottom + 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // === NOMBRE + DESCRIPCIÓN ===
            const Text(
              nombreTienda,
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Soluciones tecnológicas para hogares, empresas y proyectos.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.65),
                fontSize: 12.5,
                height: 1.4,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 18),

            // === INFORMACIÓN COMPACTA (iconos pequeños) ===
            _InfoRow(
              icon: Icons.location_on_outlined,
              text: direccion,
            ),
            if (telefono != null && telefono.isNotEmpty)
              _InfoRow(
                icon: Icons.phone_outlined,
                text: telefono,
                onTap: () => launchUrl(Uri.parse('tel:$telefono')),
              ),
            if (whatsapp.isNotEmpty)
              _InfoRow(
                icon: Icons.chat_outlined,
                text: whatsapp,
                onTap: () {
                  final num = whatsapp.replaceAll(RegExp(r'[^\d]'), '');
                  launchUrl(Uri.parse('https://wa.me/$num'));
                },
              ),
            if (email != null && email.isNotEmpty)
              _InfoRow(
                icon: Icons.email_outlined,
                text: email,
                onTap: () => launchUrl(Uri.parse('mailto:$email')),
              ),
            if (horario != null && horario.isNotEmpty)
              _InfoRow(
                icon: Icons.access_time_rounded,
                text: horario,
              ),

            const SizedBox(height: 16),

            // === CHIPS DE SERVICIOS (finos, compactos) ===
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: businessLines
                  .map((item) => _ServiceChip(label: item))
                  .toList(),
            ),

            const SizedBox(height: 18),

            // === LÍNEA DIVISORIA FINA ===
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

            // === COPYRIGHT ===
            Center(
              child: Text(
                '© ${DateTime.now().year} $nombreTienda. Todos los derechos reservados.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.40),
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  height: 1.3,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fila de información con icono pequeño y texto.
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback? onTap;

  const _InfoRow({
    required this.icon,
    required this.text,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 14,
                color: Colors.white.withValues(alpha: 0.75),
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                text,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.80),
                  fontSize: 12.5,
                  height: 1.3,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Chip fino y elegante para servicios.
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
          fontWeight: FontWeight.w500,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
