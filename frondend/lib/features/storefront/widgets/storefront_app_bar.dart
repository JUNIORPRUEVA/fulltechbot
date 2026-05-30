import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// AppBar superior profesional, fino, moderno y fijo.
/// Contiene: menú (drawer), nombre FULLTECH SRL, buscador compacto y carrito.
class StorefrontAppBar extends StatefulWidget {
  final String slug;
  final String storeName;
  final Color primaryColor;
  final Color secondaryColor;
  final VoidCallback onMenuTap;
  final VoidCallback onSearchTap;
  final VoidCallback onCartTap;

  const StorefrontAppBar({
    super.key,
    required this.slug,
    required this.storeName,
    required this.primaryColor,
    required this.secondaryColor,
    required this.onMenuTap,
    required this.onSearchTap,
    required this.onCartTap,
  });

  @override
  State<StorefrontAppBar> createState() => _StorefrontAppBarState();
}

class _StorefrontAppBarState extends State<StorefrontAppBar> {
  int _cartItemCount = 0;

  @override
  void initState() {
    super.initState();
    _loadCartCount();
  }

  Future<void> _loadCartCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'storefront_session_${widget.slug}';
      final sessionId = prefs.getString(key);
      if (sessionId == null || sessionId.isEmpty) {
        if (mounted && _cartItemCount != 0) {
          setState(() => _cartItemCount = 0);
        }
        return;
      }

      final cartKey = 'storefront_cart_${widget.slug}_$sessionId';
      final cartData = prefs.getString(cartKey);
      if (cartData == null) {
        if (mounted && _cartItemCount != 0) {
          setState(() => _cartItemCount = 0);
        }
        return;
      }

      final cart = jsonDecode(cartData) as Map<String, dynamic>;
      final items = List<dynamic>.from(cart['items'] as List? ?? const []);
      final count = items.fold<int>(0, (sum, item) {
        final map = item as Map<String, dynamic>;
        return sum + (int.tryParse(map['cantidad']?.toString() ?? '0') ?? 0);
      });
      if (mounted && count != _cartItemCount) {
        setState(() => _cartItemCount = count);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final topPadding = MediaQuery.viewPaddingOf(context).top;
    final isDesktop = screenWidth >= 1024;
    final isSmallScreen = screenWidth < 380;

    return Container(
      padding: EdgeInsets.only(top: topPadding),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFE5EAF1).withValues(alpha: 0.6),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        bottom: false,
        child: Container(
          height: isDesktop ? 56 : 52,
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 24 : (isSmallScreen ? 8 : 12),
          ),
          child: Row(
            children: [
              // Botón menú (drawer)
              _AppBarIconButton(
                icon: Icons.menu_rounded,
                onTap: widget.onMenuTap,
                size: isSmallScreen ? 34 : 38,
              ),
              if (!isSmallScreen) const SizedBox(width: 6),

              // Nombre de la empresa
              if (!isSmallScreen)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    widget.storeName,
                    style: TextStyle(
                      fontSize: isDesktop ? 17 : (isSmallScreen ? 14 : 15),
                      fontWeight: FontWeight.w900,
                      color: widget.primaryColor,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),

              // Buscador compacto
              Expanded(
                child: GestureDetector(
                  onTap: widget.onSearchTap,
                  child: Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: const Color(0xFFE5EAF1).withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.search_rounded,
                          size: 16,
                          color: const Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            isSmallScreen ? 'Buscar...' : 'Buscar productos...',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // Carrito
              _CartIconButton(
                itemCount: _cartItemCount,
                onTap: widget.onCartTap,
                size: isSmallScreen ? 34 : 38,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppBarIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;

  const _AppBarIconButton({
    required this.icon,
    required this.onTap,
    this.size = 38,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(
            icon,
            size: 20,
            color: const Color(0xFF0F172A),
          ),
        ),
      ),
    );
  }
}

class _CartIconButton extends StatelessWidget {
  final int itemCount;
  final VoidCallback onTap;
  final double size;

  const _CartIconButton({
    required this.itemCount,
    required this.onTap,
    this.size = 38,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(
                Icons.shopping_cart_outlined,
                size: 20,
                color: Color(0xFF0F172A),
              ),
              if (itemCount > 0)
                Positioned(
                  top: 4,
                  right: 2,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      itemCount > 99 ? '99+' : itemCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
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
    );
  }
}
