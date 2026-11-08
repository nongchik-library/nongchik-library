import 'package:flutter/material.dart';
import 'login_page.dart';
import 'public_portal_page.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE4F7F4),
              Color(0xFFE6EDFF),
              Color(0xFFFFE8F1),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 112,
                      height: 112,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(60),
                        border: Border.all(
                          color: const Color(0xFFD9AD28),
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/logo_skr.jpg',
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.menu_book_rounded,
                          size: 56,
                          color: Color(0xFF00897B),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      'คลังข้อมูลหนองจิก',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF173B57),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'งานการศึกษาตลอดชีวิต • ห้องสมุดประชาชนอำเภอหนองจิก',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, color: Color(0xFF526B7A)),
                    ),
                    const SizedBox(height: 32),
                    _EntryCard(
                      icon: Icons.menu_book_rounded,
                      title: 'ประชาชน / ผู้เรียน',
                      subtitle: 'เข้าชมข้อมูลเพื่อการศึกษาและดาวน์โหลดเอกสาร',
                      color: const Color(0xFF00897B),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PublicPortalPage(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _EntryCard(
                      icon: Icons.admin_panel_settings_rounded,
                      title: 'ผู้ดูแลระบบ / เจ้าหน้าที่',
                      subtitle: 'เข้าสู่ระบบเพื่อจัดการและบันทึกข้อมูล',
                      color: const Color(0xFF1976D2),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'SMART LIBRARY • NONGCHIK',
                      style: TextStyle(
                        letterSpacing: 2,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF71859A),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _EntryCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.92),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: color.withOpacity(0.18)),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.08),
                blurRadius: 18,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, color: color),
            ],
          ),
        ),
      ),
    );
  }
}
