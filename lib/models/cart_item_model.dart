class CartItemModel {
  final Map<String, dynamic> data;

  const CartItemModel(this.data);

  int get id => int.tryParse((data['id'] ?? 0).toString()) ?? 0;

  String get title {
    return (data['name'] ??
            data['title'] ??
            data['username'] ??
            data['order_code'] ??
            data['message_text'] ??
            '')
        .toString();
  }
}
