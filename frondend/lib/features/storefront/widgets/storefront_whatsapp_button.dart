import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.05), weight: 1),
          TweenSequenceItem(tween: Tween(begin: 1.05, end: 1.0), weight: 1),
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
    final isWide = widget.isDesktop || MediaQuery.sizeOf(context).width >= 720;
    final height = isWide ? 66.0 : 60.0;
    final bubbleSize = isWide ? 42.0 : 38.0;
    final iconSize = isWide ? 28.0 : 26.0;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(scale: _pulseAnimation.value, child: child);
      },
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: _openWhatsApp,
          borderRadius: BorderRadius.circular(999),
          splashColor: Colors.white.withValues(alpha: 0.12),
          highlightColor: Colors.white.withValues(alpha: 0.06),
          child: Ink(
            height: height,
            padding: EdgeInsets.symmetric(horizontal: isWide ? 14 : 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF25D366), Color(0xFF10B981)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.90),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF25D366).withValues(alpha: 0.30),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: bubbleSize,
                  height: bubbleSize,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  alignment: Alignment.center,
                  child: Image.asset(
                    'assets/whatsappp.png',
                    width: iconSize,
                    height: iconSize,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 10),
                if (isWide)
                  const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'WhatsApp',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Escribenos',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          height: 1,
                        ),
                      ),
                    ],
                  )
                else
                  const Text(
                    'WhatsApp',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
