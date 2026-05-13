import 'package:flutter/material.dart';

import 'models.dart';
import 'team_service.dart';

class TeamManagementScreen extends StatefulWidget {
  final CompetitionItem competition;

  const TeamManagementScreen({super.key, required this.competition});

  @override
  State<TeamManagementScreen> createState() => _TeamManagementScreenState();
}

class _TeamManagementScreenState extends State<TeamManagementScreen> {
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  bool saving = false;

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createTeam() async {
    if (nameController.text.trim().isEmpty) {
      _snack('Багийн нэр оруулна уу');
      return;
    }
    setState(() => saving = true);
    try {
      await TeamService.createTeam(
        competition: widget.competition,
        name: nameController.text,
        description: descriptionController.text,
        logoUrl: '',
      );
      if (!mounted) return;
      setState(() => saving = false);
      _snack('Баг амжилттай үүслээ');
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => saving = false);
      _snack('Алдаа: $e');
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    const yellow = Color(0xFFF5C400);
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      appBar: AppBar(
        title: const Text('Баг үүсгэх'),
        backgroundColor: yellow,
        foregroundColor: Colors.black,
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _field(nameController, 'Багийн нэр', Icons.groups_outlined),
          _field(
            descriptionController,
            'Багийн тайлбар',
            Icons.description_outlined,
            maxLines: 4,
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: _cardDecoration(),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Color(0xFFFF6A00)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Багийн ахлагч нь автоматаар та болно. Баг үүссэний дараа системд бүртгэлтэй хэрэглэгчдийг email/name-ээр хайж invite илгээнэ.',
                    style: TextStyle(color: Colors.grey.shade700, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: saving ? null : _createTeam,
              icon: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_rounded),
              label: Text(
                saving ? 'Үүсгэж байна...' : 'Баг үүсгэх',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: yellow,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
        ),
      ),
    );
  }
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(8),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.055),
        blurRadius: 16,
        offset: const Offset(0, 8),
      ),
    ],
  );
}
