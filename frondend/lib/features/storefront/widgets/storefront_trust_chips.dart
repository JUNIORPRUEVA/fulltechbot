import 'dart:async';

import 'package:flutter/material.dart';

/// Chips de confianza con animación automática tipo marquee/infinite scroll.
/// Se desplaza suavemente hacia la izquierda para dar una impresión tecnológica.
class StorefrontTrustChips extends StatefulWidget {
  final Color primaryColor;

  const StorefrontTrustChips({
    super.key,
    required this.primaryColor,
  });

  @override
  State<StorefrontTrustChips> createState() => _StorefrontTrustChipsState();
}

class _StorefrontTrustChipsState extends State<StorefrontTrustChips> {
  late ScrollController _scrollController;
  Timer? _scrollTimer;
  double _scrollPosition = 0;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _startAutoScroll();
  }

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    _scrollTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (_isPaused || !mounted) return;

      final maxScroll = _scrollController.position.maxScrollExtent;
      if (maxScroll <= 0) return;

      _scrollPosition += 0.8; // Velocidad suave y elegante

      if (_scrollPosition >= maxScroll) {
        // Reinicio suave al inicio cuando llega al final
        _scrollPosition = 0;
        _scrollController.jumpTo(0);
      } else {
        _scrollController.jumpTo(_scrollPosition);
      }
    });
  }

  List<Widget> _buildChips() {
    final chips = [
      _TrustChip(
        icon: Icons.verified_rounded,
        label: 'Garantía',
        color: widget.primaryColor,
      ),
      const SizedBox(width: 8),
      _TrustChip(
        icon: Icons.store_rounded,
        label: 'Tienda física',
        color: widget.primaryColor,
      ),
      const SizedBox(width: 8),
      _TrustChip(
        icon: Icons.support_agent_rounded,
        label: 'Soporte',
        color: widget.primaryColor,
      ),
      const SizedBox(width: 8),
      _TrustChip(
        icon: Icons.build_circle_rounded,
        label: 'Instalación',
        color: widget.primaryColor,
      ),
      const SizedBox(width: 8),
      _TrustChip(
        icon: Icons.local_shipping_rounded,
        label: 'Entrega',
        color: widget.primaryColor,
      ),
      const SizedBox(width: 8),
      _TrustChip(
        icon: Icons.security_rounded,
        label: 'Pago seguro',
        color: widget.primaryColor,
      ),
    ];

    // Duplicamos los chips para que el scroll infinito se vea continuo
    return [
      ...chips,
      const SizedBox(width: 16),
      ...chips,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final contentPadding = screenWidth >= 1320
        ? ((screenWidth - 1240) / 2).clamp(16.0, 9999.0)
        : screenWidth >= 700
            ? 20.0
            : 14.0;

    return MouseRegion(
      onEnter: (_) => setState(() => _isPaused = true),
      onExit: (_) => setState(() => _isPaused = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPaused = true),
        onTapUp: (_) => setState(() => _isPaused = false),
        onTapCancel: () => setState(() => _isPaused = false),
        child: Padding(
          padding: EdgeInsets.fromLTRB(contentPadding, 8, contentPadding, 4),
          child: SizedBox(
            height: 34,
            child: ListView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              children: _buildChips(),
            ),
          ),
        ),
      ),
    );
  }
}

class _TrustChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _TrustChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE5EAF1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }
}
