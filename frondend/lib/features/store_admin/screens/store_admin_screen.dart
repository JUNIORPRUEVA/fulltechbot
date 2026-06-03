import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/store_admin_provider.dart';
import 'store_config_screen.dart';
import 'store_banners_screen.dart';
import 'store_carts_screen.dart';
import 'store_payments_screen.dart';
import 'store_policies_screen.dart';

/// Pantalla principal de administración de tienda.
/// Se integra dentro del panel admin principal con tabs internas.
class StoreAdminScreen extends StatefulWidget {
  const StoreAdminScreen({super.key});

  @override
  State<StoreAdminScreen> createState() => _StoreAdminScreenState();
}

class _StoreAdminScreenState extends State<StoreAdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<_TabItem> _tabs = [
    _TabItem(icon: Icons.settings, label: 'Configuración'),
    _TabItem(icon: Icons.view_carousel, label: 'Banners'),
    _TabItem(icon: Icons.shopping_cart, label: 'Carritos'),
    _TabItem(icon: Icons.payment, label: 'Pagos'),
    _TabItem(icon: Icons.description, label: 'Políticas'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Administración de Tienda'),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: theme.colorScheme.surface,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: theme.colorScheme.primary,
              labelColor: theme.colorScheme.primary,
              unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.6),
              tabs: _tabs.map((tab) {
                return Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(tab.icon, size: 18),
                      const SizedBox(width: 6),
                      Text(tab.label),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          StoreConfigScreen(),
          StoreBannersScreen(),
          StoreCartsScreen(),
          StorePaymentsScreen(),
          StorePoliciesScreen(),
        ],
      ),
    );
  }
}

class _TabItem {
  final IconData icon;
  final String label;
  const _TabItem({required this.icon, required this.label});
}
