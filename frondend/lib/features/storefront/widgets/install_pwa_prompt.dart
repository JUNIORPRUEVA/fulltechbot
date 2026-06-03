import 'dart:async';
import 'dart:html' as html;
import 'dart:js' as js;

import 'package:flutter/material.dart';

/// ============================================
/// INSTALL PWA PROMPT - FULLTECH
/// ============================================
///
/// Componente inteligente para instalar la tienda como PWA.
///
/// ESTADOS:
///   1. Hidden: app instalada, usuario cerró hace <24h, no soportado
///   2. Floating button: botón píldora pequeño "Instalar tienda"
///   3. Expanded banner: banner completo con título, descripción y botones
///   4. iOS instructions: instrucciones manuales para iPhone/Safari
///   5. Installed: ocultar todo permanentemente
///
/// SOPORTE:
///   - Android Chrome: beforeinstallprompt + prompt()
///   - Desktop Chrome: beforeinstallprompt + prompt()
///   - iPhone/Safari: instrucciones manuales (Compartir > Agregar a pantalla de inicio)
///
/// FRECUENCIA:
///   - Si cierra: no mostrar por 24h (localStorage)
///   - Si instala: no mostrar nunca (localStorage)
///   - Si está en standalone: no mostrar
///   - Si no hay beforeinstallprompt: no mostrar botón automático
/// ============================================

/// Helper para detectar si la app ya está instalada como PWA.
bool isPwaInstalled() {
  try {
    // Android/Chrome/Desktop: display-mode standalone
    final standalone = html.window.matchMedia('(display-mode: standalone)');
    if (standalone.matches) return true;
  } catch (_) {}

  try {
    // iOS Safari: navigator.standalone
    final isIOS = js.context['navigator']['standalone'] == true;
    if (isIOS) return true;
  } catch (_) {}

  return false;
}

/// Helper para detectar si es iOS en general (cualquier browser)
bool _isiOS() {
  try {
    final userAgent = html.window.navigator.userAgent?.toLowerCase() ?? '';
    return userAgent.contains('iphone') ||
        userAgent.contains('ipad') ||
        userAgent.contains('ipod');
  } catch (_) {
    return false;
  }
}

/// Constantes de localStorage
const String _lsDismissedKey = 'fulltech_pwa_dismissed_at';
const String _lsInstalledKey = 'fulltech_pwa_installed';
const String _lsIOSDismissedKey = 'fulltech_pwa_ios_dismissed_at';
const int _dismissHours = 24;

/// Widget principal para el prompt de instalación PWA
class InstallPwaPrompt extends StatefulWidget {
  final Color primaryColor;
  final Color secondaryColor;

  const InstallPwaPrompt({
    super.key,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  State<InstallPwaPrompt> createState() => _InstallPwaPromptState();
}

class _InstallPwaPromptState extends State<InstallPwaPrompt>
    with SingleTickerProviderStateMixin {
  // ==========================================
  // ESTADOS
  // ==========================================
  /// Estado actual del prompt
  _PwaState _state = _PwaState.hidden;

  /// Control de animación
  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  /// Timer para mostrar el banner después de un delay
  Timer? _showTimer;

  /// Si el componente está listo (después de init)
  bool _ready = false;

  /// Si beforeinstallprompt está disponible (JS bridge)
  bool _pwaAvailable = false;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));

    // Inicializar después del primer frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialize();
    });
  }

  @override
  void dispose() {
    _showTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  // ==========================================
  // INICIALIZACIÓN
  // ==========================================
  void _initialize() {
    // 1. Si ya está instalada, no hacer nada
    if (isPwaInstalled()) {
      debugPrint('[PWA] App ya instalada (standalone) - ocultando prompt');
      setState(() => _state = _PwaState.hidden);
      _ready = true;
      return;
    }

    // 2. Verificar localStorage si ya instaló antes
    try {
      final installed = html.window.localStorage[_lsInstalledKey];
      if (installed == 'true') {
        debugPrint('[PWA] Usuario ya instaló antes - ocultando prompt');
        setState(() => _state = _PwaState.hidden);
        _ready = true;
        return;
      }
    } catch (_) {}

    // 3. Verificar si el usuario cerró hace menos de 24h
    if (_isDismissedRecently(_lsDismissedKey)) {
      debugPrint('[PWA] Usuario cerró hace <24h - ocultando prompt');
      setState(() => _state = _PwaState.hidden);
      _ready = true;
      return;
    }

    // 4. Verificar disponibilidad de beforeinstallprompt via JS bridge
    _checkPwaAvailability();

    // 5. Si es iOS, mostrar instrucciones manuales (con delay)
    if (_isiOS()) {
      if (_isDismissedRecently(_lsIOSDismissedKey)) {
        debugPrint('[PWA] iOS: usuario cerró instrucciones hace <24h');
        setState(() => _state = _PwaState.hidden);
        _ready = true;
        return;
      }

      debugPrint('[PWA] iOS detectado - programando instrucciones manuales');
      _showTimer = Timer(const Duration(seconds: 4), () {
        if (mounted) {
          setState(() => _state = _PwaState.iosInstructions);
          _animController.forward();
        }
      });
      _ready = true;
      return;
    }

    // 6. Esperar beforeinstallprompt (Android/Desktop)
    // El JS bridge en index.html ya capturó el evento
    // Verificamos periódicamente si está disponible
    _pollForPwaAvailability();

    _ready = true;
  }

  /// Verificar si el JS bridge tiene beforeinstallprompt disponible
  void _checkPwaAvailability() {
    try {
      final available = js.context.callMethod('fulltechPwaIsAvailable');
      _pwaAvailable = available == true;
      debugPrint('[PWA] fulltechPwaIsAvailable: $_pwaAvailable');
    } catch (e) {
      _pwaAvailable = false;
      debugPrint('[PWA] Error checking PWA availability: $e');
    }
  }

  /// Polling para detectar beforeinstallprompt (hasta 10s)
  void _pollForPwaAvailability() {
    int attempts = 0;
    const maxAttempts = 20; // 20 * 500ms = 10s

    Timer.periodic(const Duration(milliseconds: 500), (timer) {
      attempts++;
      _checkPwaAvailability();

      if (_pwaAvailable) {
        timer.cancel();
        debugPrint('[PWA] beforeinstallprompt disponible después de ${attempts * 500}ms');

        // Mostrar banner después de 3s desde que está disponible
        _showTimer = Timer(const Duration(seconds: 3), () {
          if (mounted && _state == _PwaState.hidden) {
            debugPrint('[PWA] Mostrando banner de instalación');
            setState(() => _state = _PwaState.expandedBanner);
            _animController.forward();
          }
        });
      } else if (attempts >= maxAttempts) {
        timer.cancel();
        debugPrint('[PWA] No se detectó beforeinstallprompt en 10s');
      }
    });
  }

  // ==========================================
  // ACCIONES
  // ==========================================

  /// Ejecutar el prompt de instalación usando el JS bridge
  Future<void> _handleInstall() async {
    if (!_pwaAvailable) return;

    try {
      // Llamar al JS bridge fulltechPwaPromptInstall()
      final result = await js.context.callMethod('fulltechPwaPromptInstall');
      final outcome = result?['outcome']?.toString() ?? '';

      if (outcome == 'accepted') {
        debugPrint('[PWA] Usuario aceptó la instalación');
        _markInstalled();
      } else {
        debugPrint('[PWA] Usuario canceló la instalación ($outcome)');
        _handleDismiss();
      }
    } catch (e) {
      debugPrint('[PWA] Error en prompt de instalación: $e');
      _handleDismiss();
    }
  }

  /// Marcar como instalado permanentemente
  void _markInstalled() {
    try {
      html.window.localStorage[_lsInstalledKey] = 'true';
    } catch (_) {}
    setState(() => _state = _PwaState.hidden);
    _animController.reverse();
  }

  /// Cerrar el prompt temporalmente (24h)
  void _handleDismiss() {
    try {
      html.window.localStorage[_lsDismissedKey] =
          DateTime.now().millisecondsSinceEpoch.toString();
    } catch (_) {}
    setState(() => _state = _PwaState.hidden);
    _animController.reverse();
  }

  /// Cerrar instrucciones iOS temporalmente (24h)
  void _handleIOSDismiss() {
    try {
      html.window.localStorage[_lsIOSDismissedKey] =
          DateTime.now().millisecondsSinceEpoch.toString();
    } catch (_) {}
    setState(() => _state = _PwaState.hidden);
    _animController.reverse();
  }

  /// Cerrar instrucciones iOS por hoy
  void _handleIOSNotToday() {
    try {
      html.window.localStorage[_lsIOSDismissedKey] =
          DateTime.now().millisecondsSinceEpoch.toString();
    } catch (_) {}
    setState(() => _state = _PwaState.hidden);
    _animController.reverse();
  }

  // ==========================================
  // HELPER: Verificar si fue descartado recientemente
  // ==========================================
  bool _isDismissedRecently(String key) {
    try {
      final stored = html.window.localStorage[key];
      if (stored == null || stored.isEmpty) return false;

      final dismissedAt = int.tryParse(stored);
      if (dismissedAt == null) return false;

      final now = DateTime.now().millisecondsSinceEpoch;
      final diff = now - dismissedAt;
      final hoursSinceDismiss = diff / (1000 * 60 * 60);

      return hoursSinceDismiss < _dismissHours;
    } catch (_) {
      return false;
    }
  }

  // ==========================================
  // BUILD
  // ==========================================
  @override
  Widget build(BuildContext context) {
    // No mostrar nada si está oculto o no listo
    if (_state == _PwaState.hidden || !_ready) {
      return const SizedBox.shrink();
    }

    final isDesktop = MediaQuery.sizeOf(context).width >= 1024;
    final bottomPadding = MediaQuery.viewPaddingOf(context).bottom;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Padding(
            padding: EdgeInsets.only(
              left: isDesktop ? 24 : 12,
              right: isDesktop ? 24 : 12,
              bottom: bottomPadding + (isDesktop ? 24 : 12),
            ),
            child: _buildPrompt(isDesktop),
          ),
        ),
      ),
    );
  }

  Widget _buildPrompt(bool isDesktop) {
    switch (_state) {
      case _PwaState.floatingButton:
        return _buildFloatingButton(isDesktop);
      case _PwaState.expandedBanner:
        return _buildExpandedBanner(isDesktop);
      case _PwaState.iosInstructions:
        return _buildIOSInstructions(isDesktop);
      case _PwaState.hidden:
        return const SizedBox.shrink();
    }
  }

  // ==========================================
  // BOTÓN FLOTANTE (píldora pequeña)
  // ==========================================
  Widget _buildFloatingButton(bool isDesktop) {
    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: () {
            setState(() => _state = _PwaState.expandedBanner);
          },
          borderRadius: BorderRadius.circular(999),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: widget.primaryColor,
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: widget.primaryColor.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.download_rounded,
                  size: 18,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  'Instalar tienda',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isDesktop ? 14 : 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // BANNER EXPANDIDO
  // ==========================================
  Widget _buildExpandedBanner(bool isDesktop) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: isDesktop ? 420 : double.infinity,
      ),
      padding: EdgeInsets.all(isDesktop ? 20 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con icono y título
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: widget.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.install_mobile_rounded,
                  size: 22,
                  color: widget.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Instala FULLTECH',
                      style: TextStyle(
                        fontSize: isDesktop ? 16 : 15,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Compra más rápido desde tu pantalla de inicio.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Botones
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: FilledButton(
                    onPressed: _handleInstall,
                    style: FilledButton.styleFrom(
                      backgroundColor: widget.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.download_rounded, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'Instalar',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 42,
                child: OutlinedButton(
                  onPressed: _handleDismiss,
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    'Ahora no',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // INSTRUCCIONES iOS / SAFARI
  // ==========================================
  Widget _buildIOSInstructions(bool isDesktop) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: isDesktop ? 420 : double.infinity,
      ),
      padding: EdgeInsets.all(isDesktop ? 20 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.ios_share_rounded,
                  size: 22,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Instala FULLTECH',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Para una mejor experiencia, agrega la tienda a tu pantalla de inicio.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Instrucciones paso a paso
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStep(1, 'Toca el botón Compartir', Icons.ios_share_rounded),
                const SizedBox(height: 8),
                _buildStep(2, 'Desplázate hacia abajo', Icons.arrow_downward_rounded),
                const SizedBox(height: 8),
                _buildStep(3, 'Toca "Agregar a pantalla de inicio"', Icons.add_box_outlined),
                const SizedBox(height: 8),
                _buildStep(4, 'Toca "Agregar" en la esquina superior', Icons.check_circle_outline),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Botones
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: FilledButton(
                    onPressed: _handleIOSDismiss,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Entendido',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 42,
                child: OutlinedButton(
                  onPressed: _handleIOSNotToday,
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    'No mostrar hoy',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep(int number, String text, IconData icon) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            '$number',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

/// Estados posibles del prompt PWA
enum _PwaState {
  /// Oculto: app instalada, cerrado recientemente, no soportado
  hidden,

  /// Botón flotante pequeño tipo píldora
  floatingButton,

  /// Banner expandido con título, descripción y botones
  expandedBanner,

  /// Instrucciones manuales para iOS/Safari
  iosInstructions,
}
