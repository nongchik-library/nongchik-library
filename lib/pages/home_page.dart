import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import 'data_list_page.dart';
import 'file_library_page.dart';
import 'admin_review_page.dart';
import 'login_page.dart';
import 'map_page.dart';
import 'user_management_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final c = Supabase.instance.client;
  bool admin = false;
  String assignedSubdistrict = '';

  @override
  void initState() {
    super.initState();
    _role();
  }

  Future<void> _role() async {
    final u = c.auth.currentUser;
    if (u == null) return;
    try {
      final p = await c.from('profiles').select('role,subdistrict,is_active').eq('id', u.id).maybeSingle();
      if (mounted) setState(() {
        admin = p?['role'] == 'admin';
        assignedSubdistrict = p?['subdistrict']?.toString() ?? '';
      });
    } catch (_) {}
  }

  Future<void> _logout() async {
    await AuthService().signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  void _open(DataType type) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DataListPage(type: type)),
    );
  }

  Widget card(
    IconData icon,
    String title,
    String subtitle,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.13),
                Colors.white,
              ],
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            leading: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(subtitle),
            ),
            trailing: Icon(Icons.arrow_forward_ios_rounded, size: 18, color: color),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final email = c.auth.currentUser?.email ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'งานการศึกษาตลอดชีวิต\nห้องสมุดประชาชนอำเภอหนองจิก\nศูนย์ส่งเสริมการเรียนรู้ระดับอำเภอหนองจิก\nสำนักงานส่งเสริมการเรียนรู้ประจำจังหวัดปัตตานี',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
        children: [
          Card(
            clipBehavior: Clip.antiAlias,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF00796B), Color(0xFF4DB6AC)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white.withValues(alpha: 0.22),
                    foregroundColor: Colors.white,
                    child: const Icon(Icons.person, size: 30),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('ผู้ใช้งาน', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
                        Text(
                          email,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          admin
                              ? 'ผู้ดูแลระบบ (Admin)'
                              : (assignedSubdistrict.isNotEmpty ? 'คุณครู • รับผิดชอบตำบล$assignedSubdistrict' : 'คุณครู • ยังไม่ได้กำหนดตำบล'),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.92),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'ระบบคลังข้อมูล',
            style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(height: 12),
          card(
            Icons.map_outlined,
            'แผนที่แหล่งเรียนรู้',
            'แผนที่รวมข้อมูลและพิกัด GPS ทั้งอำเภอ',
            Colors.red,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MapPage()),
            ),
          ),
          card(
            Icons.folder_copy_outlined,
            'คลังรูปภาพและเอกสาร',
            'รูปภาพ • Word • PDF • ดาวน์โหลด',
            Colors.teal,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FileLibraryPage()),
            ),
          ),
          card(
            Icons.menu_book,
            'แหล่งเรียนรู้',
            'ข้อมูลพร้อมรูปภาพและพิกัด GPS',
            Colors.green,
            () => _open(DataType.learningResource),
          ),
          card(
            Icons.eco,
            'ภูมิปัญญาท้องถิ่น',
            'ภูมิปัญญาและการสืบทอด',
            Colors.green,
            () => _open(DataType.localWisdom),
          ),
          card(
            Icons.person,
            'ปราชญ์ชาวบ้าน',
            'ผู้รู้และความเชี่ยวชาญในชุมชน',
            Colors.deepPurple,
            () => _open(DataType.localScholar),
          ),
          card(
            Icons.home_work,
            'บ้านหนังสือชุมชน',
            'บ้านหนังสือพร้อมพิกัด GPS',
            Colors.blue,
            () => _open(DataType.communityBookHouse),
          ),
          card(
            Icons.location_city,
            'ศกร.ระดับตำบล',
            'ข้อมูล ศกร.ระดับตำบล',
            Colors.indigo,
            () => _open(DataType.subdistrictLearningCenter),
          ),
          card(
            Icons.photo_camera,
            'แหล่งท่องเที่ยวในตำบล',
            'สถานที่ท่องเที่ยวพร้อมพิกัด GPS',
            Colors.pink,
            () => _open(DataType.touristAttraction),
          ),
          card(
            Icons.restaurant,
            'อาหาร/ขนมโบราณในชุมชน',
            'อาหาร ขนม และเรื่องราวชุมชน',
            Colors.orange,
            () => _open(DataType.traditionalFood),
          ),
          if (admin) ...[
            Card(
              color: const Color(0xFFEAF0FF),
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.manage_accounts)),
                title: const Text('จัดการผู้ใช้งานและสิทธิ์', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('กำหนดสิทธิ์ Admin / Teacher และตำบลที่รับผิดชอบ'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserManagementPage())),
              ),
            ),
            Card(
              color: const Color(0xFFE6F4F1),
              child: ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.verified_user),
                ),
                title: const Text(
                  'ศูนย์ตรวจสอบข้อมูล',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('อนุมัติ / ไม่อนุมัติข้อมูล'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminReviewPage()),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
