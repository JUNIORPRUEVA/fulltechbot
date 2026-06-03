import 'dart:async';

import 'package:flutter/material.dart';

class StorefrontTrustChips extends StatefulWidget {
  final Color primaryColor;
  final VoidCallback? onLocationTap;

  const StorefrontTrustChips({
    super.key,
    required this.primaryColor,
    this.onLocationTap,
  });

  @override
  State<StorefrontTrustChips> createState() => _StorefrontTrustChipsState();
}

class _StorefrontTrustChipsState extends State<StorefrontTrustChips> {
  late final ScrollController _scrollController;
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
      if (_isPaused || !mounted || !_scrollController.hasClients) return;

      final maxScroll = _scrollController.position.maxScrollExtent;
      if (maxScroll <= 0) return;

      _scrollPosition += 0.8;

      if (_scrollPosition >= maxScroll) {
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
        label: 'Garantia',
        color: widget.primaryColor,
      ),
      const SizedBox(width: 8),
      _TrustChip(
        icon: Icons.store_rounded,
        label: 'Tienda fisica',
        color: widget.primaryColor,
        onTap: widget.onLocationTap,
        isHighlighted: widget.onLocationTap != null,
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
        label: 'Instalacion',
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

    return [...chips, const SizedBox(width: 16), ...chips];
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
            height: 38,
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
  final VoidCallback? onTap;
  final bool isHighlighted;

  const _TrustChip({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final chip = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: isHighlighted ? color.withValues(alpha: 0.10) : Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isHighlighted
              ? color.withValues(alpha: 0.16)
              : const Color(0xFFE5EAF1),
        ),
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

    if (onTap == null) return chip;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: chip,
      ),
    );
  }
}
