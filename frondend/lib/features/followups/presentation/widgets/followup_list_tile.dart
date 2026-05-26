import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/scheduled_followup_model.dart';
import '../../models/conversation_recovery_model.dart';
import 'followup_status_badge.dart';
import 'followup_type_badge.dart';

/// Tile genérico para mostrar seguimientos programados
class ScheduledFollowupTile extends StatelessWidget {
  final ScheduledFollowupModel followup;
  final VoidCallback? onTap;
  final VoidCallback? onFinalizar;
  final VoidCallback? onCancelar;
  final VoidCallback? onReactivar;
  final VoidCallback? onAbrirCRM;

  const ScheduledFollowupTile({
    super.key,
    required this.followup,
    this.onTap,
    this.onFinalizar,
    this.onCancelar,
    this.onReactivar,
    this.onAbrirCRM,
  });

  @override
  Widget build(BuildContext context) {
    return _BaseFollowupTile(
      nombreCliente: followup.nombreCliente ?? 'Sin nombre',
      telefono: followup.telefonoCliente ?? '',
      estado: followup.estado ?? 'pendiente',
      tipo: followup.tipoSeguimiento,
      nivel: followup.nivel > 0 ? followup.nivel.toString() : null,
      motivo: followup.motivo,
      ultimoMensaje: followup.ultimoMensajeBot,
      mensajeCliente: followup.mensajeCliente,
      fechaObjetivo: followup.fechaObjetivo,
      proximoSeguimiento: followup.proximoSeguimientoAt,
      estaVencido: followup.estaVencido,
      clienteCompro: followup.clienteCompro,
      fechaUltimaRespuesta: followup.fechaUltimaRespuestaCliente,
      onTap: onTap,
      onFinalizar: onFinalizar,
      onCancelar: onCancelar,
      onReactivar: onReactivar,
      onAbrirCRM: onAbrirCRM,
    );
  }
}

/// Tile genérico para mostrar recuperaciones de conversación
class RecoveryFollowupTile extends StatelessWidget {
  final ConversationRecoveryModel followup;
  final VoidCallback? onTap;
  final VoidCallback? onFinalizar;
  final VoidCallback? onCancelar;
  final VoidCallback? onReactivar;
  final VoidCallback? onAbrirCRM;

  const RecoveryFollowupTile({
    super.key,
    required this.followup,
    this.onTap,
    this.onFinalizar,
    this.onCancelar,
    this.onReactivar,
    this.onAbrirCRM,
  });

  @override
  Widget build(BuildContext context) {
    return _BaseFollowupTile(
      nombreCliente: followup.nombreCliente ?? 'Sin nombre',
      telefono: followup.telefonoCliente ?? '',
      estado: followup.estado ?? 'pendiente',
      tipo: followup.etapa,
      nivel: followup.nivel,
      motivo: followup.motivoSeguimiento,
      ultimoMensaje: followup.ultimoMensajeBot,
      mensajeCliente: followup.ultimoMensajeCliente,
      fechaObjetivo: null,
      proximoSeguimiento: followup.proximoSeguimientoAt,
      estaVencido: followup.estaVencido,
      prioridad: followup.prioridad,
      clienteCompro: null,
      fechaUltimaRespuesta: followup.ultimoSeguimientoAt,
      onTap: onTap,
      onFinalizar: onFinalizar,
      onCancelar: onCancelar,
      onReactivar: onReactivar,
      onAbrirCRM: onAbrirCRM,
    );
  }
}

class _BaseFollowupTile extends StatelessWidget {
  final String nombreCliente;
  final String telefono;
  final String estado;
  final String? tipo;
  final String? nivel;
  final String? motivo;
  final String? ultimoMensaje;
  final String? mensajeCliente;
  final DateTime? fechaObjetivo;
  final DateTime? proximoSeguimiento;
  final bool estaVencido;
  final String? prioridad;
  final bool? clienteCompro;
  final DateTime? fechaUltimaRespuesta;
  final VoidCallback? onTap;
  final VoidCallback? onFinalizar;
  final VoidCallback? onCancelar;
  final VoidCallback? onReactivar;
  final VoidCallback? onAbrirCRM;

  const _BaseFollowupTile({
    required this.nombreCliente,
    required this.telefono,
    required this.estado,
    this.tipo,
    this.nivel,
    this.motivo,
    this.ultimoMensaje,
    this.mensajeCliente,
    this.fechaObjetivo,
    this.proximoSeguimiento,
    required this.estaVencido,
    this.prioridad,
    this.clienteCompro,
    this.fechaUltimaRespuesta,
    this.onTap,
    this.onFinalizar,
    this.onCancelar,
    this.onReactivar,
    this.onAbrirCRM,
  });

  @override
  Widget build(BuildContext context) {
    final isPendiente = estado == 'pendiente';
    final isFinalizado = estado == 'finalizado' || estado == 'recuperado';
    final isCancelado = estado == 'cancelado';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: estaVencido && isPendiente
              ? Colors.red.shade200
              : Colors.grey.shade200,
          width: estaVencido && isPendiente ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: _getAvatarColor().withValues(alpha: 0.15),
                    child: Text(
                      nombreCliente.isNotEmpty
                          ? nombreCliente[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: _getAvatarColor(),
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                nombreCliente,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (estaVencido && isPendiente)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'VENCIDO',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.red.shade700,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            FollowupStatusBadge(estado: estado, fontSize: 9),
                            if (tipo != null) ...[
                              const SizedBox(width: 6),
                              Flexible(
                                child: FollowupTypeBadge(
                                  tipo: tipo!,
                                  fontSize: 9,
                                ),
                              ),
                            ],
                            if (nivel != null) ...[
                              const SizedBox(width: 6),
                              _buildNivelBadge(nivel!),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Motivo
              if (motivo != null && motivo!.isNotEmpty) ...[
                Text(
                  motivo!,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
              ],
              // Mensajes
              if (ultimoMensaje != null && ultimoMensaje!.isNotEmpty) ...[
                _buildMessageRow(
                  Icons.smart_toy_outlined,
                  'Bot: ${ultimoMensaje!}',
                  Colors.blue.shade600,
                ),
              ],
              if (mensajeCliente != null && mensajeCliente!.isNotEmpty) ...[
                const SizedBox(height: 4),
                _buildMessageRow(
                  Icons.person_outline,
                  'Cliente: ${mensajeCliente!}',
                  Colors.green.shade600,
                ),
              ],
              const SizedBox(height: 8),
              // Fechas
              Row(
                children: [
                  if (proximoSeguimiento != null)
                    _buildDateChip(
                      Icons.schedule_outlined,
                      _formatFecha(proximoSeguimiento!),
                      estaVencido && isPendiente
                          ? Colors.red.shade600
                          : Colors.grey.shade600,
                    ),
                  if (fechaObjetivo != null) ...[
                    const SizedBox(width: 8),
                    _buildDateChip(
                      Icons.flag_outlined,
                      'Obj: ${_formatFecha(fechaObjetivo!)}',
                      Colors.grey.shade600,
                    ),
                  ],
                  if (clienteCompro == true) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'COMPRÓ',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              // Prioridad (solo recovery)
              if (prioridad != null && prioridad != 'bajo') ...[
                const SizedBox(height: 6),
                _buildPrioridadBadge(prioridad!),
              ],
              // Actions
              if (isPendiente || isFinalizado || isCancelado) ...[
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (isPendiente) ...[
                      _buildActionButton(
                        context,
                        icon: Icons.check_circle_outline,
                        label: 'Finalizar',
                        color: Colors.green,
                        onTap: onFinalizar,
                      ),
                      const SizedBox(width: 4),
                      _buildActionButton(
                        context,
                        icon: Icons.cancel_outlined,
                        label: 'Cancelar',
                        color: Colors.red,
                        onTap: onCancelar,
                      ),
                    ],
                    if (isFinalizado || isCancelado)
                      _buildActionButton(
                        context,
                        icon: Icons.refresh_rounded,
                        label: 'Reactivar',
                        color: Colors.orange,
                        onTap: onReactivar,
                      ),
                    if (telefono.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      _buildActionButton(
                        context,
                        icon: Icons.copy_rounded,
                        label: '',
                        color: Colors.grey,
                        compact: true,
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: telefono));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Teléfono copiado'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 4),
                      _buildActionButton(
                        context,
                        icon: Icons.chat_outlined,
                        label: '',
                        color: Colors.green,
                        compact: true,
                        onTap: () => _abrirWhatsApp(telefono),
                      ),
                    ],
                    if (onAbrirCRM != null) ...[
                      const SizedBox(width: 4),
                      _buildActionButton(
                        context,
                        icon: Icons.open_in_new_rounded,
                        label: '',
                        color: Colors.blue,
                        compact: true,
                        onTap: onAbrirCRM,
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageRow(IconData icon, String text, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildDateChip(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 3),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildNivelBadge(String nivel) {
    Color color;
    switch (nivel.toLowerCase()) {
      case 'alto':
        color = Colors.red;
        break;
      case 'medio':
        color = Colors.orange;
        break;
      default:
        color = Colors.blue;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        nivel.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _buildPrioridadBadge(String prioridad) {
    Color color;
    String label;
    switch (prioridad) {
      case 'alto':
        color = Colors.red;
        label = '⚠ ALTA PRIORIDAD';
        break;
      case 'medio':
        color = Colors.orange;
        label = '⚠ PRIORIDAD MEDIA';
        break;
      default:
        return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onTap,
    bool compact = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 8 : 10,
            vertical: 6,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: compact ? 18 : 16, color: color),
              if (!compact && label.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getAvatarColor() {
    final hash = nombreCliente.hashCode;
    final colors = [
      Colors.blue,
      Colors.teal,
      Colors.purple,
      Colors.indigo,
      Colors.cyan,
      Colors.deepOrange,
    ];
    return colors[hash.abs() % colors.length];
  }

  String _formatFecha(DateTime date) {
    final now = DateTime.now();
    final diff = date.difference(now);

    if (diff.isNegative) {
      final absDiff = diff.abs();
      if (absDiff.inMinutes < 60) return 'Hace ${absDiff.inMinutes}min';
      if (absDiff.inHours < 24) return 'Hace ${absDiff.inHours}h';
      if (absDiff.inDays == 1) return 'Ayer';
      return 'Vencido ${absDiff.inDays}d';
    }

    if (diff.inMinutes < 60) return 'En ${diff.inMinutes}min';
    if (diff.inHours < 24) return 'En ${diff.inHours}h';
    if (diff.inDays == 0) return 'Hoy';
    if (diff.inDays == 1) return 'Mañana';
    if (diff.inDays < 7) return 'En ${diff.inDays}d';
    return '${date.day}/${date.month}/${date.year}';
  }

  void _abrirWhatsApp(String telefono) async {
    final cleanPhone = telefono.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('https://wa.me/$cleanPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
