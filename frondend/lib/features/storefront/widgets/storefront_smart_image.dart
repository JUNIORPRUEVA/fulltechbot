import 'package:flutter/material.dart';

import '../services/storefront_image_resolver.dart';

class StorefrontSmartImage extends StatelessWidget {
  final dynamic source;
  final BoxFit fit;
  final Widget? placeholder;
  final BorderRadius? borderRadius;
  final double? width;
  final double? height;

  const StorefrontSmartImage({
    super.key,
    required this.source,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.borderRadius,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final resolved = StorefrontImageResolver.resolve(source);
    final fallback =
        placeholder ??
        Container(
          color: const Color(0xFFF3F6FB),
          alignment: Alignment.center,
          child: const Icon(
            Icons.image_outlined,
            color: Color(0xFF94A3B8),
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
        errorBuilder: (_, __, ___) => fallback,
      );
    } else {
      child = Image.network(
        resolved.value,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, __, ___) => fallback,
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
