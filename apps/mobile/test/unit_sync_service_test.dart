import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:qrims_mobile/core/services/sync_service.dart';
import 'package:qrims_mobile/core/local_db/drift_database.dart';
import 'package:qrims_mobile/core/network/dio_provider.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart';

// Lightweight MockDio implementation
class MockDio implements Dio {
  final Map<String, dynamic> responses;
  final int statusCode;

  MockDio(this.responses, {this.statusCode = 200});

  @override
  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    void Function(int, int)? onSendProgress,
    void Function(int, int)? onReceiveProgress,
  }) async {
    return _buildResponse<T>(path);
  }

  @override
  Future<Response<T>> get<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    void Function(int, int)? onReceiveProgress,
  }) async {
    return _buildResponse<T>(path);
  }

  @override
  Future<Response<T>> put<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    void Function(int, int)? onSendProgress,
    void Function(int, int)? onReceiveProgress,
  }) async {
    return _buildResponse<T>(path);
  }

  Future<Response<T>> _buildResponse<T>(String path) async {
    String cleanPath = path;
    if (path.startsWith('http')) {
      final uri = Uri.parse(path);
      cleanPath = uri.path;
    }
    final responseData = responses[cleanPath] ?? responses['default'] ?? {};
    if (statusCode >= 400) {
      throw DioException(
        requestOptions: RequestOptions(path: path),
        response: Response(
          requestOptions: RequestOptions(path: path),
          data: responseData,
          statusCode: statusCode,
        ),
      );
    }
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      data: responseData as T,
      statusCode: statusCode,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final Map<String, String> secureStorageData = {};
  late AppDatabase database;
  String currentConnectivity = 'wifi';

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'write') {
          final args = methodCall.arguments as Map;
          secureStorageData[args['key'] as String] = args['value'] as String;
          return null;
        } else if (methodCall.method == 'read') {
          final args = methodCall.arguments as Map;
          return secureStorageData[args['key'] as String];
        } else if (methodCall.method == 'delete') {
          final args = methodCall.arguments as Map;
          secureStorageData.remove(args['key'] as String);
          return null;
        } else if (methodCall.method == 'clear') {
          secureStorageData.clear();
          return null;
        }
        return null;
      },
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/connectivity'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'check') {
          return currentConnectivity;
        }
        return null;
      },
    );
  });

  setUp(() {
    secureStorageData.clear();
    currentConnectivity = 'wifi';
    database = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  group('SyncService Tests', () {
    test('downloadCatalog fetches and caches products', () async {
      secureStorageData['jwt_token'] = 'token-xyz';

      final mockResponse = {
        '/api/v1/products': [
          {
            'id': 'p-1',
            'sku': '111111',
            'name': 'Soda Can',
            'price': 1.5,
            'discount': 0.0,
            'tax': 0.1,
            'compliment': 'Cold',
            'isActive': true
          }
        ]
      };

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(database),
          dioProvider.overrideWithValue(MockDio(mockResponse)),
        ],
      );
      addTearDown(container.dispose);

      final syncService = container.read(syncServiceProvider);
      final success = await syncService.downloadCatalog();
      expect(success, true);

      final allProducts = await database.getAllProducts();
      expect(allProducts.length, 1);
      expect(allProducts.first.name, 'Soda Can');
    });

    test('fetchShopSettings fetches and caches supermarket metadata', () async {
      secureStorageData['jwt_token'] = 'token-xyz';

      final mockResponse = {
        '/api/v1/settings': {
          'name': 'Grand Supermarket',
          'address': '789 Main Rd',
          'phoneNumber': '+1-800-555-0199'
        }
      };

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(database),
          dioProvider.overrideWithValue(MockDio(mockResponse)),
        ],
      );
      addTearDown(container.dispose);

      final syncService = container.read(syncServiceProvider);
      await syncService.fetchShopSettings();

      expect(secureStorageData['supermarket_name'], 'Grand Supermarket');
      expect(secureStorageData['supermarket_address'], '789 Main Rd');
      expect(secureStorageData['supermarket_phone'], '+1-800-555-0199');
    });

    test('processOfflineQueue drains DB entries to backend', () async {
      secureStorageData['jwt_token'] = 'token-xyz';

      await database.enqueueSync(SyncQueueCompanion.insert(
        endpoint: '/api/v1/carts/checkout',
        payload: '{"items": []}',
      ));

      final mockResponse = {
        '/api/v1/carts/checkout': {'status': 'success'}
      };

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(database),
          dioProvider.overrideWithValue(MockDio(mockResponse)),
        ],
      );
      addTearDown(container.dispose);

      final syncService = container.read(syncServiceProvider);
      await syncService.processOfflineQueue();

      final queue = await database.getSyncQueue();
      expect(queue.isEmpty, true);
    });
  });
}
