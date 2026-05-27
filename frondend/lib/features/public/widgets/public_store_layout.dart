import 'package:flutter/material.dart';

import '../../storefront/widgets/storefront_main_hero_slider.dart';

class PublicStoreLayout extends StatelessWidget {
  final String slug;
  final String storeName;
  final dynamic logoUrl;
  final Color primaryColor;
  final Color secondaryColor;
  final String heroTitle;
  final String heroSubtitle;
  final List<dynamic> banners;
  final VoidCallback onSearchTap;
  final VoidCallback onCategoriesTap;
  final VoidCallback onOffersTap;
  final VoidCallback onAdminTap;
  final VoidCallback onCartTap;
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
    required this.onSearchTap,
    required this.onCategoriesTap,
    required this.onOffersTap,
    required this.onAdminTap,
    required this.onCartTap,
    required this.slivers,
    this.floatingActionButton,
  });

  bool _isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 900;

  @override
  Widget build(BuildContext context) {
    final isDesktop = _isDesktop(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      drawer: isDesktop
          ? null
          : _PublicMenuDrawer(
              slug: slug,
              onCategoriesTap: onCategoriesTap,
              onOffersTap: onOffersTap,
              onAdminTap: onAdminTap,
              onCartTap: onCartTap,
            ),
      floatingActionButton: floatingActionButton,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Builder(
              builder: (heroContext) => StorefrontMainHeroSlider(
                slug: slug,
                storeName: storeName,
                logoUrl: logoUrl,
                primaryColor: primaryColor,
                secondaryColor: secondaryColor,
                heroTitle: heroTitle,
                heroSubtitle: heroSubtitle,
                banners: banners,
                onSearchTap: onSearchTap,
                onCategoriesTap: onCategoriesTap,
                onOffersTap: onOffersTap,
                onAdminTap: onAdminTap,
                onCartTap: onCartTap,
                onMenuTap: isDesktop
                    ? null
                    : () => Scaffold.of(heroContext).openDrawer(),
                canPop: false,
                isDesktop: isDesktop,
              ),
            ),
          ),
          ...slivers,
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

  const _PublicMenuDrawer({
    required this.slug,
    required this.onCategoriesTap,
    required this.onOffersTap,
    required this.onAdminTap,
    required this.onCartTap,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const ListTile(
              title: Text(
                'FULLTECH',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              subtitle: Text('Tienda online'),
            ),
            ListTile(
              leading: const Icon(Icons.home_outlined),
              title: const Text('Inicio'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/tienda/$slug');
              },
            ),
            ListTile(
              leading: const Icon(Icons.grid_view_rounded),
              title: const Text('Categorias'),
              onTap: () {
                Navigator.pop(context);
                onCategoriesTap();
              },
            ),
            ListTile(
              leading: const Icon(Icons.local_offer_outlined),
              title: const Text('Ofertas'),
              onTap: () {
                Navigator.pop(context);
                onOffersTap();
              },
            ),
            ListTile(
              leading: const Icon(Icons.shopping_cart_outlined),
              title: const Text('Carrito'),
              onTap: () {
                Navigator.pop(context);
                onCartTap();
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat_outlined),
              title: const Text('WhatsApp'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.admin_panel_settings_outlined),
              title: const Text('Iniciar sesion'),
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
