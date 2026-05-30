import 'package:flutter/material.dart';

class StorefrontSkeleton extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const StorefrontSkeleton({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  State<StorefrontSkeleton> createState() => _StorefrontSkeletonState();
}

class _StorefrontSkeletonState extends State<StorefrontSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              colors: const [
                Color(0xFFE5E7EB),
                Color(0xFFF3F4F6),
                Color(0xFFE5E7EB),
              ],
              stops: [
                _animation.value.clamp(0.0, 1.0),
                (_animation.value + 0.3).clamp(0.0, 1.0),
                (_animation.value + 0.6).clamp(0.0, 1.0),
              ],
            ),
          ),
        );
      },
    );
  }
}

class StorefrontProductCardSkeleton extends StatelessWidget {
  const StorefrontProductCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: const StorefrontSkeleton(
              width: double.infinity,
              height: double.infinity,
              borderRadius: 0,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const StorefrontSkeleton(width: double.infinity, height: 14, borderRadius: 4),
                const SizedBox(height: 8),
                const StorefrontSkeleton(width: 100, height: 12, borderRadius: 4),
                const SizedBox(height: 8),
                const StorefrontSkeleton(width: 80, height: 18, borderRadius: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class StorefrontHomeSkeleton extends StatelessWidget {
  const StorefrontHomeSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          // AppBar skeleton
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8,
                left: 16,
                right: 16,
                bottom: 12,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const StorefrontSkeleton(width: 36, height: 36, borderRadius: 10),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: StorefrontSkeleton(width: double.infinity, height: 18, borderRadius: 4),
                  ),
                  const SizedBox(width: 12),
                  const StorefrontSkeleton(width: 36, height: 36, borderRadius: 10),
                ],
              ),
            ),
          ),
          // Slider skeleton
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: const StorefrontSkeleton(width: double.infinity, height: 200, borderRadius: 20),
            ),
          ),
          // Trust chips skeleton
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: SizedBox(
                height: 36,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 4,
                  itemBuilder: (_, __) => const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: StorefrontSkeleton(width: 100, height: 36, borderRadius: 18),
                  ),
                ),
              ),
            ),
          ),
          // Categories skeleton
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: const StorefrontSkeleton(width: 120, height: 22, borderRadius: 4),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                height: 144,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 4,
                  itemBuilder: (_, __) => const Padding(
                    padding: EdgeInsets.only(right: 12),
                    child: StorefrontSkeleton(width: 118, height: 144, borderRadius: 22),
                  ),
                ),
              ),
            ),
          ),
          // Products grid skeleton
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: const StorefrontSkeleton(width: 150, height: 22, borderRadius: 4),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.61,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                return const StorefrontProductCardSkeleton();
              }, childCount: 4),
            ),
          ),
        ],
      ),
    );
  }
}

// Necesitamos StorefrontColors aquí para el skeleton
class StorefrontColors {
  static const Color primary = Color(0xFF0F172A);
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
