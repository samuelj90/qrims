import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qrims_mobile/core/local_db/drift_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('LocalProducts Cache Queries', () {
    test('cacheProducts and getProductBySku/getAllProducts should work', () async {
      const product1 = LocalProduct(
        id: 'p-1',
        sku: 'SKU111',
        name: 'Milk',
        price: 2.50,
        discount: 0.0,
        tax: 0.10,
        isActive: true,
      );
      const product2 = LocalProduct(
        id: 'p-2',
        sku: 'SKU222',
        name: 'Bread',
        price: 1.80,
        discount: 0.20,
        tax: 0.0,
        isActive: true,
      );

      await db.cacheProducts([product1, product2]);

      final allProducts = await db.getAllProducts();
      expect(allProducts.length, 2);

      final milk = await db.getProductBySku('SKU111');
      expect(milk, isNotNull);
      expect(milk!.name, 'Milk');
      expect(milk.price, 2.50);

      final nonExistent = await db.getProductBySku('SKU333');
      expect(nonExistent, isNull);
    });
  });

  group('LocalCartItems Queries', () {
    test('Cart CRUD operations should update DB correctly', () async {
      // 1. Initially empty
      var items = await db.getCartItems();
      expect(items.isEmpty, true);

      // 2. Add item
      await db.addCartItem(LocalCartItemsCompanion.insert(
        productId: 'prod-abc',
        name: 'Juice',
        price: 3.0,
        discount: 0.5,
        tax: 0.2,
        quantity: 1,
      ));

      items = await db.getCartItems();
      expect(items.length, 1);
      expect(items.first.name, 'Juice');
      expect(items.first.quantity, 1);

      // 3. Update quantity
      await db.updateCartItemQuantity('prod-abc', 5);
      items = await db.getCartItems();
      expect(items.first.quantity, 5);

      // 4. Remove item
      await db.removeCartItem('prod-abc');
      items = await db.getCartItems();
      expect(items.isEmpty, true);

      // 5. Clear cart
      await db.addCartItem(LocalCartItemsCompanion.insert(
        productId: 'prod-123',
        name: 'Chips',
        price: 1.5,
        discount: 0.0,
        tax: 0.0,
        quantity: 2,
      ));
      await db.clearCart();
      items = await db.getCartItems();
      expect(items.isEmpty, true);
    });
  });

  group('SyncQueue Queries', () {
    test('Offline sync queue enqueuing and draining', () async {
      var queue = await db.getSyncQueue();
      expect(queue.isEmpty, true);

      await db.enqueueSync(SyncQueueCompanion.insert(
        endpoint: '/api/v1/carts/checkout',
        payload: '{"items": []}',
      ));

      queue = await db.getSyncQueue();
      expect(queue.length, 1);
      expect(queue.first.endpoint, '/api/v1/carts/checkout');
      expect(queue.first.payload, '{"items": []}');

      final queueId = queue.first.id;
      await db.deleteSync(queueId);

      queue = await db.getSyncQueue();
      expect(queue.isEmpty, true);
    });
  });
}
