import 'package:flutter/material.dart';

class FilterOption {
  final String label;
  final String value;

  const FilterOption({required this.label, required this.value});
}

class FollowupFilterBar extends StatefulWidget {
  final List<FilterOption> estadoOptions;
  final List<FilterOption>? secondaryOptions;
  final String? secondaryLabel;
  final List<FilterOption> fechaOptions;
  final String? selectedEstado;
  final String? selectedSecondary;
  final String? selectedFecha;
  final String? searchQuery;
  final ValueChanged<String?> onEstadoChanged;
  final ValueChanged<String?> onSecondaryChanged;
  final ValueChanged<String?> onFechaChanged;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClear;

  const FollowupFilterBar({
    super.key,
    required this.estadoOptions,
    this.secondaryOptions,
    this.secondaryLabel,
    required this.fechaOptions,
    this.selectedEstado,
    this.selectedSecondary,
    this.selectedFecha,
    this.searchQuery,
    required this.onEstadoChanged,
    required this.onSecondaryChanged,
    required this.onFechaChanged,
    required this.onSearchChanged,
    required this.onClear,
  });

  @override
  State<FollowupFilterBar> createState() => _FollowupFilterBarState();
}

class _FollowupFilterBarState extends State<FollowupFilterBar> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.searchQuery ?? '';
  }

  @override
  void didUpdateWidget(FollowupFilterBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchQuery != oldWidget.searchQuery) {
      _searchController.text = widget.searchQuery ?? '';
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool get _hasActiveFilters =>
      widget.selectedEstado != null ||
      widget.selectedSecondary != null ||
      widget.selectedFecha != null ||
      (widget.searchQuery?.isNotEmpty ?? false);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search bar
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: TextField(
            controller: _searchController,
            onChanged: widget.onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Buscar por nombre, teléfono o motivo...',
              prefixIcon: const Icon(Icons.search_rounded, size: 22),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        widget.onSearchChanged('');
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              _buildDropdownChip(
                label: _getSelectedLabel(
                  widget.estadoOptions,
                  widget.selectedEstado,
                  'Estado',
                ),
                icon: Icons.filter_alt_outlined,
                onTap: () => _showFilterSheet(
                  context,
                  'Estado',
                  widget.estadoOptions,
                  widget.selectedEstado,
                  widget.onEstadoChanged,
                ),
              ),
              if (widget.secondaryOptions != null) ...[
                const SizedBox(width: 8),
                _buildDropdownChip(
                  label: _getSelectedLabel(
                    widget.secondaryOptions!,
                    widget.selectedSecondary,
                    widget.secondaryLabel ?? 'Tipo',
                  ),
                  icon: Icons.label_outline,
                  onTap: () => _showFilterSheet(
                    context,
                    widget.secondaryLabel ?? 'Tipo',
                    widget.secondaryOptions!,
                    widget.selectedSecondary,
                    widget.onSecondaryChanged,
                  ),
                ),
              ],
              const SizedBox(width: 8),
              _buildDropdownChip(
                label: _getSelectedLabel(
                  widget.fechaOptions,
                  widget.selectedFecha,
                  'Fecha',
                ),
                icon: Icons.calendar_today_outlined,
                onTap: () => _showFilterSheet(
                  context,
                  'Fecha',
                  widget.fechaOptions,
                  widget.selectedFecha,
                  widget.onFechaChanged,
                ),
              ),
              if (_hasActiveFilters) ...[
                const SizedBox(width: 8),
                ActionChip(
                  label: const Text('Limpiar', style: TextStyle(fontSize: 12)),
                  avatar: const Icon(Icons.clear_all_rounded, size: 16),
                  onPressed: widget.onClear,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  String _getSelectedLabel(
    List<FilterOption> options,
    String? selected,
    String defaultLabel,
  ) {
    if (selected == null) return defaultLabel;
    final found = options.where((o) => o.value == selected);
    return found.isNotEmpty ? found.first.label : selected;
  }

  Widget _buildDropdownChip({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      avatar: Icon(icon, size: 16),
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  void _showFilterSheet(
    BuildContext context,
    String title,
    List<FilterOption> options,
    String? selected,
    ValueChanged<String?> onChanged,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('Todos'),
                      selected: selected == null,
                      onSelected: (_) {
                        onChanged(null);
                        Navigator.pop(ctx);
                      },
                    ),
                    ...options.map((option) {
                      return FilterChip(
                        label: Text(option.label),
                        selected: selected == option.value,
                        onSelected: (_) {
                          onChanged(option.value);
                          Navigator.pop(ctx);
                        },
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }
}
