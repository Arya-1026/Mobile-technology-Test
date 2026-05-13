import 'package:flutter/material.dart';
import 'models.dart';
import 'competition_service.dart';

class CompetitionDetailScreen extends StatefulWidget {
  final CompetitionItem item;

  const CompetitionDetailScreen({super.key, required this.item});

  @override
  State<CompetitionDetailScreen> createState() =>
      _CompetitionDetailScreenState();
}

class _CompetitionDetailScreenState extends State<CompetitionDetailScreen> {
  bool isExpanded = false;
  bool isBookmarked = false;
  bool isRegistering = false;

  Future<void> register() async {
    try {
      setState(() => isRegistering = true);

      await CompetitionService.registerToCompetition(widget.item);

      if (!mounted) return;

      setState(() => isRegistering = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Бүртгэл амжилттай хадгалагдлаа'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => isRegistering = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Бүртгүүлэхэд алдаа гарлаа: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    const yellow = Color(0xFFF5C400);
    const orange = Color(0xFFFF6A00);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 300,
              pinned: true,
              backgroundColor: yellow,
              elevation: 0,
              leading: Padding(
                padding: const EdgeInsets.only(left: 10),
                child: CircleAvatar(
                  backgroundColor: Colors.white.withOpacity(0.9),
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      size: 18,
                      color: Colors.black,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
              actions: [
                CircleAvatar(
                  backgroundColor: Colors.white.withOpacity(0.9),
                  child: IconButton(
                    icon: Icon(
                      isBookmarked
                          ? Icons.bookmark
                          : Icons.bookmark_border_rounded,
                      color: isBookmarked ? orange : Colors.black,
                    ),
                    onPressed: () {
                      setState(() => isBookmarked = !isBookmarked);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                CircleAvatar(
                  backgroundColor: Colors.white.withOpacity(0.9),
                  child: IconButton(
                    icon: const Icon(Icons.share_outlined, color: Colors.black),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Түгээх хэсэг дараа нэмэгдэнэ'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    _image(item.imageUrl, double.infinity),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.05),
                            Colors.black.withOpacity(0.55),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 18,
                      right: 18,
                      bottom: 22,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.organizationName.isEmpty
                                ? 'Зохион байгуулагч'
                                : item.organizationName,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 27,
                              fontWeight: FontWeight.w900,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: item.tags.map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3D1),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: yellow.withOpacity(0.4)),
                          ),
                          child: Text(
                            tag,
                            style: const TextStyle(
                              color: Color(0xFF6B5600),
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 18),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: _cardDecoration(),
                      child: Column(
                        children: [
                          _infoRow(
                            icon: Icons.calendar_month_outlined,
                            title: 'Бүртгэлийн хугацаа',
                            value: item.date,
                          ),
                          const Divider(),
                          _infoRow(
                            icon: Icons.payments_outlined,
                            title: 'Хураамж',
                            value: item.fee.isEmpty ? 'Үнэгүй' : item.fee,
                          ),
                          const Divider(),
                          _infoRow(
                            icon: Icons.description_outlined,
                            title: 'Бүрдүүлэх материал',
                            value: item.materials.isEmpty
                                ? 'Тодорхойгүй'
                                : item.materials,
                          ),
                          const Divider(),
                          _infoRow(
                            icon: Icons.category_outlined,
                            title: 'Төрөл',
                            value: item.category,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),

                    Row(
                      children: [
                        const Text(
                          'Тайлбар',
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () {
                            setState(() => isExpanded = !isExpanded);
                          },
                          icon: Icon(
                            isExpanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: orange,
                          ),
                          label: Text(
                            isExpanded ? 'Хураах' : 'Дэлгэрэнгүй',
                            style: const TextStyle(
                              color: orange,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: _cardDecoration(),
                      child: Text(
                        item.fullDescription.isEmpty
                            ? 'Тайлбар оруулаагүй байна.'
                            : item.fullDescription,
                        maxLines: isExpanded ? null : 7,
                        overflow: isExpanded
                            ? TextOverflow.visible
                            : TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.55,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    const SizedBox(height: 22),

                    const Text(
                      'Poster',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),

                    const SizedBox(height: 12),

                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: item.posterUrl.isEmpty
                          ? Container(
                              height: 230,
                              width: double.infinity,
                              color: Colors.white,
                              child: const Center(
                                child: Icon(
                                  Icons.image_not_supported_outlined,
                                  size: 42,
                                  color: Colors.grey,
                                ),
                              ),
                            )
                          : Image.network(
                              item.posterUrl,
                              height: 230,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                height: 230,
                                width: double.infinity,
                                color: Colors.white,
                                child: const Center(
                                  child: Icon(
                                    Icons.image_not_supported_outlined,
                                    size: 42,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                    ),

                    const SizedBox(height: 22),

                    const Text(
                      'Холбоос',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: _cardDecoration(),
                      child: Row(
                        children: [
                          const Icon(Icons.link, color: orange),
                          const SizedBox(width: 10),
                          Expanded(
                            child: SelectableText(
                              item.linkText.isEmpty
                                  ? 'Холбоос оруулаагүй'
                                  : item.linkText,
                              style: const TextStyle(
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 18,
              offset: const Offset(0, -6),
            ),
          ],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(22),
            topRight: Radius.circular(22),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3D1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: IconButton(
                  onPressed: () {
                    setState(() => isBookmarked = !isBookmarked);
                  },
                  icon: Icon(
                    isBookmarked
                        ? Icons.bookmark
                        : Icons.bookmark_border_rounded,
                    color: orange,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: isRegistering ? null : register,
                    icon: isRegistering
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.app_registration_rounded),
                    label: Text(
                      isRegistering ? 'Бүртгэж байна...' : 'Бүртгүүлэх',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: orange,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _image(String url, double height) {
    if (url.isEmpty) {
      return Container(
        height: height,
        width: double.infinity,
        color: Colors.grey.shade300,
        child: const Icon(
          Icons.image_not_supported_outlined,
          size: 45,
          color: Colors.grey,
        ),
      );
    }

    return Image.network(
      url,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        height: height,
        width: double.infinity,
        color: Colors.grey.shade300,
        child: const Icon(
          Icons.image_not_supported_outlined,
          size: 45,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    const orange = Color(0xFFFF6A00);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3D1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: orange, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.055),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }
}
