import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../domain/models/cart_item.dart';
import '../../../../core/local_db/drift_database.dart';

class CartState {
  final List<CartItem> items;
  final bool isSubmitting;
  final String? successMessage;
  final String? errorMessage;

  const CartState({
    this.items = const [],
    this.isSubmitting = false,
    this.successMessage,
    this.errorMessage,
  });

  double get grandTotal => items.fold(0.0, (sum, item) => sum + item.totalPrice);

  CartState copyWith({
    List<CartItem>? items,
    bool? isSubmitting,
    String? successMessage,
    String? errorMessage,
  }) {
    return CartState(
      items: items ?? this.items,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      successMessage: successMessage,
      errorMessage: errorMessage,
    );
  }
}

class CartNotifier extends StateNotifier<CartState> {
  final Ref _ref;
  final _dio = Dio();
  final _storage = const FlutterSecureStorage();

  CartNotifier(this._ref) : super(const CartState()) {
    _loadCartFromDb();
  }

  AppDatabase get _db => _ref.read(databaseProvider);

  Future<void> _loadCartFromDb() async {
    try {
      final dbItems = await _db.getCartItems();
      final items = dbItems.map((dbItem) => CartItem(
        id: dbItem.productId,
        name: dbItem.name,
        price: dbItem.price,
        discount: dbItem.discount,
        tax: dbItem.tax,
        quantity: dbItem.quantity,
      )).toList();
      state = state.copyWith(items: items);
    } catch (_) {
      // Handle db reading errors gracefully
    }
  }

  Future<void> addScannedItem(String skuOrPayload) async {
    try {
      // 1. Try to look up by SKU in local database first (real seeded database data)
      final localProd = await _db.getProductBySku(skuOrPayload);
      CartItem newItem;
      
      if (localProd != null) {
        newItem = CartItem(
          id: localProd.id, // Use actual Product UUID ID
          name: localProd.name,
          price: localProd.price,
          discount: localProd.discount,
          tax: localProd.tax,
          quantity: 1,
        );
      } else {
        // Fallback: Parse decrypted text QR payload directly
        newItem = CartItem.fromQrPayload(skuOrPayload);
      }

      final index = state.items.indexWhere((item) => item.id == newItem.id);

      if (index >= 0) {
        final updatedQty = state.items[index].quantity + 1;
        final updatedItems = [...state.items];
        updatedItems[index] = updatedItems[index].copyWith(quantity: updatedQty);
        
        state = state.copyWith(items: updatedItems);
        await _db.updateCartItemQuantity(newItem.id, updatedQty);
      } else {
        state = state.copyWith(items: [...state.items, newItem]);
        await _db.addCartItem(LocalCartItemsCompanion.insert(
          productId: newItem.id,
          name: newItem.name,
          price: newItem.price,
          discount: newItem.discount,
          tax: newItem.tax,
          quantity: 1,
        ));
      }
    } catch (e) {
      state = state.copyWith(errorMessage: 'Product SKU not found / Invalid QR Payload');
    }
  }

  Future<void> updateQuantity(String productId, int quantity) async {
    if (quantity <= 0) {
      await removeItem(productId);
      return;
    }
    final updatedItems = state.items.map((item) {
      return item.id == productId ? item.copyWith(quantity: quantity) : item;
    }).toList();
    state = state.copyWith(items: updatedItems);
    await _db.updateCartItemQuantity(productId, quantity);
  }

  Future<void> removeItem(String productId) async {
    final updatedItems = state.items.where((item) => item.id != productId).toList();
    state = state.copyWith(items: updatedItems);
    await _db.removeCartItem(productId);
  }

  Future<void> clearCart() async {
    state = const CartState();
    await _db.clearCart();
  }

  Future<void> checkout(String serverIp) async {
    if (state.items.isEmpty) return;

    state = state.copyWith(isSubmitting: true);
    try {
      final token = await _storage.read(key: 'jwt_token');
      final connectivityResult = await Connectivity().checkConnectivity();

      final payload = {
        'items': state.items.map((item) => item.toJson()).toList(),
        'totalAmount': state.grandTotal,
      };

      if (connectivityResult == ConnectivityResult.none) {
        // Enqueue checkout payload into local SQLite SyncQueue table
        await _db.enqueueSync(SyncQueueCompanion.insert(
          endpoint: '/api/v1/carts/checkout',
          payload: jsonEncode(payload),
        ));
        
        state = state.copyWith(
          isSubmitting: false,
          successMessage: 'Offline! Checkout queued. Will sync once connection is restored.',
          items: [],
        );
        await _db.clearCart();
        return;
      }

      final response = await _dio.post(
        'http://$serverIp:3000/api/v1/carts/checkout',
        data: payload,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200 || response.statusCode == 210 || response.statusCode == 201) {
        state = state.copyWith(
          isSubmitting: false,
          successMessage: 'Checkout succeeded! Order submitted.',
          items: [],
        );
        await _db.clearCart();
      } else {
        state = state.copyWith(
          isSubmitting: false,
          errorMessage: 'Checkout rejected by API gateway.',
        );
      }
    } catch (e) {
      // On network exception, fallback and save to SQLite queue
      try {
        final payload = {
          'items': state.items.map((item) => item.toJson()).toList(),
          'totalAmount': state.grandTotal,
        };
        await _db.enqueueSync(SyncQueueCompanion.insert(
          endpoint: '/api/v1/carts/checkout',
          payload: jsonEncode(payload),
        ));
        state = state.copyWith(
          isSubmitting: false,
          successMessage: 'Network error: checkout saved offline in sync queue.',
          items: [],
        );
        await _db.clearCart();
      } catch (innerError) {
        state = state.copyWith(
          isSubmitting: false,
          errorMessage: 'Network error: failed to queue checkout offline.',
        );
      }
    }
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier(ref);
});
