import 'dart:io';
import 'dart:typed_data';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../features/cart/domain/models/cart_item.dart';

class DiscoveredPrinter {
  final String ip;
  final int port;

  const DiscoveredPrinter({
    required this.ip,
    required this.port,
  });
}

class PrintService {
  static const int defaultEscPosPort = 9100; // Industry standard for ESC/POS network printers

  // Scans the local subnet for responsive receipt printers on raw port 9100
  static Stream<DiscoveredPrinter> discoverPrinters() async* {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) return;

    // Discover the base subnet (e.g., 192.168.1.xxx)
    String subnet = '192.168.1';
    try {
      final interfaces = await NetworkInterface.list(
        includeLinkLocal: false,
        type: InternetAddressType.IPv4,
      );
      if (interfaces.isNotEmpty) {
        final ip = interfaces.first.addresses.first.address;
        final parts = ip.split('.');
        if (parts.length == 4) {
          subnet = '${parts[0]}.${parts[1]}.${parts[2]}';
        }
      }
    } catch (_) {
      // Fallback to default class C subnet prefix
    }

    // Probes IP addresses on the local subnet concurrently
    // Port 9100 handles receipt printers
    final futures = <Future<DiscoveredPrinter?>>[];
    for (int i = 1; i <= 254; i++) {
      final host = '$subnet.$i';
      futures.add(
        Socket.connect(host, defaultEscPosPort, timeout: const Duration(milliseconds: 300))
            .then((socket) {
          socket.destroy();
          return DiscoveredPrinter(ip: host, port: defaultEscPosPort);
        }).catchError((_) => null),
      );
    }

    final results = await Future.wait(futures);
    for (final printer in results) {
      if (printer != null) {
        yield printer;
      }
    }
  }

  // Formats and prints the receipt using standard ESC/POS command sequences
  static Future<bool> printReceipt({
    required String printerIp,
    required List<CartItem> items,
    required double total,
    String supermarketName = 'QRBS SUPERMARKET',
    String supermarketAddress = '123/Street, City',
  }) async {
    Socket? socket;
    try {
      socket = await Socket.connect(printerIp, defaultEscPosPort, timeout: const Duration(seconds: 3));

      // ESC/POS Commands
      final Uint8List escInit = Uint8List.fromList([0x1B, 0x40]);      // Initialize printer
      final Uint8List escCenter = Uint8List.fromList([0x1B, 0x61, 0x01]); // Align Center
      final Uint8List escLeft = Uint8List.fromList([0x1B, 0x61, 0x00]);   // Align Left
      final Uint8List escFeed = Uint8List.fromList([0x0A]);            // Feed line
      final Uint8List escCut = Uint8List.fromList([0x1D, 0x56, 0x41, 0x03]); // Paper Cut

      final buffer = StringBuffer();
      
      // Print Header
      socket.add(escInit);
      socket.add(escCenter);
      socket.write('$supermarketName\n');
      socket.write('$supermarketAddress\n');
      socket.write('--------------------------------\n');
      socket.add(escFeed);

      // Print Items list
      socket.add(escLeft);
      for (final item in items) {
        // Line format: Name  Qty x Price
        socket.write('${item.name}\n');
        final lineTotal = item.totalPrice.toStringAsFixed(2);
        socket.write('  ${item.quantity} x \$${item.price.toStringAsFixed(2)}   Total: \$$lineTotal\n');
      }
      
      socket.write('--------------------------------\n');
      socket.add(escCenter);
      socket.write('GRAND TOTAL: \$${total.toStringAsFixed(2)}\n');
      socket.write('Thank you for shopping with us!\n');
      socket.add(escFeed);
      socket.add(escFeed);
      
      // Cut paper
      socket.add(escCut);
      await socket.flush();
      return true;
    } catch (e) {
      return false;
    } finally {
      socket?.destroy();
    }
  }
}
