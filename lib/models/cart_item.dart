class CartItem {
  final int id;
  final String title;
  final num price;
  final int quantity;
  final num total;
  final num discountPercentage;
  final num discountedPrice;

  CartItem({
    required this.id,
    required this.title,
    required this.price,
    required this.quantity,
    required this.total,
    required this.discountPercentage,
    required this.discountedPrice,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      price: json['price'] as num? ?? 0,
      quantity: json['quantity'] as int? ?? 0,
      total: json['total'] as num? ?? 0,
      discountPercentage: json['discountPercentage'] as num? ?? 0,
      discountedPrice: (json['discountedPrice'] ??
              json['discountedTotal'] ??
              json['total']) as num? ??
          0,
    );
  }
}
