import 'package:flutter/material.dart';

import '../../storefront/widgets/install_pwa_prompt.dart';
import '../../storefront/widgets/storefront_app_bar.dart';
import '../../storefront/widgets/storefront_hero_slider.dart';
import '../../storefront/widgets/storefront_whatsapp_button.dart' as wa;

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

  PublicStoreLayout({
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

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool _isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 1024;

  @override
  Widget build(BuildContext context) {
    final isDesktop = _isDesktop(context);
    final width = MediaQuery.sizeOf(context).width;
    final sidePadding = width >= 1320
        ? ((width - 1240) / 2).clamp(18.0, 9999.0)
        : width >= 700
        ? 20.0
        : 14.0;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF5F7FA),
      drawerEnableOpenDragGesture: true,
      drawerEdgeDragWidth: 34,
      drawerScrimColor: Colors.black.withValues(alpha: 0.36),
      drawer: _PublicMenuDrawer(
        slug: slug,
        onCategoriesTap: onCategoriesTap,
        onOffersTap: onOffersTap,
        onAdminTap: onAdminTap,
        onCartTap: onCartTap,
        onWhatsappTap: onWhatsappTap,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              StorefrontAppBar(
                slug: slug,
                storeName: storeName,
                primaryColor: primaryColor,
                secondaryColor: secondaryColor,
                onMenuTap: () {
                  final state = _scaffoldKey.currentState;
                  if (state == null) return;
                  if (state.isDrawerOpen) {
                    Navigator.of(context).maybePop();
                  } else {
                    state.openDrawer();
                  }
                },
                onSearchTap: onSearchTap,
                onCartTap: onCartTap,
              ),
              Expanded(
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  slivers: [
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        sidePadding,
                        10,
                        sidePadding,
                        0,
                      ),
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
                    ...slivers,
                  ],
                ),
              ),
            ],
          ),
          if (floatingActionButton != null)
            Positioned(
              right: isDesktop ? 28 : 18,
              bottom:
                  MediaQuery.viewPaddingOf(context).bottom +
                  (isDesktop ? 28 : 22),
              child: floatingActionButton!,
            )
          else if (onWhatsappTap != null)
            Positioned(
              right: isDesktop ? 28 : 18,
              bottom:
                  MediaQuery.viewPaddingOf(context).bottom +
                  (isDesktop ? 28 : 22),
              child: wa.StorefrontWhatsAppFloatingButton(
                phoneNumber: '8494314070',
                isDesktop: isDesktop,
              ),
            ),
          IgnorePointer(
            ignoring: false,
            child: InstallPwaPrompt(
              primaryColor: primaryColor,
              secondaryColor: secondaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

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
    final isDesktop = MediaQuery.sizeOf(context).width >= 1024;

    return Drawer(
      width: isDesktop ? 360 : null,
      backgroundColor: const Color(0xFFF8FAFC),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF0F172A,
                          ).withValues(alpha: 0.15),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.asset(
                                'assets/logo_principal.jpeg',
                                width: 40,
                                height: 40,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFF3B82F6),
                                            Color(0xFF60A5FA),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      alignment: Alignment.center,
                                      child: const Text(
                                        'F',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(Icons.close_rounded),
                              color: Colors.white,
                              splashRadius: 20,
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'FULLTECH',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tienda online premium',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _DrawerTile(
                    icon: Icons.home_rounded,
                    title: 'Inicio',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/tienda/$slug');
                    },
                  ),
                  _DrawerTile(
                    icon: Icons.grid_view_rounded,
                    title: 'Categorias',
                    onTap: () {
                      Navigator.pop(context);
                      onCategoriesTap();
                    },
                  ),
                  _DrawerTile(
                    icon: Icons.local_offer_rounded,
                    title: 'Ofertas',
                    onTap: () {
                      Navigator.pop(context);
                      onOffersTap();
                    },
                  ),
                  _DrawerTile(
                    icon: Icons.shopping_cart_rounded,
                    title: 'Carrito',
                    onTap: () {
                      Navigator.pop(context);
                      onCartTap();
                    },
                  ),
                  if (onWhatsappTap != null)
                    _DrawerTile(
                      icon: Icons.chat_rounded,
                      title: 'WhatsApp',
                      iconColor: const Color(0xFF25D366),
                      onTap: () {
                        Navigator.pop(context);
                        onWhatsappTap!.call();
                      },
                    ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: const Color(0xFFE5EAF1).withValues(alpha: 0.5),
                  ),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: _DrawerTile(
                icon: Icons.admin_panel_settings_rounded,
                title: 'Iniciar sesion',
                iconColor: const Color(0xFF64748B),
                onTap: () {
                  Navigator.pop(context);
                  onAdminTap();
                },
              ),
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
  final Color? iconColor;

  const _DrawerTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? const Color(0xFF0F172A);

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: color.withValues(alpha: 0.06),
          highlightColor: color.withValues(alpha: 0.03),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 22, color: color),
                ),
                const SizedBox(width: 14),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: color,
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
