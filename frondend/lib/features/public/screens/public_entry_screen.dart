import 'package:flutter/material.dart';

import '../../../core/constants/app_config.dart';

class PublicEntryScreen extends StatelessWidget {
  const PublicEntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (AppConfig.hasDefaultStore) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(
          context,
        ).pushReplacementNamed('/tienda/${AppConfig.defaultStoreSlug}');
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'FULLTECH',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  AppConfig.hasDefaultStore
                      ? 'Redirigiendo a la tienda...'
                      : 'No hay una tienda publica por defecto configurada todavia.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                if (!AppConfig.hasDefaultStore)
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pushNamed('/admin'),
                    icon: const Icon(Icons.admin_panel_settings_outlined),
                    label: const Text('Entrar al panel admin'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
