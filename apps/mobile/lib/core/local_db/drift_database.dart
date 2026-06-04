import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'drift_database.g.dart';

// 1. Caches remote catalog for offline scanning
class LocalProducts extends Table {
  TextColumn get id => text()();
  TextColumn get sku => text().unique()();
  TextColumn get name => text()();
  RealColumn get price => real()();
  RealColumn get discount => real().withDefault(const Constant(0.0))();
  RealColumn get tax => real().withDefault(const Constant(0.0))();
  TextColumn get compliment => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

// 2. Holds current active items in the cart
class LocalCartItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get productId => text()();
  TextColumn get name => text()();
  RealColumn get price => real()();
  RealColumn get discount => real()();
  RealColumn get tax => real()();
  IntColumn get quantity => integer()();
}

// 3. Enqueues checkout payloads for offline sync playbacks
class SyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get endpoint => text()(); // e.g. '/api/v1/carts/checkout'
  TextColumn get payload => text()();  // JSON payload
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(tables: [LocalProducts, LocalCartItems, SyncQueue])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  // LocalProducts Queries
  Future<List<LocalProduct>> getAllProducts() => select(localProducts).get();
  Future<void> cacheProducts(List<LocalProduct> products) async {
    await batch((b) {
      b.insertAll(localProducts, products, mode: InsertMode.insertOrReplace);
    });
  }
  Future<LocalProduct?> getProductBySku(String sku) =>
      (select(localProducts)..where((tbl) => tbl.sku.equals(sku))).getSingleOrNull();

  // LocalCartItems Queries
  Future<List<LocalCartItem>> getCartItems() => select(localCartItems).get();
  Future<int> addCartItem(LocalCartItemsCompanion item) => into(localCartItems).insert(item);
  Future<void> updateCartItemQuantity(String productId, int qty) async {
    await (update(localCartItems)..where((tbl) => tbl.productId.equals(productId)))
        .write(LocalCartItemsCompanion(quantity: Value(qty)));
  }
  Future<void> removeCartItem(String productId) async {
    await (delete(localCartItems)..where((tbl) => tbl.productId.equals(productId))).go();
  }
  Future<void> clearCart() => delete(localCartItems).go();

  // SyncQueue Queries
  Future<List<SyncQueueData>> getSyncQueue() => select(syncQueue).get();
  Future<int> enqueueSync(SyncQueueCompanion entry) => into(syncQueue).insert(entry);
  Future<void> deleteSync(int id) => (delete(syncQueue)..where((tbl) => tbl.id.equals(id))).go();
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'qrims_cache.db'));
    return NativeDatabase.createInBackground(file);
  });
}

// Riverpod Provider
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
