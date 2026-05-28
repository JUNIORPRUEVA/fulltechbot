import 'package:flutter/material.dart';

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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 14),
          SelectableText(
            content,
            style: const TextStyle(
              height: 1.75,
              color: Color(0xFF475569),
              fontSize: 15.5,
            ),
          ),
        ],
      ),
    );
  }
}
