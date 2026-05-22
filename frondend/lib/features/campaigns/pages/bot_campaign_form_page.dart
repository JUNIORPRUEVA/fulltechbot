import 'package:flutter/material.dart';

import '../models/bot_campaign_model.dart';

class BotCampaignFormPage extends StatefulWidget {
  final String botId;
  final BotCampaignModel? campaign;

  const BotCampaignFormPage({
    super.key,
    required this.botId,
    this.campaign,
  });

  @override
  State<BotCampaignFormPage> createState() => _BotCampaignFormPageState();
}

class _BotCampaignFormPageState extends State<BotCampaignFormPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _campaignCodeController;
  late final TextEditingController _campaignNameController;
  late final TextEditingController _keywordsController;
  late final TextEditingController _triggerPhrasesController;
  late final TextEditingController _initialMessageController;
  late final TextEditingController _campaignContextController;
  late final TextEditingController _mediaUrlsController;

  bool _active = true;

  @override
  void initState() {
    super.initState();
    final campaign = widget.campaign;
    _campaignCodeController =
        TextEditingController(text: campaign?.campaignCode ?? '');
    _campaignNameController =
        TextEditingController(text: campaign?.campaignName ?? '');
    _keywordsController = TextEditingController(
      text: (campaign?.keywords ?? const []).join('\n'),
    );
    _triggerPhrasesController = TextEditingController(
      text: (campaign?.triggerPhrases ?? const []).join('\n'),
    );
    _initialMessageController =
        TextEditingController(text: campaign?.initialMessage ?? '');
    _campaignContextController =
        TextEditingController(text: campaign?.campaignContext ?? '');
    _mediaUrlsController = TextEditingController(
      text: (campaign?.mediaUrls ?? const []).join('\n'),
    );
    _active = campaign?.active ?? true;
  }

  @override
  void dispose() {
    _campaignCodeController.dispose();
    _campaignNameController.dispose();
    _keywordsController.dispose();
    _triggerPhrasesController.dispose();
    _initialMessageController.dispose();
    _campaignContextController.dispose();
    _mediaUrlsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.campaign != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar campaña' : 'Nueva campaña'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            _SectionCard(
              title: 'Datos básicos',
              icon: Icons.campaign_outlined,
              children: [
                _buildTextField(
                  controller: _campaignCodeController,
                  label: 'Código de campaña',
                  helper: 'Ejemplo: sistema_4_camaras',
                  validator: _requiredValidator,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _campaignNameController,
                  label: 'Nombre de campaña',
                  validator: _requiredValidator,
                ),
                const SizedBox(height: 12),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Campaña activa'),
                  subtitle: const Text(
                    'Si está inactiva no será usada en la detección.',
                  ),
                  value: _active,
                  onChanged: (value) {
                    setState(() {
                      _active = value;
                    });
                  },
                ),
              ],
            ),
            _SectionCard(
              title: 'Detección',
              icon: Icons.radar_outlined,
              children: [
                _buildTextField(
                  controller: _keywordsController,
                  label: 'Palabras clave',
                  helper: 'Una por línea',
                  validator: (value) {
                    if (_splitLines(value).isEmpty) {
                      return 'Agrega al menos una palabra clave';
                    }
                    return null;
                  },
                  maxLines: 7,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _triggerPhrasesController,
                  label: 'Frases disparadoras',
                  helper: 'Una por línea',
                  maxLines: 6,
                ),
              ],
            ),
            _SectionCard(
              title: 'Respuesta del agente',
              icon: Icons.support_agent_outlined,
              children: [
                _buildTextField(
                  controller: _initialMessageController,
                  label: 'Mensaje inicial',
                  validator: _requiredValidator,
                  maxLines: 5,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _campaignContextController,
                  label: 'Contexto de campaña',
                  helper:
                      'Escribe aquí precio, oferta, garantía, instalación, objeciones y reglas de venta en texto claro.',
                  validator: _requiredValidator,
                  maxLines: 12,
                ),
              ],
            ),
            _SectionCard(
              title: 'Recursos',
              icon: Icons.photo_library_outlined,
              children: [
                _buildTextField(
                  controller: _mediaUrlsController,
                  label: 'Imágenes / videos / links',
                  helper: 'Una URL por línea',
                  maxLines: 5,
                ),
              ],
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.save_outlined),
              label: Text(isEditing ? 'Guardar cambios' : 'Crear campaña'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? helper,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        helperText: helper,
        alignLabelWithHint: maxLines > 1,
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.pop(context, {
      'campaign_code': _campaignCodeController.text.trim(),
      'campaign_name': _campaignNameController.text.trim(),
      'keywords': _splitLines(_keywordsController.text),
      'trigger_phrases': _splitLines(_triggerPhrasesController.text),
      'initial_message': _nullIfEmpty(_initialMessageController.text),
      'campaign_context': _nullIfEmpty(_campaignContextController.text),
      'media_urls': _splitLines(_mediaUrlsController.text),
      'active': _active,
    });
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Este campo es obligatorio';
    }
    return null;
  }

  static List<String> _splitLines(String? text) {
    if (text == null) return const [];
    return text
        .split(RegExp(r'[\n,]'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  static String? _nullIfEmpty(String text) {
    final trimmed = text.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
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
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}
