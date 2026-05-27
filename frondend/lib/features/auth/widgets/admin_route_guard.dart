import 'package:flutter/material.dart';

import '../services/admin_session_service.dart';

class AdminRouteGuard extends StatefulWidget {
  final Widget child;
  final String redirectPath;

  const AdminRouteGuard({
    super.key,
    required this.child,
    required this.redirectPath,
  });

  @override
  State<AdminRouteGuard> createState() => _AdminRouteGuardState();
}

class _AdminRouteGuardState extends State<AdminRouteGuard> {
  bool _loading = true;
  bool _allowed = false;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final authenticated = await AdminSessionService.isAuthenticated();

    if (!mounted) return;

    if (!authenticated) {
      final encoded = Uri.encodeComponent(widget.redirectPath);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/login?redirect=$encoded');
      });
      return;
    }

    setState(() {
      _allowed = true;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(strokeWidth: 3)),
      );
    }

    if (!_allowed) {
      return const SizedBox.shrink();
    }

    return widget.child;
  }
}
