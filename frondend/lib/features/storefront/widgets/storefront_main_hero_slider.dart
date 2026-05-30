import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/storefront_helpers.dart';
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
  Timer? _cartCheckTimer;
  int _currentIndex = 0;
  int _cartItemCount = 0;

  static const List<Map<String, String>> _fallbackCopy = [
    {
      'titulo': 'Tienda oficial FULLTECH SRL',
      'subtitulo': 'Productos, ofertas y soluciones para hogar, empresa y proyectos',
      'badge': 'FULLTECH SRL',
      'cta': 'Ver ofertas',
      'action': 'offers',
    },
    {
      'titulo': 'Compra facil desde un solo lugar',
      'subtitulo': 'Explora categorias, productos y promociones de FULLTECH',
      'badge': 'Tienda general',
      'cta': 'Buscar productos',
      'action': 'search',
    },
    {
      'titulo': 'Atencion profesional y entrega rapida',
      'subtitulo': 'Soporte, tienda fisica y acompanamiento en cada compra',
      'badge': 'Soporte profesional',
      'cta': 'Cotizar ahora',
      'action': 'categories',
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
        'badge': copy['badge'],
        'boton_texto': copy['cta'],
        'cta_action': copy['action'],
      };
    });
  }

  Map<String, dynamic> _normalizeSlide(Map<String, dynamic> raw) {
    final index = _slidesSeedIndex(raw);
    final copy = _fallbackCopy[index % _fallbackCopy.length];
    final version = raw['actualizadoEn']?.toString() ?? raw['updatedAt']?.toString();
    final image = StorefrontHelpers.normalizeImageUrl(
      raw['imagen_url'] ?? raw['imagen'] ?? raw['imageUrl'] ?? raw['image'],
      version: version,
    );

    return {
      ...raw,
      'titulo': _takeText(
        raw['titulo'],
        raw['title'],
        null,
        copy['titulo']!,
      ),
      'subtitulo': _takeText(
        raw['subtitulo'],
        raw['subtitle'],
        raw['descripcion'],
        copy['subtitulo']!,
      ),
      'badge': _takeText(raw['badge'], raw['tag'], null, copy['badge']!),
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
    final index = product['orden'] is num
        ? (product['orden'] as num).toInt()
        : 0;
    final copy = _fallbackCopy[index % _fallbackCopy.length];
    final productId = product['id']?.toString();

    return {
      'titulo': _takeText(product['titulo'], null, null, copy['titulo']!),
      'subtitulo': _takeText(
        product['descripcion_web'],
        product['descripcion'],
        null,
        copy['subtitulo']!,
      ),
      'badge': _takeText(
        product['categoria'],
        null,
        null,
        copy['badge']!,
      ),
      'boton_texto': _offerCta(product, copy['cta']!),
      'cta_action': productId != null && productId.isNotEmpty ? 'product' : copy['action'],
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
    _startCartPolling();
  }

  @override
  void didUpdateWidget(covariant StorefrontMainHeroSlider oldWidget) {
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
    _cartCheckTimer?.cancel();
    _pageController.dispose();
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
      if (cartData == null) {
        if (_cartItemCount != 0 && mounted) {
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
      if (count != _cartItemCount && mounted) {
        setState(() => _cartItemCount = count);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final height = widget.isDesktop
        ? 420.0
        : (screenHeight * 0.43).clamp(320.0, 420.0);

    return SizedBox(
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.isDesktop ? 34 : 28),
        child: Stack(
          fit: StackFit.expand,
          children: [
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
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: widget.isDesktop ? 0.22 : 0.12),
                        Colors.black.withValues(alpha: widget.isDesktop ? 0.18 : 0.08),
                        Colors.black.withValues(alpha: 0.28),
                        Colors.black.withValues(alpha: 0.68),
                      ],
                      stops: const [0, 0.36, 0.68, 1],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      widget.primaryColor.withValues(alpha: 0.24),
                      Colors.transparent,
                      widget.secondaryColor.withValues(alpha: 0.18),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                widget.isDesktop ? 28 : 16,
                widget.isDesktop ? 22 : 14,
                widget.isDesktop ? 28 : 16,
                widget.isDesktop ? 24 : 16,
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 360),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  final offset = Tween<Offset>(
                    begin: const Offset(0.08, 0),
                    end: Offset.zero,
                  ).animate(animation);
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(position: offset, child: child),
                  );
                },
                child: _HeroSlideOverlay(
                  key: ValueKey(
                    'overlay-$_currentIndex-${_slides[_currentIndex]['titulo']}',
                  ),
                  slide: _slides[_currentIndex],
                  isDesktop: widget.isDesktop,
                  currentIndex: _currentIndex,
                  totalSlides: _slides.length,
                  primaryColor: widget.primaryColor,
                  cartItemCount: _cartItemCount,
                  onSecondaryAction: widget.onSearchTap,
                  onCartTap: widget.onCartTap,
                  onMenuTap: widget.onMenuTap,
                  onIndicatorTap: _goToPage,
                  canPop: widget.canPop,
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

  String _offerCta(Map<String, dynamic> product, String fallback) {
    final offerPrice = product['precio_oferta_web'] ?? product['precioOferta'];
    return offerPrice != null ? 'Ver oferta' : fallback;
  }
}

class _HeroSlideOverlay extends StatelessWidget {
  final Map<String, dynamic> slide;
  final bool isDesktop;
  final int currentIndex;
  final int totalSlides;
  final Color primaryColor;
  final int cartItemCount;
  final VoidCallback onSecondaryAction;
  final VoidCallback onCartTap;
  final VoidCallback? onMenuTap;
  final ValueChanged<int> onIndicatorTap;
  final bool canPop;

  const _HeroSlideOverlay({
    super.key,
    required this.slide,
    required this.isDesktop,
    required this.currentIndex,
    required this.totalSlides,
    required this.primaryColor,
    required this.cartItemCount,
    required this.onSecondaryAction,
    required this.onCartTap,
    required this.onMenuTap,
    required this.onIndicatorTap,
    required this.canPop,
  });

  @override
  Widget build(BuildContext context) {
    final title = slide['titulo']?.toString() ?? '';
    final subtitle = slide['subtitulo']?.toString() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'FULLTECH',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.6,
              ),
            ),
            const Spacer(),
            _Indicators(
              currentIndex: currentIndex,
              totalSlides: totalSlides,
              onTap: onIndicatorTap,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _HeroSearchBar(
          primaryColor: primaryColor,
          onTap: onSecondaryAction,
        ),
        const Spacer(),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isDesktop ? 620 : 280),
          child: Text(
            title,
            maxLines: isDesktop ? 2 : 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontSize: isDesktop ? 34 : 22,
              fontWeight: FontWeight.w900,
              height: 1.06,
              letterSpacing: isDesktop ? -0.9 : -0.3,
            ),
          ),
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isDesktop ? 520 : 270),
          child: Text(
            subtitle,
            maxLines: isDesktop ? 2 : 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: isDesktop ? 14.5 : 11.5,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroSearchBar extends StatelessWidget {
  final Color primaryColor;
  final VoidCallback onTap;

  const _HeroSearchBar({
    required this.primaryColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.26),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.search_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Buscar productos',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.96),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.tune_rounded,
                  color: primaryColor.computeLuminance() > 0.65
                      ? const Color(0xFF0F172A)
                      : Colors.white,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
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
    final resolved =
        slide['imagen_resuelta']?.toString() ??
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

class _Indicators extends StatelessWidget {
  final int currentIndex;
  final int totalSlides;
  final ValueChanged<int> onTap;

  const _Indicators({
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
            margin: EdgeInsets.only(right: index == totalSlides - 1 ? 0 : 6),
            width: active ? 20 : 7,
            height: 7,
            decoration: BoxDecoration(
              color: active ? Colors.white : Colors.white.withValues(alpha: 0.34),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        );
      }),
    );
  }
}
