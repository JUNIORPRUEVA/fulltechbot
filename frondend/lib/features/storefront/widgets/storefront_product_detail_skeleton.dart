import 'package:flutter/material.dart';

class StorefrontProductDetailSkeleton extends StatelessWidget {
  const StorefrontProductDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Producto'),
        backgroundColor: const Color(0xFFF8FAFC),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: isDesktop
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(flex: 6, child: _SkeletonBox(height: 620)),
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 5,
                    child: Column(
                      children: const [
                        _SkeletonBox(height: 40),
                        SizedBox(height: 12),
                        _SkeletonBox(height: 120),
                        SizedBox(height: 12),
                        _SkeletonBox(height: 220),
                      ],
                    ),
                  ),
                ],
              )
            : const Column(
                children: [
                  _SkeletonBox(height: 360),
                  SizedBox(height: 16),
                  _SkeletonBox(height: 200),
                  SizedBox(height: 16),
                  _SkeletonBox(height: 280),
                ],
              ),
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
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFFF8FAFC), Color(0xFFEFF4F8), Color(0xFFF8FAFC)],
        ),
      ),
    );
  }
}
