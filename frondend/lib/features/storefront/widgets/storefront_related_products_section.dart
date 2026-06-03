import 'package:flutter/material.dart';

import 'storefront_product_card.dart';

/// Sección de productos relacionados con grid de 2 columnas optimizado.
class StorefrontRelatedProductsSection extends StatelessWidget {
  final List<dynamic> products;
  final String slug;
  final Color primaryColor;
  final Color secondaryColor;
  final String? whatsapp;

  const StorefrontRelatedProductsSection({
    super.key,
    required this.products,
    required this.slug,
    required this.primaryColor,
    required this.secondaryColor,
    this.whatsapp,
  });

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const SizedBox.shrink();

    final isDesktop = MediaQuery.sizeOf(context).width >= 1000;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Línea divisoria
        Container(
          height: 1,
          width: double.infinity,
          color: const Color(0xFFE8EEF4),
        ),
        const SizedBox(height: 24),
        Text(
          'Productos relacionados',
          style: TextStyle(
            fontSize: isDesktop ? 24 : 20,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF0F172A),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Opciones similares dentro de la misma categoría.',
          style: TextStyle(
            color: const Color(0xFF64748B),
            fontSize: isDesktop ? 14 : 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
        if (isDesktop)
          // Grid de 4 columnas en desktop
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: products.take(8).map((product) {
              return SizedBox(
                width: (MediaQuery.sizeOf(context).width - 80) / 4,
                child: StorefrontProductCard(
                  product: Map<String, dynamic>.from(product as Map),
                  slug: slug,
                  primaryColor: primaryColor,
                  secondaryColor: secondaryColor,
                  whatsapp: whatsapp,
                ),
              );
            }).toList(),
          )
        else
          // Grid de 2 columnas en móvil
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.62,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: products.length > 4 ? 4 : products.length,
            itemBuilder: (context, index) {
              return StorefrontProductCard(
                product: Map<String, dynamic>.from(
                  products[index] as Map,
                ),
                slug: slug,
                primaryColor: primaryColor,
                secondaryColor: secondaryColor,
                whatsapp: whatsapp,
              );
            },
          ),
      ],
    );
  }
}
