import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/shared_widgets/adaptive_scaffold.dart';

class ShellScreen extends StatelessWidget {
  final Widget child;
  final GoRouterState state;

  const ShellScreen({
    super.key,
    required this.child,
    required this.state,
  });

  int _getSelectedIndex(String location) {
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/cart')) return 1;
    if (location.startsWith('/settings')) return 2;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/cart');
        break;
      case 2:
        context.go('/settings');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = state.uri.toString();
    final selectedIndex = _getSelectedIndex(location);

    return AdaptiveScaffold(
      selectedIndex: selectedIndex,
      onDestinationSelected: (idx) => _onItemTapped(idx, context),
      destinations: const [
        AdaptiveDestination(
          label: 'Home',
          icon: Icons.home_rounded,
          selectedIcon: Icons.home_filled,
        ),
        AdaptiveDestination(
          label: 'Cart',
          icon: Icons.shopping_cart_outlined,
          selectedIcon: Icons.shopping_cart_rounded,
        ),
        AdaptiveDestination(
          label: 'Settings',
          icon: Icons.settings_outlined,
          selectedIcon: Icons.settings_rounded,
        ),
      ],
      body: child,
    );
  }
}
