import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:qrims_mobile/features/cart/presentation/controllers/cart_controller.dart';
import 'package:qrims_mobile/features/cart/domain/models/cart_item.dart';
import 'package:qrims_mobile/core/local_db/drift_database.dart';
import 'package:qrims_mobile/core/services/sync_service.dart';
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

  group('CartNotifier Tests', () {
    test('Loads initial state from database', () async {
      await database.addCartItem(LocalCartItemsCompanion.insert(
        productId: 'p-1',
        name: 'Soda',
        price: 2.0,
        discount: 0.1,
        tax: 0.15,
        quantity: 3,
      ));

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(database),
        ],
      );
      addTearDown(container.dispose);

      container.read(cartProvider);

      await Future.delayed(const Duration(milliseconds: 50));

      final state = container.read(cartProvider);
      expect(state.items.length, 1);
      expect(state.items.first.id, 'p-1');
      expect(state.items.first.quantity, 3);
    });

    test('addScannedItem adds item to database and state', () async {
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(database),
        ],
      );
      addTearDown(container.dispose);

      await database.cacheProducts([
        LocalProduct(
          id: 'uuid-111',
          sku: 'SKU-ABC',
          name: 'Choco Cookies',
          price: 5.0,
          discount: 0.5,
          tax: 0.2,
          isActive: true,
        )
      ]);

      final notifier = container.read(cartProvider.notifier);

      await notifier.addScannedItem('SKU-ABC');

      await Future.delayed(const Duration(milliseconds: 50));

      var state = container.read(cartProvider);
      expect(state.items.length, 1);
      expect(state.items.first.id, 'uuid-111');
      expect(state.items.first.name, 'Choco Cookies');
      expect(state.items.first.quantity, 1);
    });

    test('addScannedItem fallback to QR payload parsing when not found in DB', () async {
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(database),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(cartProvider.notifier);

      await notifier.addScannedItem('qr-item-123:Orange Juice:4.0:0.2:0.1:Fresh');

      await Future.delayed(const Duration(milliseconds: 50));

      final state = container.read(cartProvider);
      expect(state.items.length, 1);
      expect(state.items.first.id, 'qr-item-123');
      expect(state.items.first.name, 'Orange Juice');
      expect(state.items.first.price, 4.0);
    });

    test('updateQuantity updates DB and removes if <= 0', () async {
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(database),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(cartProvider.notifier);
      await notifier.addScannedItem('id-1:Soda:2.0:0.0:0.0');

      await notifier.updateQuantity('id-1', 3);
      var state = container.read(cartProvider);
      expect(state.items.first.quantity, 3);

      await notifier.updateQuantity('id-1', 0);
      state = container.read(cartProvider);
      expect(state.items.isEmpty, true);
    });

    test('removeItem removes from state and DB', () async {
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(database),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(cartProvider.notifier);
      await notifier.addScannedItem('id-1:Soda:2.0:0.0:0.0');

      await notifier.removeItem('id-1');
      final state = container.read(cartProvider);
      expect(state.items.isEmpty, true);
    });

    test('checkout online submits to api and clears cart', () async {
      secureStorageData['jwt_token'] = 'token-ok';
      currentConnectivity = 'wifi';

      final mockResponse = {
        '/api/v1/carts/checkout': {'status': 'success'}
      };

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(database),
          dioProvider.overrideWithValue(MockDio(mockResponse, statusCode: 201)),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(cartProvider.notifier);
      await notifier.addScannedItem('id-1:Soda:2.0:0.0:0.0');

      await notifier.checkout('localhost');

      final state = container.read(cartProvider);
      expect(state.items.isEmpty, true);
      expect(state.successMessage, contains('Checkout succeeded'));
    });

    test('checkout offline enqueues checkout sync in database', () async {
      secureStorageData['jwt_token'] = 'token-ok';
      currentConnectivity = 'none';

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(database),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(cartProvider.notifier);
      await notifier.addScannedItem('id-1:Soda:2.0:0.0:0.0');

      await notifier.checkout('localhost');

      final state = container.read(cartProvider);
      expect(state.items.isEmpty, true);
      expect(state.successMessage, contains('Offline! Checkout queued'));

      final queue = await database.getSyncQueue();
      expect(queue.length, 1);
    });
  });
}
