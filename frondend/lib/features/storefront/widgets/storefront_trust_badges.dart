import 'package:flutter/material.dart';

class StorefrontTrustBadges extends StatelessWidget {
  final bool installationAvailable;

  const StorefrontTrustBadges({super.key, required this.installationAvailable});

  @override
  Widget build(BuildContext context) {
    final items = <({IconData icon, String title, String subtitle})>[
      (
        icon: Icons.verified_user_outlined,
        title: 'Compra con confianza',
        subtitle: 'Atención y seguimiento profesional.',
      ),
      (
        icon: Icons.support_agent_outlined,
        title: 'Soporte técnico',
        subtitle: 'Te ayudamos antes y después de la compra.',
      ),
      (
        icon: Icons.storefront_outlined,
        title: 'Retiro o coordinación',
        subtitle: 'Opción de tienda física y entrega acordada.',
      ),
      (
        icon: installationAvailable
            ? Icons.handyman_outlined
            : Icons.chat_bubble_outline_rounded,
        title: installationAvailable
            ? 'Instalación disponible'
            : 'Asesoría por WhatsApp',
        subtitle: installationAvailable
            ? 'Ideal para proyectos residenciales o comerciales.'
            : 'Confirma compatibilidad y disponibilidad con nosotros.',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Beneficios y confianza',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: items.map((item) {
            return SizedBox(
              width: 240,
              child: _TrustItem(
                icon: item.icon,
                title: item.title,
                subtitle: item.subtitle,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _TrustItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _TrustItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: const Color(0xFF2563EB)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(height: 1.4, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
