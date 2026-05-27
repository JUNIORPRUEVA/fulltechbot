import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../core/constants/api_config.dart';

class PublicStoreResolution {
  final Map<String, dynamic>? store;
  final String? message;
  final Map<String, dynamic>? diagnostics;

  const PublicStoreResolution({
    required this.store,
    required this.message,
    required this.diagnostics,
  });

  bool get found => store != null;

  String? get slug => store?['slug']?.toString();
}

class PublicStoreService {
  static final String _baseUrl = '${ApiConfig.baseUrl}/api/storefront';

  static Future<PublicStoreResolution> resolveDefaultStore({
    String? preferredSlug,
  }) async {
    final queryParameters = <String, String>{};
    if (preferredSlug != null && preferredSlug.trim().isNotEmpty) {
      queryParameters['slug'] = preferredSlug.trim();
    }

    final uri = Uri.parse(
      '$_baseUrl/public/default',
    ).replace(queryParameters: queryParameters.isEmpty ? null : queryParameters);
    final response = await http.get(uri);

    if (response.body.isEmpty) {
      return const PublicStoreResolution(
        store: null,
        message: 'Respuesta vacia al resolver la tienda publica.',
        diagnostics: null,
      );
    }

    final payload = jsonDecode(response.body);
    final data = payload is Map<String, dynamic> ? payload : <String, dynamic>{};
    final diagnostics = data['diagnostics'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(data['diagnostics'] as Map)
        : null;
    final store = data['data'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(data['data'] as Map)
        : null;

    debugPrint(
      '[PublicStoreService] preferredSlug=${preferredSlug ?? "-"} '
      'status=${response.statusCode} found=${store != null} '
      'strategy=${diagnostics?['strategy']} message=${data['message']}',
    );

    return PublicStoreResolution(
      store: store,
      message: data['message']?.toString(),
      diagnostics: diagnostics,
    );
  }
}
