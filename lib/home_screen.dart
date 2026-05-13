import 'package:flutter/material.dart';

import 'competition_service.dart';
import 'competition_detail_screen.dart';
import 'models.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const yellow = Color(0xFFF5C400);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
              decoration: const BoxDecoration(
                color: yellow,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(26),
                  bottomRight: Radius.circular(26),
                ),
              ),
              child: Row(
                children: [
                  const Text(
                    'Ял эсвэл Ял',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.grid_view_rounded,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.notifications_none,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  _tabs(),
                  const SizedBox(height: 16),

                  Container(
                    height: 135,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF8A00), Color(0xFFFF4FB8)],
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        'COMPETITION\n+ Шинэ тэмцээнүүд',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  const Text(
                    'Энэ сарын онцлох 🌟',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Sport, IT, Startup, Урлаг',
                    style: TextStyle(color: Colors.grey),
                  ),

                  const SizedBox(height: 16),

                  StreamBuilder<List<CompetitionItem>>(
                    stream: CompetitionService.approvedCompetitions(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final items = snapshot.data!;

                      if (items.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(20),
                          child: Text('Одоогоор зөвшөөрөгдсөн тэмцээн байхгүй'),
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: 245,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: items.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 14),
                              itemBuilder: (context, index) {
                                final item = items[index];

                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            CompetitionDetailScreen(item: item),
                                      ),
                                    );
                                  },
                                  child: SizedBox(
                                    width: 155,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          child: item.imageUrl.isEmpty
                                              ? Container(
                                                  height: 155,
                                                  width: 155,
                                                  color: Colors.grey.shade300,
                                                  child: const Icon(
                                                    Icons.image,
                                                  ),
                                                )
                                              : Image.network(
                                                  item.imageUrl,
                                                  height: 155,
                                                  width: 155,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) {
                                                    return Container(
                                                      height: 155,
                                                      width: 155,
                                                      color:
                                                          Colors.grey.shade300,
                                                      child: const Icon(
                                                        Icons.image,
                                                      ),
                                                    );
                                                  },
                                                ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          item.organizationName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                          ),
                                        ),
                                        Text(
                                          item.title,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                          Row(
                            children: [
                              const Text(
                                'Монголын тэмцээнүүд 🇲🇳',
                                style: TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const Spacer(),
                              TextButton(
                                onPressed: () {},
                                child: const Text(
                                  'Бүгд >',
                                  style: TextStyle(color: yellow),
                                ),
                              ),
                            ],
                          ),

                          ...items.map((item) {
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: item.imageUrl.isEmpty
                                      ? Container(
                                          width: 58,
                                          height: 58,
                                          color: Colors.grey.shade300,
                                          child: const Icon(Icons.image),
                                        )
                                      : Image.network(
                                          item.imageUrl,
                                          width: 58,
                                          height: 58,
                                          fit: BoxFit.cover,
                                        ),
                                ),
                                title: Text(
                                  item.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(item.date),
                                trailing: const Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          CompetitionDetailScreen(item: item),
                                    ),
                                  );
                                },
                              ),
                            );
                          }),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabs() {
    final tabs = ['Танд зориулсан', 'Багийн', 'IT', 'Startup'];

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 20),
        itemBuilder: (context, index) {
          return Text(
            tabs[index],
            style: TextStyle(
              color: index == 0 ? const Color(0xFFF5C400) : Colors.black87,
              fontWeight: FontWeight.w800,
            ),
          );
        },
      ),
    );
  }
}
