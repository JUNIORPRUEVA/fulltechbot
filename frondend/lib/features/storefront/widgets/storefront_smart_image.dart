import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../services/storefront_image_resolver.dart';

/// Widget inteligente para mostrar imágenes con:
/// - Resolución automática de URLs (relativas/absolutas)
/// - Versionado automático basado en updatedAt del producto
/// - Cache de imágenes con CachedNetworkImage (rápido, no bloquea)
/// - Placeholder elegante mientras carga
/// - Error widget profesional
/// - Precarga automática para imágenes visibles
class StorefrontSmartImage extends StatelessWidget {
  final dynamic source;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;
  final double? width;
  final double? height;
  
  /// Versión del producto (updatedAt) para versionado de cache
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
    this.version,
  });

  @override
  Widget build(BuildContext context) {
    final resolved = StorefrontImageResolver.resolve(source, version: version);
    
    final fallback = placeholder ??
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFF8FAFC), Color(0xFFEAF1F9)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.image_outlined,
            color: Color(0xFFCBD5E1),
            size: 28,
          ),
        );

    final errorWidgetLocal = errorWidget ??
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFEF2F2), Color(0xFFFEE2E2)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.broken_image_outlined,
            color: Color(0xFFFCA5A5),
            size: 28,
          ),
        );

    Widget child;
    if (resolved == null || resolved.isEmpty) {
      child = fallback;
    } else if (resolved.isAsset) {
      child = Image.asset(
        resolved.value,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, __, ___) => errorWidgetLocal,
      );
    } else {
      // Usar CachedNetworkImage para cache eficiente de imágenes
      // El versionado por URL (?v=...) asegura que si la imagen cambia,
      // se descargue la nueva versión automáticamente
      child = CachedNetworkImage(
        imageUrl: resolved.value,
        fit: fit,
        width: width,
        height: height,
        placeholder: (context, url) => fallback,
        errorWidget: (context, url, error) => errorWidgetLocal,

        // Cache en disco para que las imágenes carguen rápido
        // incluso sin conexión (si ya se descargaron antes)
        memCacheWidth: width?.toInt(),
        memCacheHeight: height?.toInt(),
        // Usar placeholder mientras carga desde cache/red
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
