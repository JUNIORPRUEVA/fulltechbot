import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

class _StorefrontAppBarState extends State<StorefrontAppBar>
    with SingleTickerProviderStateMixin {
  int _cartItemCount = 0;
  bool _searchExpanded = false;
  int _previousCartCount = 0;

  late final AnimationController _cartBounceController;
  late final Animation<double> _cartBounceAnimation;

  @override
  void initState() {
    super.initState();
    _loadCartCount();

    _cartBounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _cartBounceAnimation =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.25), weight: 1),
          TweenSequenceItem(tween: Tween(begin: 1.25, end: 0.95), weight: 1),
          TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.0), weight: 1),
        ]).animate(
          CurvedAnimation(
            parent: _cartBounceController,
            curve: Curves.easeInOut,
          ),
        );
  }

  @override
  void dispose() {
    _cartBounceController.dispose();
    super.dispose();
  }

  Future<void> _loadCartCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionKey = 'storefront_session_${widget.slug}';
      final sessionId = prefs.getString(sessionKey);
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

      if (!mounted) return;
      if (count != _cartItemCount) {
        setState(() => _cartItemCount = count);
        if (count > _previousCartCount) {
          _cartBounceController.forward(from: 0);
        }
        _previousCartCount = count;
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
        child: SizedBox(
          height: isDesktop ? 60 : 54,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 24 : (isSmallScreen ? 8 : 12),
            ),
            child: Row(
              children: [
                _AppBarIconButton(
                  icon: Icons.menu_rounded,
                  onTap: widget.onMenuTap,
                  size: isSmallScreen ? 40 : 44,
                  iconSize: 22,
                ),
                if (!isSmallScreen) const SizedBox(width: 8),
                if (!_searchExpanded)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      'assets/logo_principal_small.png',
                      width: isDesktop ? 34 : 30,
                      height: isDesktop ? 34 : 30,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: isDesktop ? 34 : 30,
                        height: isDesktop ? 34 : 30,
                        decoration: BoxDecoration(
                          color: widget.primaryColor.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'F',
                          style: TextStyle(
                            color: widget.primaryColor,
                            fontWeight: FontWeight.w900,
                            fontSize: isDesktop ? 18 : 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                if (!isSmallScreen && !_searchExpanded)
                  const SizedBox(width: 10),
                if (!isSmallScreen && !_searchExpanded)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Text(
                      widget.storeName,
                      style: TextStyle(
                        fontSize: isDesktop ? 18 : 16,
                        fontWeight: FontWeight.w900,
                        color: widget.primaryColor,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                if (_searchExpanded)
                  Expanded(
                    child: Container(
                      height: 42,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: widget.primaryColor.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 14),
                          Icon(
                            Icons.search_rounded,
                            size: 20,
                            color: widget.primaryColor,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              autofocus: true,
                              decoration: const InputDecoration(
                                hintText: 'Buscar productos...',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                hintStyle: TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 15,
                                ),
                              ),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF0F172A),
                              ),
                              textInputAction: TextInputAction.search,
                              onSubmitted: (value) {
                                setState(() => _searchExpanded = false);
                                widget.onSearchTap();
                              },
                            ),
                          ),
                          SizedBox(
                            width: 40,
                            height: 40,
                            child: IconButton(
                              onPressed: () {
                                setState(() => _searchExpanded = false);
                              },
                              icon: const Icon(Icons.close_rounded, size: 20),
                              color: const Color(0xFF64748B),
                              padding: EdgeInsets.zero,
                              splashRadius: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  const Spacer(),
                if (!_searchExpanded)
                  _AppBarIconButton(
                    icon: Icons.search_rounded,
                    onTap: () {
                      setState(() => _searchExpanded = true);
                    },
                    size: isSmallScreen ? 40 : 44,
                    iconSize: 22,
                  ),
                if (!_searchExpanded) const SizedBox(width: 4),
                _CartIconButton(
                  itemCount: _cartItemCount,
                  onTap: widget.onCartTap,
                  size: isSmallScreen ? 40 : 44,
                  bounceAnimation: _cartBounceAnimation,
                ),
              ],
            ),
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
  final double iconSize;

  const _AppBarIconButton({
    required this.icon,
    required this.onTap,
    this.size = 44,
    this.iconSize = 22,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        splashColor: const Color(0xFF0F172A).withValues(alpha: 0.06),
        highlightColor: const Color(0xFF0F172A).withValues(alpha: 0.03),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFFE5EAF1).withValues(alpha: 0.5),
            ),
          ),
          child: Icon(icon, size: iconSize, color: const Color(0xFF0F172A)),
        ),
      ),
    );
  }
}

class _CartIconButton extends StatelessWidget {
  final int itemCount;
  final VoidCallback onTap;
  final double size;
  final Animation<double> bounceAnimation;

  const _CartIconButton({
    required this.itemCount,
    required this.onTap,
    this.size = 44,
    required this.bounceAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: bounceAnimation,
      builder: (context, child) {
        return Transform.scale(scale: bounceAnimation.value, child: child);
      },
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          splashColor: const Color(0xFF0F172A).withValues(alpha: 0.06),
          highlightColor: const Color(0xFF0F172A).withValues(alpha: 0.03),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFE5EAF1).withValues(alpha: 0.5),
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(
                  Icons.shopping_cart_outlined,
                  size: 22,
                  color: Color(0xFF0F172A),
                ),
                if (itemCount > 0)
                  Positioned(
                    top: 4,
                    right: 2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFFEF4444,
                            ).withValues(alpha: 0.4),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        itemCount > 99 ? '99+' : itemCount.toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
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
