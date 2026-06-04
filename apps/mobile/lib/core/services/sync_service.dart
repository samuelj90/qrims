import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../local_db/drift_database.dart';
import '../config/app_config.dart';
import '../network/dio_provider.dart';

class SyncService {
  final Ref _ref;
  Dio get _dio => _ref.read(dioProvider);
  final _storage = const FlutterSecureStorage();

  SyncService(this._ref) {
    // Proactively process offline queue and sync catalog on startup
    processOfflineQueue();
    downloadCatalog();
    fetchShopSettings();

    // Listen to network changes
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      if (result != ConnectivityResult.none) {
        processOfflineQueue();
        downloadCatalog();
        fetchShopSettings();
      }
    });
  }

  Future<void> fetchShopSettings() async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      if (token == null) return;

      final String url;
      if (AppConfig.enableSimulationDebug) {
        url = 'http://localhost:3000/api/v1/settings';
      } else {
        url = '${AppConfig.apiBaseUrl}/settings';
      }

      final response = await _dio.get(
        url,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        await _storage.write(key: 'supermarket_name', value: data['name'] ?? 'QRBS Supermarket');
        await _storage.write(key: 'supermarket_address', value: data['address'] ?? '123052/Street, City');
        await _storage.write(key: 'supermarket_phone', value: data['phoneNumber'] ?? '944858585858');
      }
    } catch (_) {
      // Fail silently
    }
  }

  AppDatabase get _db => _ref.read(databaseProvider);

  // Processes (drains) the local SQLite SyncQueue table to the NestJS server
  Future<void> processOfflineQueue() async {
    try {
      final queue = await _db.getSyncQueue();
      if (queue.isEmpty) return;

      final token = await _storage.read(key: 'jwt_token');
      if (token == null) return;

      final String baseUrl;
      if (AppConfig.enableSimulationDebug) {
        final serverIp = await _storage.read(key: 'server_ip') ?? '192.168.1.12';
        baseUrl = 'http://$serverIp:3000';
      } else {
        final apiIndex = AppConfig.apiBaseUrl.indexOf('/api/v1');
        baseUrl = apiIndex != -1
            ? AppConfig.apiBaseUrl.substring(0, apiIndex)
            : AppConfig.apiBaseUrl;
      }

      for (final item in queue) {
        final payload = jsonDecode(item.payload);
        
        final response = await _dio.post(
          '$baseUrl${item.endpoint}',
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
      final token = await _storage.read(key: 'jwt_token');
      if (token == null) return false;

      final String url;
      if (AppConfig.enableSimulationDebug) {
        final serverIp = await _storage.read(key: 'server_ip') ?? '192.168.1.12';
        url = 'http://$serverIp:3000/api/v1/products';
      } else {
        url = '${AppConfig.apiBaseUrl}/products';
      }

      final response = await _dio.get(
        url,
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
