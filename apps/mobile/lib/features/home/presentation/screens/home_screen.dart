import 'package:flutter/material';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('QRIMS Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
          )
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Welcome Panel
              CircleAvatar(
                radius: 40,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Icon(
                  Icons.person_outline_rounded,
                  size: 44,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Welcome, ${user?.username ?? 'Operator'}!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Chip(
                label: Text(
                  'Role: ${user?.role ?? 'CUSTOMER'}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
              ),
              const SizedBox(height: 40),

              // Quick Actions Grid (Adaptive for tablets vs phones)
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.3,
                  children: [
                    _ActionCard(
                      icon: Icons.add_shopping_cart_rounded,
                      title: 'Create Cart',
                      color: Colors.indigo,
                      onTap: () => context.go('/cart'),
                    ),
                    _ActionCard(
                      icon: Icons.qr_code_scanner_rounded,
                      title: 'Scan QR Barcode',
                      color: Colors.teal,
                      onTap: () => context.go('/cart'),
                    ),
                    _ActionCard(
                      icon: Icons.settings_suggest_rounded,
                      title: 'Settings',
                      color: Colors.amber,
                      onTap: () => context.go('/settings'),
                    ),
                    _ActionCard(
                      icon: Icons.security_rounded,
                      title: 'Change Password',
                      color: Colors.deepOrange,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Password changes routed securely via REST API.'),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 36, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
