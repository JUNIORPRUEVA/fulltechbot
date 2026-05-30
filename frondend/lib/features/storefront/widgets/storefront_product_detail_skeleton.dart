import 'package:flutter/material.dart';

/// Skeleton loader para la pantalla de detalle de producto rediseñada.
class StorefrontProductDetailSkeleton extends StatelessWidget {
  const StorefrontProductDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        top: false,
        bottom: false,
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            children: [
              // Hero image skeleton
              _HeroSkeleton(),
              const SizedBox(height: 20),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 32 : 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SkeletonLine(width: 100, height: 22),
                    const SizedBox(height: 12),
                    _SkeletonLine(width: double.infinity, height: 32),
                    const SizedBox(height: 8),
                    _SkeletonLine(width: 200, height: 32),
                    const SizedBox(height: 12),
                    _SkeletonLine(width: double.infinity, height: 16),
                    const SizedBox(height: 6),
                    _SkeletonLine(width: 160, height: 16),
                    const SizedBox(height: 20),
                    _SkeletonLine(width: 120, height: 28),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _SkeletonLine(width: 80, height: 26),
                        const SizedBox(width: 8),
                        _SkeletonLine(width: 60, height: 26),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _SkeletonLine(width: 180, height: 40),
                    const SizedBox(height: 24),
                    Container(
                      height: 1,
                      width: double.infinity,
                      color: const Color(0xFFE8EEF4),
                    ),
                    const SizedBox(height: 20),
                    _SkeletonLine(width: 160, height: 22),
                    const SizedBox(height: 12),
                    _SkeletonLine(width: double.infinity, height: 14),
                    const SizedBox(height: 6),
                    _SkeletonLine(width: double.infinity, height: 14),
                    const SizedBox(height: 6),
                    _SkeletonLine(width: 120, height: 14),
                    const SizedBox(height: 30),
                    Container(
                      height: 1,
                      width: double.infinity,
                      color: const Color(0xFFE8EEF4),
                    ),
                    const SizedBox(height: 24),
                    _SkeletonLine(width: 200, height: 24),
                    const SizedBox(height: 6),
                    _SkeletonLine(width: 140, height: 14),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _SkeletonBox(height: 240)),
                        const SizedBox(width: 10),
                        Expanded(child: _SkeletonBox(height: 240)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final heroHeight = (mediaQuery.size.height * 0.42).clamp(280.0, 480.0);

    return Container(
      width: double.infinity,
      height: heroHeight,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF8FAFC), Color(0xFFEAF1F9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: 120,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
              ],
            ),
          ),
          // Simular botones superiores
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 12,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 12,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  final double width;
  final double height;

  const _SkeletonLine({
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE8EEF4),
        borderRadius: BorderRadius.circular(height / 2),
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  final double height;

  const _SkeletonBox({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EEF4)),
      ),
    );
  }
}
