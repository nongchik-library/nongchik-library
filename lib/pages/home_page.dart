import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import 'admin_review_page.dart';
import 'dashboard_page.dart';
import 'data_list_page.dart';
import 'file_library_page.dart';
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
      if (mounted) {
        setState(() {
          admin = p?['role'] == 'admin';
          assignedSubdistrict = p?['subdistrict']?.toString() ?? '';
        });
      }
    } catch (_) {}
  }

  Future<void> _logout() async {
    await AuthService().signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginPage()), (_) => false);
  }

  void _open(DataType type) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => DataListPage(type: type)));
  }

  Widget _menuTile({required IconData icon, required String title, required String subtitle, required Color color, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .72),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white.withValues(alpha: .75)),
            ),
            child: Row(children: [
              Container(width: 38, height: 38, decoration: BoxDecoration(color: color.withValues(alpha: .12), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 21)),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10.5, color: Colors.black54)),
              ])),
              Icon(Icons.chevron_right_rounded, color: color, size: 19),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _sidebar() {
    return Container(
      width: 310,
      decoration: const BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFE8F6F3), Color(0xFFF7FAFF)]),
        border: Border(right: BorderSide(color: Color(0xFFD6E7E3))),
      ),
      child: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
            child: Row(children: [
              Container(width: 48, height: 48, decoration: BoxDecoration(color: const Color(0xFF00897B), borderRadius: BorderRadius.circular(15)), child: const Icon(Icons.local_library_rounded, color: Colors.white, size: 28)),
              const SizedBox(width: 12),
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('คลังข้อมูลหนองจิก', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)), Text('งานการศึกษาตลอดชีวิต', style: TextStyle(fontSize: 11, color: Colors.black54))])),
            ]),
          ),
          const Divider(height: 1),
          Expanded(child: ListView(padding: const EdgeInsets.fromLTRB(12, 12, 12, 16), children: [
            _menuTile(icon: Icons.dashboard_rounded, title: 'Dashboard', subtitle: 'ภาพรวมความก้าวหน้า', color: const Color(0xFF00796B), onTap: () {}),
            const Padding(padding: EdgeInsets.fromLTRB(8, 8, 8, 8), child: Text('เมนูหลัก', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.black45))),
            _menuTile(icon: Icons.menu_book_rounded, title: 'แหล่งเรียนรู้', subtitle: 'ข้อมูลพร้อมรูปภาพและ GPS', color: Colors.green, onTap: () => _open(DataType.learningResource)),
            _menuTile(icon: Icons.eco_rounded, title: 'ภูมิปัญญาท้องถิ่น', subtitle: 'ภูมิปัญญาและการสืบทอด', color: Colors.teal, onTap: () => _open(DataType.localWisdom)),
            _menuTile(icon: Icons.person_rounded, title: 'ปราชญ์ชาวบ้าน', subtitle: 'ผู้รู้และความเชี่ยวชาญ', color: Colors.deepPurple, onTap: () => _open(DataType.localScholar)),
            _menuTile(icon: Icons.home_work_rounded, title: 'บ้านหนังสือชุมชน', subtitle: 'บ้านหนังสือพร้อม GPS', color: Colors.blue, onTap: () => _open(DataType.communityBookHouse)),
            _menuTile(icon: Icons.location_city_rounded, title: 'ศกร.ระดับตำบล', subtitle: 'ข้อมูล ศกร.ระดับตำบล', color: Colors.indigo, onTap: () => _open(DataType.subdistrictLearningCenter)),
            _menuTile(icon: Icons.photo_camera_rounded, title: 'แหล่งท่องเที่ยวในตำบล', subtitle: 'สถานที่ท่องเที่ยวพร้อม GPS', color: Colors.pink, onTap: () => _open(DataType.touristAttraction)),
            _menuTile(icon: Icons.restaurant_rounded, title: 'อาหาร/ขนมโบราณในชุมชน', subtitle: 'อาหาร ขนม และเรื่องราวชุมชน', color: Colors.orange, onTap: () => _open(DataType.traditionalFood)),
            _menuTile(icon: Icons.local_library_rounded, title: 'มุมหนังสือหมู่บ้าน', subtitle: 'ข้อมูลมุมหนังสือและกิจกรรมส่งเสริมการอ่าน', color: const Color(0xFF6A1B9A), onTap: () => _open(DataType.villageBookCorner)),
            const Padding(padding: EdgeInsets.fromLTRB(8, 12, 8, 8), child: Text('เครื่องมือระบบ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.black45))),
            _menuTile(icon: Icons.map_outlined, title: 'แผนที่แหล่งเรียนรู้', subtitle: 'แผนที่และพิกัด GPS ทั้งอำเภอ', color: Colors.red, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MapPage()))),
            _menuTile(icon: Icons.folder_copy_outlined, title: 'คลังรูปภาพและเอกสาร', subtitle: 'รูปภาพ • Word • PDF', color: Colors.teal, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FileLibraryPage()))),
            if (admin) ...[
              _menuTile(icon: Icons.manage_accounts_rounded, title: 'จัดการผู้ใช้งานและสิทธิ์', subtitle: 'Admin / Teacher / ตำบลที่รับผิดชอบ', color: Colors.blueGrey, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserManagementPage()))),
              _menuTile(icon: Icons.verified_user_rounded, title: 'ศูนย์ตรวจสอบข้อมูล', subtitle: 'อนุมัติ / ไม่อนุมัติข้อมูล', color: Colors.green.shade700, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminReviewPage()))),
            ],
          ])),
          const Divider(height: 1),
          Padding(padding: const EdgeInsets.fromLTRB(12, 8, 12, 10), child: ListTile(leading: const CircleAvatar(child: Icon(Icons.person)), title: Text(c.auth.currentUser?.email ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Text(admin ? 'Admin' : (assignedSubdistrict.isEmpty ? 'Teacher' : 'Teacher • $assignedSubdistrict')), trailing: IconButton(onPressed: _logout, icon: const Icon(Icons.logout_rounded), tooltip: 'ออกจากระบบ'))),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(children: [
        _sidebar(),
        const Expanded(child: DashboardPage()),
      ]),
    );
  }
}
