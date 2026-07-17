import 'package:flutter/material.dart';

import '../core/api_client.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  bool loading = true;
  bool saving = false;

  final nameC = TextEditingController();
  final usernameC = TextEditingController();
  final emailC = TextEditingController();
  final phoneC = TextEditingController();

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    nameC.dispose();
    usernameC.dispose();
    emailC.dispose();
    phoneC.dispose();
    super.dispose();
  }

  bool ok(Map<String, dynamic> res) {
    return res['success'] == true || res['status'] == 'success' || res['ok'] == true;
  }

  String message(Map<String, dynamic> res, String fallback) {
    return (res['message'] ?? fallback).toString();
  }

  Future<void> load() async {
    try {
      final res = await ApiClient.get('account_summary.php');
      final data = res['data'] as Map<String, dynamic>? ?? {};
      final profile = Map<String, dynamic>.from(data['user_profile'] as Map? ?? {});

      if (!mounted) return;

      setState(() {
        nameC.text = (profile['name'] ?? '').toString();
        usernameC.text = (profile['username'] ?? '').toString();
        emailC.text = (profile['email'] ?? '').toString();
        phoneC.text = (profile['phone'] ?? '').toString();
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => loading = false);
    }
  }

  Future<void> save() async {
    if (nameC.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama tidak boleh kosong.')),
      );
      return;
    }

    setState(() => saving = true);

    try {
      final res = await ApiClient.post(
        'update_profile.php',
        body: {
          'name': nameC.text.trim(),
          'username': usernameC.text.trim(),
          'email': emailC.text.trim(),
          'phone': phoneC.text.trim(),
        },
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message(res, ok(res) ? 'Profil berhasil diperbarui.' : 'Gagal memperbarui profil.'))),
      );

      if (ok(res)) {
        Navigator.pop(context, true);
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menyimpan profil.')),
      );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Widget input({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(title: const Text('Edit Profil')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEEF2),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Text(
                    'Data profil mengikuti akun customer MI MART yang sama dengan website.',
                    style: TextStyle(color: Color(0xFF97002B), fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 14),
                input(controller: nameC, label: 'Nama Lengkap', icon: Icons.person_outline_rounded),
                input(controller: usernameC, label: 'Username', icon: Icons.alternate_email_rounded),
                input(controller: emailC, label: 'Email', icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                input(controller: phoneC, label: 'Nomor HP / WhatsApp', icon: Icons.phone_outlined, keyboardType: TextInputType.phone),
                const SizedBox(height: 6),
                SizedBox(
                  height: 48,
                  child: FilledButton(
                    onPressed: saving ? null : save,
                    style: FilledButton.styleFrom(backgroundColor: const Color(0xFF97002B)),
                    child: saving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Simpan Profil'),
                  ),
                ),
              ],
            ),
    );
  }
}
