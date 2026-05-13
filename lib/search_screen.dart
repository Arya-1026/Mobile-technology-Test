import 'package:flutter/material.dart';

import 'demo_competitions.dart';
import 'team_competition_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  static final List<CategoryItem> _categories = [
    CategoryItem(
      title: 'Football',
      subtitle: 'Талбайн спорт',
      accentColor: Color(0xFF47D18C),
      icon: Icons.sports_soccer_outlined,
      imageUrl: DemoCompetitions.imageFor('Football', 0),
    ),
    CategoryItem(
      title: 'Basketball',
      subtitle: 'Indoor match',
      accentColor: Color(0xFFFFB35C),
      icon: Icons.sports_basketball_outlined,
      imageUrl: DemoCompetitions.imageFor('Basketball', 0),
    ),
    CategoryItem(
      title: 'Volleyball',
      subtitle: 'Team play',
      accentColor: Color(0xFFFFD166),
      icon: Icons.sports_volleyball_outlined,
      imageUrl: DemoCompetitions.imageFor('Volleyball', 0),
    ),
    CategoryItem(
      title: 'Running',
      subtitle: 'Track & marathon',
      accentColor: Color(0xFF5FD4FF),
      icon: Icons.directions_run_rounded,
      imageUrl: DemoCompetitions.imageFor('Running', 0),
    ),
    CategoryItem(
      title: 'Tennis',
      subtitle: 'Court game',
      accentColor: Color(0xFFB9F85D),
      icon: Icons.sports_tennis_outlined,
      imageUrl: DemoCompetitions.imageFor('Tennis', 0),
    ),
    CategoryItem(
      title: 'Esports',
      subtitle: 'Gaming arena',
      accentColor: Color(0xFF9B8CFF),
      icon: Icons.sports_esports_outlined,
      imageUrl: DemoCompetitions.imageFor('Esports', 0),
    ),
    CategoryItem(
      title: 'Swimming',
      subtitle: 'Pool race',
      accentColor: Color(0xFF50E3C2),
      icon: Icons.pool_outlined,
      imageUrl: DemoCompetitions.imageFor('Swimming', 0),
    ),
    CategoryItem(
      title: 'Cycling',
      subtitle: 'Road race',
      accentColor: Color(0xFFFF7A7A),
      icon: Icons.directions_bike_rounded,
      imageUrl: DemoCompetitions.imageFor('Cycling', 0),
    ),
    CategoryItem(
      title: 'Table Tennis',
      subtitle: 'Fast indoor rallies',
      accentColor: Color(0xFFF5C400),
      icon: Icons.sports_tennis_outlined,
      imageUrl: DemoCompetitions.imageFor('Table Tennis', 0),
    ),
    CategoryItem(
      title: 'Chess',
      subtitle: 'Mind sport',
      accentColor: Color(0xFFF5C400),
      icon: Icons.extension_outlined,
      imageUrl: DemoCompetitions.imageFor('Chess', 0),
    ),
    CategoryItem(
      title: 'Badminton',
      subtitle: 'Shuttle court',
      accentColor: Color(0xFF47D18C),
      icon: Icons.sports_tennis_outlined,
      imageUrl: DemoCompetitions.imageFor('Badminton', 0),
    ),
    CategoryItem(
      title: 'Athletics',
      subtitle: 'Track & field',
      accentColor: Color(0xFF5FD4FF),
      icon: Icons.directions_run_rounded,
      imageUrl: DemoCompetitions.imageFor('Athletics', 0),
    ),
    CategoryItem(
      title: 'Martial Arts',
      subtitle: 'Combat discipline',
      accentColor: Color(0xFFFF6A00),
      icon: Icons.sports_martial_arts_outlined,
      imageUrl: DemoCompetitions.imageFor('Martial Arts', 0),
    ),
    CategoryItem(
      title: 'MMA',
      subtitle: 'Pro fight night',
      accentColor: Color(0xFFFF6A00),
      icon: Icons.sports_martial_arts_outlined,
      imageUrl: DemoCompetitions.imageFor('MMA', 0),
    ),
    CategoryItem(
      title: 'Wrestling',
      subtitle: 'Strength & technique',
      accentColor: Color(0xFFFFB35C),
      icon: Icons.sports_martial_arts_outlined,
      imageUrl: DemoCompetitions.imageFor('Wrestling', 0),
    ),
  ];

  List<CategoryItem> get _filteredCategories {
    final normalizedQuery = _query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) return _categories;
    return _categories
        .where(
          (item) =>
              item.title.toLowerCase().contains(normalizedQuery) ||
              item.subtitle.toLowerCase().contains(normalizedQuery),
        )
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = _filteredCategories;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Хайх',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 14),
              _SearchField(
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value),
                onClear: () {
                  _searchController.clear();
                  setState(() => _query = '');
                },
                hasText: _query.isNotEmpty,
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Спортын төрлүүд',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                  Text(
                    '${categories.length} төрөл',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Expanded(
                child: categories.isEmpty
                    ? const Center(
                        child: Text(
                          'Ангилал олдсонгүй',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final maxWidth = constraints.maxWidth;
                          final crossAxisCount = maxWidth >= 900
                              ? 4
                              : maxWidth >= 620
                                  ? 3
                                  : 2;

                          return GridView.builder(
                            padding: const EdgeInsets.only(bottom: 24),
                            itemCount: categories.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                              childAspectRatio: maxWidth >= 620 ? 1.18 : 1.02,
                            ),
                            itemBuilder: (context, i) =>
                                CategoryCard(item: categories[i]),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final bool hasText;

  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
    required this.hasText,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Спортын төрөл хайх',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: hasText
            ? IconButton(
                tooltip: 'Арилгах',
                onPressed: onClear,
                icon: const Icon(Icons.close_rounded),
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFF5C400), width: 1.6),
        ),
      ),
    );
  }
}

class CategoryItem {
  final String title;
  final String subtitle;
  final Color accentColor;
  final IconData icon;
  final String imageUrl;

  const CategoryItem({
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.icon,
    required this.imageUrl,
  });
}

class CategoryCard extends StatefulWidget {
  final CategoryItem item;

  const CategoryCard({super.key, required this.item});

  @override
  State<CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<CategoryCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.025 : 1,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: item.accentColor.withValues(
                  alpha: _isHovered ? 0.34 : 0.18,
                ),
                blurRadius: _isHovered ? 22 : 14,
                offset: Offset(0, _isHovered ? 12 : 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TeamCompetitionScreen(category: item.title),
                ),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  AnimatedScale(
                    scale: _isHovered ? 1.08 : 1.02,
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    child: Image.network(
                      item.imageUrl,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.medium,
                      frameBuilder:
                          (context, child, frame, wasSynchronouslyLoaded) {
                        if (wasSynchronouslyLoaded || frame != null) {
                          return child;
                        }
                        return Container(color: item.accentColor);
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: item.accentColor.withValues(alpha: 0.18),
                          alignment: Alignment.center,
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: item.accentColor,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (_, __, ___) => Container(
                        color: item.accentColor,
                        alignment: Alignment.center,
                        child: Icon(item.icon, size: 42, color: Colors.white),
                      ),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(
                            alpha: _isHovered ? 0.16 : 0.24,
                          ),
                          Colors.black.withValues(alpha: 0.28),
                          Colors.black.withValues(
                            alpha: _isHovered ? 0.78 : 0.70,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(item.icon, color: item.accentColor, size: 24),
                    ),
                  ),
                  Positioned(
                    top: 14,
                    right: 12,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(
                          alpha: _isHovered ? 0.96 : 0.22,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        color: _isHovered
                            ? const Color(0xFF1F2933)
                            : Colors.white,
                        size: 19,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 13,
                    right: 13,
                    bottom: 13,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.82),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0,
                          ),
                        ),
                        const SizedBox(height: 10),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: _isHovered ? 54 : 36,
                          height: 3,
                          decoration: BoxDecoration(
                            color: item.accentColor,
                            borderRadius: BorderRadius.circular(8),
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
      ),
    );
  }
}
