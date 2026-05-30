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
      _asNum(precioOriginal) != null &&
      _asNum(precioOriginal)! > 0 &&
      _asNum(precio) != null &&
      _asNum(precioOriginal)! > _asNum(precio)!;

  @override
  Widget build(BuildContext context) {
    final color = primaryColor ?? const Color(0xFF0F172A);
    final effectivePrice = _asNum(precio);

    if (effectivePrice == null || effectivePrice <= 0) {
      return Text(
        'Consultar precio',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: large ? 22 : 14,
          fontWeight: FontWeight.w900,
          color: color,
          height: 1.1,
        ),
      );
    }

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
              '$currencyPrefix${_format(effectivePrice)}',
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
    final num v = _asNum(value) ?? 0;
    return v
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }

  int _calcularDescuento() {
    if (!tieneOferta) return 0;
    final original = (_asNum(precioOriginal) ?? 0).toDouble();
    final actual = (_asNum(precio) ?? 0).toDouble();
    if (original <= 0) return 0;
    return ((1 - actual / original) * 100).round();
  }

  num? _asNum(dynamic value) {
    if (value is num) return value;
    final parsed = num.tryParse(value?.toString() ?? '');
    if (parsed == null || parsed <= 0) {
      return null;
    }
    return parsed;
  }
}
