import 'dart:convert';

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

  late final TextEditingController _campaignNameController;
  late final TextEditingController _campaignCodeController;
  late final TextEditingController _campaignDescriptionController;
  late final TextEditingController _productNameController;
  late final TextEditingController _productIdController;
  late final TextEditingController _normalPriceController;
  late final TextEditingController _offerPriceController;
  late final TextEditingController _currencyController;
  late final TextEditingController _priorityController;
  late final TextEditingController _triggerPhrasesController;
  late final TextEditingController _keywordsController;
  late final TextEditingController _initialMessageController;
  late final TextEditingController _agentContextController;
  late final TextEditingController _salesInstructionsController;
  late final TextEditingController _negotiationRulesController;
  late final TextEditingController _objectionHandlingController;
  late final TextEditingController _closingQuestionsController;
  late final TextEditingController _locationRulesController;
  late final TextEditingController _warrantyInfoController;
  late final TextEditingController _installationInfoController;
  late final TextEditingController _mediaUrlsController;
  late final TextEditingController _crmInitialStatusController;
  late final TextEditingController _crmTagController;
  late final TextEditingController _extraCameraPriceController;
  late final TextEditingController _minimumExtraCameraPriceController;

  bool _active = true;
  String _campaignStatus = 'activa';

  @override
  void initState() {
    super.initState();
    final campaign = widget.campaign;
    _campaignNameController =
        TextEditingController(text: campaign?.campaignName ?? '');
    _campaignCodeController =
        TextEditingController(text: campaign?.campaignCode ?? '');
    _campaignDescriptionController =
        TextEditingController(text: campaign?.campaignDescription ?? '');
    _productNameController =
        TextEditingController(text: campaign?.productName ?? '');
    _productIdController =
        TextEditingController(text: campaign?.productId ?? '');
    _normalPriceController = TextEditingController(
      text: _doubleText(campaign?.normalPrice),
    );
    _offerPriceController = TextEditingController(
      text: _doubleText(campaign?.offerPrice),
    );
    _currencyController =
        TextEditingController(text: campaign?.currency ?? 'DOP');
    _priorityController = TextEditingController(
      text: (campaign?.priority ?? 0).toString(),
    );
    _triggerPhrasesController = TextEditingController(
      text: (campaign?.triggerPhrases ?? const []).join('\n'),
    );
    _keywordsController = TextEditingController(
      text: (campaign?.keywords ?? const []).join('\n'),
    );
    _initialMessageController =
        TextEditingController(text: campaign?.initialMessage ?? '');
    _agentContextController =
        TextEditingController(text: campaign?.agentContext ?? '');
    _salesInstructionsController =
        TextEditingController(text: campaign?.salesInstructions ?? '');
    _negotiationRulesController = TextEditingController(
      text: _jsonPretty(campaign?.negotiationRules),
    );
    _objectionHandlingController = TextEditingController(
      text: _jsonPretty(campaign?.objectionHandling),
    );
    _closingQuestionsController = TextEditingController(
      text: _jsonPretty(campaign?.closingQuestions),
    );
    _locationRulesController = TextEditingController(
      text: _jsonPretty(campaign?.locationRules),
    );
    _warrantyInfoController =
        TextEditingController(text: campaign?.warrantyInfo ?? '');
    _installationInfoController =
        TextEditingController(text: campaign?.installationInfo ?? '');
    _mediaUrlsController = TextEditingController(
      text: (campaign?.mediaUrls ?? const []).join('\n'),
    );
    _crmInitialStatusController =
        TextEditingController(text: campaign?.crmInitialStatus ?? 'Nuevo interesado');
    _crmTagController = TextEditingController(text: campaign?.crmTag ?? '');
    _extraCameraPriceController = TextEditingController(
      text: _doubleText(campaign?.extraCameraPrice),
    );
    _minimumExtraCameraPriceController = TextEditingController(
      text: _doubleText(campaign?.minimumExtraCameraPrice),
    );
    _active = campaign?.active ?? true;
    _campaignStatus = campaign?.campaignStatus ?? 'activa';
  }

  @override
  void dispose() {
    final controllers = [
      _campaignNameController,
      _campaignCodeController,
      _campaignDescriptionController,
      _productNameController,
      _productIdController,
      _normalPriceController,
      _offerPriceController,
      _currencyController,
      _priorityController,
      _triggerPhrasesController,
      _keywordsController,
      _initialMessageController,
      _agentContextController,
      _salesInstructionsController,
      _negotiationRulesController,
      _objectionHandlingController,
      _closingQuestionsController,
      _locationRulesController,
      _warrantyInfoController,
      _installationInfoController,
      _mediaUrlsController,
      _crmInitialStatusController,
      _crmTagController,
      _extraCameraPriceController,
      _minimumExtraCameraPriceController,
    ];

    for (final controller in controllers) {
      controller.dispose();
    }
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
              title: 'Datos generales',
              icon: Icons.campaign_outlined,
              children: [
                _buildTextField(
                  controller: _campaignNameController,
                  label: 'Nombre de campaña',
                  validator: _requiredValidator,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _campaignCodeController,
                  label: 'Código interno',
                  helper:
                      'Usa minúsculas y guiones bajos, por ejemplo: sistema_4_camaras',
                  validator: _requiredValidator,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _campaignDescriptionController,
                  label: 'Descripción de campaña',
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _campaignStatus,
                        decoration: const InputDecoration(
                          labelText: 'Estado de campaña',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'activa',
                            child: Text('Activa'),
                          ),
                          DropdownMenuItem(
                            value: 'pausada',
                            child: Text('Pausada'),
                          ),
                          DropdownMenuItem(
                            value: 'borrador',
                            child: Text('Borrador'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _campaignStatus = value ?? 'activa';
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        controller: _priorityController,
                        label: 'Prioridad',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Campaña activa'),
                  subtitle: const Text(
                    'Si está inactiva no será tomada en la detección.',
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
              title: 'Producto y oferta',
              icon: Icons.shopping_bag_outlined,
              children: [
                _buildTextField(
                  controller: _productNameController,
                  label: 'Nombre del producto',
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _productIdController,
                  label: 'Product ID opcional',
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _normalPriceController,
                        label: 'Precio normal',
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        controller: _offerPriceController,
                        label: 'Precio oferta',
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 96,
                      child: _buildTextField(
                        controller: _currencyController,
                        label: 'Moneda',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _extraCameraPriceController,
                        label: 'Precio cámara extra',
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        controller: _minimumExtraCameraPriceController,
                        label: 'Mínimo cámara extra',
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            _SectionCard(
              title: 'Detección',
              icon: Icons.radar_outlined,
              children: [
                _buildTextField(
                  controller: _triggerPhrasesController,
                  label: 'Frases disparadoras',
                  helper: 'Una por línea',
                  maxLines: 6,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _keywordsController,
                  label: 'Palabras clave',
                  helper: 'Una por línea. Incluye variantes como sin acentos.',
                  validator: (value) {
                    if (_splitLines(value).isEmpty) {
                      return 'Agrega al menos una palabra clave';
                    }
                    return null;
                  },
                  maxLines: 8,
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
                  controller: _agentContextController,
                  label: 'Contexto del agente',
                  maxLines: 4,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _salesInstructionsController,
                  label: 'Instrucciones de venta',
                  maxLines: 4,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _negotiationRulesController,
                  label: 'Reglas de negociación',
                  helper: 'Texto libre o JSON',
                  maxLines: 4,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _objectionHandlingController,
                  label: 'Objeciones frecuentes',
                  helper: 'Texto libre, JSON o una lista',
                  maxLines: 4,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _closingQuestionsController,
                  label: 'Preguntas de cierre',
                  helper: 'Texto libre, JSON o una lista',
                  maxLines: 4,
                ),
              ],
            ),
            _SectionCard(
              title: 'Recursos',
              icon: Icons.photo_library_outlined,
              children: [
                _buildTextField(
                  controller: _locationRulesController,
                  label: 'Reglas de ubicación',
                  helper: 'Texto libre o JSON',
                  maxLines: 4,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _warrantyInfoController,
                  label: 'Garantía',
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _installationInfoController,
                  label: 'Instalación',
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _mediaUrlsController,
                  label: 'Imágenes / videos / links',
                  helper: 'Una URL por línea',
                  maxLines: 5,
                ),
              ],
            ),
            _SectionCard(
              title: 'CRM',
              icon: Icons.sell_outlined,
              children: [
                _buildTextField(
                  controller: _crmInitialStatusController,
                  label: 'Estado CRM inicial',
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _crmTagController,
                  label: 'Etiqueta CRM',
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
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
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
      'campaign_description': _nullIfEmpty(_campaignDescriptionController.text),
      'product_name': _nullIfEmpty(_productNameController.text),
      'product_id': _nullIfEmpty(_productIdController.text),
      'normal_price': _toDouble(_normalPriceController.text),
      'offer_price': _toDouble(_offerPriceController.text),
      'currency': _currencyController.text.trim().isEmpty
          ? 'DOP'
          : _currencyController.text.trim(),
      'campaign_status': _campaignStatus,
      'trigger_phrases': _splitLines(_triggerPhrasesController.text),
      'keywords': _splitLines(_keywordsController.text),
      'initial_message': _nullIfEmpty(_initialMessageController.text),
      'agent_context': _nullIfEmpty(_agentContextController.text),
      'sales_instructions': _nullIfEmpty(_salesInstructionsController.text),
      'negotiation_rules': _parseFlexibleField(_negotiationRulesController.text),
      'objection_handling':
          _parseFlexibleField(_objectionHandlingController.text, fallbackToList: true),
      'closing_questions':
          _parseFlexibleField(_closingQuestionsController.text, fallbackToList: true),
      'extra_camera_price': _toDouble(_extraCameraPriceController.text),
      'minimum_extra_camera_price':
          _toDouble(_minimumExtraCameraPriceController.text),
      'location_rules': _parseFlexibleField(_locationRulesController.text),
      'warranty_info': _nullIfEmpty(_warrantyInfoController.text),
      'installation_info': _nullIfEmpty(_installationInfoController.text),
      'media_urls': _splitLines(_mediaUrlsController.text),
      'crm_initial_status':
          _crmInitialStatusController.text.trim().isEmpty
              ? 'Nuevo interesado'
              : _crmInitialStatusController.text.trim(),
      'crm_tag': _nullIfEmpty(_crmTagController.text),
      'priority': _toInt(_priorityController.text),
      'active': _active,
    });
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Este campo es obligatorio';
    }
    return null;
  }

  static String _doubleText(double? value) {
    if (value == null || value == 0) return '';
    return value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2);
  }

  static String _jsonPretty(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(value);
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

  static dynamic _parseFlexibleField(
    String text, {
    bool fallbackToList = false,
  }) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return fallbackToList ? <String>[] : <String, dynamic>{};
    }

    try {
      return jsonDecode(trimmed);
    } catch (_) {
      if (fallbackToList) {
        return _splitLines(trimmed);
      }
      return trimmed;
    }
  }

  static double _toDouble(String text) {
    return double.tryParse(text.trim()) ?? 0;
  }

  static int _toInt(String text) {
    return int.tryParse(text.trim()) ?? 0;
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
