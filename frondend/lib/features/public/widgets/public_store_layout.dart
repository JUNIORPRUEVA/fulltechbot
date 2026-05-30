import 'package:flutter/material.dart';

import '../../storefront/widgets/storefront_app_bar.dart';
import '../../storefront/widgets/storefront_hero_slider.dart';
import '../../storefront/widgets/storefront_whatsapp_button.dart' as wa;

/// Layout principal de la tienda pública FULLTECH SRL.
/// Incluye AppBar superior fijo (fuera del scroll), slider hero,
/// contenido (slivers) y WhatsApp flotante.
///
/// El AppBar está fuera del CustomScrollView para garantizar que
/// los botones (menú, buscador, carrito) sean siempre presionables
/// y no compitan con el gesto de scroll.
class PublicStoreLayout extends StatelessWidget {
  final String slug;
  final String storeName;
  final dynamic logoUrl;
  final Color primaryColor;
  final Color secondaryColor;
  final String heroTitle;
  final String heroSubtitle;
  final List<dynamic> banners;
  final List<dynamic> promotedProducts;
  final VoidCallback onSearchTap;
  final VoidCallback onCategoriesTap;
  final VoidCallback onOffersTap;
  final VoidCallback onAdminTap;
  final VoidCallback onCartTap;
  final VoidCallback? onWhatsappTap;
  final List<Widget> slivers;
  final Widget? floatingActionButton;

  const PublicStoreLayout({
    super.key,
    required this.slug,
    required this.storeName,
    required this.logoUrl,
    required this.primaryColor,
    required this.secondaryColor,
    required this.heroTitle,
    required this.heroSubtitle,
    required this.banners,
    required this.promotedProducts,
    required this.onSearchTap,
    required this.onCategoriesTap,
    required this.onOffersTap,
    required this.onAdminTap,
    required this.onCartTap,
    this.onWhatsappTap,
    required this.slivers,
    this.floatingActionButton,
  });

  bool _isDesktop(BuildContext context) => MediaQuery.sizeOf(context).width >= 1024;

  @override
  Widget build(BuildContext context) {
    final scaffoldKey = GlobalKey<ScaffoldState>();
    final isDesktop = _isDesktop(context);
    final width = MediaQuery.sizeOf(context).width;
    final sidePadding = width >= 1320
        ? ((width - 1240) / 2).clamp(18.0, 9999.0)
        : width >= 700
            ? 20.0
            : 14.0;

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: const Color(0xFFF5F7FA),
      drawer: isDesktop
          ? null
          : _PublicMenuDrawer(
              slug: slug,
              onCategoriesTap: onCategoriesTap,
              onOffersTap: onOffersTap,
              onAdminTap: onAdminTap,
              onCartTap: onCartTap,
              onWhatsappTap: onWhatsappTap,
            ),
      body: Stack(
        children: [
          // ==========================================
          // CONTENIDO PRINCIPAL
          // ==========================================
          Column(
            children: [
              // ==========================================
              // APPBAR FIJO - FUERA DEL SCROLL
              // ==========================================
              StorefrontAppBar(
                slug: slug,
                storeName: storeName,
                primaryColor: primaryColor,
                secondaryColor: secondaryColor,
                onMenuTap: () => scaffoldKey.currentState?.openDrawer(),
                onSearchTap: onSearchTap,
                onCartTap: onCartTap,
              ),

              // ==========================================
              // CONTENIDO SCROLLABLE
              // ==========================================
              Expanded(
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  slivers: [
                    // ==========================================
                    // HERO SLIDER PRINCIPAL
                    // ==========================================
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(sidePadding, 10, sidePadding, 0),
                      sliver: SliverToBoxAdapter(
                        child: StorefrontHeroSlider(
                          slug: slug,
                          primaryColor: primaryColor,
                          secondaryColor: secondaryColor,
                          banners: banners,
                          promotedProducts: promotedProducts,
                          isDesktop: isDesktop,
                          onSearchTap: onSearchTap,
                          onCategoriesTap: onCategoriesTap,
                          onOffersTap: onOffersTap,
                        ),
                      ),
                    ),

                    // ==========================================
                    // CONTENIDO ADICIONAL (categorías, productos, footer)
                    // ==========================================
                    ...slivers,
                  ],
                ),
              ),
            ],
          ),

          // ==========================================
          // BOTÓN FLOTANTE WHATSAPP
          // Posicionado sobre el contenido, respeta SafeArea
          // ==========================================
          if (floatingActionButton != null)
            Positioned(
              right: 16,
              bottom: MediaQuery.viewPaddingOf(context).bottom + 16,
              child: floatingActionButton!,
            )
          else if (onWhatsappTap != null)
            Positioned(
              right: 16,
              bottom: MediaQuery.viewPaddingOf(context).bottom + 16,
              child: wa.StorefrontWhatsAppFloatingButton(
                phoneNumber: '829-534-4286',
                isDesktop: isDesktop,
              ),
            ),
        ],
      ),
    );
  }
}

// ==========================================
// PUBLIC MENU DRAWER
// ==========================================
class _PublicMenuDrawer extends StatelessWidget {
  final String slug;
  final VoidCallback onCategoriesTap;
  final VoidCallback onOffersTap;
  final VoidCallback onAdminTap;
  final VoidCallback onCartTap;
  final VoidCallback? onWhatsappTap;

  const _PublicMenuDrawer({
    required this.slug,
    required this.onCategoriesTap,
    required this.onOffersTap,
    required this.onAdminTap,
    required this.onCartTap,
    this.onWhatsappTap,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFFF8FAFC),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 20),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'FULLTECH',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Tienda online premium',
                    style: TextStyle(color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _DrawerTile(
              icon: Icons.home_outlined,
              title: 'Inicio',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/tienda/$slug');
              },
            ),
            _DrawerTile(
              icon: Icons.grid_view_rounded,
              title: 'Categorías',
              onTap: () {
                Navigator.pop(context);
                onCategoriesTap();
              },
            ),
            _DrawerTile(
              icon: Icons.local_offer_outlined,
              title: 'Ofertas',
              onTap: () {
                Navigator.pop(context);
                onOffersTap();
              },
            ),
            _DrawerTile(
              icon: Icons.shopping_cart_outlined,
              title: 'Carrito',
              onTap: () {
                Navigator.pop(context);
                onCartTap();
              },
            ),
            if (onWhatsappTap != null)
              _DrawerTile(
                icon: Icons.chat_outlined,
                title: 'WhatsApp',
                onTap: () {
                  Navigator.pop(context);
                  onWhatsappTap!.call();
                },
              ),
            _DrawerTile(
              icon: Icons.admin_panel_settings_outlined,
              title: 'Iniciar sesión',
              onTap: () {
                Navigator.pop(context);
                onAdminTap();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _DrawerTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      leading: Icon(icon, color: const Color(0xFF0F172A)),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}
