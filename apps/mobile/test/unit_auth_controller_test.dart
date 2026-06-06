import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:qrims_mobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:qrims_mobile/core/local_db/drift_database.dart';
import 'package:qrims_mobile/core/network/dio_provider.dart';
import 'package:drift/native.dart';

// Lightweight MockDio implementation
class MockDio implements Dio {
  final Map<String, dynamic> responses;
  final int statusCode;

  MockDio(this.responses, {this.statusCode = 200});

  @override
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
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
    dynamic data,
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
    dynamic data,
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
  });

  setUp(() {
    secureStorageData.clear();
    database = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  group('AuthNotifier Tests', () {
    test('Initial state is empty when no token is persisted', () async {
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(database),
        ],
      );
      addTearDown(container.dispose);

      final state = container.read(authProvider);
      expect(state.user, isNull);
      expect(state.isLoading, false);
      expect(state.errorMessage, isNull);
    });

    test('Loads persisted user on startup', () async {
      secureStorageData['jwt_token'] = 'token-123';
      secureStorageData['user_id'] = 'user-abc';
      secureStorageData['username'] = 'bob';
      secureStorageData['role'] = 'admin';

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(database),
        ],
      );
      addTearDown(container.dispose);

      container.read(authProvider);

      await Future.delayed(const Duration(milliseconds: 50));

      final state = container.read(authProvider);
      expect(state.user, isNotNull);
      expect(state.user!.id, 'user-abc');
      expect(state.user!.username, 'bob');
      expect(state.user!.token, 'token-123');
    });

    test('Login success updates state and persists info', () async {
      final mockResponse = {
        '/api/v1/auth/login': {
          'accessToken': 'token-999',
          'userId': 'user-999',
          'username': 'alice',
          'role': 'cashier',
        },
        '/api/v1/products': [],
        '/api/v1/settings': {
          'name': 'MiniMart',
          'address': 'Street 1',
          'phoneNumber': '555-1234',
        }
      };

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(database),
          dioProvider.overrideWithValue(MockDio(mockResponse)),
        ],
      );
      addTearDown(container.dispose);

      final success = await container.read(authProvider.notifier).login(
        '192.168.1.100',
        'alice',
        'password123',
      );

      expect(success, true);
      final state = container.read(authProvider);
      expect(state.user, isNotNull);
      expect(state.user!.username, 'alice');
      expect(state.user!.token, 'token-999');

      expect(secureStorageData['jwt_token'], 'token-999');
      expect(secureStorageData['username'], 'alice');
      expect(secureStorageData['server_ip'], '192.168.1.100');
    });

    test('Login failure sets error message', () async {
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(database),
          dioProvider.overrideWithValue(MockDio({}, statusCode: 401)),
        ],
      );
      addTearDown(container.dispose);

      final success = await container.read(authProvider.notifier).login(
        '192.168.1.100',
        'alice',
        'wrong-pwd',
      );

      expect(success, false);
      final state = container.read(authProvider);
      expect(state.user, isNull);
      expect(state.errorMessage, isNotNull);
    });

    test('Logout clears state and storage', () async {
      secureStorageData['jwt_token'] = 'token-123';
      secureStorageData['username'] = 'bob';

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(database),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authProvider.notifier).logout();

      final state = container.read(authProvider);
      expect(state.user, isNull);
      expect(secureStorageData.containsKey('jwt_token'), false);
      expect(secureStorageData.containsKey('username'), false);
    });

    test('changePassword returns true on success', () async {
      secureStorageData['jwt_token'] = 'token-123';

      final mockResponse = {
        '/api/v1/auth/change-password': {'success': true}
      };

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(database),
          dioProvider.overrideWithValue(MockDio(mockResponse)),
        ],
      );
      addTearDown(container.dispose);

      final success = await container.read(authProvider.notifier).changePassword('new-secure-pass');
      expect(success, true);
    });
  });
}
