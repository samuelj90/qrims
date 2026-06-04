import 'package:flutter/material';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../controllers/cart_controller.dart';
import '../../auth/presentation/controllers/auth_controller.dart';
import '../../../../core/services/print_service.dart';
import '../../domain/models/cart_item.dart';

class CartHomeScreen extends ConsumerWidget {
  const CartHomeScreen({super.key});

  // Mock function representing scanned QR codes (AES decrypted payloads)
  void _simulateScan(BuildContext context, WidgetRef ref) {
    // Legacy scan format: ID:Name:Price:Discount:Tax:Compliment
    const mockPayloads = [
      '101:Colgate Toothpaste:45.0:2.0:1.5:Free toothbrush inside!',
      '102:Oreo Biscuits:25.0:0.0:1.0:Buy 2 get 1 promotion!',
      '103:Pure Olive Oil:180.0:10.0:8.0:10% holiday discount included'
    ];

    // Pick a random mock scanned product to add to the cart
    final randomPayload = (mockPayloads..shuffle()).first;
    ref.read(cartProvider.notifier).addScannedItem(randomPayload);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Scanned: ${randomPayload.split(':')[1]}'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  // Shows Wi-Fi scanning dialogue and trigger ESC/POS print commands
  void _showPrintDialog(BuildContext context, List<CartItem> items, double total) {
    showDialog(
      context: context,
      builder: (context) {
        final List<DiscoveredPrinter> printers = [];
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Discover Wi-Fi Billing Printers'),
              content: SizedBox(
                width: double.maxFinite,
                height: 250,
                child: StreamBuilder<DiscoveredPrinter>(
                  stream: PrintService.discoverPrinters(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting && printers.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Scanning Wi-Fi subnet for port 9100...'),
                          ],
                        ),
                      );
                    }
                    if (snapshot.hasData) {
                      final newPrinter = snapshot.data!;
                      if (!printers.any((p) => p.ip == newPrinter.ip)) {
                        printers.add(newPrinter);
                      }
                    }
                    if (printers.isEmpty) {
                      return const Center(child: Text('No network printers found. Check Wi-Fi.'));
                    }

                    return ListView.builder(
                      itemCount: printers.length,
                      itemBuilder: (context, index) {
                        final printer = printers[index];
                        return ListTile(
                          leading: const Icon(Icons.print_rounded, color: Colors.indigo),
                          title: Text('Receipt Printer (IP: ${printer.ip})'),
                          subtitle: Text('Port: ${printer.port} - ESC/POS Standard'),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () async {
                            Navigator.pop(context); // Close scan dialog
                            
                            // Show printing loader
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );

                            final success = await PrintService.printReceipt(
                              printerIp: printer.ip,
                              items: items,
                              total: total,
                            );

                            if (context.mounted) {
                              Navigator.pop(context); // Close printer loader
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(success
                                      ? 'Receipt printed successfully!'
                                      : 'Printing failed. Check network.'),
                                  backgroundColor: success ? Colors.green : Colors.red,
                                ),
                              );
                            }
                          },
                        );
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CANCEL'),
                )
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartStateProvider(ref));
    final cart = ref.watch(cartProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping Cart'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded),
            tooltip: 'Scan Barcode',
            onPressed: () => _simulateScan(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded),
            tooltip: 'Clear Cart',
            onPressed: () => ref.read(cartProvider.notifier).clearCart(),
          ),
        ],
      ),
      body: cart.items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  const Text('Cart is empty. Start scanning products!'),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _simulateScan(context, ref),
                    icon: const Icon(Icons.add_to_photos_rounded),
                    label: const Text('Simulate Scan'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: cart.items.length,
                    itemBuilder: (context, index) {
                      final item = cart.items[index];
                      return Dismissible(
                        key: Key(item.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Theme.of(context).colorScheme.error,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete_forever, color: Colors.white),
                        ),
                        onDismissed: (_) {
                          ref.read(cartProvider.notifier).removeItem(item.id);
                        },
                        child: Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Price: \$${item.price.toStringAsFixed(2)} | Tax: +\$${item.tax} | Disc: -\$${item.discount}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Subtotal: \$${item.totalPrice.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline),
                                      onPressed: () => ref
                                          .read(cartProvider.notifier)
                                          .updateQuantity(item.id, item.quantity - 1),
                                    ),
                                    Text(
                                      '${item.quantity}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline),
                                      onPressed: () => ref
                                          .read(cartProvider.notifier)
                                          .updateQuantity(item.id, item.quantity + 1),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                // Summary and checkout panel
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                    border: Border(
                      top: BorderSide(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                  ),
                  child: SafeArea(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.between,
                          children: [
                            const Text(
                              'Grand Total:',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '\$${cart.grandTotal.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (cart.successMessage != null) ...[
                          Text(
                            cart.successMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (cart.errorMessage != null) ...[
                          Text(
                            cart.errorMessage!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        ElevatedButton(
                          onPressed: cart.isSubmitting
                              ? null
                              : () => ref
                                  .read(cartProvider.notifier)
                                  .checkout('192.168.1.12'), // uses gateway IP from state
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Theme.of(context).colorScheme.onPrimary,
                          ),
                          child: cart.isSubmitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'PROCEED TO CHECKOUT',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: () => _showPrintDialog(context, cart.items, cart.grandTotal),
                          icon: const Icon(Icons.print_rounded),
                          label: const Text(
                            'DISCOVER & PRINT BILL',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              ],
            ),
    );
  }
  
  // Custom provider helper to prevent rebuild errors
  dynamic cartStateProvider(WidgetRef ref) => cartProvider;
}
