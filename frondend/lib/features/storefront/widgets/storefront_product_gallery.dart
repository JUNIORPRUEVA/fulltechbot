import 'package:flutter/material.dart';

import '../theme/storefront_theme.dart';
import 'storefront_smart_image.dart';

class StorefrontProductGallery extends StatefulWidget {
  final List<String> images;
  final String title;
  final bool isDesktop;
  final Color accentColor;
  final String? version;

  const StorefrontProductGallery({
    super.key,
    required this.images,
    required this.title,
    required this.isDesktop,
    required this.accentColor,
    this.version,
  });

  @override
  State<StorefrontProductGallery> createState() =>
      _StorefrontProductGalleryState();
}

class _StorefrontProductGalleryState extends State<StorefrontProductGallery> {
  late final PageController _pageController;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant StorefrontProductGallery oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.images != widget.images) {
      _selectedIndex = 0;
      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
    } else if (_selectedIndex >= widget.images.length) {
      _selectedIndex = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasImages = widget.images.isNotEmpty;
    final radius = widget.isDesktop ? 28.0 : 22.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: StorefrontShadows.soft,
          ),
          child: AspectRatio(
            aspectRatio: widget.isDesktop ? 1 : 0.96,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (hasImages)
                    PageView.builder(
                      controller: _pageController,
                      itemCount: widget.images.length,
                      onPageChanged: (index) =>
                          setState(() => _selectedIndex = index),
                      itemBuilder: (context, index) {
                        final image = widget.images[index];
                        return GestureDetector(
                          onTap: () => _openImageViewer(context),
                          child: Padding(
                            padding: EdgeInsets.all(widget.isDesktop ? 26 : 16),
                            child: Hero(
                              tag: 'product-image-${widget.title}-$index',
                              child: StorefrontSmartImage(
                                source: image,
                                fit: BoxFit.contain,
                                placeholder: _GalleryPlaceholder(
                                  isDesktop: widget.isDesktop,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    )
                  else
                    const _GalleryPlaceholder(isDesktop: false),
                  if (hasImages && widget.images.length > 1)
                    Positioned(
                      right: 12,
                      bottom: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.60),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${_selectedIndex + 1}/${widget.images.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  if (hasImages)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: IconButton.filled(
                        onPressed: () => _openImageViewer(context),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.88),
                          foregroundColor: const Color(0xFF0F172A),
                        ),
                        icon: const Icon(Icons.zoom_out_map_rounded),
                        tooltip: 'Ver imagen grande',
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (hasImages && widget.images.length > 1)
          Column(
            children: [
              SizedBox(
                height: widget.isDesktop ? 92 : 78,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.images.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final active = index == _selectedIndex;
                    return GestureDetector(
                      onTap: () {
                        _pageController.animateToPage(
                          index,
                          duration: const Duration(milliseconds: 240),
                          curve: Curves.easeOutCubic,
                        );
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: widget.isDesktop ? 92 : 76,
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: active
                                ? widget.accentColor
                                : const Color(0xFFE5E7EB),
                            width: active ? 2 : 1,
                          ),
                          boxShadow: active ? StorefrontShadows.soft : null,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: StorefrontSmartImage(
                            source: widget.images[index],
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.images.length, (index) {
                  final active = index == _selectedIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: active ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: active
                          ? widget.accentColor
                          : widget.accentColor.withValues(alpha: 0.24),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  );
                }),
              ),
            ],
          )
        else if (!hasImages)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.photo_library_outlined,
                  size: 18,
                  color: Color(0xFF64748B),
                ),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'No hay mas imagenes disponibles',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _openImageViewer(BuildContext context) async {
    if (widget.images.isEmpty) return;

    await showGeneralDialog<void>(
      context: context,
      barrierLabel: 'Imagen del producto',
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.82),
      pageBuilder: (context, animation, secondaryAnimation) {
        return SafeArea(
          child: Material(
            color: Colors.transparent,
            child: Stack(
              children: [
                Center(
                  child: InteractiveViewer(
                    minScale: 0.8,
                    maxScale: 4.5,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Hero(
                        tag: 'product-image-${widget.title}-$_selectedIndex',
                        child: StorefrontSmartImage(
                          source: widget.images[_selectedIndex],
                          fit: BoxFit.contain,
                          placeholder:
                              const _GalleryPlaceholder(isDesktop: true, compact: false),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.15),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }
}

class _GalleryPlaceholder extends StatelessWidget {
  final bool isDesktop;
  final bool compact;

  const _GalleryPlaceholder({
    required this.isDesktop,
    this.compact = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF8FAFC), Color(0xFFEAF1F9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.image_outlined,
              size: compact ? (isDesktop ? 76 : 56) : 90,
              color: const Color(0xFFB6C2D4),
            ),
            const SizedBox(height: 12),
            const Text(
              'Imagen no disponible',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
