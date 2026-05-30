import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
                slug: slug,
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
          // NOTA: La línea de Categorías/Ofertas que estaba aquí se ha eliminado
          // porque ya está representada dentro del slider (StorefrontMainHeroSlider).
          // Los botones "Ofertas" y "Categorías" están dentro del hero overlay.
          ...slivers,
        ],
      ),
    );
  }
}

// ==========================================
// MARKETPLACE HEADER (Stateful para carrito)
// ==========================================
class _MarketplaceHeader extends StatefulWidget {
  final String slug;
  final String storeName;
  final dynamic logoUrl;
  final Color primaryColor;
  final VoidCallback onSearchTap;
  final VoidCallback onCartTap;
  final VoidCallback onAdminTap;
  final VoidCallback? onMenuTap;

  const _MarketplaceHeader({
    required this.slug,
    required this.storeName,
    required this.logoUrl,
    required this.primaryColor,
    required this.onSearchTap,
    required this.onCartTap,
    required this.onAdminTap,
    this.onMenuTap,
  });

  @override
  State<_MarketplaceHeader> createState() => _MarketplaceHeaderState();
}

class _MarketplaceHeaderState extends State<_MarketplaceHeader>
    with SingleTickerProviderStateMixin {
  int _cartItemCount = 0;
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;
  Timer? _cartCheckTimer;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 0.9), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.1), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.1, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.easeInOut,
    ));
    _startCartPolling();
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _cartCheckTimer?.cancel();
    super.dispose();
  }

  void _startCartPolling() {
    _checkCartCount();
    _cartCheckTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _checkCartCount();
    });
  }

  Future<void> _checkCartCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'storefront_session_${widget.slug}';
      final sessionId = prefs.getString(key);
      if (sessionId == null || sessionId.isEmpty) {
        if (_cartItemCount != 0 && mounted) {
          setState(() => _cartItemCount = 0);
        }
        return;
      }
      final cartKey = 'storefront_cart_${widget.slug}_$sessionId';
      final cartData = prefs.getString(cartKey);
      if (cartData != null && mounted) {
        try {
          final cart = jsonDecode(cartData) as Map<String, dynamic>;
          final items = List<dynamic>.from(cart['items'] as List? ?? []);
          final count = items.fold<int>(0, (sum, item) {
            final map = item as Map<String, dynamic>;
            return sum + (int.tryParse(map['cantidad']?.toString() ?? '0') ?? 0);
          });
          if (count != _cartItemCount && mounted) {
            setState(() => _cartItemCount = count);
            if (count > _cartItemCount) {
              _bounceController.forward(from: 0);
            }
          }
        } catch (_) {}
      } else {
        if (_cartItemCount != 0 && mounted) {
          setState(() => _cartItemCount = 0);
        }
      }
    } catch (_) {}
  }

  void _onCartTap() {
    _bounceController.forward(from: 0);
    widget.onCartTap();
  }

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
                if (widget.onMenuTap != null) ...[
                  _HeaderIconButton(
                    icon: Icons.menu_rounded,
                    onTap: widget.onMenuTap!,
                  ),
                  const SizedBox(width: 8),
                ],
                if (isDesktop) ...[
                  _StoreBadge(
                    storeName: widget.storeName,
                    logoUrl: widget.logoUrl,
                    primaryColor: widget.primaryColor,
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: _SearchPill(
                    primaryColor: widget.primaryColor,
                    onSearchTap: widget.onSearchTap,
                  ),
                ),
                const SizedBox(width: 8),
                if (isDesktop) ...[
                  _HeaderIconButton(
                    icon: Icons.person_outline_rounded,
                    onTap: widget.onAdminTap,
                  ),
                  const SizedBox(width: 8),
                ],
                // Carrito con badge animado
                _AnimatedCartIcon(
                  itemCount: _cartItemCount,
                  animation: _bounceAnimation,
                  onTap: _onCartTap,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// ANIMATED CART ICON
// ==========================================
class _AnimatedCartIcon extends StatelessWidget {
  final int itemCount;
  final Animation<double> animation;
  final VoidCallback onTap;

  const _AnimatedCartIcon({
    required this.itemCount,
    required this.animation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.scale(
          scale: animation.value,
          child: child,
        );
      },
      child: Material(
        color: const Color(0xFFF4F6F9),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            width: 40,
            height: 40,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Center(
                  child: Icon(
                    Icons.shopping_bag_outlined,
                    color: Color(0xFF0F172A),
                    size: 19,
                  ),
                ),
                if (itemCount > 0)
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        itemCount > 99 ? '99+' : '$itemCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                        textAlign: TextAlign.center,
                      ),
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

// ==========================================
// SEARCH PILL CON FILTRO
// ==========================================
class _SearchPill extends StatelessWidget {
  final Color primaryColor;
  final VoidCallback onSearchTap;

  const _SearchPill({
    required this.primaryColor,
    required this.onSearchTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF4F6F9),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onSearchTap,
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
              // Icono de filtro separado - abre filtro real
              GestureDetector(
                onTap: () => _openFilterSheet(context),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.tune_rounded, size: 18, color: primaryColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _StorefrontFilterSheet(primaryColor: primaryColor),
    );
  }
}

// ==========================================
// FILTER BOTTOM SHEET REAL
// ==========================================
class _StorefrontFilterSheet extends StatefulWidget {
  final Color primaryColor;

  const _StorefrontFilterSheet({required this.primaryColor});

  @override
  State<_StorefrontFilterSheet> createState() => _StorefrontFilterSheetState();
}

class _StorefrontFilterSheetState extends State<_StorefrontFilterSheet> {
  String _selectedSort = 'featured';
  bool _onlyOffers = false;
  bool _onlyAvailable = false;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.viewPaddingOf(context).bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.75,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFD1D5DB),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                const Text(
                  'Filtros',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedSort = 'featured';
                      _onlyOffers = false;
                      _onlyAvailable = false;
                    });
                  },
                  child: Text(
                    'Limpiar',
                    style: TextStyle(
                      color: widget.primaryColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Content
          Flexible(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              children: [
                // Ordenar por
                const Text(
                  'Ordenar por',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _FilterChip(
                      label: 'Destacados',
                      selected: _selectedSort == 'featured',
                      primaryColor: widget.primaryColor,
                      onTap: () => setState(() => _selectedSort = 'featured'),
                    ),
                    _FilterChip(
                      label: 'Menor precio',
                      selected: _selectedSort == 'price_asc',
                      primaryColor: widget.primaryColor,
                      onTap: () => setState(() => _selectedSort = 'price_asc'),
                    ),
                    _FilterChip(
                      label: 'Mayor precio',
                      selected: _selectedSort == 'price_desc',
                      primaryColor: widget.primaryColor,
                      onTap: () => setState(() => _selectedSort = 'price_desc'),
                    ),
                    _FilterChip(
                      label: 'Más recientes',
                      selected: _selectedSort == 'newest',
                      primaryColor: widget.primaryColor,
                      onTap: () => setState(() => _selectedSort = 'newest'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Ofertas
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Solo ofertas',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: const Text(
                    'Productos con descuento',
                    style: TextStyle(fontSize: 12),
                  ),
                  value: _onlyOffers,
                  activeColor: widget.primaryColor,
                  onChanged: (v) => setState(() => _onlyOffers = v),
                ),
                // Disponibilidad
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Solo disponibles',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: const Text(
                    'Productos en stock',
                    style: TextStyle(fontSize: 12),
                  ),
                  value: _onlyAvailable,
                  activeColor: widget.primaryColor,
                  onChanged: (v) => setState(() => _onlyAvailable = v),
                ),
              ],
            ),
          ),
          // Apply button
          SafeArea(
            top: false,
            minimum: EdgeInsets.only(bottom: bottomPadding + 8),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: FilledButton(
                onPressed: () {
                  Navigator.pop(context, {
                    'sort': _selectedSort,
                    'onlyOffers': _onlyOffers,
                    'onlyAvailable': _onlyAvailable,
                  });
                },
                style: FilledButton.styleFrom(
                  backgroundColor: widget.primaryColor,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Aplicar filtros',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color primaryColor;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.primaryColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? primaryColor : const Color(0xFFF4F6F9),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? primaryColor : const Color(0xFFE5EAF1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF0F172A),
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ==========================================
// STORE BADGE
// ==========================================
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

// ==========================================
// HEADER ICON BUTTON
// ==========================================
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

// ==========================================
// HEADER DELEGATE
// ==========================================
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
