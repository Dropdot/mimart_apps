import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/formatters.dart';
import 'order_detail_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool loading = true;
  bool ordering = false;
  List<dynamic> addresses = [];
  List<dynamic> methods = [];
  List<dynamic> cartItems = [];
  int? addressId;
  int? methodId;
  num total = 0;
  int totalQty = 0;
  final TextEditingController noteC = TextEditingController();

  static const maroon = Color(0xFF97002B);
  static const bg = Color(0xFFF7F8FC);

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    noteC.dispose();
    super.dispose();
  }

  Map<String, dynamic> dataOrRoot(Map<String, dynamic> res) {
    final data = res['data'];
    if (data is Map) return Map<String, dynamic>.from(data);
    return res;
  }

  bool ok(Map<String, dynamic> res) => res['success'] == true || res['status'] == 'success' || res['ok'] == true;

  Future<Map<String, dynamic>?> safeGet(String endpoint) async {
    try {
      return await ApiClient.get(endpoint);
    } catch (_) {
      return null;
    }
  }

  Future<void> load() async {
    setState(() => loading = true);
    final cartRes = await safeGet('cart.php');
    final addressRes = await safeGet('addresses.php');
    final methodRes = await safeGet('payment_methods.php');
    if (!mounted) return;

    final cartData = cartRes == null ? <String, dynamic>{} : dataOrRoot(cartRes);
    final addrData = addressRes == null ? <String, dynamic>{} : dataOrRoot(addressRes);
    final methodData = methodRes == null ? <String, dynamic>{} : dataOrRoot(methodRes);

    final loadedItems = cartData['items'] as List<dynamic>? ?? cartData['cart_items'] as List<dynamic>? ?? [];
    final loadedAddresses = addrData['addresses'] as List<dynamic>? ?? addrData['items'] as List<dynamic>? ?? [];
    final loadedMethods = methodData['methods'] as List<dynamic>? ?? methodData['payment_methods'] as List<dynamic>? ?? [];

    setState(() {
      cartItems = loadedItems;
      total = num.tryParse('${cartData['grand_total'] ?? cartData['total'] ?? cartData['subtotal'] ?? 0}') ?? 0;
      totalQty = int.tryParse('${cartData['total_qty'] ?? 0}') ?? 0;
      if (totalQty <= 0) {
        totalQty = cartItems.fold<int>(0, (sum, raw) {
          final item = Map<String, dynamic>.from(raw as Map);
          return sum + (int.tryParse('${item['quantity'] ?? item['qty'] ?? 1}') ?? 1);
        });
      }
      addresses = loadedAddresses;
      methods = loadedMethods;
      if (addresses.isNotEmpty) addressId ??= int.tryParse('${(addresses.first as Map)['id']}');
      if (methods.isNotEmpty) methodId ??= int.tryParse('${(methods.first as Map)['id']}');
      loading = false;
    });
  }

  String itemName(Map<String, dynamic> item) => (item['product_name'] ?? item['name'] ?? '-').toString();
  String itemVariant(Map<String, dynamic> item) => (item['variant_name'] ?? '').toString();
  int itemQty(Map<String, dynamic> item) => int.tryParse('${item['quantity'] ?? item['qty'] ?? 1}') ?? 1;

  num itemSubtotal(Map<String, dynamic> item) {
    final subtotal = num.tryParse('${item['subtotal'] ?? 0}') ?? 0;
    if (subtotal > 0) return subtotal;
    final price = num.tryParse('${item['price'] ?? item['selected_price'] ?? 0}') ?? 0;
    return price * itemQty(item);
  }

  String addressLabel(Map<String, dynamic> item) {
    final parts = [
      (item['label'] ?? '').toString(),
      (item['recipient_name'] ?? item['name'] ?? '').toString(),
      (item['district'] ?? '').toString(),
      (item['city'] ?? '').toString(),
      (item['full_address'] ?? item['address'] ?? '').toString(),
    ].where((e) => e.trim().isNotEmpty).toList();
    return parts.isEmpty ? 'Alamat #${item['id']}' : parts.join(' • ');
  }

  String methodTitle(Map<String, dynamic> item) {
    return (item['display_name'] ?? item['name'] ?? item['title'] ?? 'Metode Pembayaran').toString();
  }

  Future<void> createOrder() async {
    if (cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Barang checkout masih kosong.')));
      return;
    }
    if (addresses.isNotEmpty && addressId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih alamat pengiriman dulu.')));
      return;
    }
    if (methods.isEmpty || methodId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih metode pembayaran dulu.')));
      return;
    }

    setState(() => ordering = true);
    try {
      final res = await ApiClient.post('checkout_create.php', body: {
        'address_id': addressId,
        'payment_method_id': methodId,
        'customer_note': noteC.text.trim(),
      });
      if (!mounted) return;

      if (ok(res)) {
        final data = dataOrRoot(res);
        final orderId = data['order_id'];
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text((res['message'] ?? 'Pesanan berhasil dibuat.').toString())));
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: orderId)));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text((res['message'] ?? 'Gagal membuat pesanan.').toString())));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal membuat pesanan: $e')));
    } finally {
      if (mounted) setState(() => ordering = false);
    }
  }

  Widget section({required String title, required IconData icon, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF1E5EA)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.035), blurRadius: 16, offset: const Offset(0, 8))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(icon, color: maroon, size: 20), const SizedBox(width: 8), Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15))]),
        const SizedBox(height: 12),
        child,
      ]),
    );
  }

  Widget checkoutItems() {
    if (cartItems.isEmpty) return const Text('Barang checkout masih kosong.', style: TextStyle(color: Color(0xFF6B7280)));
    return Column(children: cartItems.map((raw) {
      final item = Map<String, dynamic>.from(raw as Map);
      final variant = itemVariant(item);
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: const Color(0xFFF7F8FC), borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          Container(width: 46, height: 46, decoration: BoxDecoration(color: const Color(0xFFFFEEF2), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.shopping_bag_outlined, color: maroon)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(itemName(item), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900)),
            if (variant.isNotEmpty) Text(variant, style: const TextStyle(color: maroon, fontWeight: FontWeight.w700, fontSize: 12)),
            Text('Qty ${itemQty(item)}', style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
          ])),
          Text(Formatters.rupiah(itemSubtotal(item)), style: const TextStyle(color: maroon, fontWeight: FontWeight.w900)),
        ]),
      );
    }).toList());
  }

  Widget paymentChoice(Map<String, dynamic> item) {
    final id = int.tryParse('${item['id']}');
    final selected = id != null && id == methodId;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? const Color(0xFFFFEEF2) : const Color(0xFFF7F8FC),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => setState(() => methodId = id),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: selected ? maroon : const Color(0xFFE5E7EB), width: selected ? 1.4 : 1)),
            child: Row(children: [
              Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off, color: selected ? maroon : Colors.black38),
              const SizedBox(width: 10),
              Expanded(child: Text(methodTitle(item), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900))),
            ]),
          ),
        ),
      ),
    );
  }

  Widget noteField() {
    return TextField(
      controller: noteC,
      minLines: 3,
      maxLines: 5,
      maxLength: 255,
      decoration: InputDecoration(
        hintText: 'Tulis catatan untuk penjual...',
        counterText: '',
        filled: true,
        fillColor: const Color(0xFFF7F8FC),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.all(12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Scaffold(backgroundColor: bg, body: Center(child: CircularProgressIndicator(color: maroon)));
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(title: const Text('Checkout'), backgroundColor: maroon, foregroundColor: Colors.white),
      body: RefreshIndicator(
        onRefresh: load,
        child: ListView(physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.all(14), children: [
          section(title: 'Barang yang di-checkout', icon: Icons.shopping_bag_outlined, child: checkoutItems()),
          section(title: 'Pesan untuk Penjual', icon: Icons.edit_note_rounded, child: noteField()),
          section(
            title: 'Alamat Pengiriman',
            icon: Icons.location_on_outlined,
            child: addresses.isEmpty
                ? const Text('Belum ada alamat. Tambahkan alamat dulu dari menu Akun.', style: TextStyle(color: Color(0xFF6B7280)))
                : DropdownButtonFormField<int>(
                    value: addressId,
                    isExpanded: true,
                    decoration: InputDecoration(filled: true, fillColor: const Color(0xFFF7F8FC), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none)),
                    items: addresses.map((raw) {
                      final item = Map<String, dynamic>.from(raw as Map);
                      return DropdownMenuItem<int>(value: int.tryParse('${item['id']}'), child: Text(addressLabel(item), maxLines: 1, overflow: TextOverflow.ellipsis));
                    }).toList(),
                    onChanged: (value) => setState(() => addressId = value),
                  ),
          ),
          section(
            title: 'Pilih Metode Pembayaran',
            icon: Icons.account_balance_wallet_outlined,
            child: methods.isEmpty
                ? const Text('Metode pembayaran belum tersedia.', style: TextStyle(color: Color(0xFF6B7280)))
                : Column(children: methods.map((raw) => paymentChoice(Map<String, dynamic>.from(raw as Map))).toList()),
          ),
          section(
            title: 'Ringkasan',
            icon: Icons.receipt_long_outlined,
            child: Row(children: [
              Expanded(child: Text('$totalQty item', style: const TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w700))),
              Text(Formatters.rupiah(total), style: const TextStyle(color: maroon, fontWeight: FontWeight.w900, fontSize: 17)),
            ]),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 0, 4, 8),
            child: Text('Detail QRIS/rekening pembayaran akan muncul setelah pesanan dibuat.', style: TextStyle(color: Color(0xFF6B7280), fontSize: 12, height: 1.35)),
          ),
        ]),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: ordering || methods.isEmpty || cartItems.isEmpty ? null : createOrder,
              style: FilledButton.styleFrom(backgroundColor: maroon, disabledBackgroundColor: Colors.black12, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
              child: ordering ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text('Buat Pesanan • ${Formatters.rupiah(total)}', style: const TextStyle(fontWeight: FontWeight.w900)),
            ),
          ),
        ),
      ),
    );
  }
}
