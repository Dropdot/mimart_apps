import 'package:flutter/material.dart';

import '../core/api_client.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  bool saving = false;
  bool obscureOld = true;
  bool obscureNew = true;
  bool obscureConfirm = true;

  final oldC = TextEditingController();
  final newC = TextEditingController();
  final confirmC = TextEditingController();

  @override
  void dispose() {
    oldC.dispose();
    newC.dispose();
    confirmC.dispose();
    super.dispose();
  }

  bool ok(Map<String, dynamic> res) {
    return res['success'] == true || res['status'] == 'success' || res['ok'] == true;
  }

  String msg(Map<String, dynamic> res, String fallback) {
    return (res['message'] ?? fallback).toString();
  }

  Future<void> save() async {
    if (oldC.text.isEmpty || newC.text.isEmpty || confirmC.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua kolom password wajib diisi.')),
      );
      return;
    }

    if (newC.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password baru minimal 6 karakter.')),
      );
      return;
    }

    if (newC.text != confirmC.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Konfirmasi password tidak sama.')),
      );
      return;
    }

    setState(() => saving = true);

    try {
      final res = await ApiClient.post(
        'change_password.php',
        body: {
          'current_password': oldC.text,
          'new_password': newC.text,
          'confirm_password': confirmC.text,
        },
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg(res, ok(res) ? 'Password berhasil diganti.' : 'Gagal mengganti password.'))),
      );

      if (ok(res)) Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mengganti password.')),
      );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Widget passwordInput({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback toggle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.lock_outline_rounded),
          suffixIcon: IconButton(
            onPressed: toggle,
            icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
          ),
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
      appBar: AppBar(title: const Text('Ganti Password')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          passwordInput(
            controller: oldC,
            label: 'Password Lama',
            obscure: obscureOld,
            toggle: () => setState(() => obscureOld = !obscureOld),
          ),
          passwordInput(
            controller: newC,
            label: 'Password Baru',
            obscure: obscureNew,
            toggle: () => setState(() => obscureNew = !obscureNew),
          ),
          passwordInput(
            controller: confirmC,
            label: 'Konfirmasi Password Baru',
            obscure: obscureConfirm,
            toggle: () => setState(() => obscureConfirm = !obscureConfirm),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: saving ? null : save,
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF97002B)),
              child: saving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Simpan Password'),
            ),
          ),
        ],
      ),
    );
  }
}
