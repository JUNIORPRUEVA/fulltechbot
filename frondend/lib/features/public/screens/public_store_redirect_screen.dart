import 'package:flutter/material.dart';

import '../services/public_store_service.dart';

enum PublicStoreRedirectTarget { home, product, cart, checkout }

class PublicStoreRedirectScreen extends StatefulWidget {
  final PublicStoreRedirectTarget target;
  final String? productId;

  const PublicStoreRedirectScreen({
    super.key,
    required this.target,
    this.productId,
  });

  @override
  State<PublicStoreRedirectScreen> createState() =>
      _PublicStoreRedirectScreenState();
}

class _PublicStoreRedirectScreenState extends State<PublicStoreRedirectScreen> {
  @override
  void initState() {
    super.initState();
    _redirect();
  }

  Future<void> _redirect() async {
    try {
      final resolution = await PublicStoreService.resolveDefaultStore();
      final slug = resolution.slug;

      if (!mounted) return;

      if (slug == null || slug.isEmpty) {
        Navigator.of(context).pushReplacementNamed('/');
        return;
      }

      final route = switch (widget.target) {
        PublicStoreRedirectTarget.home => '/tienda/$slug',
        PublicStoreRedirectTarget.product =>
          '/tienda/$slug/producto/${widget.productId}',
        PublicStoreRedirectTarget.cart => '/tienda/$slug/carrito',
        PublicStoreRedirectTarget.checkout => '/tienda/$slug/checkout',
      };

      debugPrint(
        '[PublicStoreRedirectScreen] slug=$slug '
        'target=${widget.target.name} route=$route',
      );

      Navigator.of(context).pushReplacementNamed(route);
    } catch (error) {
      debugPrint('[PublicStoreRedirectScreen] error redirigiendo: $error');
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(strokeWidth: 3),
      ),
    );
  }
}
