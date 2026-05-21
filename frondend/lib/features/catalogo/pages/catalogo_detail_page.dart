import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/catalogo_model.dart';
import '../providers/catalogo_provider.dart';
import 'catalogo_form_page.dart';

class CatalogoDetailPage extends StatefulWidget {
  final CatalogoModel producto;

  const CatalogoDetailPage({super.key, required this.producto});

  @override
  State<CatalogoDetailPage> createState() => _CatalogoDetailPageState();
}

class _CatalogoDetailPageState extends State<CatalogoDetailPage> {
  late CatalogoModel _producto;
  int _imagenActual = 0;
  final _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _producto = widget.producto;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<String> get _imagenes {
    final imgs = <String>[];
    if (_producto.imagen1 != null && _producto.imagen1!.isNotEmpty) imgs.add(_producto.imagen1!);
    if (_producto.imagen2 != null && _producto.imagen2!.isNotEmpty) imgs.add(_producto.imagen2!);
    if (_producto.imagen3 != null && _producto.imagen3!.isNotEmpty) imgs.add(_producto.imagen3!);
    return imgs;
  }

  bool get _tieneVideo => _producto.video != null && _producto.video!.isNotEmpty;

  Color _getEstadoColor(String estado) {
    switch (estado) {
      case 'activo':
        return Colors.green;
      case 'agotado':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  void _abrirVisor(BuildContext context, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _VisorMultimedia(
          imagenes: _imagenes,
          videoUrl: _producto.video,
          indexInicial: index,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tieneImagenes = _imagenes.isNotEmpty;
    final colorEstado = _getEstadoColor(_producto.estado);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // AppBar con galería de imágenes
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            stretch: true,
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: _buildGaleriaHeader(tieneImagenes, colorEstado),
            ),
            leading: Container(
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onSelected: (value) {
                    if (value == 'edit') {
                      _abrirEditar(context);
                    } else if (value == 'delete') {
                      _confirmarEliminar(context);
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: ListTile(
                      leading: Icon(Icons.edit_outlined),
                      title: Text('Editar'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    )),
                    const PopupMenuItem(value: 'delete', child: ListTile(
                      leading: Icon(Icons.delete_outlined, color: Colors.red),
                      title: Text('Eliminar', style: TextStyle(color: Colors.red)),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    )),
                  ],
                ),
              ),
            ],
          ),

          // Contenido
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título, precio y estado
                _buildHeaderInfo(colorEstado),

                // Descripción
                if (_producto.descripcion != null && _producto.descripcion!.isNotEmpty)
                  _buildSection(
                    icon: Icons.description_outlined,
                    title: 'Descripción',
                    color: Colors.blue,
                    child: Text(
                      _producto.descripcion!,
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.5),
                    ),
                  ),

                // Información para el bot
                if (_producto.informacion != null && _producto.informacion!.isNotEmpty)
                  _buildSection(
                    icon: Icons.psychology_outlined,
                    title: 'Información para el bot',
                    color: Colors.purple,
                    child: Text(
                      _producto.informacion!,
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.5),
                    ),
                  ),

                // Precios
                _buildSection(
                  icon: Icons.payments_outlined,
                  title: 'Precios',
                  color: Colors.green,
                  child: Column(
                    children: [
                      _PriceRow(label: 'Precio', value: 'RD\$${_producto.precio.toStringAsFixed(0)}', isMain: true),
                      if (_producto.precioMinimo != null)
                        _PriceRow(label: 'Precio mínimo', value: 'RD\$${_producto.precioMinimo!.toStringAsFixed(0)}'),
                      if (_producto.precioOferta != null)
                        _PriceRow(label: 'Precio oferta', value: 'RD\$${_producto.precioOferta!.toStringAsFixed(0)}'),
                    ],
                  ),
                ),

                // Stock y estado
                _buildSection(
                  icon: Icons.inventory_2_rounded,
                  title: 'Inventario',
                  color: Colors.orange,
                  child: Row(
                    children: [
                      _DetailChip(
                        icon: Icons.inventory_outlined,
                        label: 'Stock: ${_producto.stock}',
                        color: _producto.stock > 0 ? Colors.blue : Colors.red,
                      ),
                      const SizedBox(width: 12),
                      _DetailChip(
                        icon: Icons.circle,
                        label: _producto.estado.toUpperCase(),
                        color: colorEstado,
                      ),
                    ],
                  ),
                ),

                // Galería de imágenes (miniaturas)
                if (tieneImagenes)
                  _buildSection(
                    icon: Icons.photo_library_outlined,
                    title: 'Galería de imágenes',
                    color: Colors.blue,
                    child: SizedBox(
                      height: 80,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _imagenes.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (_, index) {
                          return GestureDetector(
                            onTap: () => _abrirVisor(context, index),
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Image.network(
                                _imagenes[index],
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: Colors.grey.shade100,
                                  child: Icon(Icons.broken_image_outlined, color: Colors.grey.shade400),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                // Video
                if (_tieneVideo)
                  _buildSection(
                    icon: Icons.videocam_outlined,
                    title: 'Video del producto',
                    color: Colors.red,
                    child: GestureDetector(
                      onTap: () => _abrirVisor(context, _imagenes.length),
                      child: Container(
                        width: double.infinity,
                        height: 180,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(12),
                          image: _imagenes.isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(_imagenes.first),
                                  fit: BoxFit.cover,
                                  colorFilter: ColorFilter.mode(
                                    Colors.black.withValues(alpha: 0.4),
                                    BlendMode.darken,
                                  ),
                                )
                              : null,
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.play_arrow_rounded, size: 36, color: Colors.red.shade600),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Ver video',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                // Palabras clave
                if (_producto.palabrasClave != null && _producto.palabrasClave!.isNotEmpty)
                  _buildSection(
                    icon: Icons.label_outline,
                    title: 'Palabras clave',
                    color: Colors.teal,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: _producto.palabrasClave!.split(',').map((palabra) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.teal.shade50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.teal.shade200),
                          ),
                          child: Text(
                            palabra.trim(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.teal.shade700,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                // Reglas de negociación
                if (_producto.reglasNegociacion != null && _producto.reglasNegociacion!.isNotEmpty)
                  _buildSection(
                    icon: Icons.handshake_outlined,
                    title: 'Reglas de negociación',
                    color: Colors.indigo,
                    child: Text(
                      _producto.reglasNegociacion!,
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.5),
                    ),
                  ),

                // Fechas
                _buildSection(
                  icon: Icons.schedule_outlined,
                  title: 'Información de registro',
                  color: Colors.grey,
                  child: Column(
                    children: [
                      if (_producto.creadoEn != null)
                        _InfoRow(label: 'Creado', value: _formatFecha(_producto.creadoEn!)),
                      if (_producto.actualizadoEn != null)
                        _InfoRow(label: 'Actualizado', value: _formatFecha(_producto.actualizadoEn!)),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(colorEstado),
    );
  }

  Widget _buildGaleriaHeader(bool tieneImagenes, Color colorEstado) {
    if (!tieneImagenes) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorEstado,
              colorEstado.withValues(alpha: 0.7),
            ],
          ),
        ),
        child: Center(
          child: Icon(Icons.inventory_2_outlined, size: 80, color: Colors.white.withValues(alpha: 0.5)),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // PageView de imágenes
        GestureDetector(
          onTap: () => _abrirVisor(context, _imagenActual),
          child: PageView.builder(
            controller: _pageController,
            itemCount: _imagenes.length,
            onPageChanged: (index) => setState(() => _imagenActual = index),
            itemBuilder: (_, index) => Image.network(
              _imagenes[index],
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: Colors.grey.shade200,
                child: Icon(Icons.broken_image_outlined, size: 60, color: Colors.grey.shade400),
              ),
              loadingBuilder: (_, child, progress) {
                if (progress == null) return child;
                return Container(
                  color: Colors.grey.shade100,
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 3, color: colorEstado),
                  ),
                );
              },
            ),
          ),
        ),

        // Gradiente inferior
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withValues(alpha: 0.5)],
              ),
            ),
          ),
        ),

        // Indicadores + botón ver todo
        Positioned(
          left: 0,
          right: 0,
          bottom: 12,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Indicadores de página
              ...List.generate(_imagenes.length, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _imagenActual == index ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _imagenActual == index ? Colors.white : Colors.white.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
              if (_tieneVideo) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.videocam_rounded, size: 12, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'Video',
                        style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        // Botón de expandir
        Positioned(
          right: 12,
          bottom: 40,
          child: GestureDetector(
            onTap: () => _abrirVisor(context, _imagenActual),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.fullscreen_rounded, size: 20, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderInfo(Color colorEstado) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Categoría
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _producto.categoria,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(height: 10),

          // Título
          Text(
            _producto.titulo,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, height: 1.2),
          ),
          const SizedBox(height: 12),

          // Precio y estado
          Row(
            children: [
              Text(
                'RD\$${_producto.precio.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.green.shade700,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: colorEstado.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: colorEstado.withValues(alpha: 0.3)),
                ),
                child: Text(
                  _producto.estado.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: colorEstado,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required Color color,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 20, color: color),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              child,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar(Color colorEstado) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _abrirEditar(context),
              icon: const Icon(Icons.edit_outlined, size: 20),
              label: const Text('Editar'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              onPressed: () => _cambiarEstado(context),
              icon: Icon(
                _producto.estado == 'activo' ? Icons.pause_rounded : Icons.check_circle_rounded,
                size: 20,
              ),
              label: Text(_producto.estado == 'activo' ? 'Pausar' : 'Activar'),
              style: FilledButton.styleFrom(
                backgroundColor: _producto.estado == 'activo' ? Colors.orange : Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _abrirEditar(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CatalogoFormPage(producto: _producto),
      ),
    );
    if (mounted) {
      context.read<CatalogoProvider>().cargarProductos();
    }
  }

  void _cambiarEstado(BuildContext context) {
    final nuevoEstado = _producto.estado == 'activo' ? 'inactivo' : 'activo';
    context.read<CatalogoProvider>().cambiarEstado(
          id: _producto.id,
          estado: nuevoEstado,
        );
    setState(() {
      _producto = _producto.copyWith(estado: nuevoEstado);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          nuevoEstado == 'activo'
              ? 'Producto activado correctamente'
              : 'Producto pausado correctamente',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _confirmarEliminar(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Eliminar producto'),
        content: Text('¿Seguro que quieres eliminar "${_producto.titulo}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true && context.mounted) {
      await context.read<CatalogoProvider>().eliminarProducto(_producto.id);
      if (context.mounted) Navigator.pop(context);
    }
  }

  String _formatFecha(DateTime date) {
    final meses = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
    ];
    return '${date.day} ${meses[date.month - 1]} ${date.year} · ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

// Visor de pantalla completa para imágenes y video
class _VisorMultimedia extends StatefulWidget {
  final List<String> imagenes;
  final String? videoUrl;
  final int indexInicial;

  const _VisorMultimedia({
    required this.imagenes,
    this.videoUrl,
    required this.indexInicial,
  });

  @override
  State<_VisorMultimedia> createState() => _VisorMultimediaState();
}

class _VisorMultimediaState extends State<_VisorMultimedia> {
  late int _currentIndex;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.indexInicial;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  int get _totalItems {
    int count = widget.imagenes.length;
    if (widget.videoUrl != null) count++;
    return count;
  }

  bool get _isVideo => _currentIndex >= widget.imagenes.length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          _isVideo ? 'Video' : 'Imagen ${_currentIndex + 1} de ${widget.imagenes.length}',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: PageView.builder(
          controller: _pageController,
          itemCount: _totalItems,
          onPageChanged: (index) => setState(() => _currentIndex = index),
          itemBuilder: (_, index) {
            // Si es la última página y hay video
            if (index >= widget.imagenes.length && widget.videoUrl != null) {
              return _buildVideoView();
            }
            return _buildImageView(index);
          },
        ),
      ),
      bottomNavigationBar: _totalItems > 1
          ? Container(
              color: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_totalItems, (index) {
                  final isVideo = index >= widget.imagenes.length;
                  return GestureDetector(
                    onTap: () => _pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    ),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: isVideo ? 36 : 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _currentIndex == index ? Colors.white : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: isVideo
                          ? Container(
                              decoration: BoxDecoration(
                                color: Colors.red.shade900,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24),
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.network(
                                widget.imagenes[index],
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: Colors.grey.shade800,
                                  child: const Icon(Icons.broken_image, color: Colors.white54),
                                ),
                              ),
                            ),
                    ),
                  );
                }),
              ),
            )
          : null,
    );
  }

  Widget _buildImageView(int index) {
    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 4,
      child: Center(
        child: Image.network(
          widget.imagenes[index],
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image_outlined, size: 64, color: Colors.grey.shade600),
              const SizedBox(height: 12),
              Text(
                'No se pudo cargar la imagen',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
              ),
            ],
          ),
          loadingBuilder: (_, child, progress) {
            if (progress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: Colors.white,
                value: progress.expectedTotalBytes != null
                    ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                    : null,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildVideoView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.play_arrow_rounded, size: 48, color: Colors.white),
          ),
          const SizedBox(height: 20),
          Text(
            'Video del producto',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 16),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              widget.videoUrl!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Text(
              'Abrir en navegador',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isMain;

  const _PriceRow({
    required this.label,
    required this.value,
    this.isMain = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isMain ? 18 : 15,
              fontWeight: isMain ? FontWeight.w800 : FontWeight.w600,
              color: isMain ? Colors.green.shade700 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _DetailChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey.shade800)),
        ],
      ),
    );
  }
}
