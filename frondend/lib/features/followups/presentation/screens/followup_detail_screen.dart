import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/scheduled_followup_model.dart';
import '../../models/conversation_recovery_model.dart';
import '../widgets/followup_status_badge.dart';
import '../widgets/followup_type_badge.dart';

class FollowupDetailScreen extends StatelessWidget {
  final ScheduledFollowupModel? scheduled;
  final ConversationRecoveryModel? recovery;
  final VoidCallback? onAbrirCRM;

  const FollowupDetailScreen({
    super.key,
    this.scheduled,
    this.recovery,
    this.onAbrirCRM,
  });

  @override
  Widget build(BuildContext context) {
    final nombre =
        scheduled?.nombreCliente ?? recovery?.nombreCliente ?? 'Sin nombre';
    final telefono =
        scheduled?.telefonoCliente ?? recovery?.telefonoCliente ?? '';
    final estado = scheduled?.estado ?? recovery?.estado ?? 'pendiente';
    final nivel = scheduled?.nivel ?? recovery?.nivel;
    final tipo = scheduled?.tipoSeguimiento ?? recovery?.etapa;
    final motivo = scheduled?.motivo ?? recovery?.motivoSeguimiento;
    final ultimoMensajeBot =
        scheduled?.ultimoMensajeBot ?? recovery?.ultimoMensajeBot;
    final ultimoMensajeCliente =
        scheduled?.mensajeCliente ?? recovery?.ultimoMensajeCliente;
    final proximoSeguimiento =
        scheduled?.proximoSeguimientoAt ?? recovery?.proximoSeguimientoAt;
    final creadoEn = scheduled?.creadoEn ?? recovery?.creadoEn;
    final actualizadoEn = scheduled?.actualizadoEn ?? recovery?.actualizadoEn;

    return Scaffold(
      appBar: AppBar(
        title: Text(nombre),
        actions: [
          if (telefono.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.copy_rounded),
              tooltip: 'Copiar teléfono',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: telefono));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Teléfono copiado')),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.chat_outlined),
              tooltip: 'Abrir WhatsApp',
              onPressed: () => _abrirWhatsApp(telefono),
            ),
          ],
          if (onAbrirCRM != null)
            IconButton(
              icon: const Icon(Icons.open_in_new_rounded),
              tooltip: 'Abrir en CRM',
              onPressed: onAbrirCRM,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.blue.shade50,
                          child: Text(
                            nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Colors.blue.shade600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                nombre,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  FollowupStatusBadge(estado: estado),
                                  if (nivel != null) ...[
                                    const SizedBox(width: 8),
                                    _buildInfoChip(
                                      'Nivel: $nivel',
                                      Colors.grey,
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (telefono.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.phone_outlined,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            telefono,
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Info card
            _buildSectionCard('Información del seguimiento', [
              if (tipo != null)
                _buildInfoRow('Tipo', FollowupTypeBadge(tipo: tipo)),
              if (motivo != null && motivo.isNotEmpty)
                _buildInfoRow('Motivo', motivo),
              if (proximoSeguimiento != null)
                _buildInfoRow(
                  'Próximo seguimiento',
                  _formatFechaDetalle(proximoSeguimiento),
                ),
              if (scheduled?.fechaObjetivo != null)
                _buildInfoRow(
                  'Fecha objetivo',
                  _formatFechaDetalle(scheduled!.fechaObjetivo!),
                ),
              if (scheduled?.clienteCompro != null)
                _buildInfoRow(
                  'Cliente compró',
                  scheduled!.clienteCompro! ? 'Sí' : 'No',
                ),
              if (scheduled?.fechaUltimaRespuestaCliente != null)
                _buildInfoRow(
                  'Última respuesta cliente',
                  _formatFechaDetalle(scheduled!.fechaUltimaRespuestaCliente!),
                ),
              if (scheduled?.categoriaSeguimiento != null)
                _buildInfoRow('Categoría', scheduled!.categoriaSeguimiento!),
            ]),
            const SizedBox(height: 12),
            // Messages card
            if (ultimoMensajeBot != null || ultimoMensajeCliente != null)
              _buildSectionCard('Últimos mensajes', [
                if (ultimoMensajeBot != null && ultimoMensajeBot.isNotEmpty)
                  _buildMessageBubble(
                    'Bot',
                    ultimoMensajeBot,
                    Colors.blue.shade50,
                    Colors.blue.shade700,
                  ),
                if (ultimoMensajeCliente != null &&
                    ultimoMensajeCliente.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildMessageBubble(
                    'Cliente',
                    ultimoMensajeCliente,
                    Colors.green.shade50,
                    Colors.green.shade700,
                  ),
                ],
              ]),
            const SizedBox(height: 12),
            // Dates card
            _buildSectionCard('Fechas', [
              if (creadoEn != null)
                _buildInfoRow('Creado', _formatFechaDetalle(creadoEn)),
              if (actualizadoEn != null)
                _buildInfoRow(
                  'Actualizado',
                  _formatFechaDetalle(actualizadoEn),
                ),
              if (recovery?.ultimoSeguimientoAt != null)
                _buildInfoRow(
                  'Último seguimiento',
                  _formatFechaDetalle(recovery!.ultimoSeguimientoAt!),
                ),
            ]),
            const SizedBox(height: 24),
            // Actions
            if (onAbrirCRM != null || telefono.isNotEmpty)
              Row(
                children: [
                  if (telefono.isNotEmpty) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _abrirWhatsApp(telefono),
                        icon: const Icon(Icons.chat_outlined),
                        label: const Text('WhatsApp'),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  if (onAbrirCRM != null)
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: onAbrirCRM,
                        icon: const Icon(Icons.open_in_new_rounded),
                        label: const Text('Abrir en CRM'),
                      ),
                    ),
                ],
              ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(String title, List<Widget> children) {
    return Card(
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
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: value is Widget
                ? value
                : Text(
                    value.toString(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(
    String sender,
    String message,
    Color bgColor,
    Color textColor,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            sender,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade800,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  String _formatFechaDetalle(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _abrirWhatsApp(String telefono) async {
    final cleanPhone = telefono.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('https://wa.me/$cleanPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
