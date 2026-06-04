import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/shared_widgets/adaptive_scaffold.dart';
import '../../../cart/presentation/controllers/cart_controller.dart';

class ShellScreen extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final location = state.uri.toString();
    final selectedIndex = _getSelectedIndex(location);

    final cartState = ref.watch(cartProvider);
    final totalCount = cartState.items.fold<int>(0, (sum, item) => sum + item.quantity);

    return AdaptiveScaffold(
      selectedIndex: selectedIndex,
      onDestinationSelected: (idx) => _onItemTapped(idx, context),
      destinations: [
        const AdaptiveDestination(
          label: 'Home',
          icon: Icon(Icons.home_rounded),
          selectedIcon: Icon(Icons.home_filled),
        ),
        AdaptiveDestination(
          label: 'Cart',
          icon: totalCount > 0
              ? Badge(
                  label: Text('$totalCount'),
                  child: const Icon(Icons.shopping_cart_outlined),
                )
              : const Icon(Icons.shopping_cart_outlined),
          selectedIcon: totalCount > 0
              ? Badge(
                  label: Text('$totalCount'),
                  child: const Icon(Icons.shopping_cart_rounded),
                )
              : const Icon(Icons.shopping_cart_rounded),
        ),
        const AdaptiveDestination(
          label: 'Settings',
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings_rounded),
        ),
      ],
      body: child,
    );
  }
}
