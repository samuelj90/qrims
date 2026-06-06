class CartItem {
  final String id;
  final String name;
  final double price;
  final double discount;
  final double tax;
  final int quantity;

  const CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.discount,
    required this.tax,
    required this.quantity,
  });

  // Replaces the legacy math calc: ((Price - Discount) + Tax) * Qty
  double get totalPrice => ((price - discount) + tax) * quantity;

  CartItem copyWith({
    int? quantity,
  }) {
    return CartItem(
      id: id,
      name: name,
      price: price,
      discount: discount,
      tax: tax,
      quantity: quantity ?? this.quantity,
    );
  }

  factory CartItem.fromQrPayload(String decryptedText) {
    // Decrypts string formatting e.g.: ID:Name:Price:Discount:Tax:Compliment
    final parts = decryptedText.split(':');
    if (parts.length < 5) {
      throw const FormatException('Invalid QR Payload format');
    }
    return CartItem(
      id: parts[0],
      name: parts[1],
      price: double.parse(parts[2]),
      discount: double.parse(parts[3]),
      tax: double.parse(parts[4]),
      quantity: 1, // default quantity is 1 on scan
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': id,
      'name': name,
      'price': price,
      'discount': discount,
      'tax': tax,
      'quantity': quantity,
    };
  }
}
