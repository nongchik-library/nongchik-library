import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminReviewPage extends StatefulWidget {
  const AdminReviewPage({super.key});

  @override
  State<AdminReviewPage> createState() => _AdminReviewPageState();
}

class _AdminReviewPageState extends State<AdminReviewPage> {
  final SupabaseClient client = Supabase.instance.client;

  final Map<String, String> tables = const {
    'learning_resources': 'แหล่งเรียนรู้',
    'local_wisdom': 'ภูมิปัญญาท้องถิ่น',
    'local_scholars': 'ปราชญ์ชาวบ้าน',
    'community_book_houses': 'บ้านหนังสือชุมชน',
    'subdistrict_learning_centers': 'ศกร.ระดับตำบล',
    'tourist_attractions': 'แหล่งท่องเที่ยวในตำบล',
    'traditional_foods': 'อาหาร/ขนมโบราณในชุมชน',
    'village_book_corners': 'มุมหนังสือหมู่บ้าน',
  };

  List<Map<String, dynamic>> items = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (mounted) {
      setState(() => loading = true);
    }

    final result = <Map<String, dynamic>>[];

    for (final entry in tables.entries) {
      try {
        final data = await client
            .from(entry.key)
            .select()
            .eq('status', 'pending')
            .order('created_at', ascending: false);

        for (final row in List<Map<String, dynamic>>.from(data)) {
          result.add({
            ...row,
            '_table': entry.key,
            '_type': entry.value,
          });
        }
      } catch (_) {
        // ถ้าตารางใดยังไม่มี จะข้ามไปและตรวจตารางอื่นต่อ
      }
    }

    if (!mounted) return;

    setState(() {
      items = result;
      loading = false;
    });
  }

  Future<void> act(Map<String, dynamic> row, bool approve) async {
    try {
      final payload = <String, dynamic>{
        'status': approve ? 'approved' : 'rejected',
      };

      if (!approve) {
        final reason = await showDialog<String>(
          context: context,
          builder: (_) => const _ReasonDialog(),
        );

        if (reason == null) return;
        payload['rejection_reason'] = reason;
      }

      await client
          .from(row['_table'].toString())
          .update(payload)
          .eq('id', row['id']);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            approve ? 'อนุมัติข้อมูลแล้ว' : 'ส่งกลับแก้ไขแล้ว',
          ),
        ),
      );

      await load();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ดำเนินการไม่สำเร็จ: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(72),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF00897B), Color(0xFF26A69A), Color(0xFF42A5F5)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text(
              'ศูนย์ตรวจสอบข้อมูล',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            actions: [
              IconButton(
                onPressed: load,
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'รีเฟรช',
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF0FAF8), Color(0xFFEAF4FF), Color(0xFFF8F5FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : items.isEmpty
                ? Center(
                    child: Container(
                      margin: const EdgeInsets.all(24),
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 46),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFFFFF), Color(0xFFF0F7FF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: Color(0xFFB2DFDB)),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF00897B).withValues(alpha: .10),
                            blurRadius: 24,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified_rounded, size: 72, color: Color(0xFF00897B)),
                          SizedBox(height: 14),
                          Text(
                            'ไม่มีข้อมูลที่รอตรวจสอบ',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                  )
                : RefreshIndicator(
                  onRefresh: load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final row = items[index];
                      final description =
                          row['description']?.toString() ?? '';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFFFFF), Color(0xFFF4FAFF)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFFB2DFDB)),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00897B).withValues(alpha: .08),
                              blurRadius: 18,
                              offset: const Offset(0, 7),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                row['_type']?.toString() ?? '-',
                                style: const TextStyle(
                                  color: Color(0xFF008577),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                row['name']?.toString() ?? '-',
                                style: const TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'ตำบล: ${row['subdistrict'] ?? '-'}',
                              ),
                              if (description.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  description,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => act(row, false),
                                      icon: const Icon(Icons.close),
                                      label: const Text('ไม่อนุมัติ'),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: FilledButton.icon(
                                      onPressed: () => act(row, true),
                                      icon: const Icon(Icons.check),
                                      label: const Text('อนุมัติ'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
      ),
    );
  }
}

class _ReasonDialog extends StatefulWidget {
  const _ReasonDialog();

  @override
  State<_ReasonDialog> createState() => _ReasonDialogState();
}

class _ReasonDialogState extends State<_ReasonDialog> {
  final TextEditingController controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('เหตุผลที่ไม่อนุมัติ'),
      content: TextField(
        controller: controller,
        maxLines: 4,
        decoration: const InputDecoration(
          hintText: 'ระบุสิ่งที่ต้องแก้ไข',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('ยกเลิก'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, controller.text.trim()),
          child: const Text('ส่งกลับแก้ไข'),
        ),
      ],
    );
  }
}
