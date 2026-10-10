import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool loading = false;
  String? error;

  Future<void> login() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      await AuthService().signIn(email.text, password.text);
      final profile = await AuthService().getProfile();
      if (profile != null && profile['is_active'] == false) {
        await AuthService().signOut();
        throw Exception('บัญชีนี้ถูกปิดการใช้งาน กรุณาติดต่อผู้ดูแลระบบ');
      }
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomePage()),
        (_) => false,
      );
    } catch (e) {
      setState(() => error = 'เข้าสู่ระบบไม่สำเร็จ: ${e.toString()}');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF00796B)),
      filled: true,
      fillColor: Colors.white.withOpacity(0.92),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0x2200786B)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF00796B), width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE8F8F5),
              Color(0xFFD8F1F4),
              Color(0xFFEDE7FF),
              Color(0xFFFFE7EF),
            ],
            stops: [0.0, 0.38, 0.72, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Decorative gradient bubbles.
            Positioned(
              top: -110,
              left: -80,
              child: _glowCircle(260, const Color(0x5538BDF8)),
            ),
            Positioned(
              top: size.height * 0.12,
              right: -90,
              child: _glowCircle(230, const Color(0x556366F1)),
            ),
            Positioned(
              bottom: -120,
              left: size.width * 0.10,
              child: _glowCircle(300, const Color(0x5548D7B0)),
            ),
            Positioned(
              bottom: -80,
              right: -40,
              child: _glowCircle(240, const Color(0x55F472B6)),
            ),

            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 470),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(30, 30, 30, 28),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.78),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white.withOpacity(0.9)),
                      boxShadow: const [
                        BoxShadow(
                          blurRadius: 35,
                          spreadRadius: 2,
                          offset: Offset(0, 18),
                          color: Color(0x33006B63),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Official SKR logo already included in the project.
                        Container(
                          width: 108,
                          height: 108,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFD8AE36),
                              width: 2.5,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                blurRadius: 18,
                                offset: Offset(0, 8),
                                color: Color(0x26006B63),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/logo_skr.jpg',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'ระบบคลังข้อมูล',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF00796B),
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 7),
                        const Text(
                          'งานการศึกษาตลอดชีวิต',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF17324D),
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'ห้องสมุดประชาชนอำเภอหนองจิก',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF17324D),
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'ศูนย์ส่งเสริมการเรียนรู้ระดับอำเภอหนองจิก',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF4C6272),
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 22),
                        Container(
                          height: 4,
                          width: 110,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF00897B),
                                Color(0xFF3B82F6),
                                Color(0xFF8B5CF6),
                                Color(0xFFEC4899),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          controller: email,
                          keyboardType: TextInputType.emailAddress,
                          decoration: _inputDecoration(
                            label: 'อีเมล',
                            icon: Icons.email_outlined,
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: password,
                          obscureText: true,
                          onSubmitted: (_) => loading ? null : login(),
                          decoration: _inputDecoration(
                            label: 'รหัสผ่าน',
                            icon: Icons.lock_outline,
                          ),
                        ),
                        if (error != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFE8EC),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0x33D32F2F)),
                            ),
                            child: Text(
                              error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFFC62828),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF00796B),
                                  Color(0xFF009688),
                                  Color(0xFF1976D2),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: const [
                                BoxShadow(
                                  blurRadius: 14,
                                  offset: Offset(0, 7),
                                  color: Color(0x3300786B),
                                ),
                              ],
                            ),
                            child: ElevatedButton.icon(
                              onPressed: loading ? null : login,
                              icon: loading
                                  ? const SizedBox(
                                      width: 19,
                                      height: 19,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.login_rounded),
                              label: Text(
                                loading ? 'กำลังตรวจสอบ...' : 'เข้าสู่ระบบ',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                shadowColor: Colors.transparent,
                                disabledBackgroundColor: Colors.transparent,
                                disabledForegroundColor: Colors.white70,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'SMART LIBRARY • NONGCHIK',
                          style: TextStyle(
                            color: Color(0xFF718096),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _glowCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withOpacity(0.0)],
        ),
      ),
    );
  }
}
