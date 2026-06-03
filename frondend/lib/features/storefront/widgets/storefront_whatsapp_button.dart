import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Botón flotante de WhatsApp premium, más grande y resaltante.
/// Área táctil amplia con animación de pulso mejorada.
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
  static const String _defaultPhone = '18494314070';
  static const String _defaultMessage =
      'Hola, estoy viendo la tienda de FULLTECH SRL y quiero mas informacion.';

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  Timer? _initialDelay;

  String get _cleanNumber {
    final number = widget.phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    return number.isNotEmpty ? number : _defaultPhone;
  }

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );
    _pulseAnimation =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.1), weight: 1),
          TweenSequenceItem(tween: Tween(begin: 1.1, end: 1.0), weight: 1),
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 3),
        ]).animate(
          CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
        );

    _initialDelay = Timer(const Duration(milliseconds: 900), () {
      if (mounted) {
        _pulseController.repeat();
      }
    });
  }

  @override
  void dispose() {
    _initialDelay?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _openWhatsApp() async {
    final uri = Uri.parse(
      'https://wa.me/$_cleanNumber?text=${Uri.encodeComponent(_defaultMessage)}',
    );

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (_) {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Tamaño más grande y profesional
    final size = widget.isDesktop ? 64.0 : 58.0;
    final iconSize = widget.isDesktop ? 32.0 : 28.0;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(scale: _pulseAnimation.value, child: child);
      },
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        elevation: 8,
        shadowColor: const Color(0xFF25D366).withValues(alpha: 0.4),
        child: InkWell(
          onTap: _openWhatsApp,
          borderRadius: BorderRadius.circular(999),
          splashColor: Colors.white.withValues(alpha: 0.15),
          highlightColor: Colors.white.withValues(alpha: 0.08),
          child: Ink(
            height: size,
            width: size,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF25D366), Color(0xFF10B981)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.9),
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF25D366).withValues(alpha: 0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Image.asset(
              'assets/whatsappp.png',
              width: iconSize,
              height: iconSize,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
