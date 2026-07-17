import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../core/api_client.dart';
import '../core/app_config.dart';
import '../core/auth_storage.dart';
import '../core/formatters.dart';

class OrderDetailScreen extends StatefulWidget {
  final dynamic order;
  final dynamic orderId;
  final dynamic id;

  const OrderDetailScreen({
    super.key,
    this.order,
    this.orderId,
    this.id,
  });

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  bool loading = true;
  bool uploading = false;

  Map<String, dynamic> order = {};
  Map<String, dynamic> paymentMethod = {};
  Map<String, dynamic>? latestProof;
  List<dynamic> items = [];
  List<dynamic> timeline = [];

  static const maroon = Color(0xFF97002B);
  static const bg = Color(0xFFF7F8FC);

  @override
  void initState() {
    super.initState();
    load();
  }

  int orderIdFromInput() {
    final direct = int.tryParse('${widget.orderId ?? widget.id ?? ''}');
    if (direct != null && direct > 0) return direct;

    final o = widget.order;
    if (o is Map) {
      final fromOrder = int.tryParse('${o['id'] ?? o['order_id'] ?? ''}');
      if (fromOrder != null && fromOrder > 0) return fromOrder;
    }

    return 0;
  }

  Map<String, dynamic> dataOrRoot(Map<String, dynamic> res) {
    final data = res['data'];
    if (data is Map) return Map<String, dynamic>.from(data);
    return res;
  }

  bool ok(Map<String, dynamic> res) {
    return res['success'] == true || res['status'] == 'success' || res['ok'] == true;
  }

  Future<void> load() async {
    setState(() => loading = true);

    try {
      final id = orderIdFromInput();
      final res = await ApiClient.get('order_detail.php', query: {'id': '$id'});
      final data = dataOrRoot(res);

      if (!mounted) return;

      setState(() {
        order = Map<String, dynamic>.from(data['order'] as Map? ?? {});
        paymentMethod = Map<String, dynamic>.from(data['payment_method'] as Map? ?? {});
        final proof = data['latest_proof'];
        latestProof = proof is Map ? Map<String, dynamic>.from(proof) : null;
        items = data['items'] as List<dynamic>? ?? [];
        timeline = data['timeline'] as List<dynamic>? ?? [];
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      final o = widget.order;
      setState(() {
        order = o is Map ? Map<String, dynamic>.from(o) : {};
        loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat detail pesanan: $e')),
      );
    }
  }

  String val(String key, [String fallback = '']) => (order[key] ?? fallback).toString();

  String pay(String key, [String fallback = '']) => (paymentMethod[key] ?? fallback).toString();

  String proofVal(String key, [String fallback = '']) => (latestProof?[key] ?? fallback).toString();

  Widget card({required String title, required Widget child, IconData? icon}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF1E5EA)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.035), blurRadius: 16, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            if (icon != null) ...[
              Icon(icon, color: maroon, size: 20),
              const SizedBox(width: 8),
            ],
            Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15.5))),
          ]),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget rowInfo(String label, String value, {Color? valueColor}) {
    if (value.trim().isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 112, child: Text(label, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12.5))),
          Expanded(child: Text(value, style: TextStyle(color: valueColor ?? const Color(0xFF111827), fontWeight: FontWeight.w800, fontSize: 12.5))),
        ],
      ),
    );
  }

  Widget headerCard() {
    final code = val('order_code', val('order_number', 'Pesanan'));
    final paymentStatus = val('payment_status', 'unpaid');
    final total = order['grand_total'] ?? order['total_amount'] ?? order['total'] ?? 0;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [maroon, Color(0xFF820026)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(code, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 17)),
        const SizedBox(height: 12),
        rowHeader('Tanggal', val('created_at')),
        rowHeader('Pembayaran', paymentStatus),
        rowHeader('Total', Formatters.rupiah(total)),
      ]),
    );
  }

  Widget rowHeader(String label, String value) {
    if (value.trim().isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(children: [
        SizedBox(width: 96, child: Text(label, style: TextStyle(color: Colors.white.withOpacity(.75), fontSize: 12.5))),
        Expanded(child: Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12.5))),
      ]),
    );
  }

  Widget qrImageBox(String qrUrl) {
    if (qrUrl.trim().isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          const Text('Scan QRIS Pembayaran', style: TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          Container(
            width: 220,
            height: 220,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE5E7EB))),
            child: Image.network(
              qrUrl,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Center(child: Text('QRIS gagal dimuat', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF6B7280)))),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> uploadProof({
    required PlatformFile file,
    required String senderName,
    required String note,
  }) async {
    final orderId = orderIdFromInput();
    final bytes = file.bytes;

    if (bytes == null || bytes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File tidak terbaca. Pilih file lain.')));
      return;
    }

    setState(() => uploading = true);

    try {
      final token = await AuthStorage.token();
      final uri = Uri.parse('${AppConfig.baseUrl}/payment_proof_upload.php');
      final request = http.MultipartRequest('POST', uri);

      request.headers['Accept'] = 'application/json';
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      request.fields['order_id'] = '$orderId';
      request.fields['payment_method_id'] = '${paymentMethod['id'] ?? order['payment_method_id'] ?? ''}';
      request.fields['paid_amount'] = '${order['grand_total'] ?? order['total_amount'] ?? order['total'] ?? 0}';
      request.fields['sender_name'] = senderName;
      request.fields['note'] = note;

      request.files.add(
        http.MultipartFile.fromBytes(
          'proof_image',
          bytes,
          filename: file.name,
        ),
      );

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      Map<String, dynamic> body;
      try {
        final decoded = jsonDecode(response.body);
        body = decoded is Map<String, dynamic>
            ? decoded
            : <String, dynamic>{'success': false, 'message': 'Response server tidak valid.'};
      } catch (_) {
        body = <String, dynamic>{'success': false, 'message': response.body};
      }

      if (!mounted) return;

      if (response.statusCode >= 200 && response.statusCode < 300 && ok(body)) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text((body['message'] ?? 'Bukti pembayaran berhasil diupload.').toString())),
        );
        await load();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text((body['message'] ?? 'Gagal upload bukti pembayaran.').toString())),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal upload bukti pembayaran: $e')));
    } finally {
      if (mounted) setState(() => uploading = false);
    }
  }

  Future<void> showUploadProofSheet() async {
    final senderC = TextEditingController();
    final noteC = TextEditingController();
    PlatformFile? pickedFile;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> pickFile() async {
              final result = await FilePicker.platform.pickFiles(
                type: FileType.custom,
                allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
                withData: true,
              );

              if (result != null && result.files.isNotEmpty) {
                setModalState(() {
                  pickedFile = result.files.first;
                });
              }
            }

            return SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 44, height: 5, decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(99))),
                    const SizedBox(height: 16),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Upload Bukti Pembayaran', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: senderC,
                      decoration: InputDecoration(
                        labelText: 'Nama pengirim / atas nama transfer',
                        filled: true,
                        fillColor: const Color(0xFFF7F8FC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: noteC,
                      minLines: 2,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Catatan pembayaran',
                        hintText: 'Contoh: sudah transfer sesuai total pesanan',
                        filled: true,
                        fillColor: const Color(0xFFF7F8FC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: pickFile,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEEF2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFF8B4C4)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.image_outlined, color: maroon),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                pickedFile == null ? 'Pilih gambar bukti pembayaran' : pickedFile!.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: maroon, fontWeight: FontWeight.w800),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton.icon(
                        onPressed: uploading
                            ? null
                            : () {
                                if (pickedFile == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih gambar bukti pembayaran dulu.')));
                                  return;
                                }
                                uploadProof(
                                  file: pickedFile!,
                                  senderName: senderC.text.trim(),
                                  note: noteC.text.trim(),
                                );
                              },
                        icon: uploading
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.upload_file_rounded),
                        label: Text(uploading ? 'Mengupload...' : 'Kirim Bukti Pembayaran', style: const TextStyle(fontWeight: FontWeight.w900)),
                        style: FilledButton.styleFrom(backgroundColor: maroon, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    senderC.dispose();
    noteC.dispose();
  }

  Widget latestProofBox() {
    if (latestProof == null) return const SizedBox.shrink();

    final status = proofVal('status', 'pending');
    final url = proofVal('proof_image_url');
    final amount = proofVal('paid_amount');
    final created = proofVal('created_at');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            clipBehavior: Clip.antiAlias,
            child: url.isEmpty
                ? const Icon(Icons.receipt_long_rounded, color: maroon)
                : Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.receipt_long_rounded, color: maroon)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Bukti terkirim • $status', style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1E3A8A))),
              if (amount.isNotEmpty) Text('Nominal: ${Formatters.rupiah(amount)}', style: const TextStyle(color: Color(0xFF1E40AF), fontSize: 12.5)),
              if (created.isNotEmpty) Text(created, style: const TextStyle(color: Color(0xFF64748B), fontSize: 11.5)),
            ]),
          ),
        ],
      ),
    );
  }

  Widget paymentCard() {
    final name = pay('display_name', pay('method_name', pay('name', pay('title'))));
    final methodType = pay('method_type', pay('type'));
    final bank = pay('bank_name');
    final number = pay('account_number');
    final holder = pay('account_name');
    final qrUrl = pay('qr_image_url', pay('qris_image_url'));
    final instructions = pay('instructions');

    return card(
      title: 'Pembayaran',
      icon: Icons.account_balance_wallet_outlined,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (name.isEmpty && qrUrl.isEmpty && instructions.isEmpty)
          const Text('Detail pembayaran belum tersedia.', style: TextStyle(color: Color(0xFF6B7280), height: 1.35))
        else ...[
          rowInfo('Metode', name),
          rowInfo('Tipe', methodType.toUpperCase()),
          rowInfo('Bank/Channel', bank),
          rowInfo('Nomor', number, valueColor: maroon),
          rowInfo('Atas Nama', holder),
          qrImageBox(qrUrl),
          if (instructions.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFFFEEF2), borderRadius: BorderRadius.circular(14)),
              child: Text(instructions, style: const TextStyle(color: Color(0xFF374151), height: 1.35)),
            ),
        ],
        const SizedBox(height: 10),
        latestProofBox(),
        SizedBox(
          width: double.infinity,
          height: 44,
          child: FilledButton.icon(
            onPressed: uploading ? null : showUploadProofSheet,
            icon: uploading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.upload_file_rounded),
            label: Text(latestProof == null ? 'Upload Bukti Pembayaran' : 'Upload Ulang Bukti Pembayaran', style: const TextStyle(fontWeight: FontWeight.w900)),
            style: FilledButton.styleFrom(backgroundColor: maroon, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          ),
        ),
      ]),
    );
  }

  Widget noteCard() {
    final note = val('customer_note');
    if (note.trim().isEmpty) return const SizedBox.shrink();

    return card(
      title: 'Pesan untuk Penjual',
      icon: Icons.edit_note_rounded,
      child: Text(note, style: const TextStyle(color: Color(0xFF374151), height: 1.35)),
    );
  }

  Widget productCard() {
    return card(
      title: 'Produk Pesanan',
      icon: Icons.shopping_bag_outlined,
      child: items.isEmpty
          ? const Text('Item pesanan belum tersedia.', style: TextStyle(color: Color(0xFF6B7280)))
          : Column(
              children: items.map((raw) {
                final item = Map<String, dynamic>.from(raw as Map);
                final name = (item['product_name'] ?? item['name'] ?? '-').toString();
                final variant = (item['variant_name'] ?? '').toString();
                final qty = item['quantity'] ?? item['qty'] ?? 1;
                final subtotal = item['subtotal'] ?? 0;
                final price = (num.tryParse('$subtotal') ?? 0) > 0 ? subtotal : item['price'] ?? 0;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color(0xFFF7F8FC), borderRadius: BorderRadius.circular(16)),
                  child: Row(children: [
                    Container(width: 48, height: 48, decoration: BoxDecoration(color: const Color(0xFFFFEEF2), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.shopping_bag_outlined, color: maroon)),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900)),
                      if (variant.isNotEmpty) Text(variant, style: const TextStyle(color: maroon, fontWeight: FontWeight.w700, fontSize: 12)),
                    ])),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text('x$qty', style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
                      Text(Formatters.rupiah(price), style: const TextStyle(color: maroon, fontWeight: FontWeight.w900)),
                    ]),
                  ]),
                );
              }).toList(),
            ),
    );
  }

  Widget timelineCard() {
    return card(
      title: 'Timeline Pesanan',
      icon: Icons.timeline_rounded,
      child: timeline.isEmpty
          ? const Text('Timeline belum tersedia.', style: TextStyle(color: Color(0xFF6B7280)))
          : Column(
              children: timeline.map((raw) {
                final item = Map<String, dynamic>.from(raw as Map);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Icon(item['done'] == true ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, color: maroon, size: 20),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text((item['title'] ?? '').toString(), style: const TextStyle(fontWeight: FontWeight.w900)),
                      if ((item['description'] ?? '').toString().isNotEmpty) Text((item['description'] ?? '').toString(), style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12.5)),
                      if ((item['created_at'] ?? '').toString().isNotEmpty) Text((item['created_at'] ?? '').toString(), style: const TextStyle(color: Colors.black38, fontSize: 11.5)),
                    ])),
                  ]),
                );
              }).toList(),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Scaffold(backgroundColor: bg, body: Center(child: CircularProgressIndicator(color: maroon)));

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('Detail Pesanan'),
        backgroundColor: maroon,
        foregroundColor: Colors.white,
        actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh_rounded))],
      ),
      body: RefreshIndicator(
        onRefresh: load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(14),
          children: [
            headerCard(),
            paymentCard(),
            noteCard(),
            productCard(),
            timelineCard(),
          ],
        ),
      ),
    );
  }
}
