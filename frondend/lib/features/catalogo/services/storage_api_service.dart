import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../../../core/constants/api_config.dart';

class StorageUploadResult {
  final String key;
  final String url;
  final String mimeType;
  final int size;
  final String originalName;

  StorageUploadResult({
    required this.key,
    required this.url,
    required this.mimeType,
    required this.size,
    required this.originalName,
  });

  factory StorageUploadResult.fromJson(Map<String, dynamic> json) {
    return StorageUploadResult(
      key: json['key']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
      mimeType: json['mimeType']?.toString() ?? '',
      size: json['size'] is int
          ? json['size']
          : int.tryParse(json['size']?.toString() ?? '0') ?? 0,
      originalName: json['originalName']?.toString() ?? '',
    );
  }
}

class StorageApiService {
  Future<StorageUploadResult> subirArchivo(XFile file) async {
    final bytes = await file.readAsBytes();

    if (bytes.isEmpty) {
      throw Exception('No se pudo leer el archivo seleccionado');
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse(ApiConfig.storageUploadEndpoint),
    );

    final mimeType = _getMimeType(file.name);

    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: file.name,
        contentType: MediaType.parse(mimeType),
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    final body = jsonDecode(response.body);

    if ((response.statusCode == 200 || response.statusCode == 201) &&
        body['ok'] == true) {
      return StorageUploadResult.fromJson(body['data']);
    }

    throw Exception(body['message'] ?? 'Error al subir archivo');
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

    if (lower.endsWith('.gif')) {
      return 'image/gif';
    }

    if (lower.endsWith('.mp4')) {
      return 'video/mp4';
    }

    if (lower.endsWith('.webm')) {
      return 'video/webm';
    }

    if (lower.endsWith('.mov')) {
      return 'video/quicktime';
    }

    return 'application/octet-stream';
  }
}