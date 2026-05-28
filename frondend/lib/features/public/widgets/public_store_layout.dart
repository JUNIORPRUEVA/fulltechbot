import 'dart:ui';

import 'package:flutter/material.dart';

import '../../storefront/theme/storefront_theme.dart';
import '../../storefront/widgets/storefront_main_hero_slider.dart';
import '../../storefront/widgets/storefront_smart_image.dart';

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
      floatingActionButton: floatingActionButton,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: _MarketplaceHeaderDelegate(
              minExtentValue: isDesktop ? 86 : 74,
              maxExtentValue: isDesktop ? 86 : 74,
              child: _MarketplaceHeader(
                storeName: storeName,
                logoUrl: logoUrl,
                primaryColor: primaryColor,
                onSearchTap: onSearchTap,
                onCartTap: onCartTap,
                onAdminTap: onAdminTap,
                onMenuTap: isDesktop ? null : () => scaffoldKey.currentState?.openDrawer(),
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(sidePadding, 10, sidePadding, 0),
            sliver: SliverToBoxAdapter(
              child: StorefrontMainHeroSlider(
                slug: slug,
                storeName: storeName,
                logoUrl: logoUrl,
                primaryColor: primaryColor,
                secondaryColor: secondaryColor,
                heroTitle: heroTitle,
                heroSubtitle: heroSubtitle,
                banners: banners,
                promotedProducts: promotedProducts,
                onSearchTap: onSearchTap,
                onCategoriesTap: onCategoriesTap,
                onOffersTap: onOffersTap,
                onAdminTap: onAdminTap,
                onCartTap: onCartTap,
                onMenuTap: isDesktop ? null : () => scaffoldKey.currentState?.openDrawer(),
                canPop: false,
                isDesktop: isDesktop,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(sidePadding, 12, sidePadding, 2),
              child: _QuickActionRow(
                primaryColor: primaryColor,
                onCategoriesTap: onCategoriesTap,
                onOffersTap: onOffersTap,
                onWhatsappTap: onWhatsappTap,
              ),
            ),
          ),
          ...slivers,
        ],
      ),
    );
  }
}

class _MarketplaceHeader extends StatelessWidget {
  final String storeName;
  final dynamic logoUrl;
  final Color primaryColor;
  final VoidCallback onSearchTap;
  final VoidCallback onCartTap;
  final VoidCallback onAdminTap;
  final VoidCallback? onMenuTap;

  const _MarketplaceHeader({
    required this.storeName,
    required this.logoUrl,
    required this.primaryColor,
    required this.onSearchTap,
    required this.onCartTap,
    required this.onAdminTap,
    this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.viewPaddingOf(context).top;
    final isDesktop = MediaQuery.sizeOf(context).width >= 1024;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            border: const Border(
              bottom: BorderSide(color: Color(0x140F172A)),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x080F172A),
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              isDesktop ? 18 : 12,
              topPadding + 8,
              isDesktop ? 18 : 12,
              8,
            ),
            child: Row(
              children: [
                if (onMenuTap != null) ...[
                  _HeaderIconButton(
                    icon: Icons.menu_rounded,
                    onTap: onMenuTap!,
                  ),
                  const SizedBox(width: 8),
                ],
                if (isDesktop) ...[
                  _StoreBadge(
                    storeName: storeName,
                    logoUrl: logoUrl,
                    primaryColor: primaryColor,
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: _SearchPill(
                    primaryColor: primaryColor,
                    onTap: onSearchTap,
                  ),
                ),
                const SizedBox(width: 8),
                if (isDesktop) ...[
                  _HeaderIconButton(
                    icon: Icons.person_outline_rounded,
                    onTap: onAdminTap,
                  ),
                  const SizedBox(width: 8),
                ],
                _HeaderIconButton(
                  icon: Icons.shopping_bag_outlined,
                  onTap: onCartTap,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickActionRow extends StatelessWidget {
  final Color primaryColor;
  final VoidCallback onCategoriesTap;
  final VoidCallback onOffersTap;
  final VoidCallback? onWhatsappTap;

  const _QuickActionRow({
    required this.primaryColor,
    required this.onCategoriesTap,
    required this.onOffersTap,
    required this.onWhatsappTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _QuickActionChip(
            icon: Icons.grid_view_rounded,
            label: 'Categorias',
            primaryColor: primaryColor,
            onTap: onCategoriesTap,
          ),
          const SizedBox(width: 10),
          _QuickActionChip(
            icon: Icons.local_fire_department_outlined,
            label: 'Ofertas',
            primaryColor: primaryColor,
            onTap: onOffersTap,
          ),
          if (onWhatsappTap != null) ...[
            const SizedBox(width: 10),
            _QuickActionChip(
              icon: Icons.chat_bubble_outline_rounded,
              label: 'WhatsApp',
              primaryColor: primaryColor,
              onTap: onWhatsappTap!,
            ),
          ],
        ],
      ),
    );
  }
}

class _QuickActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color primaryColor;
  final VoidCallback onTap;

  const _QuickActionChip({
    required this.icon,
    required this.label,
    required this.primaryColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFE5EAF1)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 17, color: primaryColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoreBadge extends StatelessWidget {
  final String storeName;
  final dynamic logoUrl;
  final Color primaryColor;

  const _StoreBadge({
    required this.storeName,
    required this.logoUrl,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
          ),
          child: StorefrontSmartImage(
            source: logoUrl,
            fit: BoxFit.cover,
            borderRadius: BorderRadius.circular(14),
            placeholder: Icon(
              Icons.storefront_rounded,
              color: primaryColor,
              size: 18,
            ),
          ),
        ),
        const SizedBox(width: 10),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 170),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                storeName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF111827),
                ),
              ),
              Text(
                'Marketplace Fulltech',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: primaryColor.withValues(alpha: 0.72),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SearchPill extends StatelessWidget {
  final Color primaryColor;
  final VoidCallback onTap;

  const _SearchPill({
    required this.primaryColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF4F6F9),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFFE5EAF1)),
          ),
          child: Row(
            children: [
              Icon(Icons.search_rounded, color: primaryColor, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Buscar productos',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(Icons.tune_rounded, size: 18, color: primaryColor),
            ],
          ),
        ),
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
      color: const Color(0xFFF4F6F9),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: const Color(0xFF0F172A), size: 19),
        ),
      ),
    );
  }
}

class _MarketplaceHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minExtentValue;
  final double maxExtentValue;
  final Widget child;

  const _MarketplaceHeaderDelegate({
    required this.minExtentValue,
    required this.maxExtentValue,
    required this.child,
  });

  @override
  double get minExtent => minExtentValue;

  @override
  double get maxExtent => maxExtentValue;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _MarketplaceHeaderDelegate oldDelegate) {
    return minExtentValue != oldDelegate.minExtentValue ||
        maxExtentValue != oldDelegate.maxExtentValue ||
        child != oldDelegate.child;
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
                boxShadow: StorefrontShadows.soft,
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
              title: 'Categorias',
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
              title: 'Iniciar sesion',
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
