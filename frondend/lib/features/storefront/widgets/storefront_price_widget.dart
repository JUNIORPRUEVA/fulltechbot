import 'package:flutter/material.dart';

class StorefrontPriceWidget extends StatelessWidget {
  final dynamic precio;
  final dynamic precioOriginal;
  final bool large;
  final Color? primaryColor;
  final String currencyPrefix;

  const StorefrontPriceWidget({
    super.key,
    required this.precio,
    this.precioOriginal,
    this.large = false,
    this.primaryColor,
    this.currencyPrefix = '\$',
  });

  bool get tieneOferta =>
      precioOriginal != null &&
      (precioOriginal is num ? precioOriginal > 0 : true) &&
      (precio is num
          ? precioOriginal is num && precioOriginal > precio
          : false);

  @override
  Widget build(BuildContext context) {
    final color = primaryColor ?? const Color(0xFF0F172A);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (tieneOferta)
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              '$currencyPrefix${_format(precioOriginal)}',
              style: TextStyle(
                color: const Color(0xFF9CA3AF),
                fontSize: large ? 15 : 11,
                decoration: TextDecoration.lineThrough,
                decorationColor: const Color(0xFF9CA3AF),
                decorationThickness: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$currencyPrefix${_format(precio)}',
              style: TextStyle(
                fontSize: large ? 28 : 19,
                fontWeight: FontWeight.w900,
                color: color,
                height: 1,
                letterSpacing: -0.8,
              ),
            ),
            if (tieneOferta) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: const [Color(0xFFEF4444), Color(0xFFF87171)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '-${_calcularDescuento()}%',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: large ? 12 : 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  String _format(dynamic value) {
    if (value == null) return '0';
    final num v = value is num ? value : double.tryParse(value.toString()) ?? 0;
    return v
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }

  int _calcularDescuento() {
    if (!tieneOferta) return 0;
    final original =
        (precioOriginal is num
                ? precioOriginal
                : double.tryParse(precioOriginal.toString()) ?? 0)
            .toDouble();
    final actual =
        (precio is num ? precio : double.tryParse(precio.toString()) ?? 0)
            .toDouble();
    if (original <= 0) return 0;
    return ((1 - actual / original) * 100).round();
  }
}
