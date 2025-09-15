import 'cart_item.dart';

class Cart {
  final int id;
  final int userId;
  final List<CartItem> products;
  final num total;
  final num discountedTotal;
  final int totalProducts;
  final int totalQuantity;

  Cart({
    required this.id,
    required this.userId,
    required this.products,
    required this.total,
    required this.discountedTotal,
    required this.totalProducts,
    required this.totalQuantity,
  });

  factory Cart.fromJson(Map<String, dynamic> json) {
    final items = (json['products'] as List<dynamic>? ?? [])
        .map((e) => CartItem.fromJson(e as Map<String, dynamic>))
        .toList();

    return Cart(
      id: json['id'] as int,
      userId: json['userId'] as int? ?? 0,
      products: items,
      total: json['total'] as num? ?? 0,
      discountedTotal: (json['discountedTotal'] ?? json['total']) as num? ?? 0,
      totalProducts: json['totalProducts'] as int? ?? items.length,
      totalQuantity: json['totalQuantity'] as int? ??
          items.fold<int>(0, (sum, it) => sum + it.quantity),
    );
  }
}
