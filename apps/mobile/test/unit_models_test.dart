import 'package:flutter_test/flutter_test.dart';
import 'package:qrims_mobile/features/auth/domain/models/user.dart';
import 'package:qrims_mobile/features/cart/domain/models/cart_item.dart';

void main() {
  group('User Model Tests', () {
    test('User.fromJson should construct User correctly', () {
      final json = {
        'userId': 'user-123',
        'username': 'john_doe',
        'role': 'admin',
      };
      const token = 'jwt-token-xyz';

      final user = User.fromJson(json, token);

      expect(user.id, 'user-123');
      expect(user.username, 'john_doe');
      expect(user.role, 'admin');
      expect(user.token, token);
    });

    test('User.toJson should return correct map', () {
      const user = User(
        id: 'user-456',
        username: 'jane_doe',
        role: 'staff',
        token: 'token-abc',
      );

      final json = user.toJson();

      expect(json['userId'], 'user-456');
      expect(json['username'], 'jane_doe');
      expect(json['role'], 'staff');
      expect(json.containsKey('token'), false);
    });
  });

  group('CartItem Model Tests', () {
    test('totalPrice calculation should be correct', () {
      const item = CartItem(
        id: 'p-1',
        name: 'Product 1',
        price: 100.0,
        discount: 10.0,
        tax: 5.0,
        quantity: 2,
      );

      // ((Price - Discount) + Tax) * Qty = ((100 - 10) + 5) * 2 = 95 * 2 = 190
      expect(item.totalPrice, 190.0);
    });

    test('copyWith should update quantity and preserve other fields', () {
      const item = CartItem(
        id: 'p-1',
        name: 'Product 1',
        price: 100.0,
        discount: 10.0,
        tax: 5.0,
        quantity: 2,
      );

      final updated = item.copyWith(quantity: 5);

      expect(updated.id, item.id);
      expect(updated.name, item.name);
      expect(updated.price, item.price);
      expect(updated.discount, item.discount);
      expect(updated.tax, item.tax);
      expect(updated.quantity, 5);

      final preserved = item.copyWith();
      expect(preserved.quantity, 2);
    });

    test('fromQrPayload should parse valid colon-separated payload', () {
      const payload = 'prod-123:Apple Juice:3.50:0.50:0.25:Complimentary text';
      final item = CartItem.fromQrPayload(payload);

      expect(item.id, 'prod-123');
      expect(item.name, 'Apple Juice');
      expect(item.price, 3.50);
      expect(item.discount, 0.50);
      expect(item.tax, 0.25);
      expect(item.quantity, 1);
    });

    test('fromQrPayload should throw FormatException for invalid payload', () {
      expect(
        () => CartItem.fromQrPayload('invalid-payload-no-colons'),
        throwsA(isA<FormatException>()),
      );
    });

    test('toJson should return correct map for backend/sync', () {
      const item = CartItem(
        id: 'p-9',
        name: 'Soda',
        price: 2.0,
        discount: 0.1,
        tax: 0.15,
        quantity: 3,
      );

      final json = item.toJson();

      expect(json['productId'], 'p-9');
      expect(json['name'], 'Soda');
      expect(json['price'], 2.0);
      expect(json['discount'], 0.1);
      expect(json['tax'], 0.15);
      expect(json['quantity'], 3);
    });
  });
}
