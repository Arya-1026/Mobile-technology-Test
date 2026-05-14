import 'package:flutter/material.dart';
import 'models.dart';
import 'competition_service.dart';
import 'competition_detail_screen.dart';

class TeamCompetitionScreen extends StatelessWidget {
  final String category;
  const TeamCompetitionScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      body: SafeArea(
        child: Column(children: [
          _HeaderSection(title: category, onBack: () => Navigator.pop(context)),
          Expanded(
            child: StreamBuilder<List<CompetitionItem>>(
              stream: CompetitionService.approvedCompetitions(category: category),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final items = snapshot.data!;
                if (items.isEmpty) return const Center(child: Text('Зөвшөөрөгдсөн тэмцээн байхгүй байна'));
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
                  itemCount: items.length,
                  itemBuilder: (context, i) => CompetitionCard(item: items[i], index: i),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}

class _HeaderSection extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  const _HeaderSection({required this.title, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      width: double.infinity,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFF0C64A), Color(0xFFE4B939), Color(0xFF8C9BB0)]),
      ),
      child: Stack(children: [
        Positioned(top: 16, left: 10, child: IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black))),
        Align(alignment: Alignment.center, child: Text(title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.black))),
      ]),
    );
  }
}

class CompetitionCard extends StatelessWidget {
  final CompetitionItem item;
  final int index;
  const CompetitionCard({super.key, required this.item, required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 12, offset: const Offset(0, 6))]),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CompetitionDetailScreen(item: item))),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: item.displayImageUrl.isEmpty
                  ? Container(width: 92, height: 92, color: Colors.grey.shade200, child: const Icon(Icons.image_not_supported_outlined))
                  : Image.network(item.displayImageUrl, width: 92, height: 92, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(width: 92, height: 92, color: Colors.grey.shade200, child: const Icon(Icons.image_not_supported_outlined))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 92,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 3),
                  Expanded(child: Text(item.subtitle, maxLines: 3, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.8, height: 1.35, color: Colors.grey.shade700))),
                  Row(children: [
                    Icon(Icons.calendar_month_outlined, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Expanded(child: Text(item.date, style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w600))),
                    const Text('Дэлгэрэнгүй', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFFF6A00))),
                  ]),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
