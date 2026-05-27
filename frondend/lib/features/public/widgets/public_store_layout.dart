import 'package:flutter/material.dart';

import '../../storefront/widgets/storefront_smart_image.dart';

class PublicStoreLayout extends StatelessWidget {
  final String slug;
  final String storeName;
  final dynamic logoUrl;
  final Color primaryColor;
  final Color secondaryColor;
  final String heroTitle;
  final String heroSubtitle;
  final VoidCallback onSearchTap;
  final VoidCallback onCategoriesTap;
  final VoidCallback onOffersTap;
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
    required this.onSearchTap,
    required this.onCategoriesTap,
    required this.onOffersTap,
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
            ),
      floatingActionButton: floatingActionButton,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _PublicHero(
              slug: slug,
              storeName: storeName,
              logoUrl: logoUrl,
              primaryColor: primaryColor,
              secondaryColor: secondaryColor,
              heroTitle: heroTitle,
              heroSubtitle: heroSubtitle,
              onSearchTap: onSearchTap,
              onCategoriesTap: onCategoriesTap,
              onOffersTap: onOffersTap,
              isDesktop: isDesktop,
            ),
          ),
          ...slivers,
        ],
      ),
    );
  }
}

class _PublicHero extends StatelessWidget {
  final String slug;
  final String storeName;
  final dynamic logoUrl;
  final Color primaryColor;
  final Color secondaryColor;
  final String heroTitle;
  final String heroSubtitle;
  final VoidCallback onSearchTap;
  final VoidCallback onCategoriesTap;
  final VoidCallback onOffersTap;
  final bool isDesktop;

  const _PublicHero({
    required this.slug,
    required this.storeName,
    required this.logoUrl,
    required this.primaryColor,
    required this.secondaryColor,
    required this.heroTitle,
    required this.heroSubtitle,
    required this.onSearchTap,
    required this.onCategoriesTap,
    required this.onOffersTap,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final canPop = Navigator.of(context).canPop();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      padding: EdgeInsets.fromLTRB(18, topPadding + 10, 18, 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          colors: [primaryColor, secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x260F172A),
            blurRadius: 30,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -40,
            top: -20,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            left: -30,
            bottom: -55,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (!isDesktop)
                    _GlassIconButton(
                      icon: Icons.menu_rounded,
                      onTap: () => Scaffold.of(context).openDrawer(),
                    ),
                  if (!isDesktop) const SizedBox(width: 10),
                  if (canPop)
                    _GlassIconButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                  if (canPop) const SizedBox(width: 10),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: StorefrontSmartImage(
                      source: logoUrl,
                      fit: BoxFit.cover,
                      borderRadius: BorderRadius.circular(16),
                      placeholder: const Center(
                        child: Icon(
                          Icons.shield_moon_outlined,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          storeName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Tienda oficial FULLTECH',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.78),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isDesktop) ...[
                    _DesktopNavButton(
                      label: 'Inicio',
                      onTap: () => Navigator.pushNamed(context, '/tienda/$slug'),
                    ),
                    _DesktopNavButton(
                      label: 'Categorias',
                      onTap: onCategoriesTap,
                    ),
                    _DesktopNavButton(
                      label: 'Ofertas',
                      onTap: onOffersTap,
                    ),
                    const SizedBox(width: 6),
                  ],
                  _GlassIconButton(
                    icon: Icons.search_rounded,
                    onTap: onSearchTap,
                  ),
                  const SizedBox(width: 8),
                  _GlassIconButton(
                    icon: Icons.shopping_cart_outlined,
                    onTap: () =>
                        Navigator.pushNamed(context, '/tienda/$slug/carrito'),
                  ),
                  if (isDesktop) ...[
                    const SizedBox(width: 10),
                    OutlinedButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/login?redirect=/admin'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.26),
                        ),
                      ),
                      child: const Text('Iniciar sesion'),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 26),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Garantia, soporte e instalacion profesional',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.94),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                heroTitle,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  height: 1.04,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: Text(
                  heroSubtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.84),
                    fontSize: 15,
                    height: 1.55,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  FilledButton.icon(
                    onPressed: onSearchTap,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    icon: const Icon(Icons.flash_on_rounded),
                    label: const Text('Buscar productos'),
                  ),
                  OutlinedButton.icon(
                    onPressed: onOffersTap,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    icon: const Icon(Icons.local_offer_outlined),
                    label: const Text('Ver ofertas'),
                  ),
                ],
              ),
            ],
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

  const _PublicMenuDrawer({
    required this.slug,
    required this.onCategoriesTap,
    required this.onOffersTap,
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
                Navigator.pushNamed(context, '/tienda/$slug/carrito');
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
                Navigator.pushNamed(context, '/login?redirect=/admin');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GlassIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: Colors.white),
        ),
      ),
    );
  }
}

class _DesktopNavButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _DesktopNavButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
      ),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}
