import 'package:flutter/material.dart';

import '../../storefront/theme/storefront_theme.dart';
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
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              sidePadding,
              MediaQuery.viewPaddingOf(context).top + 10,
              sidePadding,
              0,
            ),
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
                onCartTap: onCartTap,
                onMenuTap: isDesktop
                    ? null
                    : () => scaffoldKey.currentState?.openDrawer(),
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
// ANIMATED CART ICON
// ==========================================

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
