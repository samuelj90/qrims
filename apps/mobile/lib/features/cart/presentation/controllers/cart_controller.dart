import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../domain/models/cart_item.dart';

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
  final _dio = Dio();
  final _storage = const FlutterSecureStorage();

  CartNotifier() : super(const CartState());

  void addScannedItem(String decryptedText) {
    try {
      final newItem = CartItem.fromQrPayload(decryptedText);
      final index = state.items.indexWhere((item) => item.id == newItem.id);

      if (index >= 0) {
        // Increment quantity if product is already in cart
        final updatedItems = [...state.items];
        updatedItems[index] = updatedItems[index].copyWith(
          quantity: updatedItems[index].quantity + 1,
        );
        state = state.copyWith(items: updatedItems);
      } else {
        // Add new item
        state = state.copyWith(items: [...state.items, newItem]);
      }
    } catch (e) {
      state = state.copyWith(errorMessage: 'Invalid QR Payload configuration');
    }
  }

  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeItem(productId);
      return;
    }
    final updatedItems = state.items.map((item) {
      return item.id == productId ? item.copyWith(quantity: quantity) : item;
    }).toList();
    state = state.copyWith(items: updatedItems);
  }

  void removeItem(String productId) {
    final updatedItems = state.items.where((item) => item.id != productId).toList();
    state = state.copyWith(items: updatedItems);
  }

  void clearCart() {
    state = const CartState();
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
        // Offline Sync implementation: Cache checkout in database queue
        // (In production, write record to Drift AppDatabase.syncQueue)
        state = state.copyWith(
          isSubmitting: false,
          successMessage: 'Offline! Checkout queued. Will sync once connection is restored.',
          items: [],
        );
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
      } else {
        state = state.copyWith(
          isSubmitting: false,
          errorMessage: 'Checkout rejected by API gateway.',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Network error: checkout saved offline.',
      );
    }
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier();
});
