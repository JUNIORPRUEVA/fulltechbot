import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Botón flotante de WhatsApp premium y elegante.
/// Se posiciona en la parte inferior derecha de la pantalla.
/// Diseño circular con animación de pulso suave.
/// Abre WhatsApp con el número 829-534-4286 y mensaje predefinido.
class StorefrontWhatsAppFloatingButton extends StatefulWidget {
  final String phoneNumber;
  final bool isDesktop;

  const StorefrontWhatsAppFloatingButton({
    super.key,
    required this.phoneNumber,
    this.isDesktop = false,
  });

  @override
  State<StorefrontWhatsAppFloatingButton> createState() =>
      _StorefrontWhatsAppFloatingButtonState();
}

class _StorefrontWhatsAppFloatingButtonState
    extends State<StorefrontWhatsAppFloatingButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  Timer? _initialDelay;

  static const String defaultPhone = '18295344286';
  static const String defaultMessage =
      'Hola, estoy viendo la tienda de FULLTECH SRL y quiero más información.';

  String get _cleanNumber {
    final num = widget.phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    return num.isNotEmpty ? num : defaultPhone;
  }

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _pulseAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.06), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.06, end: 1.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 3),
    ]).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Retraso inicial para que aparezca después de cargar la página
    _initialDelay = Timer(const Duration(milliseconds: 800), () {
      if (mounted) {
        _pulseController.repeat();
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _initialDelay?.cancel();
    super.dispose();
  }

  Future<void> _openWhatsApp() async {
    final url =
        'https://wa.me/$_cleanNumber?text=${Uri.encodeComponent(defaultMessage)}';

    try {
      final launched = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        // Fallback: abrir en navegador
        await launchUrl(Uri.parse(url), mode: LaunchMode.platformDefault);
      }
    } catch (_) {
      // Último fallback
      await launchUrl(Uri.parse(url), mode: LaunchMode.platformDefault);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.viewPaddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(
        right: widget.isDesktop ? 20 : 16,
        bottom: bottomPadding + (widget.isDesktop ? 20 : 16),
      ),
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: child,
          );
        },
        child: Material(
          color: const Color(0xFF25D366),
          borderRadius: BorderRadius.circular(999),
          elevation: 6,
          shadowColor: const Color(0xFF25D366).withValues(alpha: 0.4),
          child: InkWell(
            onTap: _openWhatsApp,
            borderRadius: BorderRadius.circular(999),
            splashColor: Colors.white.withValues(alpha: 0.2),
            child: Container(
              width: widget.isDesktop ? 60 : 52,
              height: widget.isDesktop ? 60 : 52,
              alignment: Alignment.center,
              child: Icon(
                Icons.chat_rounded,
                color: Colors.white,
                size: widget.isDesktop ? 28 : 24,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
