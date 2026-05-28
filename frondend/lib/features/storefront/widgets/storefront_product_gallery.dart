import 'package:flutter/material.dart';

import '../theme/storefront_theme.dart';
import 'storefront_smart_image.dart';

class StorefrontProductGallery extends StatefulWidget {
  final List<String> images;
  final String title;
  final bool isDesktop;
  final Color accentColor;
  
  /// Versión del producto (updatedAt) para versionado de imágenes
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
  int _selectedIndex = 0;

  @override
  void didUpdateWidget(covariant StorefrontProductGallery oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_selectedIndex >= widget.images.length) {
      _selectedIndex = 0;
    }
    if (oldWidget.images != widget.images) {
      _selectedIndex = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasImages = widget.images.isNotEmpty;
    final selectedImage = hasImages ? widget.images[_selectedIndex] : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(widget.isDesktop ? 28 : 22),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: widget.isDesktop ? 560 : 360,
            ),
            child: AspectRatio(
              aspectRatio: 1,
              child: InkWell(
                borderRadius: BorderRadius.circular(widget.isDesktop ? 28 : 22),
                onTap: hasImages ? () => _openImageViewer(context) : null,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Padding(
                        padding: EdgeInsets.all(widget.isDesktop ? 28 : 14),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          child: hasImages
                              ? Hero(
                                  key: ValueKey(selectedImage),
                                  tag:
                                      'product-image-${widget.title}-$_selectedIndex',
                                  child: StorefrontSmartImage(
                                    source: selectedImage,
                                    fit: BoxFit.contain,
                                    placeholder: _GalleryPlaceholder(
                                      isDesktop: widget.isDesktop,
                                    ),
                                  ),
                                )
                              : _GalleryPlaceholder(
                                  key: const ValueKey('placeholder'),
                                  isDesktop: widget.isDesktop,
                                ),
                        ),
                      ),
                    ),
                    if (hasImages)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: StorefrontShadows.soft,
                          ),
                          child: IconButton(
                            onPressed: () => _openImageViewer(context),
                            icon: const Icon(Icons.zoom_out_map_rounded),
                            tooltip: 'Ver imagen grande',
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (hasImages)
          SizedBox(
            height: widget.isDesktop ? 92 : 80,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                final isActive = index == _selectedIndex;
                return GestureDetector(
                  onTap: () => setState(() => _selectedIndex = index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: widget.isDesktop ? 92 : 76,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isActive
                            ? widget.accentColor
                            : const Color(0xFFE5E7EB),
                        width: isActive ? 2 : 1,
                      ),
                      boxShadow: isActive ? StorefrontShadows.soft : null,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: StorefrontSmartImage(
                        source: widget.images[index],
                        fit: BoxFit.contain,
                        placeholder: Container(
                          color: const Color(0xFFF8FAFC),
                          child: const Icon(
                            Icons.image_not_supported_outlined,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemCount: widget.images.length,
            ),
          )
        else
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
                    'No hay más imágenes disponibles',
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
                          placeholder: const _GalleryPlaceholder(
                            isDesktop: true,
                            compact: false,
                          ),
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
    super.key,
    required this.isDesktop,
    this.compact = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
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
