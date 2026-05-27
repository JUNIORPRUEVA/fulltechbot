import 'package:flutter/material.dart';

import '../../../core/constants/app_config.dart';
import '../services/public_store_service.dart';

class PublicEntryScreen extends StatefulWidget {
  final String? preferredSlug;

  const PublicEntryScreen({super.key, this.preferredSlug});

  @override
  State<PublicEntryScreen> createState() => _PublicEntryScreenState();
}

class _PublicEntryScreenState extends State<PublicEntryScreen> {
  bool _loading = true;
  String? _message;
  Map<String, dynamic>? _diagnostics;

  @override
  void initState() {
    super.initState();
    final immediateSlug = _pickBestSlug(apiSlug: null, diagnostics: null);
    if (immediateSlug != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _redirectToStore(slug: immediateSlug, diagnostics: const {});
      });
      return;
    }
    _resolveStore();
  }

  Future<void> _resolveStore() async {
    setState(() {
      _loading = true;
      _message = null;
      _diagnostics = null;
    });

    try {
      final resolution = await PublicStoreService.resolveDefaultStore(
        preferredSlug: widget.preferredSlug,
      );

      if (!mounted) return;

      final resolvedSlug = _pickBestSlug(
        apiSlug: resolution.slug,
        diagnostics: resolution.diagnostics,
      );

      if (resolvedSlug != null) {
        _redirectToStore(
          slug: resolvedSlug,
          diagnostics: resolution.diagnostics,
        );
        return;
      }

      debugPrint(
        '[PublicEntryScreen] sin tienda publica activa '
        'preferredSlug=${widget.preferredSlug ?? "-"} '
        'message=${resolution.message} diagnostics=${resolution.diagnostics}',
      );

      setState(() {
        _loading = false;
        _message =
            resolution.message ??
            'La tienda publica aun no esta configurada.';
        _diagnostics = resolution.diagnostics;
      });
    } catch (error) {
      debugPrint('[PublicEntryScreen] error resolviendo tienda publica: $error');
      if (!mounted) return;

      final fallbackSlug = _pickBestSlug(apiSlug: null, diagnostics: null);
      if (fallbackSlug != null) {
        _redirectToStore(slug: fallbackSlug, diagnostics: const {});
        return;
      }

      setState(() {
        _loading = false;
        _message = 'No se pudo cargar la tienda publica en este momento.';
      });
    }
  }

  String? _pickBestSlug({
    required String? apiSlug,
    required Map<String, dynamic>? diagnostics,
  }) {
    if (widget.preferredSlug != null && widget.preferredSlug!.trim().isNotEmpty) {
      return widget.preferredSlug!.trim();
    }

    if (apiSlug != null && apiSlug.trim().isNotEmpty) {
      return apiSlug.trim();
    }

    final envSlug = diagnostics?['envDefaultSlug']?.toString().trim();
    if (envSlug != null && envSlug.isNotEmpty) {
      return envSlug;
    }

    if (AppConfig.hasDefaultStore) {
      return AppConfig.defaultStoreSlug.trim();
    }

    return null;
  }

  void _redirectToStore({
    required String slug,
    required Map<String, dynamic>? diagnostics,
  }) {
    final target = '/tienda/$slug';
    debugPrint(
      '[PublicEntryScreen] tienda resuelta slug=$slug '
      'strategy=${diagnostics?['strategy']} target=$target',
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pushReplacementNamed(target);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 880),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF2563EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1F0F172A),
                    blurRadius: 32,
                    offset: Offset(0, 18),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.shield_moon_outlined,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'FULLTECH',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Tienda online y panel administrativo',
                            style: TextStyle(
                              color: Color(0xFFDCE7FF),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Text(
                    _loading
                        ? 'Cargando la tienda publica'
                        : 'La tienda publica aun no esta lista',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _loading
                        ? 'Estamos buscando la tienda activa para abrirla como pagina principal.'
                        : _message ??
                            'Todavia no encontramos una tienda activa para mostrar en la portada.',
                    style: const TextStyle(
                      color: Color(0xFFDCE7FF),
                      fontSize: 15,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      FilledButton.icon(
                        onPressed: _loading ? null : _resolveStore,
                        icon: _loading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.storefront_rounded),
                        label: Text(_loading ? 'Buscando...' : 'Reintentar'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF0F172A),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 14,
                          ),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).pushNamed('/login'),
                        icon: const Icon(Icons.admin_panel_settings_outlined),
                        label: const Text('Iniciar sesion admin'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.35),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_diagnostics != null) ...[
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      child: DefaultTextStyle(
                        style: theme.textTheme.bodySmall!.copyWith(
                          color: const Color(0xFFDCE7FF),
                          height: 1.6,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Diagnostico de tienda publica',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'strategy: ${_diagnostics?['strategy'] ?? "-"}',
                            ),
                            Text(
                              'candidateCount: ${_diagnostics?['candidateCount'] ?? "-"}',
                            ),
                            Text(
                              'preferredSlug: ${widget.preferredSlug ?? "-"}',
                            ),
                            Text(
                              'envDefaultSlug: ${_diagnostics?['envDefaultSlug'] ?? "-"}',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
