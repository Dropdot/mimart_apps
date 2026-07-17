import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/api_client.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  bool loading = true;
  String ownerPhone = '';
  String whatsappUrl = '';
  List<dynamic> faq = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => loading = true);

    try {
      final res = await ApiClient.get('help.php');
      final data = res['data'] as Map<String, dynamic>? ?? {};

      if (!mounted) return;

      setState(() {
        ownerPhone = (data['owner_phone'] ?? '').toString();
        whatsappUrl = (data['whatsapp_url'] ?? '').toString();
        faq = data['faq'] as List<dynamic>? ?? [];
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        ownerPhone = '6285174465615';
        whatsappUrl = '';
        faq = [];
        loading = false;
      });
    }
  }

  Future<void> copy(String text, String label) async {
    if (text.trim().isEmpty) return;

    await Clipboard.setData(ClipboardData(text: text));

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label disalin.')),
    );
  }

  Widget contactCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF97002B), Color(0xFF6F001F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.headset_mic_outlined, color: Colors.white, size: 32),
          const SizedBox(height: 18),
          const Text(
            'Pusat Bantuan MI MART',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20),
          ),
          const SizedBox(height: 5),
          const Text(
            'Hubungi admin jika ada kendala pesanan, pembayaran, desain, atau pengiriman.',
            style: TextStyle(color: Colors.white70, height: 1.35),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => copy(ownerPhone, 'Nomor WhatsApp'),
                  icon: const Icon(Icons.copy_rounded),
                  label: Text(ownerPhone.isEmpty ? 'Salin Nomor' : ownerPhone),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF97002B),
                  ),
                ),
              ),
            ],
          ),
          if (whatsappUrl.isNotEmpty) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => copy(whatsappUrl, 'Link WhatsApp'),
              child: const Text(
                'Tekan untuk salin link WhatsApp',
                style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget faqCard(Map<String, dynamic> f) {
    final q = (f['question'] ?? 'Pertanyaan').toString();
    final a = (f['answer'] ?? '').toString();

    return Container(
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.035), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: ExpansionTile(
        title: Text(q, style: const TextStyle(fontWeight: FontWeight.w900)),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(a, style: const TextStyle(color: Colors.black87, height: 1.35)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final defaultFaq = [
      {
        'question': 'Bagaimana melihat status pesanan?',
        'answer': 'Buka menu Akun, lalu pilih status pada bagian Pesanan Saya.',
      },
      {
        'question': 'Bagaimana mengubah alamat pengiriman?',
        'answer': 'Buka Akun > Daftar Alamat Pengiriman, lalu tambah atau edit alamat.',
      },
      {
        'question': 'Bagaimana menghubungi admin?',
        'answer': 'Salin nomor WhatsApp di halaman ini lalu hubungi admin MI MART.',
      },
    ];

    final faqRows = faq.isEmpty ? defaultFaq : faq;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(title: const Text('Bantuan')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  contactCard(),
                  const SizedBox(height: 18),
                  const Text('Pertanyaan Umum', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  ...faqRows.map((e) => faqCard(Map<String, dynamic>.from(e as Map))),
                ],
              ),
            ),
    );
  }
}
