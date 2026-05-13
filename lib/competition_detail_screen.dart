import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  bool isSending = false;
  String? myRequestStatus; // null | 'pending' | 'accepted' | 'rejected'
  bool loadingStatus = true;

  @override
  void initState() {
    super.initState();
    _loadMyStatus();
  }

  Future<void> _loadMyStatus() async {
    final status =
        await CompetitionService.getMyRequestStatus(widget.item.id);
    if (mounted) {
      setState(() {
        myRequestStatus = status;
        loadingStatus = false;
      });
    }
  }

  Future<void> _sendRequest() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnack('Эхлээд нэвтрэнэ үү');
      return;
    }

    setState(() => isSending = true);
    try {
      await CompetitionService.sendParticipationRequest(widget.item);
      if (!mounted) return;
      setState(() {
        myRequestStatus = 'pending';
        isSending = false;
      });
      _showSnack('Оролцох хүсэлт амжилттай илгээгдлээ!');
    } catch (e) {
      if (!mounted) return;
      setState(() => isSending = false);
      _showSnack('Алдаа гарлаа: $e');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
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
            // ── Expandable image header ───────────────────────────────────
            SliverAppBar(
              expandedHeight: 300,
              pinned: true,
              backgroundColor: yellow,
              elevation: 0,
              leading: Padding(
                padding: const EdgeInsets.only(left: 10),
                child: CircleAvatar(
                  backgroundColor:
                      Colors.white.withValues(alpha: 0.9),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new,
                        size: 18, color: Colors.black),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
              actions: [
                CircleAvatar(
                  backgroundColor:
                      Colors.white.withValues(alpha: 0.9),
                  child: IconButton(
                    icon: Icon(
                      isBookmarked
                          ? Icons.bookmark
                          : Icons.bookmark_border_rounded,
                      color: isBookmarked ? orange : Colors.black,
                    ),
                    onPressed: () =>
                        setState(() => isBookmarked = !isBookmarked),
                  ),
                ),
                const SizedBox(width: 10),
                CircleAvatar(
                  backgroundColor:
                      Colors.white.withValues(alpha: 0.9),
                  child: IconButton(
                    icon: const Icon(Icons.share_outlined,
                        color: Colors.black),
                    onPressed: () => _showSnack('Түгээх хэсэг удахгүй нэмэгдэнэ'),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    _networkImage(item.imageUrl, double.infinity),
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0x0D000000),
                            Color(0x8C000000),
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
                              fontSize: 26,
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

            // ── Content ───────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tags
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: item.tags.map((tag) => _tag(tag)).toList(),
                    ),

                    const SizedBox(height: 18),

                    // Info card
                    _infoCard(item, orange),

                    const SizedBox(height: 18),

                    // Description
                    _descriptionSection(orange),

                    const SizedBox(height: 18),

                    // Prizes (if available)
                    if (item.prizes.isNotEmpty) ...[
                      _sectionTitle('Шагнал'),
                      const SizedBox(height: 10),
                      _textCard(item.prizes, Icons.workspace_premium_outlined, orange),
                      const SizedBox(height: 18),
                    ],

                    // Rules (if available)
                    if (item.rules.isNotEmpty) ...[
                      _sectionTitle('Дүрэм журам'),
                      const SizedBox(height: 10),
                      _textCard(item.rules, Icons.gavel_outlined, orange),
                      const SizedBox(height: 18),
                    ],

                    // Contact info
                    if (item.contactInfo.isNotEmpty) ...[
                      _sectionTitle('Холбоо барих'),
                      const SizedBox(height: 10),
                      _textCard(
                          item.contactInfo, Icons.contact_phone_outlined, orange),
                      const SizedBox(height: 18),
                    ],

                    // Poster
                    _sectionTitle('Poster'),
                    const SizedBox(height: 12),
                    _posterWidget(item.posterUrl),

                    // Link
                    if (item.linkText.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      _sectionTitle('Холбоос'),
                      const SizedBox(height: 10),
                      _linkCard(item.linkText, orange),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // ── Bottom action bar ─────────────────────────────────────────────
      bottomNavigationBar: _bottomBar(orange),
    );
  }

  Widget _infoCard(CompetitionItem item, Color orange) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          _infoRow(
            icon: Icons.calendar_month_outlined,
            title: 'Бүртгэлийн хугацаа',
            value: item.date,
            orange: orange,
          ),
          if (item.registrationDeadline != null) ...[
            const Divider(),
            _infoRow(
              icon: Icons.event_busy_outlined,
              title: 'Бүртгэл хаагдах',
              value:
                  '${item.registrationDeadline!.year}.${item.registrationDeadline!.month.toString().padLeft(2, '0')}.${item.registrationDeadline!.day.toString().padLeft(2, '0')}',
              orange: orange,
            ),
          ],
          const Divider(),
          _infoRow(
            icon: Icons.category_outlined,
            title: 'Ангилал',
            value: item.category,
            orange: orange,
          ),
          const Divider(),
          _infoRow(
            icon: Icons.people_outline,
            title: 'Оролцох хэлбэр',
            value: item.participationType.isEmpty ? 'Тодорхойгүй' : item.participationType,
            orange: orange,
          ),
          if (item.location.isNotEmpty) ...[
            const Divider(),
            _infoRow(
              icon: Icons.place_outlined,
              title: 'Байршил',
              value: item.location,
              orange: orange,
            ),
          ],
          if (item.ageCategory.isNotEmpty) ...[
            const Divider(),
            _infoRow(
              icon: Icons.person_outline,
              title: 'Насны ангилал',
              value: item.ageCategory,
              orange: orange,
            ),
          ],
          if (item.genderCategory.isNotEmpty) ...[
            const Divider(),
            _infoRow(
              icon: Icons.wc_outlined,
              title: 'Хүйсийн ангилал',
              value: item.genderCategory,
              orange: orange,
            ),
          ],
          if (item.maxParticipants > 0) ...[
            const Divider(),
            _infoRow(
              icon: Icons.group_outlined,
              title: 'Дээд хязгаар',
              value: '${item.maxParticipants} оролцогч',
              orange: orange,
            ),
          ],
          const Divider(),
          _infoRow(
            icon: Icons.payments_outlined,
            title: 'Хураамж',
            value: item.fee.isEmpty ? 'Үнэгүй' : item.fee,
            orange: orange,
          ),
          if (item.materials.isNotEmpty) ...[
            const Divider(),
            _infoRow(
              icon: Icons.fact_check_outlined,
              title: 'Бүрдүүлэх материал',
              value: item.materials,
              orange: orange,
            ),
          ],
        ],
      ),
    );
  }

  Widget _descriptionSection(Color orange) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _sectionTitle('Тайлбар'),
            const Spacer(),
            TextButton.icon(
              onPressed: () =>
                  setState(() => isExpanded = !isExpanded),
              icon: Icon(
                isExpanded
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                color: orange,
              ),
              label: Text(
                isExpanded ? 'Хураах' : 'Дэлгэрэнгүй',
                style: TextStyle(
                    color: orange, fontWeight: FontWeight.w800),
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
            widget.item.fullDescription.isEmpty
                ? 'Тайлбар оруулаагүй байна.'
                : widget.item.fullDescription,
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
      ],
    );
  }

  Widget _bottomBar(Color orange) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
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
                onPressed: () =>
                    setState(() => isBookmarked = !isBookmarked),
                icon: Icon(
                  isBookmarked
                      ? Icons.bookmark
                      : Icons.bookmark_border_rounded,
                  color: orange,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: _requestButton(orange)),
          ],
        ),
      ),
    );
  }

  Widget _requestButton(Color orange) {
    if (loadingStatus) {
      return Container(
        height: 52,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (myRequestStatus == 'pending') {
      return Container(
        height: 52,
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: Colors.orange.withValues(alpha: 0.4)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hourglass_top_rounded,
                color: Colors.orange, size: 20),
            SizedBox(width: 8),
            Text(
              'Хүлээгдэж байна...',
              style: TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
          ],
        ),
      );
    }

    if (myRequestStatus == 'accepted') {
      return Container(
        height: 52,
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: Colors.green.withValues(alpha: 0.4)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline,
                color: Colors.green, size: 20),
            SizedBox(width: 8),
            Text(
              'Бүртгэгдсэн',
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
          ],
        ),
      );
    }

    if (myRequestStatus == 'rejected') {
      return SizedBox(
        height: 52,
        child: ElevatedButton.icon(
          onPressed: isSending ? null : _sendRequest,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text(
            'Дахин хүсэлт илгээх',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
          ),
        ),
      );
    }

    // No request yet
    return SizedBox(
      height: 52,
      child: ElevatedButton.icon(
        onPressed: isSending ? null : _sendRequest,
        icon: isSending
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.send_rounded),
        label: Text(
          isSending ? 'Илгээж байна...' : 'Оролцох хүсэлт илгээх',
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
              borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
    );
  }

  Widget _tag(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3D1),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
            color: const Color(0xFFF5C400).withValues(alpha: 0.4)),
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
  }

  Widget _infoRow({
    required IconData icon,
    required String title,
    required String value,
    required Color orange,
  }) {
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
            child: Icon(icon, color: orange, size: 20),
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
                const SizedBox(height: 2),
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

  Widget _textCard(String text, IconData icon, Color orange) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: orange, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _linkCard(String url, Color orange) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Icon(Icons.link, color: orange),
          const SizedBox(width: 10),
          Expanded(
            child: SelectableText(
              url,
              style: const TextStyle(
                color: Colors.blue,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _posterWidget(String url) {
    if (url.isEmpty) {
      return Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: Icon(Icons.image_not_supported_outlined,
              size: 42, color: Colors.grey),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Image.network(
        url,
        height: 230,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          height: 200,
          color: Colors.white,
          child: const Center(
              child: Icon(Icons.broken_image_outlined,
                  size: 42, color: Colors.grey)),
        ),
      ),
    );
  }

  Widget _networkImage(String url, double height) {
    if (url.isEmpty) {
      return Container(
        height: height,
        color: Colors.grey.shade300,
        child: const Icon(Icons.image_not_supported_outlined,
            size: 45, color: Colors.grey),
      );
    }
    return Image.network(
      url,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        height: height,
        color: Colors.grey.shade300,
        child: const Icon(Icons.broken_image_outlined,
            size: 45, color: Colors.grey),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.055),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }
}
