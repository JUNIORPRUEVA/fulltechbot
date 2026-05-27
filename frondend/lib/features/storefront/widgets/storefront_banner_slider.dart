import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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
      if (_pageController.hasClients) {
        final nextPage = (_currentPage + 1) % widget.banners.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
        );
      }
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
    final screenWidth = MediaQuery.of(context).size.width;

    return SizedBox(
      height: 220,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemCount: widget.banners.length,
            itemBuilder: (context, index) {
              final banner = widget.banners[index];
              return _BannerItem(
                banner: banner,
                screenWidth: screenWidth,
                primaryColor: widget.primaryColor,
                secondaryColor: widget.secondaryColor,
              );
            },
          ),
          // Indicadores modernos
          if (widget.banners.length > 1)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.banners.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _currentPage ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: i == _currentPage
                          ? (widget.secondaryColor ?? const Color(0xFF2563EB))
                          : Colors.white.withValues(alpha: 0.5),
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
  final double screenWidth;
  final Color? primaryColor;
  final Color? secondaryColor;

  const _BannerItem({
    required this.banner,
    required this.screenWidth,
    this.primaryColor,
    this.secondaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = banner['imagen_url'] != null &&
        banner['imagen_url'].toString().isNotEmpty;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: (secondaryColor ?? const Color(0xFF2563EB)).withValues(alpha: 0.08),
        image: hasImage
            ? DecorationImage(
                image: NetworkImage(banner['imagen_url']),
                fit: BoxFit.cover,
              )
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              Colors.black.withValues(alpha: hasImage ? 0.45 : 0.0),
              Colors.transparent,
            ],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (banner['titulo'] != null)
              Text(
                banner['titulo'],
                style: TextStyle(
                  color: hasImage ? Colors.white : (primaryColor ?? const Color(0xFF0F172A)),
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
            if (banner['subtitulo'] != null) ...[
              const SizedBox(height: 6),
              Text(
                banner['subtitulo'],
                style: TextStyle(
                  color: hasImage
                      ? Colors.white.withValues(alpha: 0.9)
                      : const Color(0xFF6B7280),
                  fontSize: 14,
                  height: 1.3,
                ),
              ),
            ],
            if (banner['boton_texto'] != null) ...[
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  if (banner['link_url'] != null) {
                    launchUrl(Uri.parse(banner['link_url']));
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: hasImage
                      ? Colors.white
                      : (secondaryColor ?? const Color(0xFF2563EB)),
                  foregroundColor: hasImage
                      ? (primaryColor ?? const Color(0xFF0F172A))
                      : Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  banner['boton_texto'],
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
