import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/conversacion_model.dart';
import '../providers/conversaciones_provider.dart';

class ChatDetailPage extends StatefulWidget {
  final String sessionId;
  final String nombreCliente;

  const ChatDetailPage({
    super.key,
    required this.sessionId,
    required this.nombreCliente,
  });

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final _mensajeController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<ConversacionesProvider>().listarMensajes(widget.sessionId);
    });
  }

  @override
  void dispose() {
    _mensajeController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _enviarMensaje() {
    final texto = _mensajeController.text.trim();
    if (texto.isEmpty) return;

    context.read<ConversacionesProvider>().enviarMensaje(
          sessionId: widget.sessionId,
          message: {
            'role': 'admin',
            'content': texto,
          },
        );
    _mensajeController.clear();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ConversacionesProvider>();
    final mensajes = provider.mensajesActuales;

    // Contar mensajes por tipo
    final mensajesBot = mensajes.where((m) => m.role == 'assistant' || m.role == 'admin').length;
    final mensajesCliente = mensajes.where((m) => m.role == 'user').length;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _getAvatarColor(widget.nombreCliente).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  _getInitials(widget.nombreCliente),
                  style: TextStyle(
                    color: _getAvatarColor(widget.nombreCliente),
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.nombreCliente,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '${mensajes.length} mensajes  ·  Bot: $mensajesBot  ·  Cliente: $mensajesCliente',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              context.read<ConversacionesProvider>().listarMensajes(widget.sessionId);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Error banner
          if (provider.error != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline_rounded, color: Colors.red.shade400, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      provider.error!,
                      style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

          // Mensajes
          Expanded(
            child: provider.cargando && mensajes.isEmpty
                ? const Center(child: CircularProgressIndicator(strokeWidth: 3))
                : mensajes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline_rounded,
                                size: 48, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Text(
                              'No hay mensajes en esta conversación',
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(12),
                        itemCount: mensajes.length,
                        itemBuilder: (context, index) {
                          final mensaje = mensajes[index];
                          final esAdmin = mensaje.role == 'admin' || mensaje.role == 'assistant';
                          final esCliente = mensaje.role == 'user';
                          final esTool = mensaje.role == 'tool';

                          if (esTool) {
                            return _ToolMensaje(mensaje: mensaje);
                          }

                          return _BurbujaMensaje(
                            mensaje: mensaje,
                            esAdmin: esAdmin,
                            esCliente: esCliente,
                          );
                        },
                      ),
          ),

          // Input
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              border: Border(
                top: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            padding: EdgeInsets.only(
              left: 12,
              right: 12,
              top: 8,
              bottom: MediaQuery.of(context).padding.bottom + 8,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _mensajeController,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _enviarMensaje(),
                    decoration: InputDecoration(
                      hintText: 'Escribe un mensaje...',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    onPressed: _enviarMensaje,
                  ),
                ),
              ],
            ),
          ),
        ],
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
}

class _BurbujaMensaje extends StatelessWidget {
  final ConversacionModel mensaje;
  final bool esAdmin;
  final bool esCliente;

  const _BurbujaMensaje({
    required this.mensaje,
    required this.esAdmin,
    required this.esCliente,
  });

  @override
  Widget build(BuildContext context) {
    final isRight = esAdmin;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: isRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Etiqueta de quién envía
          Padding(
            padding: EdgeInsets.only(
              left: isRight ? 0 : 38,
              right: isRight ? 38 : 0,
              bottom: 4,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isRight ? Icons.smart_toy_rounded : Icons.person_rounded,
                  size: 13,
                  color: isRight ? Colors.blue.shade500 : Colors.green.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  isRight ? 'Bot' : 'Cliente',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isRight ? Colors.blue.shade600 : Colors.green.shade700,
                  ),
                ),
              ],
            ),
          ),

          // Burbuja
          Row(
            mainAxisAlignment: isRight ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isRight) ...[
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.person_rounded, size: 16, color: Colors.green),
                ),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.70,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isRight
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isRight ? 18 : 4),
                      bottomRight: Radius.circular(isRight ? 4 : 18),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: isRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      Text(
                        mensaje.content,
                        style: TextStyle(
                          color: isRight ? Colors.white : Colors.black87,
                          fontSize: 15,
                        ),
                      ),
                      if (mensaje.createdAt != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          _formatHora(mensaje.createdAt!),
                          style: TextStyle(
                            fontSize: 11,
                            color: isRight
                                ? Colors.white.withValues(alpha: 0.7)
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (isRight) ...[
                const SizedBox(width: 6),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.smart_toy_rounded, size: 16, color: Colors.blue),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _formatHora(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _ToolMensaje extends StatelessWidget {
  final ConversacionModel mensaje;

  const _ToolMensaje({required this.mensaje});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          // Etiqueta
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.build_rounded, size: 13, color: Colors.orange.shade600),
                const SizedBox(width: 4),
                Text(
                  'Herramienta',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.shade700,
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.85,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.build_rounded, size: 16, color: Colors.orange.shade700),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        mensaje.content,
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
          ),
        ],
      ),
    );
  }
}
