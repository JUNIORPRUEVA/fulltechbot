import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../bots/providers/bot_provider.dart';
import '../../conversaciones/models/conversacion_model.dart';
import '../../conversaciones/pages/chat_detail_page.dart';
import '../../conversaciones/providers/conversaciones_provider.dart';
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
  bool _mostrarTodo = true;

  @override
  void initState() {
    super.initState();
    _cliente = widget.cliente;
    _cargarConversaciones();
  }

  void _cargarConversaciones() {
    Future.microtask(() {
      if (!mounted) return;
      final botId =
          context.read<BotProvider>().botSeleccionado?.id ?? _cliente.botId;
      context.read<ConversacionesProvider>().listarMensajes(
        _cliente.chatid ?? _cliente.telefono,
        botId: botId,
      );
    });
  }

  void _confirmarEliminar(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('¿Eliminar cliente?'),
        content: const Text(
          'Se eliminará este cliente y todas sus conversaciones. '
          'El bot perderá la memoria de este cliente y empezará desde cero.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final botId =
                  context.read<BotProvider>().botSeleccionado?.id ??
                  _cliente.botId;
              await context.read<ClientesProvider>().eliminarCliente(
                _cliente.telefono,
                botId: botId,
                chatid: _cliente.chatid,
                userRole: 'admin',
              );
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final conversacionesProvider = context.watch<ConversacionesProvider>();
    final mensajes = conversacionesProvider.mensajesActuales;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 210,
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
                icon: Icon(Icons.delete_outline_rounded, color: Colors.red.shade200),
                onPressed: () => _confirmarEliminar(context),
                tooltip: 'Eliminar cliente',
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: _cargarConversaciones,
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildOverviewSection(),
                _buildIdentitySection(),
                _buildContactSection(),
                _buildBusinessSection(),
                _buildReservationSection(),
                _buildSeguimientoSection(),
                _buildControlSection(),
                _buildMetadataSection(),
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
          colors: [color, color.withValues(alpha: 0.72)],
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
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        _getInitials(nombre),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 24,
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
                            color: Colors.white.withValues(alpha: 0.88),
                            fontSize: 14,
                          ),
                        ),
                        if (_cliente.chatid != null &&
                            _cliente.chatid!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            _cliente.chatid!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.72),
                              fontSize: 12,
                            ),
                          ),
                        ],
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

  Widget _buildOverviewSection() {
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
                  Icon(
                    Icons.dashboard_outlined,
                    size: 20,
                    color: Colors.indigo.shade600,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Resumen',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => setState(() => _mostrarTodo = !_mostrarTodo),
                    child: Text(
                      _mostrarTodo ? 'Compactar' : 'Mostrar todo',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.indigo.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _StatusChip(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: '${_cliente.totalMensajes} mensajes',
                    color: Colors.blue,
                  ),
                  _StatusChip(
                    icon: Icons.timer_outlined,
                    label: '${_cliente.diasSinResponder} dias',
                    color: _cliente.diasSinResponder > 3
                        ? Colors.red
                        : Colors.green,
                  ),
                  _StatusChip(
                    icon: Icons.track_changes_outlined,
                    label: 'Etapa: ${_cliente.etapa}',
                    color: Colors.deepPurple,
                  ),
                  _StatusChip(
                    icon: Icons.support_agent_outlined,
                    label: _cliente.requiereSeguimiento
                        ? 'Requiere seguimiento'
                        : 'Sin seguimiento',
                    color: _cliente.requiereSeguimiento
                        ? Colors.orange
                        : Colors.grey,
                  ),
                  _StatusChip(
                    icon: Icons.pause_circle_outline,
                    label: _cliente.botPausado ? 'Bot pausado' : 'Bot activo',
                    color: _cliente.botPausado ? Colors.red : Colors.teal,
                  ),
                  _StatusChip(
                    icon: Icons.person_pin_circle_outlined,
                    label: _cliente.humanoTomoControl
                        ? 'Con control humano'
                        : 'Control bot',
                    color: _cliente.humanoTomoControl
                        ? Colors.pink
                        : Colors.blueGrey,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _InfoField(
                icon: Icons.shopping_bag_outlined,
                label: 'Interes principal',
                value: _cliente.interesPrincipal ?? 'No especificado',
              ),
              const SizedBox(height: 10),
              _InfoField(
                icon: Icons.category_outlined,
                label: 'Producto o servicio',
                value: _cliente.productoServicioInteres ?? 'No especificado',
              ),
              const SizedBox(height: 10),
              _InfoField(
                icon: Icons.label_outline,
                label: 'Categoria de interes',
                value: _cliente.categoriaInteres ?? 'No especificada',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIdentitySection() {
    final fields = <Widget>[
      _InfoField(
        icon: Icons.phone_outlined,
        label: 'Telefono',
        value: _cliente.telefono,
      ),
      if (_cliente.nombre != null && _cliente.nombre!.isNotEmpty)
        _InfoField(
          icon: Icons.badge_outlined,
          label: 'Nombre',
          value: _cliente.nombre!,
        ),
      if (_cliente.chatid != null && _cliente.chatid!.isNotEmpty)
        _InfoField(
          icon: Icons.tag_outlined,
          label: 'Chat ID',
          value: _cliente.chatid!,
        ),
      if (_cliente.usuarioWhatsapp != null &&
          _cliente.usuarioWhatsapp!.isNotEmpty)
        _InfoField(
          icon: Icons.alternate_email_rounded,
          label: 'Usuario WhatsApp',
          value: _cliente.usuarioWhatsapp!,
        ),
      _InfoField(
        icon: Icons.flag_outlined,
        label: 'Estado cliente',
        value: _cliente.estadoCliente,
      ),
      _InfoField(
        icon: Icons.trending_up_rounded,
        label: 'Etapa',
        value: _cliente.etapa,
      ),
      _InfoField(
        icon: Icons.star_outline,
        label: 'Satisfaccion',
        value: _cliente.satisfaccion.replaceAll('_', ' '),
      ),
      if (_cliente.comentarioSatisfaccion != null &&
          _cliente.comentarioSatisfaccion!.isNotEmpty)
        _InfoField(
          icon: Icons.rate_review_outlined,
          label: 'Comentario satisfaccion',
          value: _cliente.comentarioSatisfaccion!,
          multiline: true,
        ),
    ];

    return _buildSectionCard(
      title: 'Identidad y estado',
      icon: Icons.info_outline_rounded,
      color: Colors.blue.shade600,
      children: _visibleFields(fields),
    );
  }

  Widget _buildContactSection() {
    final ubicacion = [
      if (_cliente.sector != null && _cliente.sector!.isNotEmpty)
        _cliente.sector,
      if (_cliente.ciudad != null && _cliente.ciudad!.isNotEmpty)
        _cliente.ciudad,
    ].join(', ');

    final fields = <Widget>[
      if (_cliente.direccion != null && _cliente.direccion!.isNotEmpty)
        _InfoField(
          icon: Icons.home_outlined,
          label: 'Direccion',
          value: _cliente.direccion!,
          multiline: true,
        ),
      if (ubicacion.isNotEmpty)
        _InfoField(
          icon: Icons.location_on_outlined,
          label: 'Ubicacion',
          value: ubicacion,
        ),
      if (_cliente.referenciaDireccion != null &&
          _cliente.referenciaDireccion!.isNotEmpty)
        _InfoField(
          icon: Icons.pin_drop_outlined,
          label: 'Referencia direccion',
          value: _cliente.referenciaDireccion!,
          multiline: true,
        ),
    ];

    return _buildSectionCard(
      title: 'Contacto y ubicacion',
      icon: Icons.contact_page_outlined,
      color: Colors.teal.shade600,
      children: _visibleFields(fields),
    );
  }

  Widget _buildBusinessSection() {
    final fields = <Widget>[
      _InfoField(
        icon: Icons.attach_money_outlined,
        label: 'Presupuesto estimado',
        value: _cliente.presupuestoEstimado != null
            ? 'RD\$${_cliente.presupuestoEstimado!.toStringAsFixed(0)}'
            : 'No especificado',
      ),
      if (_cliente.fechaInteres != null && _cliente.fechaInteres!.isNotEmpty)
        _InfoField(
          icon: Icons.event_available_outlined,
          label: 'Fecha interes',
          value: _formatStringDate(_cliente.fechaInteres),
        ),
      if (_cliente.ultimaCompraAt != null)
        _InfoField(
          icon: Icons.shopping_cart_checkout_outlined,
          label: 'Ultima compra',
          value: _formatDateTime(_cliente.ultimaCompraAt),
        ),
      if (_cliente.productosComprados != null &&
          _cliente.productosComprados!.isNotEmpty)
        _InfoField(
          icon: Icons.inventory_2_outlined,
          label: 'Productos comprados',
          value: _cliente.productosComprados!,
          multiline: true,
        ),
    ];

    return _buildSectionCard(
      title: 'Negocio e interes',
      icon: Icons.storefront_outlined,
      color: Colors.indigo.shade600,
      children: _visibleFields(fields),
    );
  }

  Widget _buildReservationSection() {
    final fields = <Widget>[
      if (_cliente.fechaReserva != null && _cliente.fechaReserva!.isNotEmpty)
        _InfoField(
          icon: Icons.event_note_outlined,
          label: 'Fecha reserva',
          value: _formatStringDate(_cliente.fechaReserva),
        ),
      if (_cliente.motivoReserva != null && _cliente.motivoReserva!.isNotEmpty)
        _InfoField(
          icon: Icons.assignment_late_outlined,
          label: 'Motivo reserva',
          value: _cliente.motivoReserva!,
          multiline: true,
        ),
    ];

    return _buildSectionCard(
      title: 'Reservas',
      icon: Icons.calendar_month_outlined,
      color: Colors.cyan.shade700,
      children: _visibleFields(fields),
    );
  }

  Widget _buildSeguimientoSection() {
    final fields = <Widget>[
      _InfoField(
        icon: Icons.chat_bubble_outline,
        label: 'Ultimo mensaje',
        value: _cliente.ultimoMensaje ?? 'Sin mensaje registrado',
        multiline: true,
      ),
      _InfoField(
        icon: Icons.mark_chat_unread_outlined,
        label: 'Total mensajes',
        value: _cliente.totalMensajes.toString(),
      ),
      _InfoField(
        icon: Icons.hourglass_bottom_outlined,
        label: 'Dias sin responder',
        value: _cliente.diasSinResponder.toString(),
      ),
      if (_cliente.ultimaInteraccionAt != null)
        _InfoField(
          icon: Icons.access_time_outlined,
          label: 'Ultima interaccion',
          value: _formatDateTime(_cliente.ultimaInteraccionAt),
        ),
      _InfoField(
        icon: Icons.support_agent_outlined,
        label: 'Requiere seguimiento',
        value: _cliente.requiereSeguimiento ? 'Si' : 'No',
      ),
      _InfoField(
        icon: Icons.repeat_outlined,
        label: 'Cantidad seguimientos',
        value: _cliente.cantidadSeguimientos.toString(),
      ),
      if (_cliente.proximoSeguimientoAt != null)
        _InfoField(
          icon: Icons.schedule_send_outlined,
          label: 'Proximo seguimiento',
          value: _formatDateTime(_cliente.proximoSeguimientoAt),
        ),
      if (_cliente.ultimoSeguimientoAt != null)
        _InfoField(
          icon: Icons.history_toggle_off_outlined,
          label: 'Ultimo seguimiento',
          value: _formatDateTime(_cliente.ultimoSeguimientoAt),
        ),
      if (_cliente.motivoSeguimiento != null &&
          _cliente.motivoSeguimiento!.isNotEmpty)
        _InfoField(
          icon: Icons.priority_high_rounded,
          label: 'Motivo seguimiento',
          value: _cliente.motivoSeguimiento!,
          multiline: true,
        ),
      if (_cliente.resumenConversacion != null &&
          _cliente.resumenConversacion!.isNotEmpty)
        _InfoField(
          icon: Icons.summarize_outlined,
          label: 'Resumen conversacion',
          value: _cliente.resumenConversacion!,
          multiline: true,
        ),
      if (_cliente.datosImportantes != null &&
          _cliente.datosImportantes!.isNotEmpty)
        _InfoField(
          icon: Icons.warning_amber_rounded,
          label: 'Datos importantes',
          value: _cliente.datosImportantes!,
          multiline: true,
        ),
      if (_cliente.preferenciasCliente != null &&
          _cliente.preferenciasCliente!.isNotEmpty)
        _InfoField(
          icon: Icons.tune_outlined,
          label: 'Preferencias cliente',
          value: _cliente.preferenciasCliente!,
          multiline: true,
        ),
      if (_cliente.notasInternas != null && _cliente.notasInternas!.isNotEmpty)
        _InfoField(
          icon: Icons.sticky_note_2_outlined,
          label: 'Notas internas',
          value: _cliente.notasInternas!,
          multiline: true,
        ),
    ];

    return _buildSectionCard(
      title: 'Seguimiento comercial',
      icon: Icons.notifications_outlined,
      color: Colors.orange.shade600,
      children: _visibleFields(fields),
    );
  }

  Widget _buildControlSection() {
    final fields = <Widget>[
      _InfoField(
        icon: Icons.pause_circle_outline,
        label: 'Bot pausado',
        value: _cliente.botPausado ? 'Si' : 'No',
      ),
      _InfoField(
        icon: Icons.person_outline_rounded,
        label: 'Humano tomo control',
        value: _cliente.humanoTomoControl ? 'Si' : 'No',
      ),
      if (_cliente.creadoEn != null)
        _InfoField(
          icon: Icons.add_circle_outline,
          label: 'Creado en',
          value: _formatDateTime(_cliente.creadoEn),
        ),
      if (_cliente.actualizadoEn != null)
        _InfoField(
          icon: Icons.update_outlined,
          label: 'Actualizado en',
          value: _formatDateTime(_cliente.actualizadoEn),
        ),
    ];

    return _buildSectionCard(
      title: 'Control del sistema',
      icon: Icons.settings_suggest_outlined,
      color: Colors.deepPurple.shade500,
      children: _visibleFields(fields),
    );
  }

  Widget _buildMetadataSection() {
    final metadataPretty = _formatMetadata(_cliente.metadata);

    final fields = <Widget>[
      _InfoField(
        icon: Icons.data_object_outlined,
        label: 'Metadata',
        value: metadataPretty,
        multiline: true,
        monospace: true,
      ),
    ];

    return _buildSectionCard(
      title: 'Metadata',
      icon: Icons.storage_outlined,
      color: Colors.brown.shade600,
      children: _visibleFields(fields),
    );
  }

  Widget _buildConversacionSection(List<ConversacionModel> mensajes) {
    final conversacionesProvider = context.watch<ConversacionesProvider>();
    final mensajesBot = mensajes
        .where((m) => m.role == 'assistant' || m.role == 'admin')
        .length;
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
                  Icon(
                    Icons.chat_outlined,
                    size: 20,
                    color: Colors.purple.shade600,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Conversacion',
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
              if (mensajes.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _StatusChip(
                      icon: Icons.smart_toy_rounded,
                      label: 'Bot: $mensajesBot',
                      color: Colors.blue,
                    ),
                    _StatusChip(
                      icon: Icons.person_rounded,
                      label: 'Cliente: $mensajesCliente',
                      color: Colors.green,
                    ),
                    _StatusChip(
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
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 40,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sin mensajes registrados',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...mensajes.reversed.take(5).map(_buildMensajePreview),
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
                  esAdmin
                      ? 'Bot'
                      : esTool
                      ? 'Herramienta'
                      : 'Cliente',
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
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                    height: 1.3,
                  ),
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

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

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
                  Icon(icon, size: 20, color: color),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ..._withSpacing(children),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _visibleFields(List<Widget> children) {
    if (_mostrarTodo) {
      return children;
    }

    return children.take(3).toList();
  }

  List<Widget> _withSpacing(List<Widget> children) {
    final widgets = <Widget>[];

    for (var i = 0; i < children.length; i++) {
      if (i > 0) {
        widgets.add(const SizedBox(height: 10));
      }
      widgets.add(children[i]);
    }

    return widgets;
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

  String _formatDateTime(DateTime? date) {
    if (date == null) {
      return 'No disponible';
    }

    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year.toString();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');

    return '$day/$month/$year $hour:$minute';
  }

  String _formatStringDate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'No disponible';
    }

    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      return value;
    }

    return _formatDateTime(parsed);
  }

  String _formatMetadata(Map<String, dynamic> metadata) {
    if (metadata.isEmpty) {
      return '{}';
    }

    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(metadata);
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
    final parts = name
        .trim()
        .split(' ')
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  String _formatHora(DateTime date) {
    final local = date.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}

class _InfoField extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool multiline;
  final bool monospace;

  const _InfoField({
    required this.icon,
    required this.label,
    required this.value,
    this.multiline = false,
    this.monospace = false,
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
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              SelectableText(
                value,
                minLines: multiline ? 1 : null,
                maxLines: multiline ? null : 3,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: multiline ? 1.4 : 1.2,
                  fontFamily: monospace ? 'monospace' : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatusChip({
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

class _EstadoBadgeGrande extends StatelessWidget {
  final String estado;

  const _EstadoBadgeGrande({required this.estado});

  @override
  Widget build(BuildContext context) {
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
}
