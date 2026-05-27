import 'package:flutter/material.dart';

class StorefrontProductInfoSection extends StatelessWidget {
  final String title;
  final String content;
  final IconData icon;

  const StorefrontProductInfoSection({
    super.key,
    required this.title,
    required this.content,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              height: 34,
              width: 34,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: const Color(0xFF2563EB), size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
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
        const SizedBox(height: 20),
        const Divider(color: Color(0xFFE5E7EB), height: 1),
      ],
    );
  }
}
