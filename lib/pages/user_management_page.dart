import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  final client = Supabase.instance.client;
  final searchController = TextEditingController();
  List<Map<String, dynamic>> users = [];
  bool loading = true;
  String? error;

  static const subdistricts = <String>[
    'เกาะเปาะ','ลิปะสะโง','คอลอตันหยง','ดอนรัก','ดาโต๊ะ','ตุยง',
    'ท่ากำชำ','บางเขา','บางตาวา','บ่อทอง','ปุโละปุโย','ยาบี',
  ];

  @override
  void initState() {
    super.initState();
    searchController.addListener(_filter);
    load();
  }

  @override
  void dispose() {
    searchController.removeListener(_filter);
    searchController.dispose();
    super.dispose();
  }

  Future<void> load() async {
    setState(() { loading = true; error = null; });
    try {
      final data = await client.from('profiles').select().order('created_at');
      users = List<Map<String, dynamic>>.from(data);
      if (mounted) setState(() => loading = false);
    } catch (e) {
      if (mounted) setState(() { loading = false; error = e.toString(); });
    }
  }

  List<Map<String, dynamic>> get filtered {
    final q = searchController.text.trim().toLowerCase();
    if (q.isEmpty) return users;
    return users.where((u) {
      final text = [u['email'], u['display_name'], u['phone'], u['subdistrict'], u['role']]
          .map((v) => v?.toString().toLowerCase() ?? '').join(' ');
      return text.contains(q);
    }).toList();
  }

  void _filter() => setState(() {});

  Future<void> addTeacher() async {
    final name = TextEditingController();
    final email = TextEditingController();
    final phone = TextEditingController();
    final password = TextEditingController();
    final confirmPassword = TextEditingController();
    String sub = '';
    bool saving = false;
    bool obscurePassword = true;
    bool obscureConfirm = true;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.person_add_alt_1),
              SizedBox(width: 10),
              Text('เพิ่มคุณครู'),
            ],
          ),
          content: SizedBox(
            width: 540,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: name,
                    decoration: const InputDecoration(
                      labelText: 'ชื่อผู้ใช้งาน / ชื่อ–สกุล *',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'อีเมลสำหรับเข้าสู่ระบบ *',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: phone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'เบอร์โทรศัพท์',
                      prefixIcon: Icon(Icons.phone_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: sub.isEmpty ? null : sub,
                    decoration: const InputDecoration(
                      labelText: 'ตำบลที่รับผิดชอบ *',
                      prefixIcon: Icon(Icons.location_on_outlined),
                      border: OutlineInputBorder(),
                    ),
                    items: subdistricts
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) => setDialog(() => sub = v ?? ''),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: password,
                    obscureText: obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'รหัสผ่านเริ่มต้น *',
                      helperText: 'อย่างน้อย 6 ตัวอักษร',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        onPressed: () => setDialog(() => obscurePassword = !obscurePassword),
                        icon: Icon(obscurePassword ? Icons.visibility : Icons.visibility_off),
                      ),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: confirmPassword,
                    obscureText: obscureConfirm,
                    decoration: InputDecoration(
                      labelText: 'ยืนยันรหัสผ่าน *',
                      prefixIcon: const Icon(Icons.lock_reset_outlined),
                      suffixIcon: IconButton(
                        onPressed: () => setDialog(() => obscureConfirm = !obscureConfirm),
                        icon: Icon(obscureConfirm ? Icons.visibility : Icons.visibility_off),
                      ),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'บัญชีที่สร้างจะเป็นสิทธิ์ “คุณครู / Teacher” และเปิดใช้งานทันที\nคุณครูสามารถเพิ่มและแก้ไขข้อมูลของตนเองตามตำบลที่รับผิดชอบได้',
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(dialogContext, false),
              child: const Text('ยกเลิก'),
            ),
            FilledButton.icon(
              onPressed: saving ? null : () async {
                if (name.text.trim().isEmpty || email.text.trim().isEmpty || sub.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('กรุณากรอกชื่อ อีเมล และตำบลให้ครบ')),
                  );
                  return;
                }
                if (password.text.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร')),
                  );
                  return;
                }
                if (password.text != confirmPassword.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('รหัสผ่านยืนยันไม่ตรงกัน')),
                  );
                  return;
                }

                setDialog(() => saving = true);
                try {
                  final response = await client.functions.invoke(
                    'create-teacher',
                    body: {
                      'display_name': name.text.trim(),
                      'email': email.text.trim(),
                      'phone': phone.text.trim(),
                      'subdistrict': sub,
                      'password': password.text,
                    },
                  );

                  final data = response.data;
                  if (data is Map && data['success'] == true) {
                    if (dialogContext.mounted) Navigator.pop(dialogContext, true);
                  } else {
                    throw Exception(data is Map ? (data['error'] ?? 'สร้างบัญชีไม่สำเร็จ') : 'สร้างบัญชีไม่สำเร็จ');
                  }
                } catch (e) {
                  setDialog(() => saving = false);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('เพิ่มคุณครูไม่สำเร็จ: $e')),
                    );
                  }
                }
              },
              icon: const Icon(Icons.person_add),
              label: Text(saving ? 'กำลังสร้างบัญชี...' : 'เพิ่มคุณครู'),
            ),
          ],
        ),
      ),
    );

    name.dispose();
    email.dispose();
    phone.dispose();
    password.dispose();
    confirmPassword.dispose();
    if (result == true) {
      await load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('เพิ่มคุณครูเรียบร้อยแล้ว')),
        );
      }
    }
  }

  Future<void> editUser(Map<String, dynamic> user) async {
    final name = TextEditingController(text: user['display_name']?.toString() ?? '');
    final phone = TextEditingController(text: user['phone']?.toString() ?? '');
    String role = user['role']?.toString() == 'admin' ? 'admin' : 'teacher';
    String sub = user['subdistrict']?.toString() ?? '';
    if (sub.isNotEmpty && !subdistricts.contains(sub)) sub = '';
    bool active = user['is_active'] != false;
    bool saving = false;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          title: const Text('แก้ไขผู้ใช้งาน'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(user['email']?.toString() ?? user['id']?.toString() ?? '-',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 14),
                  TextField(controller: name, decoration: const InputDecoration(labelText: 'ชื่อผู้ใช้งาน', border: OutlineInputBorder())),
                  const SizedBox(height: 10),
                  TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'เบอร์โทรศัพท์', border: OutlineInputBorder())),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: role,
                    decoration: const InputDecoration(labelText: 'สิทธิ์ผู้ใช้งาน', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'teacher', child: Text('คุณครู / Teacher')),
                      DropdownMenuItem(value: 'admin', child: Text('ผู้ดูแลระบบ / Admin')),
                    ],
                    onChanged: (v) => setDialog(() => role = v ?? 'teacher'),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: sub.isEmpty ? null : sub,
                    decoration: const InputDecoration(labelText: 'ตำบลที่รับผิดชอบ', border: OutlineInputBorder()),
                    items: [
                      const DropdownMenuItem(value: '', child: Text('ไม่กำหนด')),
                      ...subdistricts.map((s) => DropdownMenuItem(value: s, child: Text(s))),
                    ],
                    onChanged: (v) => setDialog(() => sub = v ?? ''),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('อนุญาตให้เข้าใช้งานระบบ'),
                    subtitle: Text(active ? 'เปิดใช้งาน' : 'ปิดการใช้งาน'),
                    value: active,
                    onChanged: (v) => setDialog(() => active = v),
                  ),
                  const SizedBox(height: 4),
                  const Text('หมายเหตุ: การสร้าง/ลบรหัสผ่านต้องทำผ่าน Supabase Authentication', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: saving ? null : () => Navigator.pop(dialogContext, false), child: const Text('ยกเลิก')),
            FilledButton(
              onPressed: saving ? null : () async {
                setDialog(() => saving = true);
                try {
                  await client.from('profiles').update({
                    'display_name': name.text.trim(),
                    'phone': phone.text.trim(),
                    'role': role,
                    'subdistrict': sub,
                    'is_active': active,
                  }).eq('id', user['id']);
                  if (dialogContext.mounted) Navigator.pop(dialogContext, true);
                } catch (e) {
                  setDialog(() => saving = false);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('บันทึกไม่สำเร็จ: $e')));
                  }
                }
              },
              child: Text(saving ? 'กำลังบันทึก...' : 'บันทึก'),
            ),
          ],
        ),
      ),
    );
    name.dispose(); phone.dispose();
    if (result == true) load();
  }

  Future<void> deleteUser(Map<String, dynamic> user) async {
    final role = user['role']?.toString() ?? 'teacher';
    final name = (user['display_name']?.toString().trim().isNotEmpty ?? false)
        ? user['display_name'].toString().trim()
        : (user['email']?.toString() ?? 'ผู้ใช้งาน');

    if (role == 'admin') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่สามารถลบบัญชี Admin จากหน้านี้ได้')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 10),
            Text('ยืนยันการลบคุณครู'),
          ],
        ),
        content: Text(
          'ต้องการลบ “$name” ใช่หรือไม่?\n\n'
          'การลบนี้จะลบบัญชีเข้าสู่ระบบและข้อมูลโปรไฟล์ของคุณครูอย่างถาวร\n'
          'รวมถึงข้อมูลที่คุณครูเป็นเจ้าของตามความสัมพันธ์ของฐานข้อมูล\n\n'
          'การดำเนินการนี้ไม่สามารถย้อนกลับได้',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.delete_forever),
            label: const Text('ลบคุณครู'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final response = await client.functions.invoke(
        'delete-teacher',
        body: {'user_id': user['id']},
      );
      final data = response.data;
      if (data is Map && data['success'] == true) {
        await load();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('ลบคุณครู “$name” เรียบร้อยแล้ว')),
          );
        }
      } else {
        throw Exception(
          data is Map ? (data['error'] ?? 'ลบบัญชีไม่สำเร็จ') : 'ลบบัญชีไม่สำเร็จ',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ลบคุณครูไม่สำเร็จ: $e')),
        );
      }
    }
  }

  Color roleColor(String role) => role == 'admin' ? Colors.deepPurple : Colors.teal;

  @override
  Widget build(BuildContext context) {
    final list = filtered;
    return Scaffold(
      appBar: AppBar(
        title: const Text('จัดการผู้ใช้งานและสิทธิ์'),
        actions: [
          IconButton(onPressed: load, icon: const Icon(Icons.refresh)),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: addTeacher,
        icon: const Icon(Icons.person_add),
        label: const Text('เพิ่มคุณครู'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('เกิดข้อผิดพลาด\n$error', textAlign: TextAlign.center)))
              : Column(
                  children: [
                    Card(
                      elevation: 0,
                      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(children: [
                          TextField(
                            controller: searchController,
                            decoration: const InputDecoration(
                              labelText: 'ค้นหาผู้ใช้งาน',
                              hintText: 'ชื่อ อีเมล เบอร์โทร หรือตำบล',
                              prefixIcon: Icon(Icons.search),
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(children: [
                            const Icon(Icons.groups_outlined), const SizedBox(width: 8),
                            Text('ผู้ใช้งาน ${list.length} คน', style: const TextStyle(fontWeight: FontWeight.bold)),
                            const Spacer(),
                            const Text('แก้ไขสิทธิ์ได้เฉพาะ Admin', style: TextStyle(color: Colors.grey)),
                          ]),
                        ]),
                      ),
                    ),
                    Expanded(
                      child: list.isEmpty
                          ? const Center(child: Text('ไม่พบผู้ใช้งาน'))
                          : RefreshIndicator(
                              onRefresh: load,
                              child: ListView.builder(
                                padding: const EdgeInsets.fromLTRB(16, 4, 16, 30),
                                itemCount: list.length,
                                itemBuilder: (_, i) {
                                  final u = list[i];
                                  final role = u['role']?.toString() ?? 'teacher';
                                  final active = u['is_active'] != false;
                                  final display = (u['display_name']?.toString().trim().isNotEmpty ?? false)
                                      ? u['display_name'].toString()
                                      : (u['email']?.toString().trim().isNotEmpty ?? false)
                                          ? u['email'].toString()
                                          : 'ผู้ใช้งาน';
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      leading: CircleAvatar(
                                        backgroundColor: roleColor(role).withValues(alpha: .12),
                                        foregroundColor: roleColor(role),
                                        child: Icon(role == 'admin' ? Icons.admin_panel_settings : Icons.person),
                                      ),
                                      title: Text(display, style: const TextStyle(fontWeight: FontWeight.bold)),
                                      subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                        if ((u['email']?.toString() ?? '').isNotEmpty) Text(u['email'].toString()),
                                        Text('สิทธิ์: ${role == 'admin' ? 'Admin' : 'Teacher'}'),
                                        Text('รับผิดชอบ: ${(u['subdistrict']?.toString().isNotEmpty ?? false) ? u['subdistrict'] : 'ยังไม่กำหนด'}'),
                                        Text(active ? 'สถานะ: เปิดใช้งาน' : 'สถานะ: ปิดการใช้งาน', style: TextStyle(color: active ? Colors.green : Colors.red)),
                                      ]),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit_outlined),
                                            tooltip: 'แก้ไข',
                                            onPressed: () => editUser(u),
                                          ),
                                          if (role != 'admin')
                                            IconButton(
                                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                                              tooltip: 'ลบคุณครู',
                                              onPressed: () => deleteUser(u),
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }
}
