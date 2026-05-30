import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/storefront_helpers.dart';
import 'storefront_smart_image.dart';

/// Slider principal limpio y profesional.
/// Solo muestra: imagen, título, descripción, precio/oferta, botón CTA e indicadores.
/// NO incluye nombre de empresa, buscador ni carrito (van en el AppBar).
class StorefrontHeroSlider extends StatefulWidget {
  final String slug;
  final Color primaryColor;
  final Color secondaryColor;
  final List<dynamic> banners;
  final List<dynamic> promotedProducts;
  final bool isDesktop;
  final VoidCallback onSearchTap;
  final VoidCallback onCategoriesTap;
  final VoidCallback onOffersTap;

  const StorefrontHeroSlider({
    super.key,
    required this.slug,
    required this.primaryColor,
    required this.secondaryColor,
    required this.banners,
    required this.promotedProducts,
    required this.isDesktop,
    required this.onSearchTap,
    required this.onCategoriesTap,
    required this.onOffersTap,
  });

  @override
  State<StorefrontHeroSlider> createState() => _StorefrontHeroSliderState();
}

class _StorefrontHeroSliderState extends State<StorefrontHeroSlider> {
  late final PageController _pageController;
  Timer? _autoSlideTimer;
  int _currentIndex = 0;

  static const List<Map<String, String>> _fallbackCopy = [
    {
      'titulo': 'Tecnología para tu hogar y empresa',
      'subtitulo': 'Cámaras, motores, computadoras y más',
      'cta': 'Ver ofertas',
      'action': 'offers',
    },
    {
      'titulo': 'Soluciones profesionales',
      'subtitulo': 'Sistemas de seguridad, software e instalación',
      'cta': 'Explorar',
      'action': 'categories',
    },
    {
      'titulo': 'Compra fácil y seguro',
      'subtitulo': 'Atención personalizada y entrega rápida',
      'cta': 'Buscar productos',
      'action': 'search',
    },
  ];

  List<Map<String, dynamic>> get _slides {
    final productSlides = widget.promotedProducts
        .whereType<Map>()
        .map((item) => _mapProductSlide(Map<String, dynamic>.from(item)))
        .where(
          (item) => (item['imagen_resuelta']?.toString().trim() ?? '').isNotEmpty,
        )
        .toList();
    if (productSlides.isNotEmpty) {
      return productSlides;
    }

    final bannerSlides = widget.banners
        .whereType<Map>()
        .map((item) => _normalizeSlide(Map<String, dynamic>.from(item)))
        .toList();
    if (bannerSlides.isNotEmpty) {
      return bannerSlides;
    }

    return List.generate(3, (index) {
      final copy = _fallbackCopy[index];
      return {
        'titulo': copy['titulo'],
        'subtitulo': copy['subtitulo'],
        'boton_texto': copy['cta'],
        'cta_action': copy['action'],
      };
    });
  }

  Map<String, dynamic> _normalizeSlide(Map<String, dynamic> raw) {
    final index = _slidesSeedIndex(raw);
    final copy = _fallbackCopy[index % _fallbackCopy.length];
    final version =
        raw['actualizadoEn']?.toString() ?? raw['updatedAt']?.toString();
    final image = StorefrontHelpers.normalizeImageUrl(
      raw['imagen_url'] ?? raw['imagen'] ?? raw['imageUrl'] ?? raw['image'],
      version: version,
    );

    return {
      ...raw,
      'titulo': _takeText(raw['titulo'], raw['title'], null, copy['titulo']!),
      'subtitulo': _takeText(
        raw['subtitulo'],
        raw['subtitle'],
        raw['descripcion'],
        copy['subtitulo']!,
      ),
      'boton_texto': _takeText(
        raw['boton_texto'],
        raw['cta_texto'],
        raw['buttonText'],
        copy['cta']!,
      ),
      'cta_action': _takeText(raw['cta_action'], null, null, copy['action']!),
      'imagen_resuelta': image,
      'cta_url': raw['cta_url'] ?? raw['link_url'],
    };
  }

  Map<String, dynamic> _mapProductSlide(Map<String, dynamic> product) {
    final index =
        product['orden'] is num ? (product['orden'] as num).toInt() : 0;
    final copy = _fallbackCopy[index % _fallbackCopy.length];
    final productId = product['id']?.toString();
    final price = StorefrontHelpers.getDisplayPrice(product);
    final originalPrice = StorefrontHelpers.getOriginalPrice(product);

    return {
      'titulo': _takeText(product['titulo'], null, null, copy['titulo']!),
      'subtitulo': _takeText(
        product['descripcion_web'],
        product['descripcion'],
        null,
        copy['subtitulo']!,
      ),
      'precio': price,
      'precio_original': originalPrice,
      'boton_texto': price != null && price > 0 ? 'Ver oferta' : copy['cta'],
      'cta_action':
          productId != null && productId.isNotEmpty ? 'product' : copy['action'],
      'cta_url': productId != null && productId.isNotEmpty
          ? '/tienda/${widget.slug}/producto/$productId'
          : null,
      'imagen_resuelta': StorefrontHelpers.getPrimaryImage(product),
    };
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1);
    _restartAutoplay();
  }

  @override
  void didUpdateWidget(covariant StorefrontHeroSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.banners != widget.banners ||
        oldWidget.promotedProducts != widget.promotedProducts) {
      _currentIndex = 0;
      _restartAutoplay();
    }
  }

  void _restartAutoplay() {
    _autoSlideTimer?.cancel();
    if (_slides.length <= 1) return;

    _autoSlideTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_pageController.hasClients) return;
      final nextPage = (_currentIndex + 1) % _slides.length;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeInOutCubic,
      );
    });
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
    final height = widget.isDesktop
        ? 420.0
        : (screenHeight * 0.38).clamp(280.0, 380.0);

    return SizedBox(
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.isDesktop ? 34 : 24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // PageView con las slides
            PageView.builder(
              controller: _pageController,
              padEnds: false,
              itemCount: _slides.length,
              onPageChanged: (index) => setState(() => _currentIndex = index),
              itemBuilder: (context, index) {
                final slide = _slides[index];
                return TweenAnimationBuilder<double>(
                  key: ValueKey('hero-slide-$index'),
                  duration: const Duration(milliseconds: 420),
                  tween: Tween(begin: 1.035, end: 1),
                  curve: Curves.easeOutCubic,
                  builder: (context, scale, child) {
                    return Transform.scale(scale: scale, child: child);
                  },
                  child: _HeroSlideBackground(
                    slide: slide,
                    primaryColor: widget.primaryColor,
                    secondaryColor: widget.secondaryColor,
                  ),
                );
              },
            ),

            // Gradiente oscuro suave en la parte inferior para legibilidad
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.08),
                        Colors.black.withValues(alpha: 0.06),
                        Colors.black.withValues(alpha: 0.22),
                        Colors.black.withValues(alpha: 0.58),
                      ],
                      stops: const [0, 0.3, 0.6, 1],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
            ),

            // Contenido del slide (solo texto, precio y botón)
            Positioned(
              left: widget.isDesktop ? 28 : 16,
              right: widget.isDesktop ? 28 : 16,
              bottom: widget.isDesktop ? 24 : 16,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 360),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  final offset = Tween<Offset>(
                    begin: const Offset(0.06, 0),
                    end: Offset.zero,
                  ).animate(animation);
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(position: offset, child: child),
                  );
                },
                child: _HeroSlideContent(
                  key: ValueKey(
                    'slide-content-$_currentIndex-${_slides[_currentIndex]['titulo']}',
                  ),
                  slide: _slides[_currentIndex],
                  isDesktop: widget.isDesktop,
                  currentIndex: _currentIndex,
                  totalSlides: _slides.length,
                  primaryColor: widget.primaryColor,
                  onIndicatorTap: _goToPage,
                  onCtaTap: () => _handleSlideAction(_slides[_currentIndex]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _goToPage(int page) {
    if (!_pageController.hasClients) return;
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _handleSlideAction(Map<String, dynamic> slide) async {
    final action = slide['cta_action']?.toString().trim().toLowerCase() ?? '';
    final url = slide['cta_url']?.toString().trim() ?? '';

    if (url.isNotEmpty) {
      if (url.startsWith('/')) {
        if (!mounted) return;
        Navigator.pushNamed(context, url);
        return;
      }

      final uri = Uri.tryParse(url);
      if (uri != null) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
        return;
      }
    }

    switch (action) {
      case 'search':
        widget.onSearchTap();
        return;
      case 'categories':
        widget.onCategoriesTap();
        return;
      case 'product':
      case 'offers':
      default:
        widget.onOffersTap();
    }
  }

  int _slidesSeedIndex(Map<String, dynamic> slide) {
    final raw = slide['id']?.toString() ?? slide['titulo']?.toString() ?? '';
    if (raw.isEmpty) return 0;
    return raw.codeUnits.fold<int>(0, (sum, item) => sum + item);
  }

  String _takeText(dynamic a, [dynamic b, dynamic c, String fallback = '']) {
    for (final value in [a, b, c]) {
      final clean = value?.toString().trim() ?? '';
      if (clean.isNotEmpty && clean.toLowerCase() != 'null') {
        return clean;
      }
    }
    return fallback;
  }
}

/// Contenido del slide: título, descripción, precio, botón CTA e indicadores
class _HeroSlideContent extends StatelessWidget {
  final Map<String, dynamic> slide;
  final bool isDesktop;
  final int currentIndex;
  final int totalSlides;
  final Color primaryColor;
  final ValueChanged<int> onIndicatorTap;
  final VoidCallback onCtaTap;

  const _HeroSlideContent({
    super.key,
    required this.slide,
    required this.isDesktop,
    required this.currentIndex,
    required this.totalSlides,
    required this.primaryColor,
    required this.onIndicatorTap,
    required this.onCtaTap,
  });

  @override
  Widget build(BuildContext context) {
    final title = slide['titulo']?.toString() ?? '';
    final subtitle = slide['subtitulo']?.toString() ?? '';
    final price = slide['precio'];
    final originalPrice = slide['precio_original'];
    final ctaText = slide['boton_texto']?.toString() ?? 'Ver más';
    final hasPrice = price != null && (price is num && price > 0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título
        ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isDesktop ? 560 : 260,
          ),
          child: Text(
            title,
            maxLines: isDesktop ? 2 : 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontSize: isDesktop ? 30 : 20,
              fontWeight: FontWeight.w900,
              height: 1.08,
              letterSpacing: isDesktop ? -0.8 : -0.2,
            ),
          ),
        ),
        const SizedBox(height: 6),

        // Descripción
        ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isDesktop ? 480 : 250,
          ),
          child: Text(
            subtitle,
            maxLines: isDesktop ? 2 : 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: isDesktop ? 14 : 11.5,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
        ),

        // Precio (si aplica)
        if (hasPrice) ...[
          const SizedBox(height: 8),
          _SlidePrice(
            price: price,
            originalPrice: originalPrice,
            isDesktop: isDesktop,
          ),
        ],

        const SizedBox(height: 10),

        // Botón CTA + Indicadores
        Row(
          children: [
            _SlideCtaButton(
              label: ctaText,
              isDesktop: isDesktop,
              onTap: onCtaTap,
            ),
            const Spacer(),
            _SlideIndicators(
              currentIndex: currentIndex,
              totalSlides: totalSlides,
              onTap: onIndicatorTap,
            ),
          ],
        ),
      ],
    );
  }
}

/// Precio del slide
class _SlidePrice extends StatelessWidget {
  final dynamic price;
  final dynamic originalPrice;
  final bool isDesktop;

  const _SlidePrice({
    required this.price,
    this.originalPrice,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    final hasOffer = originalPrice != null &&
        (originalPrice is num && originalPrice > 0) &&
        (price is num) &&
        originalPrice > price;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'RD\$${(price as num).toStringAsFixed(0)}',
          style: TextStyle(
            color: Colors.white,
            fontSize: isDesktop ? 26 : 20,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            height: 1,
          ),
        ),
        if (hasOffer) ...[
          const SizedBox(width: 8),
          Text(
            'RD\$${(originalPrice as num).toStringAsFixed(0)}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: isDesktop ? 15 : 12,
              decoration: TextDecoration.lineThrough,
              decorationColor: Colors.white.withValues(alpha: 0.6),
              fontWeight: FontWeight.w600,
              height: 1,
            ),
          ),
        ],
      ],
    );
  }
}

/// Botón CTA del slide
class _SlideCtaButton extends StatelessWidget {
  final String label;
  final bool isDesktop;
  final VoidCallback onTap;

  const _SlideCtaButton({
    required this.label,
    required this.isDesktop,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.22),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 20 : 14,
            vertical: isDesktop ? 10 : 8,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isDesktop ? 14 : 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: isDesktop ? 16 : 14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Indicadores de página del slider
class _SlideIndicators extends StatelessWidget {
  final int currentIndex;
  final int totalSlides;
  final ValueChanged<int> onTap;

  const _SlideIndicators({
    required this.currentIndex,
    required this.totalSlides,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (totalSlides <= 1) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(totalSlides, (index) {
        final active = index == currentIndex;
        return GestureDetector(
          onTap: () => onTap(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            margin: EdgeInsets.only(right: index == totalSlides - 1 ? 0 : 5),
            width: active ? 18 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: active
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        );
      }),
    );
  }
}

/// Fondo del slide con imagen
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
    final resolved = slide['imagen_resuelta']?.toString() ??
        StorefrontHelpers.normalizeImageUrl(
          slide['imagen_url'] ?? slide['imagen'] ?? slide['imageUrl'],
        );

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
              top: -26,
              right: -18,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.10),
                ),
              ),
            ),
            Positioned(
              left: 20,
              bottom: 22,
              child: Icon(
                Icons.videocam_outlined,
                size: 104,
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
