class ProductDisplayHelper {
  static num asNum(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value;
    return num.tryParse(value.toString().replaceAll(',', '.')) ?? 0;
  }

  static num price(Map<String, dynamic> p) {
    return asNum(p['final_price'] ?? p['flash_price'] ?? p['sale_price'] ?? p['base_price'] ?? p['price'] ?? 0);
  }

  static num strikePrice(Map<String, dynamic> p) {
    return asNum(p['strike_price'] ?? p['compare_at_price'] ?? p['original_price'] ?? p['old_price'] ?? p['harga_coret'] ?? 0);
  }

  static bool hasStrikePrice(Map<String, dynamic> p) {
    final strike = strikePrice(p);
    final now = price(p);
    return strike > now && now > 0;
  }

  static int discountPercent(Map<String, dynamic> p) {
    final direct = asNum(p['discount_percent']).round();
    if (direct > 0) return direct;
    final strike = strikePrice(p);
    final now = price(p);
    if (strike <= 0 || now <= 0 || strike <= now) return 0;
    return (((strike - now) / strike) * 100).round();
  }

  static bool isFlashSale(Map<String, dynamic> p) {
    final value = p['is_flash_sale'];
    return value == true || value == 1 || value.toString() == '1' || value.toString().toLowerCase() == 'true';
  }

  static double rating(Map<String, dynamic> p) {
    final raw = asNum(p['rating_avg'] ?? p['rating'] ?? 0).toDouble();
    if (raw < 0) return 0;
    if (raw > 5) return 5;
    return raw;
  }

  static int ratingCount(Map<String, dynamic> p) {
    return asNum(p['rating_count'] ?? p['review_count'] ?? 0).round();
  }
}
