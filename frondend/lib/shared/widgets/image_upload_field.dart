import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../services/upload_api_service.dart';

class ImageUploadField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String folder;
  final String context;
  final String? botId;
  final double aspectRatio;
  final String? helperText;
  final String? hintText;

  const ImageUploadField({
    super.key,
    required this.controller,
    required this.label,
    required this.folder,
    required this.context,
    this.botId,
    this.aspectRatio = 1,
    this.helperText,
    this.hintText,
  });

  @override
  State<ImageUploadField> createState() => _ImageUploadFieldState();
}

class _ImageUploadFieldState extends State<ImageUploadField> {
  final UploadApiService _uploadApiService = const UploadApiService();
  bool _isUploading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleControllerChange);
  }

  @override
  void didUpdateWidget(covariant ImageUploadField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleControllerChange);
      widget.controller.addListener(_handleControllerChange);
    }
  }

  void _handleControllerChange() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _pickAndUpload() async {
    try {
      setState(() {
        _isUploading = true;
        _error = null;
      });

      const typeGroup = XTypeGroup(
        label: 'Imagenes',
        extensions: ['jpg', 'jpeg', 'png', 'webp'],
      );

      final file = await openFile(acceptedTypeGroups: const [typeGroup]);
      if (file == null) {
        return;
      }

      final bytes = await file.readAsBytes();
      final result = await _uploadApiService.uploadImage(
        bytes: bytes,
        fileName: file.name,
        folder: widget.folder,
        context: widget.context,
        botId: widget.botId,
      );

      widget.controller.text = result.url;
    } catch (error) {
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  void _clearImage() {
    widget.controller.clear();
    setState(() {
      _error = null;
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = widget.controller.text.trim().isNotEmpty;
    final borderRadius = BorderRadius.circular(18);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        AspectRatio(
          aspectRatio: widget.aspectRatio,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              border: Border.all(color: Colors.grey.shade300),
              color: Colors.grey.shade50,
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (hasImage)
                  Image.network(
                    widget.controller.text.trim(),
                    fit: widget.aspectRatio > 1.4
                        ? BoxFit.cover
                        : BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildPlaceholder(
                        icon: Icons.broken_image_outlined,
                        message: 'No se pudo cargar la vista previa',
                      );
                    },
                  )
                else
                  _buildPlaceholder(
                    icon: widget.aspectRatio > 1.4
                        ? Icons.slideshow_outlined
                        : Icons.image_outlined,
                    message: 'Sube una imagen o pega una URL',
                  ),
                if (_isUploading)
                  Container(
                    color: Colors.black.withValues(alpha: 0.45),
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Subiendo imagen...',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            FilledButton.icon(
              onPressed: _isUploading ? null : _pickAndUpload,
              icon: Icon(hasImage ? Icons.sync : Icons.upload_file),
              label: Text(hasImage ? 'Cambiar' : 'Subir imagen'),
            ),
            if (hasImage)
              OutlinedButton.icon(
                onPressed: _isUploading ? null : _clearImage,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Quitar'),
              ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: widget.controller,
          decoration: InputDecoration(
            labelText: 'URL manual',
            hintText: widget.hintText,
            prefixIcon: const Icon(Icons.link),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          widget.helperText ?? 'PNG, JPG o WEBP. Maximo 5MB.',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        if (_error != null) ...[
          const SizedBox(height: 6),
          Text(
            _error!,
            style: TextStyle(
              fontSize: 12,
              color: Colors.red.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPlaceholder({required IconData icon, required String message}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 34, color: Colors.grey.shade400),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
