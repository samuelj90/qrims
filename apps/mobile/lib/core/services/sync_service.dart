import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../local_db/drift_database.dart';

class SyncService {
  final Ref _ref;
  final _dio = Dio();
  final _storage = const FlutterSecureStorage();

  SyncService(this._ref) {
    // Listen to network changes
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      if (result != ConnectivityResult.none) {
        processOfflineQueue();
        downloadCatalog();
      }
    });
  }

  AppDatabase get _db => _ref.read(databaseProvider);

  // Processes (drains) the local SQLite SyncQueue table to the NestJS server
  Future<void> processOfflineQueue() async {
    try {
      final queue = await _db.getSyncQueue();
      if (queue.isEmpty) return;

      final serverIp = await _storage.read(key: 'server_ip') ?? '192.168.1.12';
      final token = await _storage.read(key: 'jwt_token');
      if (token == null) return;

      for (final item in queue) {
        final payload = jsonDecode(item.payload);
        
        final response = await _dio.post(
          'http://$serverIp:3000${item.endpoint}',
          data: payload,
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );

        if (response.statusCode == 200 || response.statusCode == 210 || response.statusCode == 201) {
          // Success! Remove from local sync queue
          await _db.deleteSync(item.id);
        } else {
          // API gateway rejected, stop processing rest of queue for now
          break;
        }
      }
    } catch (_) {
      // Fail silently on networking issues; will retry on next connection change
    }
  }

  // Fetches real seeded products from backend and caches them locally
  Future<bool> downloadCatalog() async {
    try {
      final serverIp = await _storage.read(key: 'server_ip') ?? '192.168.1.12';
      final token = await _storage.read(key: 'jwt_token');
      if (token == null) return false;

      final response = await _dio.get(
        'http://$serverIp:3000/api/v1/products',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final products = data.map((json) {
          return LocalProduct(
            id: json['id'] as String,
            sku: json['sku'] as String,
            name: json['name'] as String,
            price: (json['price'] as num).toDouble(),
            discount: (json['discount'] as num).toDouble(),
            tax: (json['tax'] as num).toDouble(),
            compliment: json['compliment'] as String?,
            isActive: json['isActive'] as bool? ?? true,
          );
        }).toList();

        await _db.cacheProducts(products);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}

// Sync service provider
final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(ref);
});
