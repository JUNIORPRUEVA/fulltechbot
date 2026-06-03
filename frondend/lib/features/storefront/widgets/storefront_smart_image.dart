import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/storefront_image_resolver.dart';

/// Widget inteligente para mostrar imagenes con:
/// - Resolucion automatica de URLs (relativas/absolutas)
/// - Versionado automatico basado en updatedAt del producto
/// - Peticiones optimizadas para web via backend de imagenes
/// - Cache de imagenes con CachedNetworkImage
/// - Placeholder elegante mientras carga
class StorefrontSmartImage extends StatelessWidget {
  final dynamic source;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;
  final double? width;
  final double? height;
  final int? requestWidth;
  final int? requestHeight;
  final int quality;
  final String? version;

  const StorefrontSmartImage({
    super.key,
    required this.source,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
    this.width,
    this.height,
    this.requestWidth,
    this.requestHeight,
    this.quality = 72,
    this.version,
  });

  @override
  Widget build(BuildContext context) {
    final devicePixelRatio = MediaQuery.maybeDevicePixelRatioOf(context) ?? 1;
    final targetWidth = requestWidth ?? _scaledDimension(width, devicePixelRatio);
    final targetHeight = requestHeight ?? _scaledDimension(height, devicePixelRatio);
    final resolved = StorefrontImageResolver.resolveForDisplay(
      source,
      version: version,
      width: targetWidth,
      height: targetHeight,
      quality: quality,
    );
    final fallback = placeholder ?? const _StorefrontImageFallback();
    final resolvedErrorWidget =
        errorWidget ?? const _StorefrontImageFallback(isError: true);

    Widget child;
    if (resolved == null || resolved.isEmpty) {
      child = fallback;
    } else if (resolved.isAsset) {
      child = Image.asset(
        resolved.value,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, _, _) => resolvedErrorWidget,
      );
    } else {
      child = CachedNetworkImage(
        imageUrl: resolved.value,
        fit: fit,
        width: width,
        height: height,
        placeholder: (context, url) => fallback,
        errorWidget: (_, url, error) {
          if (kDebugMode) {
            debugPrint('Storefront image failed: $url');
            debugPrint('Storefront image error: $error');
          }
          return resolvedErrorWidget;
        },
        memCacheWidth: targetWidth,
        memCacheHeight: targetHeight,
        fadeInDuration: const Duration(milliseconds: 150),
        fadeOutDuration: const Duration(milliseconds: 75),
      );
    }

    if (borderRadius == null) {
      return child;
    }

    return ClipRRect(
      borderRadius: borderRadius!,
      child: child,
    );
  }
}

int? _scaledDimension(double? logicalSize, double devicePixelRatio) {
  if (logicalSize == null || logicalSize <= 0) {
    return null;
  }

  return (logicalSize * devicePixelRatio).round();
}

class _StorefrontImageFallback extends StatelessWidget {
  final bool isError;

  const _StorefrontImageFallback({this.isError = false});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isError
              ? const [Color(0xFFFFF1F2), Color(0xFFFDE2E4)]
              : const [Color(0xFFF8FAFC), Color(0xFFEAF1F9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            right: -18,
            bottom: -16,
            child: Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.35),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isError ? Icons.broken_image_outlined : Icons.image_outlined,
                  color: isError
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF94A3B8),
                  size: 28,
                ),
                const SizedBox(height: 8),
                Text(
                  isError ? 'Imagen no disponible' : 'Cargando imagen',
                  style: TextStyle(
                    color: isError
                        ? const Color(0xFFB91C1C)
                        : const Color(0xFF64748B),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
