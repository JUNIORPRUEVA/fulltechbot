import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../core/constants/api_config.dart';

class UploadResult {
  final bool ok;
  final String url;
  final String key;
  final String mimeType;
  final int size;

  const UploadResult({
    required this.ok,
    required this.url,
    required this.key,
    required this.mimeType,
    required this.size,
  });

  factory UploadResult.fromJson(Map<String, dynamic> json) {
    return UploadResult(
      ok: json['ok'] == true,
      url: json['url']?.toString() ?? '',
      key: json['key']?.toString() ?? '',
      mimeType: json['mimeType']?.toString() ?? '',
      size: json['size'] is int
          ? json['size'] as int
          : int.tryParse(json['size']?.toString() ?? '0') ?? 0,
    );
  }
}

class UploadApiService {
  const UploadApiService();

  Future<UploadResult> uploadImage({
    required Uint8List bytes,
    required String fileName,
    required String folder,
    required String context,
    String? botId,
  }) async {
    if (bytes.isEmpty) {
      throw Exception('No se pudo leer la imagen seleccionada');
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse(ApiConfig.uploadsImageEndpoint),
    );

    request.fields['folder'] = folder;
    request.fields['context'] = context;

    if (botId != null && botId.trim().isNotEmpty) {
      request.fields['bot_id'] = botId.trim();
    }

    request.files.add(
      http.MultipartFile.fromBytes(
        'image',
        bytes,
        filename: fileName,
        contentType: MediaType.parse(_getMimeType(fileName)),
      ),
    );

    final streamedResponse = await request.send().timeout(
      const Duration(seconds: 30),
    );
    final response = await http.Response.fromStream(streamedResponse);

    Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw Exception('Respuesta invalida del servidor de uploads');
    }

    if ((response.statusCode == 200 || response.statusCode == 201) &&
        body['ok'] == true) {
      return UploadResult.fromJson(body);
    }

    throw Exception(
      body['message']?.toString() ?? 'No se pudo subir la imagen',
    );
  }

  String _getMimeType(String fileName) {
    final lower = fileName.toLowerCase();

    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return 'image/jpeg';
    }

    if (lower.endsWith('.png')) {
      return 'image/png';
    }

    if (lower.endsWith('.webp')) {
      return 'image/webp';
    }

    return 'application/octet-stream';
  }
}
