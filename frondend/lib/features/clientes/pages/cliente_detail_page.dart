import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../conversaciones/models/conversacion_model.dart';
import '../../conversaciones/providers/conversaciones_provider.dart';
import '../../conversaciones/pages/chat_detail_page.dart';
import '../models/cliente_model.dart';
import '../providers/clientes_provider.dart';

class ClienteDetailPage extends StatefulWidget {
  final ClienteModel cliente;

  const ClienteDetailPage({super.key, required this.cliente});

  @override
  State<ClienteDetailPage> createState() => _ClienteDetailPageState();
}

class _ClienteDetailPageState extends State<ClienteDetailPage> {
  late ClienteModel _cliente;
  bool _mostrarTodo = false;

  @override
  void initState() {
    super.initState();
    _cliente = widget.cliente;
    _cargarConversaciones();
  }

  void _cargarConversaciones() {
    Future.microtask(() {
      context.read<ConversacionesProvider>().listarMensajes(_cliente.chatid ?? _cliente.telefono);
    });
  }

  @override
  Widget build(BuildContext context) {
    final conversacionesProvider = context.watch<ConversacionesProvider>();
    final mensajes = conversacionesProvider.mensajesActuales;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // AppBar personalizada
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildHeaderBackground(),
              stretchModes: const [StretchMode.zoomBackground],
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: _cargarConversaciones,
              ),
            ],
          ),

          // Contenido
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoSection(),
                _buildContactSection(),
                _buildSeguimientoSection(),
                _buildConversacionSection(mensajes),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBackground() {
    final nombre = _cliente.nombre ?? _cliente.telefono;
    final color = _getAvatarColor(nombre);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color,
            color.withValues(alpha: 0.7),
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 60, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Center(
                      child: Text(
                        _getInitials(nombre),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 22,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nombre,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _cliente.telefono,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _EstadoBadgeGrande(estado: _cliente.estadoCliente),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 20, color: Colors.blue.shade600),
                  const SizedBox(width: 8),
                  const Text(
                    'Información general',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => setState(() => _mostrarTodo = !_mostrarTodo),
                    child: Text(
                      _mostrarTodo ? 'Ver menos' : 'Ver todo',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _InfoField(
                icon: Icons.shopping_bag_outlined,
                label: 'Interés principal',
                value: _cliente.interesPrincipal ?? 'No especificado',
              ),
              const SizedBox(height: 10),
              _InfoField(
                icon: Icons.category_outlined,
                label: 'Producto/Servicio',
                value: _cliente.productoServicioInteres ?? 'No especificado',
              ),
              const SizedBox(height: 10),
              _InfoField(
                icon: Icons.label_outline,
                label: 'Categoría',
                value: _cliente.categoriaInteres ?? 'No especificada',
              ),
              if (_mostrarTodo) ...[
                const Divider(height: 24),
                _InfoField(
                  icon: Icons.trending_up_rounded,
                  label: 'Etapa',
                  value: _cliente.etapa,
                ),
                const SizedBox(height: 10),
                _InfoField(
                  icon: Icons.monetization_on_outlined,
                  label: 'Presupuesto estimado',
                  value: _cliente.presupuestoEstimado != null
                      ? 'RD\$${_cliente.presupuestoEstimado!.toStringAsFixed(0)}'
                      : 'No especificado',
                ),
                const SizedBox(height: 10),
                _InfoField(
                  icon: Icons.star_outline,
                  label: 'Satisfacción',
                  value: _cliente.satisfaccion.replaceAll('_', ' '),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.contact_page_outlined, size: 20, color: Colors.teal.shade600),
                  const SizedBox(width: 8),
                  const Text(
                    'Contacto y ubicación',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _InfoField(
                icon: Icons.phone_outlined,
                label: 'Teléfono',
                value: _cliente.telefono,
              ),
              if (_cliente.usuarioWhatsapp != null) ...[
                const SizedBox(height: 10),
                _InfoField(
                  icon: Icons.chat_outlined,
                  label: 'WhatsApp',
                  value: _cliente.usuarioWhatsapp!,
                ),
              ],
              if (_cliente.ciudad != null || _cliente.sector != null) ...[
                const SizedBox(height: 10),
                _InfoField(
                  icon: Icons.location_on_outlined,
                  label: 'Ubicación',
                  value: [
                    if (_cliente.sector != null) _cliente.sector,
                    if (_cliente.ciudad != null) _cliente.ciudad,
                  ].join(', '),
                ),
              ],
              if (_cliente.direccion != null) ...[
                const SizedBox(height: 10),
                _InfoField(
                  icon: Icons.home_outlined,
                  label: 'Dirección',
                  value: _cliente.direccion!,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeguimientoSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.notifications_outlined, size: 20, color: Colors.orange.shade600),
                  const SizedBox(width: 8),
                  const Text(
                    'Seguimiento',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _SeguimientoChip(
                    icon: Icons.chat_bubble_outline,
                    label: '${_cliente.totalMensajes} mensajes',
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  _SeguimientoChip(
                    icon: Icons.timer_outlined,
                    label: '${_cliente.diasSinResponder} días',
                    color: _cliente.diasSinResponder > 3 ? Colors.red : Colors.green,
                  ),
                ],
              ),
              if (_cliente.motivoSeguimiento != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.priority_high_rounded, size: 18, color: Colors.orange.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _cliente.motivoSeguimiento!,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.orange.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (_cliente.resumenConversacion != null) ...[
                const SizedBox(height: 12),
                const Text(
                  'Resumen',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  _cliente.resumenConversacion!,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.4),
                ),
              ],
              if (_cliente.datosImportantes != null) ...[
                const SizedBox(height: 12),
                const Text(
                  'Datos importantes',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  _cliente.datosImportantes!,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.4),
                ),
              ],
              if (_cliente.preferenciasCliente != null) ...[
                const SizedBox(height: 12),
                const Text(
                  'Preferencias',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  _cliente.preferenciasCliente!,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.4),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConversacionSection(List<ConversacionModel> mensajes) {
    final conversacionesProvider = context.watch<ConversacionesProvider>();

    // Contar mensajes por tipo
    final mensajesBot = mensajes.where((m) => m.role == 'assistant' || m.role == 'admin').length;
    final mensajesCliente = mensajes.where((m) => m.role == 'user').length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.chat_outlined, size: 20, color: Colors.purple.shade600),
                  const SizedBox(width: 8),
                  const Text(
                    'Conversación',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  if (mensajes.isNotEmpty)
                    TextButton.icon(
                      onPressed: () => _abrirChatCompleto(context),
                      icon: const Icon(Icons.open_in_new_rounded, size: 18),
                      label: const Text('Ver todo'),
                    ),
                ],
              ),
              // Contador de mensajes
              if (mensajes.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    _MiniContador(
                      icon: Icons.smart_toy_rounded,
                      label: 'Bot: $mensajesBot',
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 12),
                    _MiniContador(
                      icon: Icons.person_rounded,
                      label: 'Cliente: $mensajesCliente',
                      color: Colors.green,
                    ),
                    const SizedBox(width: 12),
                    _MiniContador(
                      icon: Icons.chat_bubble_outline_rounded,
                      label: 'Total: ${mensajes.length}',
                      color: Colors.purple,
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              if (conversacionesProvider.cargando && mensajes.isEmpty)


                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(strokeWidth: 3),
                  ),
                )
              else if (mensajes.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded, size: 40, color: Colors.grey.shade300),
                        const SizedBox(height: 8),
                        Text(
                          'Sin mensajes registrados',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...mensajes.reversed.take(5).map((m) => _buildMensajePreview(m)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMensajePreview(ConversacionModel mensaje) {
    final esAdmin = mensaje.role == 'assistant' || mensaje.role == 'admin';
    final esTool = mensaje.role == 'tool';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: esAdmin
                  ? Colors.blue.shade100
                  : esTool
                      ? Colors.orange.shade100
                      : Colors.green.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              esAdmin
                  ? Icons.smart_toy_rounded
                  : esTool
                      ? Icons.build_rounded
                      : Icons.person_rounded,
              size: 16,
              color: esAdmin
                  ? Colors.blue.shade700
                  : esTool
                      ? Colors.orange.shade700
                      : Colors.green.shade700,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  esAdmin ? 'Bot' : esTool ? 'Herramienta' : 'Cliente',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  mensaje.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.3),
                ),
              ],
            ),
          ),
          if (mensaje.createdAt != null)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                _formatHora(mensaje.createdAt!),
                style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
              ),
            ),
        ],
      ),
    );
  }

  void _abrirChatCompleto(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatDetailPage(
          sessionId: _cliente.chatid ?? _cliente.telefono,
          nombreCliente: _cliente.nombre ?? _cliente.telefono,
        ),
      ),
    );
  }

  Color _getAvatarColor(String name) {
    const colors = [
      Color(0xFF2563EB),
      Color(0xFF0D9488),
      Color(0xFFEA580C),
      Color(0xFF7C3AED),
      Color(0xFFDB2777),
      Color(0xFF4F46E5),
      Color(0xFF059669),
      Color(0xFF0891B2),
    ];
    return colors[name.hashCode.abs() % colors.length];
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  String _formatHora(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _InfoField extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoField({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade500),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SeguimientoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _SeguimientoChip({
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

class _MiniContador extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MiniContador({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _EstadoBadgeGrande extends StatelessWidget {

  final String estado;

  const _EstadoBadgeGrande({required this.estado});

  @override
  Widget build(BuildContext context) {
    final color = _getColor();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Text(
        estado.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Color _getColor() {
    switch (estado) {
      case 'prospecto':
        return const Color(0xFF2563EB);
      case 'seguimiento':
        return const Color(0xFF0D9488);
      case 'activo':
        return const Color(0xFF059669);
      case 'inactivo':
        return Colors.grey;
      case 'perdido':
        return const Color(0xFFDC2626);
      default:
        return Colors.grey;
    }
  }
}
