import 'package:flutter/material.dart';
import 'team_competition_screen.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final categories = [
      CategoryItem('Багийн', const Color(0xFFB7D3B0), Icons.groups_outlined),
      CategoryItem('Ганцаараа', const Color(0xFF3FA0CF), Icons.person_outline),
      CategoryItem(
        'Үндэсний хэмжээний',
        const Color(0xFF0A29FF),
        Icons.map_outlined,
      ),
      CategoryItem(
        'Дэлхийн хэмжээний',
        const Color(0xFF6E8EF8),
        Icons.public_outlined,
      ),
      CategoryItem(
        'Sport/E-Sport',
        const Color(0xFF39FF14),
        Icons.sports_esports_outlined,
      ),
      CategoryItem('Урлаг', const Color(0xFF74BC3C), Icons.brush_outlined),
      CategoryItem(
        'Шинжлэх ухаан',
        const Color(0xFF78C98A),
        Icons.science_outlined,
      ),
      CategoryItem(
        'Нийгэм, эдийн засаг',
        const Color(0xFF20C8C9),
        Icons.account_balance_wallet_outlined,
      ),
      CategoryItem('IT, ICT', const Color(0xFF6B51B8), Icons.computer_outlined),
      CategoryItem(
        'Бизнес, Стартап',
        const Color(0xFFFF3B63),
        Icons.lightbulb_outline,
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Хайх',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: const TextField(
                  decoration: InputDecoration(
                    hintText: 'Хайх',
                    prefixIcon: Icon(Icons.search),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 13),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Ангиллууд',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: GridView.builder(
                  itemCount: categories.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 1.55,
                  ),
                  itemBuilder: (context, i) =>
                      CategoryCard(item: categories[i]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CategoryItem {
  final String title;
  final Color color;
  final IconData icon;
  CategoryItem(this.title, this.color, this.icon);
}

class CategoryCard extends StatelessWidget {
  final CategoryItem item;
  const CategoryCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TeamCompetitionScreen(category: item.title),
        ),
      ),
      child: Ink(
        decoration: BoxDecoration(
          color: item.color,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    item.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      height: 1.2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.topRight,
                child: Icon(item.icon, size: 36, color: Colors.black87),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
