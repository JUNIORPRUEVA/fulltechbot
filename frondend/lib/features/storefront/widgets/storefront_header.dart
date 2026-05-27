import 'package:flutter/material.dart';
import '../services/storefront_helpers.dart';

class StorefrontHeader extends StatelessWidget {
  final Map<String, dynamic> config;
  final String slug;
  final Color primaryColor;
  final Color secondaryColor;
  final TextEditingController searchController;
  final ValueChanged<String> onSearch;

  const StorefrontHeader({
    super.key,
    required this.config,
    required this.slug,
    required this.primaryColor,
    required this.secondaryColor,
    required this.searchController,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    final logoUrl = StorefrontHelpers.resolveMediaUrl(config['logo_url']);

    return SliverAppBar(
      expandedHeight: 130,
      pinned: true,
      stretch: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                primaryColor,
                primaryColor.withValues(alpha: 0.92),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            right: 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fila superior: logo, nombre, carrito
              Row(
                children: [
                  // Logo
                  if (logoUrl != null)
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          logoUrl,
                          height: 36,
                          width: 36,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.store_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  if (logoUrl != null) const SizedBox(width: 12),
                  // Nombre tienda
                  Expanded(
                    child: Text(
                      config['nombre_tienda'] ?? 'FULLTECH',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  // Botón carrito
                  _HeaderIconButton(
                    icon: Icons.shopping_cart_outlined,
                    onTap: () => Navigator.pushNamed(
                      context,
                      '/tienda/$slug/carrito',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Mensaje principal
              if (config['mensaje_principal'] != null)
                Text(
                  config['mensaje_principal'],
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(0),
        child: Container(),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderIconButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}
