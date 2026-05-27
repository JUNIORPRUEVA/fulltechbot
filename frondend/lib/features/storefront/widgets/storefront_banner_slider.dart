import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/storefront_helpers.dart';
import '../theme/storefront_theme.dart';
import 'storefront_smart_image.dart';

class StorefrontBannerSlider extends StatefulWidget {
  final List<dynamic> banners;
  final Color? primaryColor;
  final Color? secondaryColor;

  const StorefrontBannerSlider({
    super.key,
    required this.banners,
    this.primaryColor,
    this.secondaryColor,
  });

  @override
  State<StorefrontBannerSlider> createState() => _StorefrontBannerSliderState();
}

class _StorefrontBannerSliderState extends State<StorefrontBannerSlider> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.banners.length > 1) {
      _startAutoPlay();
    }
  }

  void _startAutoPlay() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!_pageController.hasClients) {
        return;
      }

      final nextPage = (_currentPage + 1) % widget.banners.length;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 320,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.banners.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) {
              return _BannerItem(
                banner: widget.banners[index],
                primaryColor: widget.primaryColor,
                secondaryColor: widget.secondaryColor,
              );
            },
          ),
          if (widget.banners.length > 1)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.banners.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 280),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: index == _currentPage ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: index == _currentPage
                          ? (widget.secondaryColor ?? const Color(0xFF2563EB))
                          : Colors.white.withValues(alpha: 0.45),
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

class _BannerItem extends StatelessWidget {
  final dynamic banner;
  final Color? primaryColor;
  final Color? secondaryColor;

  const _BannerItem({
    required this.banner,
    this.primaryColor,
    this.secondaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = StorefrontHelpers.resolveMediaUrl(
      banner['imagen_url'] ?? banner['imageUrl'] ?? banner['image'],
    );
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;
    final title =
        banner['titulo']?.toString().trim().isNotEmpty == true
        ? banner['titulo'].toString().trim()
        : 'Tecnología y seguridad para tu hogar y negocio';
    final subtitle =
        banner['subtitulo']?.toString().trim().isNotEmpty == true
        ? banner['subtitulo'].toString().trim()
        : 'Cámaras, automatización y soporte técnico con instalación profesional.';
    final cta =
        banner['boton_texto']?.toString().trim().isNotEmpty == true
        ? banner['boton_texto'].toString().trim()
        : 'Ver ofertas';
    final primary = primaryColor ?? const Color(0xFF0F172A);
    final secondary = secondaryColor ?? const Color(0xFF2563EB);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: hasImage
            ? null
            : LinearGradient(
                colors: [primary, secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        boxShadow: StorefrontShadows.strong,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasImage)
            StorefrontSmartImage(
              source: imageUrl,
              fit: BoxFit.cover,
              placeholder: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primary, secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withValues(alpha: hasImage ? 0.58 : 0.1),
                  Colors.black.withValues(alpha: hasImage ? 0.18 : 0.02),
                ],
                begin: Alignment.bottomLeft,
                end: Alignment.topRight,
              ),
            ),
          ),
          Positioned(
            top: 22,
            right: 22,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.18),
                ),
              ),
              child: Text(
                'FULLTECH SRL',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.92),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Instalación profesional',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.96),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 10),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Text(
                    subtitle,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.88),
                      fontSize: 15,
                      height: 1.45,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: (banner['link_url'] != null &&
                          banner['link_url'].toString().trim().isNotEmpty)
                      ? () => launchUrl(Uri.parse(banner['link_url'].toString()))
                      : null,
                  child: Text(
                    cta,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
          if (!hasImage)
            Positioned(
              right: -40,
              bottom: -20,
              child: IgnorePointer(
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
