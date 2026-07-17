import 'package:flutter/material.dart';

import '../core/api_client.dart';

class AddressListScreen extends StatefulWidget {
  const AddressListScreen({super.key});

  @override
  State<AddressListScreen> createState() => _AddressListScreenState();
}

class _AddressListScreenState extends State<AddressListScreen> {
  bool loading = true;
  List<dynamic> addresses = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  bool success(Map<String, dynamic> res) {
    return res['success'] == true || res['status'] == 'success' || res['ok'] == true;
  }

  String message(Map<String, dynamic> res, String fallback) {
    return (res['message'] ?? fallback).toString();
  }

  Future<void> load() async {
    if (mounted) {
      setState(() => loading = true);
    }

    try {
      final res = await ApiClient.get('addresses.php');
      final data = res['data'] as Map<String, dynamic>? ?? {};

      if (!mounted) return;

      setState(() {
        addresses = data['addresses'] as List<dynamic>? ?? [];
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        addresses = [];
        loading = false;
      });
    }
  }

  String pick(Map<String, dynamic> item, String key, [String fallback = '']) {
    final value = (item[key] ?? '').toString().trim();
    return value.isEmpty ? fallback : value;
  }

  void openForm([Map<String, dynamic>? address]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (_) {
        return _AddressFormSheet(
          address: address,
          onSaved: load,
        );
      },
    );
  }

  Future<void> deleteAddress(Map<String, dynamic> address) async {
    final id = address['id'];

    if (id == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Hapus alamat?'),
          content: const Text('Alamat yang dihapus tidak bisa dikembalikan.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE11D48)),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      final res = await ApiClient.post(
        'address_delete.php',
        body: {'id': id},
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message(res, 'Alamat berhasil dihapus.'))),
      );

      await load();
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menghapus alamat.')),
      );
    }
  }

  Widget emptyState() {
    return ListView(
      padding: const EdgeInsets.all(22),
      children: [
        const SizedBox(height: 80),
        Container(
          width: 82,
          height: 82,
          decoration: const BoxDecoration(
            color: Color(0xFFFFEEF2),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.location_on_outlined,
            color: Color(0xFF97002B),
            size: 42,
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Belum ada alamat',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Tambahkan alamat pengiriman agar proses checkout lebih cepat.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.black54,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: () => openForm(),
          icon: const Icon(Icons.add_location_alt_outlined),
          label: const Text('Tambah Alamat'),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF97002B),
            minimumSize: const Size.fromHeight(48),
          ),
        ),
      ],
    );
  }

  Widget addressCard(Map<String, dynamic> address) {
    final label = pick(address, 'label', 'Alamat');
    final recipientName = pick(address, 'recipient_name', '-');
    final phone = pick(address, 'phone');
    final province = pick(address, 'province');
    final city = pick(address, 'city');
    final district = pick(address, 'district');
    final village = pick(address, 'village');
    final postalCode = pick(address, 'postal_code');
    final fullAddress = pick(address, 'full_address');
    final note = pick(address, 'note');
    final isDefault = '${address['is_default'] ?? 0}' == '1';

    final area = [
      village,
      district,
      city,
      province,
      postalCode,
    ].where((item) => item.trim().isNotEmpty).join(', ');

    return Container(
      margin: const EdgeInsets.only(bottom: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => openForm(address),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEEF2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.location_on_outlined,
                        color: Color(0xFF97002B),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        label,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    if (isDefault)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEEF2),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'Utama',
                          style: TextStyle(
                            color: Color(0xFF97002B),
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  recipientName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
                if (phone.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    phone,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 12.5,
                    ),
                  ),
                ],
                if (fullAddress.isNotEmpty) ...[
                  const SizedBox(height: 9),
                  Text(
                    fullAddress,
                    style: const TextStyle(
                      height: 1.35,
                      fontSize: 13,
                    ),
                  ),
                ],
                if (area.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    area,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 12.5,
                      height: 1.35,
                    ),
                  ),
                ],
                if (note.isNotEmpty) ...[
                  const SizedBox(height: 9),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F8FC),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      note,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 12.5,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () => openForm(address),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Edit'),
                    ),
                    TextButton.icon(
                      onPressed: () => deleteAddress(address),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Hapus'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFE11D48),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(title: const Text('Alamat Pengiriman')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openForm(),
        backgroundColor: const Color(0xFF97002B),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text('Tambah'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : addresses.isEmpty
              ? RefreshIndicator(
                  onRefresh: load,
                  child: emptyState(),
                )
              : RefreshIndicator(
                  onRefresh: load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 92),
                    children: addresses
                        .map((item) => addressCard(Map<String, dynamic>.from(item as Map)))
                        .toList(),
                  ),
                ),
    );
  }
}

class _AddressFormSheet extends StatefulWidget {
  final Map<String, dynamic>? address;
  final Future<void> Function() onSaved;

  const _AddressFormSheet({
    required this.address,
    required this.onSaved,
  });

  @override
  State<_AddressFormSheet> createState() => _AddressFormSheetState();
}

class _AddressFormSheetState extends State<_AddressFormSheet> {
  bool saving = false;
  bool isDefault = false;

  final labelC = TextEditingController();
  final recipientNameC = TextEditingController();
  final phoneC = TextEditingController();
  final provinceC = TextEditingController();
  final cityC = TextEditingController();
  final districtC = TextEditingController();
  final villageC = TextEditingController();
  final postalCodeC = TextEditingController();
  final fullAddressC = TextEditingController();
  final noteC = TextEditingController();

  @override
  void initState() {
    super.initState();

    final address = widget.address;

    if (address != null) {
      labelC.text = (address['label'] ?? '').toString();
      recipientNameC.text = (address['recipient_name'] ?? '').toString();
      phoneC.text = (address['phone'] ?? '').toString();
      provinceC.text = (address['province'] ?? '').toString();
      cityC.text = (address['city'] ?? '').toString();
      districtC.text = (address['district'] ?? '').toString();
      villageC.text = (address['village'] ?? '').toString();
      postalCodeC.text = (address['postal_code'] ?? '').toString();
      fullAddressC.text = (address['full_address'] ?? '').toString();
      noteC.text = (address['note'] ?? '').toString();
      isDefault = '${address['is_default'] ?? 0}' == '1';
    } else {
      labelC.text = 'Rumah';
    }
  }

  @override
  void dispose() {
    labelC.dispose();
    recipientNameC.dispose();
    phoneC.dispose();
    provinceC.dispose();
    cityC.dispose();
    districtC.dispose();
    villageC.dispose();
    postalCodeC.dispose();
    fullAddressC.dispose();
    noteC.dispose();
    super.dispose();
  }

  bool success(Map<String, dynamic> res) {
    return res['success'] == true || res['status'] == 'success' || res['ok'] == true;
  }

  String message(Map<String, dynamic> res, String fallback) {
    return (res['message'] ?? fallback).toString();
  }

  Future<void> save() async {
    if (recipientNameC.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama penerima wajib diisi.')),
      );
      return;
    }

    if (phoneC.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nomor HP penerima wajib diisi.')),
      );
      return;
    }

    if (fullAddressC.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alamat lengkap wajib diisi.')),
      );
      return;
    }

    setState(() => saving = true);

    final body = {
      if (widget.address?['id'] != null) 'id': widget.address!['id'],
      'label': labelC.text.trim(),
      'recipient_name': recipientNameC.text.trim(),
      'phone': phoneC.text.trim(),
      'province': provinceC.text.trim(),
      'city': cityC.text.trim(),
      'district': districtC.text.trim(),
      'village': villageC.text.trim(),
      'postal_code': postalCodeC.text.trim(),
      'full_address': fullAddressC.text.trim(),
      'note': noteC.text.trim(),
      'is_default': isDefault ? 1 : 0,
    };

    try {
      final res = await ApiClient.post(
        'address_save.php',
        body: body,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message(res, success(res) ? 'Alamat berhasil disimpan.' : 'Gagal menyimpan alamat.'))),
      );

      if (success(res)) {
        await widget.onSaved();
        if (mounted) Navigator.pop(context);
      }
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menyimpan alamat.')),
      );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Widget input({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    bool requiredField = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: requiredField ? '$label *' : label,
          prefixIcon: Icon(icon),
          filled: true,
          fillColor: const Color(0xFFF7F8FC),
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
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: ListView(
        shrinkWrap: true,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            widget.address == null ? 'Tambah Alamat' : 'Edit Alamat',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Sesuaikan dengan data alamat pengiriman di database MI MART.',
            style: TextStyle(
              color: Colors.black54,
              fontSize: 12.5,
            ),
          ),
          const SizedBox(height: 14),
          input(
            controller: labelC,
            label: 'Label',
            icon: Icons.bookmark_border_rounded,
          ),
          input(
            controller: recipientNameC,
            label: 'Nama Penerima',
            icon: Icons.person_outline_rounded,
            requiredField: true,
          ),
          input(
            controller: phoneC,
            label: 'Nomor HP',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            requiredField: true,
          ),
          input(
            controller: provinceC,
            label: 'Provinsi',
            icon: Icons.public_outlined,
          ),
          input(
            controller: cityC,
            label: 'Kota / Kabupaten',
            icon: Icons.location_city_outlined,
          ),
          input(
            controller: districtC,
            label: 'Kecamatan',
            icon: Icons.map_outlined,
          ),
          input(
            controller: villageC,
            label: 'Desa / Kelurahan',
            icon: Icons.holiday_village_outlined,
          ),
          input(
            controller: postalCodeC,
            label: 'Kode Pos',
            icon: Icons.local_post_office_outlined,
            keyboardType: TextInputType.number,
          ),
          input(
            controller: fullAddressC,
            label: 'Alamat Lengkap',
            icon: Icons.location_on_outlined,
            maxLines: 3,
            requiredField: true,
          ),
          input(
            controller: noteC,
            label: 'Catatan',
            icon: Icons.notes_outlined,
            maxLines: 2,
          ),
          SwitchListTile(
            value: isDefault,
            activeColor: const Color(0xFF97002B),
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Jadikan alamat utama',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: const Text('Alamat utama akan diprioritaskan saat checkout.'),
            onChanged: (value) => setState(() => isDefault = value),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: saving ? null : save,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF97002B),
              ),
              child: saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Simpan Alamat'),
            ),
          ),
        ],
      ),
    );
  }
}
