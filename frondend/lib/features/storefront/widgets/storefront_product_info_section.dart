import 'package:flutter/material.dart';

/// Sección de información del producto sin tarjetas pesadas.
/// Diseño editorial limpio con líneas divisorias sutiles.
class StorefrontProductInfoSection extends StatelessWidget {
  final String title;
  final String content;
  final Color accentColor;

  const StorefrontProductInfoSection({
    super.key,
    required this.title,
    required this.content,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Línea divisoria sutil
        Container(
          height: 1,
          width: double.infinity,
          color: const Color(0xFFE8EEF4),
        ),
        const SizedBox(height: 20),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: accentColor,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 12),
        SelectableText(
          content,
          style: const TextStyle(
            height: 1.7,
            color: Color(0xFF475569),
            fontSize: 15,
            letterSpacing: 0.1,
          ),
        ),
      ],
    );
  }
}
