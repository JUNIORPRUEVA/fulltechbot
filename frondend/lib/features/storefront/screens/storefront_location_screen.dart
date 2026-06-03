import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Pantalla de ubicación de FULLTECH SRL.
/// Muestra mapa real de OpenStreetMap, dirección, contacto y horarios.
class StorefrontLocationScreen extends StatelessWidget {
  final String slug;

  const StorefrontLocationScreen({super.key, required this.slug});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 1024;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FA),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Ubicación',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              // ==========================================
              // MAPA REAL DE OpenStreetMap
              // ==========================================
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => launchUrl(
                    Uri.parse(
                      'https://www.google.com/maps/search/?api=1&query=FULLTECH+SRL+Santo+Domingo+Rep%C3%BAblica+Dominicana',
                    ),
                  ),
                  child: Container(
                    height: isDesktop ? 400 : 280,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: const NetworkImage(
                          'https://tile.openstreetmap.org/static/18/-69.93,18.48,14/800x400.png',
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF0F172A).withValues(alpha: 0.15),
                            const Color(0xFF0F172A).withValues(alpha: 0.5),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.location_on_rounded,
                                color: Color(0xFFEF4444),
                                size: 22,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Abrir en Google Maps',
                                style: TextStyle(
                                  color: Color(0xFF0F172A),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.open_in_new_rounded,
                                size: 16,
                                color: const Color(0xFF0F172A)
                                    .withValues(alpha: 0.5),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ==========================================
              // INFORMACIÓN DE UBICACIÓN
              // ==========================================
              Padding(
                padding: EdgeInsets.fromLTRB(
                  isDesktop ? 40 : 16,
                  24,
                  isDesktop ? 40 : 16,
                  32,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Título
                      const Text(
                        'FULLTECH SRL',
                        style: TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Tecnología, innovación y confianza',
                        style: TextStyle(
                          color: const Color(0xFF64748B)
                              .withValues(alpha: 0.8),
                          fontSize: 14,
                        ),
                      ),

                      const SizedBox(height: 24),
                      const Divider(height: 1, color: Color(0xFFE8EEF4)),
                      const SizedBox(height: 24),

                      // Dirección
                      _InfoRow(
                        icon: Icons.location_on_rounded,
                        iconColor: const Color(0xFFEF4444),
                        title: 'Dirección',
                        subtitle: 'Santo Domingo, República Dominicana',
                      ),
                      const SizedBox(height: 16),

                      // Horario
                      _InfoRow(
                        icon: Icons.access_time_rounded,
                        iconColor: const Color(0xFF3B82F6),
                        title: 'Horario',
                        subtitle: 'Lun - Vie: 8:00 AM - 6:00 PM\nSáb: 8:00 AM - 2:00 PM',
                      ),
                      const SizedBox(height: 16),

                      // Teléfono
                      _InfoRow(
                        icon: Icons.phone_rounded,
                        iconColor: const Color(0xFF16A34A),
                        title: 'Teléfono',
                        subtitle: '(829) 531-9442',
                        onTap: () => launchUrl(
                          Uri.parse('tel:+18295319442'),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // WhatsApp
                      _InfoRow(
                        icon: Icons.chat_rounded,
                        iconColor: const Color(0xFF25D366),
                        title: 'WhatsApp',
                        subtitle: '(849) 431-4070',
                        onTap: () => launchUrl(
                          Uri.parse('https://wa.me/18494314070'),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Email
                      _InfoRow(
                        icon: Icons.email_rounded,
                        iconColor: const Color(0xFFEA580C),
                        title: 'Email',
                        subtitle: 'fulltechsd@gmail.com',
                        onTap: () => launchUrl(
                          Uri.parse('mailto:fulltechsd@gmail.com'),
                        ),
                      ),

                      const SizedBox(height: 24),
                      const Divider(height: 1, color: Color(0xFFE8EEF4)),
                      const SizedBox(height: 24),

                      // Botón para abrir en Google Maps
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton.icon(
                          onPressed: () => launchUrl(
                            Uri.parse(
                              'https://www.google.com/maps/search/?api=1&query=FULLTECH+SRL+Santo+Domingo+Rep%C3%BAblica+Dominicana',
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF0F172A),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: const Icon(
                            Icons.map_rounded,
                            size: 20,
                          ),
                          label: const Text(
                            'Abrir en Google Maps',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
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
    );
  }
}

/// Fila de información con icono, título y subtítulo
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _InfoRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: iconColor.withValues(alpha: 0.08),
        highlightColor: iconColor.withValues(alpha: 0.04),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 22, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: const Color(0xFF64748B)
                            .withValues(alpha: 0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: const Color(0xFF94A3B8),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
