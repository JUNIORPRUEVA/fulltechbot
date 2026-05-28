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
  final List<dynamic> promotedProducts;
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
    required this.promotedProducts,
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
    if (widget.promotedProducts.isNotEmpty) {
      final productSlides = widget.promotedProducts
          .whereType<Map>()
          .map((item) => _mapProductSlide(Map<String, dynamic>.from(item)))
          .where(
            (item) =>
                (item['imagen_url']?.toString().trim().isNotEmpty ?? false),
          )
          .toList();
      if (productSlides.isNotEmpty) {
        return productSlides;
      }
    }

    if (widget.banners.isNotEmpty) {
      return widget.banners
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    return [
      {
        'titulo': widget.heroTitle,
        'subtitulo': widget.heroSubtitle,
        'imagen_url': null,
        'label': 'Flyer principal',
      },
    ];
  }

  Map<String, dynamic> _mapProductSlide(Map<String, dynamic> product) {
    final image =
        product['imagen_destacada_url'] ??
        product['imagen1'] ??
        product['imagen2'] ??
        product['imagen3'];
    final title = product['titulo']?.toString().trim();
    final category = product['categoria']?.toString().trim();
    final offerPrice = product['precio_oferta_web'] ?? product['precioOferta'];
    final description =
        product['descripcion_web']?.toString().trim().isNotEmpty == true
        ? product['descripcion_web'].toString().trim()
        : product['descripcion']?.toString().trim() ?? '';

    return {
      'titulo': title?.isNotEmpty == true ? title : widget.heroTitle,
      'subtitulo': description.isNotEmpty
          ? description
          : offerPrice != null
          ? 'Promocion activa en ${category?.isNotEmpty == true ? category : 'la tienda'}'
          : widget.heroSubtitle,
      'imagen_url': image,
      'label': offerPrice != null ? 'Oferta del dia' : 'Producto destacado',
    };
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    if (_slides.length > 1) {
      _autoSlideTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (!_pageController.hasClients) {
          return;
        }
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isDesktop = widget.isDesktop;
        final mobileAspectRatio = width < 360
            ? 1.05
            : width < 520
            ? 1.10
            : 1.16;
        final desktopHeight = width >= 1320 ? 560.0 : 520.0;
        final heroChild = DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(isDesktop ? 34 : 30),
            boxShadow: StorefrontShadows.strong,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(isDesktop ? 34 : 30),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Positioned.fill(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _slides.length,
                    onPageChanged: (index) {
                      if (mounted) {
                        setState(() => _currentIndex = index);
                      }
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
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xF20B1220),
                          widget.primaryColor.withValues(alpha: 0.90),
                          widget.secondaryColor.withValues(alpha: 0.72),
                        ],
                        stops: const [0, 0.56, 1],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: -30,
                  right: -18,
                  child: _GlowOrb(
                    size: isDesktop ? 220 : 160,
                    opacity: 0.12,
                  ),
                ),
                Positioned(
                  left: -54,
                  bottom: -72,
                  child: _GlowOrb(
                    size: isDesktop ? 240 : 180,
                    opacity: 0.08,
                  ),
                ),
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      isDesktop ? 28 : 18,
                      isDesktop ? 22 : 14,
                      isDesktop ? 28 : 18,
                      isDesktop ? 26 : 18,
                    ),
                    child: isDesktop
                        ? _DesktopHeroContent(
                            storeName: widget.storeName,
                            logoUrl: widget.logoUrl,
                            currentSlide: _slides[_currentIndex],
                            currentIndex: _currentIndex,
                            totalSlides: _slides.length,
                            primaryColor: widget.primaryColor,
                            secondaryColor: widget.secondaryColor,
                            canPop: widget.canPop,
                            onSearchTap: widget.onSearchTap,
                            onCartTap: widget.onCartTap,
                            onAdminTap: widget.onAdminTap,
                            onCategoriesTap: widget.onCategoriesTap,
                            onOffersTap: widget.onOffersTap,
                          )
                        : _MobileHeroContent(
                            width: width,
                            storeName: widget.storeName,
                            currentSlide: _slides[_currentIndex],
                            currentIndex: _currentIndex,
                            totalSlides: _slides.length,
                            canPop: widget.canPop,
                            onMenuTap: widget.onMenuTap,
                            onSearchTap: widget.onSearchTap,
                            onCartTap: widget.onCartTap,
                            onAdminTap: widget.onAdminTap,
                            onOffersTap: widget.onOffersTap,
                          ),
                  ),
                ),
              ],
            ),
          ),
        );

        return Padding(
          padding: const EdgeInsets.only(top: 10),
          child: isDesktop
              ? SizedBox(height: desktopHeight, child: heroChild)
              : AspectRatio(aspectRatio: mobileAspectRatio, child: heroChild),
        );
      },
    );
  }
}

class _MobileHeroContent extends StatelessWidget {
  final double width;
  final String storeName;
  final Map<String, dynamic> currentSlide;
  final int currentIndex;
  final int totalSlides;
  final bool canPop;
  final VoidCallback? onMenuTap;
  final VoidCallback onSearchTap;
  final VoidCallback onCartTap;
  final VoidCallback onAdminTap;
  final VoidCallback onOffersTap;

  const _MobileHeroContent({
    required this.width,
    required this.storeName,
    required this.currentSlide,
    required this.currentIndex,
    required this.totalSlides,
    required this.canPop,
    required this.onMenuTap,
    required this.onSearchTap,
    required this.onCartTap,
    required this.onAdminTap,
    required this.onOffersTap,
  });

  @override
  Widget build(BuildContext context) {
    final compactTopBar = width < 385;
    final titleSize = width < 360 ? 26.0 : width < 430 ? 29.0 : 32.0;
    final subtitleSize = width < 360 ? 13.0 : 14.0;
    final label =
        currentSlide['label']?.toString().trim().isNotEmpty == true
        ? currentSlide['label'].toString().trim()
        : 'Flyer principal';
    final title =
        currentSlide['titulo']?.toString().trim().isNotEmpty == true
        ? currentSlide['titulo'].toString().trim()
        : storeName;
    final subtitle =
        currentSlide['subtitulo']?.toString().trim().isNotEmpty == true
        ? currentSlide['subtitulo'].toString().trim()
        : 'Explora productos con entrega, soporte y garantia.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (onMenuTap != null) ...[
              _GlassIconButton(icon: Icons.menu_rounded, onTap: onMenuTap!),
              const SizedBox(width: 10),
            ],
            if (canPop) ...[
              _GlassIconButton(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(width: 10),
            ],
            if (!compactTopBar)
              Expanded(
                child: Text(
                  storeName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              )
            else
              const Spacer(),
            if (!compactTopBar) const SizedBox(width: 10),
            _GlassIconButton(
              icon: Icons.search_rounded,
              onTap: onSearchTap,
            ),
            const SizedBox(width: 8),
            _GlassIconButton(icon: Icons.person_outline_rounded, onTap: onAdminTap),
            const SizedBox(width: 8),
            _GlassIconButton(
              icon: Icons.shopping_cart_outlined,
              onTap: onCartTap,
            ),
          ],
        ),
        const Spacer(),
        _HeroLabel(label: label),
        const SizedBox(height: 12),
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white,
            fontSize: titleSize,
            fontWeight: FontWeight.w900,
            height: 1.02,
            letterSpacing: -0.9,
          ),
        ),
        const SizedBox(height: 10),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.88),
              fontSize: subtitleSize,
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(height: 14),
        const Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _TrustChip(icon: Icons.verified_outlined, label: 'Garantia'),
            _TrustChip(icon: Icons.support_agent_outlined, label: 'Soporte'),
            _TrustChip(icon: Icons.handyman_outlined, label: 'Instalacion'),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            FilledButton.icon(
              onPressed: onSearchTap,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF0F172A),
                minimumSize: const Size(0, 46),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.search_rounded, size: 18),
              label: const Text('Buscar productos'),
            ),
            OutlinedButton.icon(
              onPressed: onOffersTap,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 46),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.32)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.local_offer_outlined, size: 18),
              label: const Text('Ver ofertas'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _SliderIndicators(currentIndex: currentIndex, totalSlides: totalSlides),
      ],
    );
  }
}

class _DesktopHeroContent extends StatelessWidget {
  final String storeName;
  final dynamic logoUrl;
  final Map<String, dynamic> currentSlide;
  final int currentIndex;
  final int totalSlides;
  final Color primaryColor;
  final Color secondaryColor;
  final bool canPop;
  final VoidCallback onSearchTap;
  final VoidCallback onCartTap;
  final VoidCallback onAdminTap;
  final VoidCallback onCategoriesTap;
  final VoidCallback onOffersTap;

  const _DesktopHeroContent({
    required this.storeName,
    required this.logoUrl,
    required this.currentSlide,
    required this.currentIndex,
    required this.totalSlides,
    required this.primaryColor,
    required this.secondaryColor,
    required this.canPop,
    required this.onSearchTap,
    required this.onCartTap,
    required this.onAdminTap,
    required this.onCategoriesTap,
    required this.onOffersTap,
  });

  @override
  Widget build(BuildContext context) {
    final title =
        currentSlide['titulo']?.toString().trim().isNotEmpty == true
        ? currentSlide['titulo'].toString().trim()
        : storeName;
    final subtitle =
        currentSlide['subtitulo']?.toString().trim().isNotEmpty == true
        ? currentSlide['subtitulo'].toString().trim()
        : 'Explora el catalogo online con soporte comercial y garantia.';
    final label =
        currentSlide['label']?.toString().trim().isNotEmpty == true
        ? currentSlide['label'].toString().trim()
        : 'Flyer principal';

    return Column(
      children: [
        Row(
          children: [
            if (canPop) ...[
              _GlassIconButton(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(width: 12),
            ],
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(18),
              ),
              child: StorefrontSmartImage(
                source: logoUrl,
                fit: BoxFit.cover,
                borderRadius: BorderRadius.circular(18),
                placeholder: const Center(
                  child: Icon(
                    Icons.storefront_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
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
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Marketplace premium de tecnologia y seguridad',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.78),
                    ),
                  ),
                ],
              ),
            ),
            _NavPill(label: 'Categorias', onTap: onCategoriesTap),
            const SizedBox(width: 8),
            _NavPill(label: 'Ofertas', onTap: onOffersTap),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: onAdminTap,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.22)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text('Iniciar sesion'),
            ),
            const SizedBox(width: 8),
            _GlassIconButton(icon: Icons.search_rounded, onTap: onSearchTap),
            const SizedBox(width: 8),
            _GlassIconButton(
              icon: Icons.shopping_cart_outlined,
              onTap: onCartTap,
            ),
          ],
        ),
        const SizedBox(height: 28),
        Expanded(
          child: Row(
            children: [
              Expanded(
                flex: 11,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _HeroLabel(label: label),
                    const SizedBox(height: 16),
                    const Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _TrustChip(
                          icon: Icons.verified_outlined,
                          label: 'Garantia',
                        ),
                        _TrustChip(
                          icon: Icons.support_agent_outlined,
                          label: 'Soporte',
                        ),
                        _TrustChip(
                          icon: Icons.handyman_outlined,
                          label: 'Instalacion',
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 46,
                        fontWeight: FontWeight.w900,
                        height: 1.02,
                        letterSpacing: -1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.86),
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        FilledButton.icon(
                          onPressed: onSearchTap,
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: primaryColor,
                            minimumSize: const Size(0, 50),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          icon: const Icon(Icons.search_rounded),
                          label: const Text('Buscar productos'),
                        ),
                        OutlinedButton.icon(
                          onPressed: onOffersTap,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, 50),
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.28),
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
                    const SizedBox(height: 24),
                    _SliderIndicators(
                      currentIndex: currentIndex,
                      totalSlides: totalSlides,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 28),
              Expanded(
                flex: 9,
                child: _DesktopVisualPanel(
                  slide: currentSlide,
                  secondaryColor: secondaryColor,
                ),
              ),
            ],
          ),
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
              top: 28,
              child: Icon(
                Icons.shield_moon_outlined,
                size: 160,
                color: Colors.white.withValues(alpha: 0.10),
              ),
            ),
            Positioned(
              left: 26,
              bottom: 26,
              child: Icon(
                Icons.videocam_outlined,
                size: 120,
                color: Colors.white.withValues(alpha: 0.10),
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

class _DesktopVisualPanel extends StatelessWidget {
  final Map<String, dynamic> slide;
  final Color secondaryColor;

  const _DesktopVisualPanel({
    required this.slide,
    required this.secondaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final image = StorefrontHelpers.resolveMediaUrl(
      slide['imagen_url'] ?? slide['imagen'] ?? slide['imageUrl'],
    );
    final label =
        slide['label']?.toString().trim().isNotEmpty == true
        ? slide['label'].toString().trim()
        : 'Flyer principal';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.90),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.16),
                      Colors.white.withValues(alpha: 0.06),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: StorefrontSmartImage(
                  source: image,
                  fit: BoxFit.contain,
                  placeholder: Center(
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

class _HeroLabel extends StatelessWidget {
  final String label;

  const _HeroLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.95),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SliderIndicators extends StatelessWidget {
  final int currentIndex;
  final int totalSlides;

  const _SliderIndicators({
    required this.currentIndex,
    required this.totalSlides,
  });

  @override
  Widget build(BuildContext context) {
    if (totalSlides <= 1) {
      return const SizedBox.shrink();
    }

    return Row(
      children: List.generate(totalSlides, (index) {
        final isActive = index == currentIndex;
        return Padding(
          padding: EdgeInsets.only(right: index == totalSlides - 1 ? 0 : 7),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: isActive ? 20 : 7,
            height: 7,
            decoration: BoxDecoration(
              color: isActive
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.34),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        );
      }),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final double size;
  final double opacity;

  const _GlowOrb({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: opacity),
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

class _NavPill extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _NavPill({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _TrustChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _TrustChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.96),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
