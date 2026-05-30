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
    if (widget.banners.isNotEmpty) {
      return widget.banners
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    if (widget.promotedProducts.isNotEmpty) {
      return widget.promotedProducts
          .whereType<Map>()
          .map((item) => _mapProductSlide(Map<String, dynamic>.from(item)))
          .toList();
    }

    return [
      {
        'titulo': widget.heroTitle,
        'subtitulo': widget.heroSubtitle,
        'badge': 'Fulltech SRL',
      },
    ];
  }

  Map<String, dynamic> _mapProductSlide(Map<String, dynamic> product) {
    return {
      'titulo': product['titulo']?.toString() ?? widget.heroTitle,
      'subtitulo':
          product['descripcion_web']?.toString().trim().isNotEmpty == true
              ? product['descripcion_web'].toString().trim()
              : widget.heroSubtitle,
      'imagen_url': StorefrontHelpers.getPrimaryImage(product),
      'badge': product['categoria']?.toString() ?? 'Producto destacado',
      'cta_texto': 'Ver producto',
      'cta_url': '/tienda/${widget.slug}/producto/${product['id']}',
    };
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
          duration: const Duration(milliseconds: 460),
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
    final screenHeight = MediaQuery.sizeOf(context).height;
    final screenWidth = MediaQuery.sizeOf(context).width;
    // En móvil: 45% del alto de pantalla, mínimo 280px, máximo 380px
    final height = widget.isDesktop
        ? 350.0
        : (screenHeight * 0.45).clamp(280.0, 380.0);

    return SizedBox(
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.isDesktop ? 34 : 26),
          boxShadow: StorefrontShadows.surface,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.isDesktop ? 34 : 26),
          child: Stack(
            fit: StackFit.expand,
            children: [
              PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (index) =>
                    setState(() => _currentIndex = index),
                itemBuilder: (context, index) {
                  return _HeroSlideBackground(
                    slide: _slides[index],
                    primaryColor: widget.primaryColor,
                    secondaryColor: widget.secondaryColor,
                  );
                },
              ),
              // Overlay gradient SUAVE - no tapa la imagen
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withValues(alpha: 0.45),
                          Colors.transparent,
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.25),
                        ],
                        stops: const [0, 0.25, 0.65, 1],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                  ),
                ),
              ),
              // Contenido
              Padding(
                padding: EdgeInsets.all(widget.isDesktop ? 24 : 14),
                child: widget.isDesktop
                    ? _DesktopHeroOverlay(
                        slide: _slides[_currentIndex],
                        currentIndex: _currentIndex,
                        totalSlides: _slides.length,
                        primaryColor: widget.primaryColor,
                        onCategoriesTap: widget.onCategoriesTap,
                        onOffersTap: widget.onOffersTap,
                      )
                    : _MobileHeroOverlay(
                        slide: _slides[_currentIndex],
                        currentIndex: _currentIndex,
                        totalSlides: _slides.length,
                        primaryColor: widget.primaryColor,
                        onCategoriesTap: widget.onCategoriesTap,
                        onOffersTap: widget.onOffersTap,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MobileHeroOverlay extends StatelessWidget {
  final Map<String, dynamic> slide;
  final int currentIndex;
  final int totalSlides;
  final Color primaryColor;
  final VoidCallback onCategoriesTap;
  final VoidCallback onOffersTap;

  const _MobileHeroOverlay({
    required this.slide,
    required this.currentIndex,
    required this.totalSlides,
    required this.primaryColor,
    required this.onCategoriesTap,
    required this.onOffersTap,
  });

  @override
  Widget build(BuildContext context) {
    final title = slide['titulo']?.toString().trim().isNotEmpty == true
        ? slide['titulo'].toString().trim()
        : 'Tecnologia premium para tu negocio';
    final subtitle = slide['subtitulo']?.toString().trim().isNotEmpty == true
        ? slide['subtitulo'].toString().trim()
        : 'Compra rapido, compara facil y recibe soporte profesional.';
    final badge = slide['badge']?.toString().trim().isNotEmpty == true
        ? slide['badge'].toString().trim()
        : 'Fulltech SRL';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Badge + indicadores arriba
        Row(
          children: [
            _HeroBadge(label: badge),
            const Spacer(),
            _Indicators(currentIndex: currentIndex, totalSlides: totalSlides),
          ],
        ),
        const Spacer(),
        // Título - más pequeño en móvil
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w900,
            height: 1.05,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        // Subtítulo
        Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.90),
            fontSize: 12,
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 10),
        // Botones de acción - SOLO en el slider, NO repetir fuera
        Row(
          children: [
            _HeroMiniButton(
              icon: Icons.local_offer_outlined,
              label: 'Ofertas',
              onTap: onOffersTap,
            ),
            const SizedBox(width: 8),
            _HeroMiniButton(
              icon: Icons.grid_view_rounded,
              label: 'Categorías',
              onTap: onCategoriesTap,
            ),
          ],
        ),
      ],
    );
  }
}

class _DesktopHeroOverlay extends StatelessWidget {
  final Map<String, dynamic> slide;
  final int currentIndex;
  final int totalSlides;
  final Color primaryColor;
  final VoidCallback onCategoriesTap;
  final VoidCallback onOffersTap;

  const _DesktopHeroOverlay({
    required this.slide,
    required this.currentIndex,
    required this.totalSlides,
    required this.primaryColor,
    required this.onCategoriesTap,
    required this.onOffersTap,
  });

  @override
  Widget build(BuildContext context) {
    final title = slide['titulo']?.toString().trim().isNotEmpty == true
        ? slide['titulo'].toString().trim()
        : 'Fulltech marketplace';
    final subtitle = slide['subtitulo']?.toString().trim().isNotEmpty == true
        ? slide['subtitulo'].toString().trim()
        : 'Tecnologia, seguridad y automatizacion con presentacion premium.';
    final badge = slide['badge']?.toString().trim().isNotEmpty == true
        ? slide['badge'].toString().trim()
        : 'Fulltech SRL';

    return Row(
      children: [
        Expanded(
          flex: 11,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _HeroBadge(label: badge),
              const SizedBox(height: 16),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                  height: 1.02,
                  letterSpacing: -1.2,
                ),
              ),
              const SizedBox(height: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    height: 1.45,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  _HeroMiniButton(
                    icon: Icons.local_offer_outlined,
                    label: 'Ver ofertas',
                    onTap: onOffersTap,
                  ),
                  const SizedBox(width: 10),
                  _HeroMiniButton(
                    icon: Icons.grid_view_rounded,
                    label: 'Explorar categorías',
                    onTap: onCategoriesTap,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _Indicators(currentIndex: currentIndex, totalSlides: totalSlides),
            ],
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          flex: 8,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: StorefrontSmartImage(
                source: slide['imagen_url'] ?? slide['imagen'],
                fit: BoxFit.contain,
                placeholder: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.inventory_2_outlined,
                      size: 72,
                      color: primaryColor.withValues(alpha: 0.80),
                    ),
                  ),
                ),
              ),
            ),
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
    final rawImage = slide['imagen_url'] ?? slide['imagen'] ?? slide['imageUrl'];
    final resolved = StorefrontHelpers.resolveMediaUrl(rawImage);

    if (resolved == null || resolved.isEmpty) {
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
              right: 18,
              top: 18,
              child: Icon(
                Icons.shield_outlined,
                size: 120,
                color: Colors.white.withValues(alpha: 0.10),
              ),
            ),
            Positioned(
              left: 14,
              bottom: 12,
              child: Icon(
                Icons.videocam_outlined,
                size: 92,
                color: Colors.white.withValues(alpha: 0.10),
              ),
            ),
          ],
        ),
      );
    }

    return StorefrontSmartImage(source: resolved, fit: BoxFit.cover);
  }
}

class _HeroBadge extends StatelessWidget {
  final String label;

  const _HeroBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _HeroMiniButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _HeroMiniButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Indicators extends StatelessWidget {
  final int currentIndex;
  final int totalSlides;

  const _Indicators({
    required this.currentIndex,
    required this.totalSlides,
  });

  @override
  Widget build(BuildContext context) {
    if (totalSlides <= 1) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(totalSlides, (index) {
        final active = index == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: EdgeInsets.only(right: index == totalSlides - 1 ? 0 : 6),
          width: active ? 18 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.white.withValues(alpha: 0.36),
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}
