import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../services/storefront_helpers.dart';
import '../services/storefront_image_resolver.dart';

/// Widget de imagen principal hero para el detalle del producto.
/// Ocupa ~40% de la altura visible en móvil con bordes inferiores redondeados.
class StorefrontProductDetailHeroImage extends StatefulWidget {
  final Map<String, dynamic> product;
  final List<String> images;
  final String slug;
  final Color accentColor;
  final VoidCallback onBack;
  final VoidCallback onCart;

  const StorefrontProductDetailHeroImage({
    super.key,
    required this.product,
    required this.images,
    required this.slug,
    required this.accentColor,
    required this.onBack,
    required this.onCart,
  });

  @override
  State<StorefrontProductDetailHeroImage> createState() =>
      _StorefrontProductDetailHeroImageState();
}

class _StorefrontProductDetailHeroImageState
    extends State<StorefrontProductDetailHeroImage> {
  late final PageController _pageController;
  int _currentIndex = 0;

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
  Widget build(BuildContext context) {
    final hasImages = widget.images.isNotEmpty;
    final productId = widget.product['id']?.toString() ?? '';
    final version = StorefrontHelpers.getProductVersion(widget.product);
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top;
    final heroHeight = mediaQuery.size.height * 0.42;

    return SizedBox(
      width: double.infinity,
      height: heroHeight.clamp(280.0, 480.0),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Imagen principal con Hero animation
          Hero(
            tag: 'product-image-$productId',
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
              child: hasImages
                  ? PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) =>
                          setState(() => _currentIndex = index),
                      itemCount: widget.images.length,
                      itemBuilder: (context, index) {
                        final resolved = StorefrontImageResolver.resolve(
                          widget.images[index],
                          version: version,
                        );
                        final imageUrl = resolved?.value ?? '';

                        if (imageUrl.isEmpty) {
                          return _buildPlaceholder();
                        }

                        return CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.contain,
                          placeholder: (_, _) => _buildPlaceholder(),
                          errorWidget: (_, _, _) => _buildErrorImage(),
                          fadeInDuration:
                              const Duration(milliseconds: 200),
                          fadeOutDuration:
                              const Duration(milliseconds: 100),
                          // Fondo claro para que la imagen respire
                          imageBuilder: (context, imageProvider) =>
                              Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFFF8FAFC),
                                  Color(0xFFF1F5F9),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              image: DecorationImage(
                                image: imageProvider,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        );
                      },
                    )
                  : _buildPlaceholder(),
            ),
          ),

          // Gradiente inferior para suavizar transición
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 60,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    const Color(0xFFF5F7FA).withValues(alpha: 0.9),
                  ],
                ),
              ),
            ),
          ),

          // Botón de regresar - dentro de la imagen, arriba izquierda
          Positioned(
            top: topPadding + 8,
            left: 12,
            child: _TopButton(
              icon: Icons.arrow_back_rounded,
              onTap: widget.onBack,
            ),
          ),

          // Botón de carrito - dentro de la imagen, arriba derecha
          Positioned(
            top: topPadding + 8,
            right: 12,
            child: _TopButton(
              icon: Icons.shopping_cart_outlined,
              onTap: widget.onCart,
            ),
          ),

          // Indicador de imágenes múltiples
          if (hasImages && widget.images.length > 1)
            Positioned(
              left: 0,
              right: 0,
              bottom: 16,
              child: _ImageIndicators(
                count: widget.images.length,
                currentIndex: _currentIndex,
                accentColor: widget.accentColor,
              ),
            ),

          // Contador de imágenes
          if (hasImages && widget.images.length > 1)
            Positioned(
              right: 16,
              bottom: 40,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_currentIndex + 1}/${widget.images.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF8FAFC), Color(0xFFEAF1F9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.image_outlined,
                size: 32,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Cargando imagen',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorImage() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFF1F2), Color(0xFFFDE2E4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.broken_image_outlined,
              size: 40,
              color: Color(0xFFEF4444),
            ),
            SizedBox(height: 8),
            Text(
              'Imagen no disponible',
              style: TextStyle(
                color: Color(0xFFB91C1C),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Botón circular elegante para la parte superior de la imagen
class _TopButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _TopButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.88),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            icon,
            size: 22,
            color: const Color(0xFF0F172A),
          ),
        ),
      ),
    );
  }
}

/// Indicadores de página para múltiples imágenes
class _ImageIndicators extends StatelessWidget {
  final int count;
  final int currentIndex;
  final Color accentColor;

  const _ImageIndicators({
    required this.count,
    required this.currentIndex,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count > 7 ? 7 : count, (index) {
        final active = index == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 20 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: active
                ? accentColor
                : Colors.white.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(3),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.4),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
        );
      }),
    );
  }
}
