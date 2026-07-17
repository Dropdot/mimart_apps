import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../widgets/empty_state.dart';

class PaymentUploadScreen extends StatefulWidget {
  final int orderId;

  const PaymentUploadScreen({super.key, this.orderId = 0});

  @override
  State<PaymentUploadScreen> createState() => _PaymentUploadScreenState();
}

class _PaymentUploadScreenState extends State<PaymentUploadScreen> {
  File? file;
  bool loading = false;

  Future<void> pick() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'pdf']);
    if (result?.files.single.path != null) setState(() => file = File(result!.files.single.path!));
  }

  Future<void> upload() async {
    if (file == null) return;
    setState(() => loading = true);
    final res = await ApiClient.multipart(
      'payment_upload_proof.php',
      fields: {'order_id': '${widget.orderId}'},
      file: file,
      fileField: 'proof',
    );
    setState(() => loading = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message']?.toString() ?? 'Selesai')));
    if (res['status'] == 'success') Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(title: const Text('Upload Bukti')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (file == null)
            const EmptyState(title: 'Belum ada file', subtitle: 'Pilih gambar bukti pembayaran atau PDF.')
          else
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
              child: Text(file!.path.split('/').last, style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
          const SizedBox(height: 14),
          OutlinedButton.icon(onPressed: pick, icon: const Icon(Icons.attach_file), label: const Text('Pilih File')),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: loading || file == null ? null : upload,
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF97002B), minimumSize: const Size.fromHeight(48)),
            icon: loading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.cloud_upload_rounded),
            label: const Text('Upload'),
          ),
        ],
      ),
    );
  }
}
