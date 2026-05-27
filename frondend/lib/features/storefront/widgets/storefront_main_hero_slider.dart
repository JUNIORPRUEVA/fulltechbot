import 'dart:async';

import 'package:flutter/material.dart';

import '../services/storefront_helpers.dart';
import '../theme/storefront_theme.dart';
import 'storefront_smart_image.dart';

class StorefrontMainHeroSlider extends StatefulWidget {
  final String slug;
  final String storeName;
  final dynamic logoUrl;
  final Color primaryColor;
  final Color secondaryColor;
  final String heroTitle;
  final String heroSubtitle;
  final List<dynamic> banners;
  final bool isDesktop;
  final VoidCallback onSearchTap;
  final VoidCallback onCategoriesTap;
  final VoidCallback onOffersTap;
  final VoidCallback onAdminTap;
  final VoidCallback onCartTap;
  final VoidCallback? onMenuTap;
  final bool canPop;

  const StorefrontMainHeroSlider({
    super.key,
    required this.slug,
    required this.storeName,
    required this.logoUrl,
    required this.primaryColor,
    required this.secondaryColor,
    required this.heroTitle,
    required this.heroSubtitle,
    required this.banners,
    required this.isDesktop,
    required this.onSearchTap,
    required this.onCategoriesTap,
    required this.onOffersTap,
    required this.onAdminTap,
    required this.onCartTap,
    required this.canPop,
    this.onMenuTap,
  });

  @override
  State<StorefrontMainHeroSlider> createState() =>
      _StorefrontMainHeroSliderState();
}

class _StorefrontMainHeroSliderState extends State<StorefrontMainHeroSlider> {
  late final PageController _pageController;
  Timer? _autoSlideTimer;
  int _currentIndex = 0;

  List<Map<String, dynamic>> get _slides {
    if (widget.banners.isEmpty) {
      return const [
        {
          'titulo': 'FULLTECH SRL',
          'subtitulo': 'Tecnologia, seguridad y soporte profesional',
          'imagen_url': null,
        },
      ];
    }

    return widget.banners
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1);
    if (_slides.length > 1) {
      _autoSlideTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (!_pageController.hasClients) return;
        final nextPage = (_currentIndex + 1) % _slides.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutCubic,
        );
      });
    }
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final height = widget.isDesktop ? 620.0 : 580.0;

    return Container(
      height: height + topPadding,
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(34),
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (index) {
                  setState(() => _currentIndex = index);
                },
                itemBuilder: (context, index) {
                  return _HeroSlideBackground(
                    slide: _slides[index],
                    primaryColor: widget.primaryColor,
                    secondaryColor: widget.secondaryColor,
                  );
                },
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(34),
                gradient: LinearGradient(
                  colors: [
                    const Color(0xD90F172A),
                    widget.primaryColor.withValues(alpha: 0.86),
                    widget.secondaryColor.withValues(alpha: 0.72),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: StorefrontShadows.strong,
              ),
            ),
          ),
          Positioned(
            right: -40,
            top: 16,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
          ),
          Positioned(
            left: -48,
            bottom: -58,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(18, topPadding + 14, 18, 22),
            child: widget.isDesktop
                ? _buildDesktopContent(context)
                : _buildMobileContent(context),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HeroTopBar(
          storeName: widget.storeName,
          logoUrl: widget.logoUrl,
          canPop: widget.canPop,
          isDesktop: false,
          onAdminTap: widget.onAdminTap,
          onCartTap: widget.onCartTap,
          onSearchTap: widget.onSearchTap,
          onMenuTap: widget.onMenuTap,
        ),
        const Spacer(),
        _buildBody(context, includeSearchField: false),
      ],
    );
  }

  Widget _buildDesktopContent(BuildContext context) {
    return Column(
      children: [
        _HeroTopBar(
          storeName: widget.storeName,
          logoUrl: widget.logoUrl,
          canPop: widget.canPop,
          isDesktop: true,
          onAdminTap: widget.onAdminTap,
          onCartTap: widget.onCartTap,
          onSearchTap: widget.onSearchTap,
          onMenuTap: null,
          onCategoriesTap: widget.onCategoriesTap,
          onOffersTap: widget.onOffersTap,
        ),
        const SizedBox(height: 28),
        Expanded(
          child: Row(
            children: [
              Expanded(
                flex: 11,
                child: _buildBody(context, includeSearchField: true),
              ),
              const SizedBox(width: 26),
              Expanded(
                flex: 9,
                child: _DesktopVisualPanel(
                  slide: _slides[_currentIndex],
                  secondaryColor: widget.secondaryColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context, {required bool includeSearchField}) {
    final currentSlide = _slides[_currentIndex];
    final slideTitle = currentSlide['titulo']?.toString().trim();
    final slideSubtitle = currentSlide['subtitulo']?.toString().trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: const [
            _TrustChip(icon: Icons.verified_outlined, label: 'Garantia'),
            _TrustChip(icon: Icons.storefront_outlined, label: 'Tienda fisica'),
            _TrustChip(icon: Icons.support_agent_outlined, label: 'Soporte'),
            _TrustChip(icon: Icons.handyman_outlined, label: 'Instalacion'),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          slideTitle?.isNotEmpty == true ? slideTitle! : widget.heroTitle,
          maxLines: widget.isDesktop ? 3 : 4,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white,
            fontSize: widget.isDesktop ? 46 : 34,
            fontWeight: FontWeight.w900,
            height: 1.02,
            letterSpacing: -1.1,
          ),
        ),
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: widget.isDesktop ? 580 : 420),
          child: Text(
            slideSubtitle?.isNotEmpty == true
                ? slideSubtitle!
                : widget.heroSubtitle,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.88),
              fontSize: widget.isDesktop ? 16 : 15,
              height: 1.55,
            ),
          ),
        ),
        const SizedBox(height: 18),
        if (includeSearchField)
          _DesktopSearchField(onTap: widget.onSearchTap),
        if (includeSearchField) const SizedBox(height: 18),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton.icon(
              onPressed: widget.onSearchTap,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: widget.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              icon: const Icon(Icons.search_rounded),
              label: const Text('Buscar productos'),
            ),
            OutlinedButton.icon(
              onPressed: widget.onOffersTap,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(
                  color: Colors.white.withValues(alpha: 0.32),
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
        const SizedBox(height: 18),
        Row(
          children: [
            for (int index = 0; index < _slides.length; index++) ...[
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: _currentIndex == index ? 28 : 9,
                height: 9,
                decoration: BoxDecoration(
                  color: _currentIndex == index
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.34),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              if (index != _slides.length - 1) const SizedBox(width: 8),
            ],
          ],
        ),
      ],
    );
  }
}

class _HeroSlideBackground extends StatelessWidget {
  final Map<String, dynamic> slide;
  final Color primaryColor;
  final Color secondaryColor;

  const _HeroSlideBackground({
    required this.slide,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final image = StorefrontHelpers.resolveMediaUrl(
      slide['imagen_url'] ?? slide['imagen'] ?? slide['imageUrl'],
    );

    if (image == null) {
      return DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [primaryColor, secondaryColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: 24,
              top: 36,
              child: Icon(
                Icons.shield_moon_outlined,
                size: 180,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            Positioned(
              left: 24,
              bottom: 24,
              child: Icon(
                Icons.videocam_outlined,
                size: 130,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ],
        ),
      );
    }

    return StorefrontSmartImage(
      source: image,
      fit: BoxFit.cover,
      borderRadius: BorderRadius.circular(34),
    );
  }
}

class _HeroTopBar extends StatelessWidget {
  final String storeName;
  final dynamic logoUrl;
  final bool canPop;
  final bool isDesktop;
  final VoidCallback onSearchTap;
  final VoidCallback onCartTap;
  final VoidCallback onAdminTap;
  final VoidCallback? onMenuTap;
  final VoidCallback? onCategoriesTap;
  final VoidCallback? onOffersTap;

  const _HeroTopBar({
    required this.storeName,
    required this.logoUrl,
    required this.canPop,
    required this.isDesktop,
    required this.onSearchTap,
    required this.onCartTap,
    required this.onAdminTap,
    required this.onMenuTap,
    this.onCategoriesTap,
    this.onOffersTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (!isDesktop && onMenuTap != null)
          _GlassIconButton(
            icon: Icons.menu_rounded,
            onTap: onMenuTap!,
          ),
        if (!isDesktop && onMenuTap != null) const SizedBox(width: 10),
        if (canPop)
          _GlassIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: () => Navigator.of(context).maybePop(),
          ),
        if (canPop) const SizedBox(width: 10),
        Container(
          width: 50,
          height: 50,
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
                'Tienda online premium',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (isDesktop) ...[
          _NavPill(label: 'Categorias', onTap: onCategoriesTap),
          const SizedBox(width: 8),
          _NavPill(label: 'Ofertas', onTap: onOffersTap),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: onAdminTap,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(color: Colors.white.withValues(alpha: 0.26)),
            ),
          child: const Text('Iniciar sesion'),
          ),
          const SizedBox(width: 8),
        ],
        if (!isDesktop) ...[
          _GlassIconButton(
            icon: Icons.person_outline_rounded,
            onTap: onAdminTap,
          ),
          const SizedBox(width: 8),
        ],
        _GlassIconButton(
          icon: Icons.search_rounded,
          onTap: onSearchTap,
        ),
        const SizedBox(width: 8),
        _GlassIconButton(
          icon: Icons.shopping_cart_outlined,
          onTap: onCartTap,
        ),
      ],
    );
  }
}

class _DesktopVisualPanel extends StatelessWidget {
  final Map<String, dynamic> slide;
  final Color secondaryColor;

  const _DesktopVisualPanel({
    required this.slide,
    required this.secondaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final image = slide['imagen_url'] ?? slide['imagen'] ?? slide['imageUrl'];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Portada comercial',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.88),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: StorefrontSmartImage(
                source: image,
                fit: BoxFit.cover,
                placeholder: Container(
                  color: Colors.white.withValues(alpha: 0.06),
                  child: Center(
                    child: Icon(
                      Icons.storefront_outlined,
                      color: secondaryColor,
                      size: 78,
                    ),
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

class _DesktopSearchField extends StatelessWidget {
  final VoidCallback onTap;

  const _DesktopSearchField({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: const Row(
            children: [
              Icon(Icons.search_rounded, color: Color(0xFF64748B)),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Buscar productos, categorias o palabras clave',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(Icons.keyboard_arrow_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrustChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _TrustChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavPill extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _NavPill({required this.label, required this.onTap});

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

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GlassIconButton({
    required this.icon,
    required this.onTap,
  });

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
