import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'models.dart';
import 'competition_service.dart';

class CompetitionFormScreen extends StatefulWidget {
  final CompetitionItem? editItem;
  final bool isAdmin;

  const CompetitionFormScreen({super.key, this.editItem, this.isAdmin = false});

  @override
  State<CompetitionFormScreen> createState() => _CompetitionFormScreenState();
}

class _CompetitionFormScreenState extends State<CompetitionFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final title = TextEditingController();
  final subtitle = TextEditingController();
  final description = TextEditingController();
  final fee = TextEditingController();
  final materials = TextEditingController();
  final organization = TextEditingController();
  final imageUrl = TextEditingController();
  final posterUrl = TextEditingController();
  final link = TextEditingController();
  // New fields
  final location = TextEditingController();
  final prizes = TextEditingController();
  final rules = TextEditingController();
  final contactInfo = TextEditingController();
  final maxParticipants = TextEditingController();

  final ImagePicker picker = ImagePicker();

  Uint8List? selectedImageBytes;
  Uint8List? selectedPosterBytes;

  bool uploadingImage = false;
  bool uploadingPoster = false;
  bool isSaving = false;

  String category = 'Sport/E-Sport';
  String scope = 'Үндэсний хэмжээний';
  String participationType = 'Ганцаараа';
  String organizerType = 'Хувь хүн';
  String ageCategory = 'Бүх насны';
  String genderCategory = 'Бүх хүйс';

  DateTime? startDate;
  DateTime? endDate;
  DateTime? deadlineDate;

  final categories = [
    'Багийн',
    'Ганцаараа',
    'Үндэсний хэмжээний',
    'Дэлхийн хэмжээний',
    'Sport/E-Sport',
    'Урлаг',
    'Шинжлэх ухаан',
    'Нийгэм, эдийн засаг',
    'IT, ICT',
    'Бизнес, Стартап',
  ];

  final ageCategories = [
    'Бүх насны',
    '16-аас доош',
    '16-18',
    '18+',
    '21+',
    'Хүүхэд (7-12)',
    'Залуучууд (13-17)',
  ];

  final genderCategories = ['Бүх хүйс', 'Эрэгтэй', 'Эмэгтэй'];

  @override
  void initState() {
    super.initState();
    final item = widget.editItem;
    if (item != null) {
      title.text = item.title;
      subtitle.text = item.subtitle;
      description.text = item.fullDescription;
      fee.text = item.fee;
      materials.text = item.materials;
      organization.text = item.organizationName;
      imageUrl.text = item.imageUrl;
      posterUrl.text = item.posterUrl;
      link.text = item.linkText;
      location.text = item.location;
      prizes.text = item.prizes;
      rules.text = item.rules;
      contactInfo.text = item.contactInfo;
      maxParticipants.text =
          item.maxParticipants > 0 ? item.maxParticipants.toString() : '';

      category = item.category;
      scope = item.scope.isEmpty ? scope : item.scope;
      participationType = item.participationType.isEmpty
          ? participationType
          : item.participationType;
      organizerType = item.organizerType;
      ageCategory = item.ageCategory;
      genderCategory = item.genderCategory;

      startDate = item.registrationStart;
      endDate = item.registrationEnd;
      deadlineDate = item.registrationDeadline;
    }
  }

  @override
  void dispose() {
    title.dispose();
    subtitle.dispose();
    description.dispose();
    fee.dispose();
    materials.dispose();
    organization.dispose();
    imageUrl.dispose();
    posterUrl.dispose();
    link.dispose();
    location.dispose();
    prizes.dispose();
    rules.dispose();
    contactInfo.dispose();
    maxParticipants.dispose();
    super.dispose();
  }

  Future<void> _pickDate(String type) async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
      initialDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFFF5C400),
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );

    if (picked == null) return;
    setState(() {
      if (type == 'start') startDate = picked;
      if (type == 'end') endDate = picked;
      if (type == 'deadline') deadlineDate = picked;
    });
  }

  Future<void> _pickAndUploadImage({required bool isPoster}) async {
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (pickedFile == null) return;

    final imageBytes = await pickedFile.readAsBytes();

    setState(() {
      if (isPoster) {
        selectedPosterBytes = imageBytes;
        uploadingPoster = true;
      } else {
        selectedImageBytes = imageBytes;
        uploadingImage = true;
      }
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Нэвтрээгүй байна');

      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${pickedFile.name}';

      final ref = FirebaseStorage.instance
          .ref()
          .child('competition_images')
          .child(user.uid)
          .child(fileName);

      await ref.putData(
        imageBytes,
        SettableMetadata(contentType: pickedFile.mimeType ?? 'image/jpeg'),
      );
      final downloadUrl = await ref.getDownloadURL();

      setState(() {
        if (isPoster) {
          posterUrl.text = downloadUrl;
          uploadingPoster = false;
        } else {
          imageUrl.text = downloadUrl;
          uploadingImage = false;
        }
      });
    } catch (e) {
      setState(() {
        uploadingImage = false;
        uploadingPoster = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Зураг upload хийхэд алдаа: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (startDate == null || endDate == null) {
      _showSnack('Бүртгэлийн эхлэх/дуусах огноо сонгоно уу');
      return;
    }

    if (selectedImageBytes == null && imageUrl.text.trim().isEmpty) {
      _showSnack('Үндсэн зураг сонгоно уу');
      return;
    }

    if (selectedPosterBytes == null && posterUrl.text.trim().isEmpty) {
      _showSnack('Poster зураг сонгоно уу');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => isSaving = true);

    final parsedMax = int.tryParse(maxParticipants.text.trim()) ?? 0;

    final item = CompetitionItem(
      id: widget.editItem?.id ?? '',
      title: title.text.trim(),
      subtitle: subtitle.text.trim(),
      fullDescription: description.text.trim(),
      category: category,
      tags: [participationType, category, scope],
      scope: scope,
      participationType: participationType,
      organizerType: organizerType,
      organizationName: organizerType == 'Байгууллага'
          ? organization.text.trim()
          : user.displayName ?? 'Хувь хүн',
      fee: fee.text.trim(),
      materials: materials.text.trim(),
      imageUrl: imageUrl.text.trim(),
      posterUrl: posterUrl.text.trim(),
      linkText: link.text.trim(),
      ownerId: widget.editItem?.ownerId ?? user.uid,
      ownerEmail: widget.editItem?.ownerEmail ?? user.email ?? '',
      status: widget.isAdmin
          ? 'approved'
          : (widget.editItem?.status ?? 'pending'),
      registrationStart: startDate,
      registrationEnd: endDate,
      registrationDeadline: deadlineDate,
      location: location.text.trim(),
      ageCategory: ageCategory,
      maxParticipants: parsedMax,
      genderCategory: genderCategory,
      prizes: prizes.text.trim(),
      rules: rules.text.trim(),
      contactInfo: contactInfo.text.trim(),
    );

    if (widget.editItem == null) {
      await CompetitionService.addCompetition(item);
    } else {
      await CompetitionService.updateCompetition(
          widget.editItem!.id, item.toMap());
    }

    if (!mounted) return;

    setState(() => isSaving = false);

    _showSnack(
      widget.isAdmin ? 'Тэмцээн нийтлэгдлээ' : 'Тэмцээн хянуулахаар илгээгдлээ',
    );

    Navigator.pop(context);
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    const yellow = Color(0xFFF5C400);
    const orange = Color(0xFFFF6A00);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: yellow,
        foregroundColor: Colors.black,
        title: Text(
          widget.editItem == null ? 'Тэмцээн нэмэх' : 'Тэмцээн засах',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // 1. Basic info
              _sectionCard(
                title: 'Үндсэн мэдээлэл',
                icon: Icons.info_outline,
                children: [
                  _field(title, 'Тэмцээний нэр', Icons.emoji_events_outlined),
                  _field(subtitle, 'Богино тайлбар', Icons.short_text),
                  _field(
                    description,
                    'Дэлгэрэнгүй тайлбар',
                    Icons.description_outlined,
                    maxLines: 5,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 2. Type
              _sectionCard(
                title: 'Төрөл ба зохион байгуулагч',
                icon: Icons.category_outlined,
                children: [
                  _dropdown('Тэмцээний ангилал', category, categories,
                      (v) => setState(() => category = v!)),
                  _dropdown(
                    'Оролцох хэлбэр',
                    participationType,
                    ['Багийн', 'Ганцаараа'],
                    (v) => setState(() => participationType = v!),
                  ),
                  _dropdown('Хамрах хүрээ', scope, [
                    'Үндэсний хэмжээний',
                    'Дэлхийн хэмжээний',
                  ], (v) => setState(() => scope = v!)),
                  _dropdown(
                    'Зохион байгуулагч',
                    organizerType,
                    ['Хувь хүн', 'Байгууллага'],
                    (v) => setState(() => organizerType = v!),
                  ),
                  if (organizerType == 'Байгууллага')
                    _field(organization, 'Байгууллагын нэр',
                        Icons.business_outlined),
                ],
              ),

              const SizedBox(height: 16),

              // 3. Participants
              _sectionCard(
                title: 'Оролцогчдын мэдээлэл',
                icon: Icons.people_outline,
                children: [
                  _dropdown(
                    'Насны ангилал',
                    ageCategory,
                    ageCategories,
                    (v) => setState(() => ageCategory = v!),
                  ),
                  _dropdown(
                    'Хүйсийн ангилал',
                    genderCategory,
                    genderCategories,
                    (v) => setState(() => genderCategory = v!),
                  ),
                  _optionalField(
                    maxParticipants,
                    'Оролцогчдын дээд хязгаар',
                    Icons.person_add_outlined,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 4. Location & dates
              _sectionCard(
                title: 'Байршил ба огноо',
                icon: Icons.location_on_outlined,
                children: [
                  _optionalField(
                    location,
                    'Байршил / Газрын нэр',
                    Icons.place_outlined,
                  ),
                  const SizedBox(height: 4),
                  _dateRow(),
                  const SizedBox(height: 10),
                  _dateButton(
                    label: deadlineDate == null
                        ? 'Бүртгэл хаагдах хугацаа'
                        : 'Дуусах: ${_fmt(deadlineDate!)}',
                    icon: Icons.event_busy_outlined,
                    onTap: () => _pickDate('deadline'),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 5. Images
              _sectionCard(
                title: 'Зураг оруулах',
                icon: Icons.image_outlined,
                children: [
                  _imagePickerBox(
                    title: 'Үндсэн зураг',
                    subtitle: 'Gallery-оос зураг сонгоно',
                    imageBytes: selectedImageBytes,
                    imageUrlValue: imageUrl.text,
                    isLoading: uploadingImage,
                    onTap: () => _pickAndUploadImage(isPoster: false),
                  ),
                  const SizedBox(height: 12),
                  _imagePickerBox(
                    title: 'Poster / Banner',
                    subtitle: 'Тэмцээний постер зураг',
                    imageBytes: selectedPosterBytes,
                    imageUrlValue: posterUrl.text,
                    isLoading: uploadingPoster,
                    onTap: () => _pickAndUploadImage(isPoster: true),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 6. Additional info
              _sectionCard(
                title: 'Нэмэлт мэдээлэл',
                icon: Icons.assignment_outlined,
                children: [
                  _optionalField(fee, 'Хураамж', Icons.payments_outlined),
                  _optionalField(
                    materials,
                    'Бүрдүүлэх материал',
                    Icons.fact_check_outlined,
                    maxLines: 3,
                  ),
                  _optionalField(
                    prizes,
                    'Шагналын мэдээлэл',
                    Icons.workspace_premium_outlined,
                    maxLines: 3,
                  ),
                  _optionalField(
                    rules,
                    'Дүрэм журам',
                    Icons.gavel_outlined,
                    maxLines: 4,
                  ),
                  _optionalField(
                    contactInfo,
                    'Холбоо барих мэдээлэл',
                    Icons.contact_phone_outlined,
                    maxLines: 2,
                  ),
                  _optionalField(link, 'Холбоос', Icons.link),
                ],
              ),

              const SizedBox(height: 24),

              // Save button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed:
                      isSaving || uploadingImage || uploadingPoster ? null : _save,
                  icon: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.save_alt_rounded),
                  label: Text(
                    isSaving ? 'Хадгалж байна...' : 'Хадгалах',
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

              if (!widget.isAdmin) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: yellow.withValues(alpha: 0.4)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 16, color: Color(0xFFF5C400)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Тэмцээн илгээгдсэний дараа админ хянан зөвшөөрсний дараа л нийтлэгдэнэ.',
                          style: TextStyle(fontSize: 12, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _dateRow() {
    return Row(
      children: [
        Expanded(
          child: _dateButton(
            label: startDate == null ? 'Эхлэх огноо' : _fmt(startDate!),
            icon: Icons.calendar_today_outlined,
            onTap: () => _pickDate('start'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _dateButton(
            label: endDate == null ? 'Дуусах огноо' : _fmt(endDate!),
            icon: Icons.calendar_month_outlined,
            onTap: () => _pickDate('end'),
          ),
        ),
      ],
    );
  }

  String _fmt(DateTime d) =>
      '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    const yellow = Color(0xFFF5C400);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFFFFF3D1),
                child: Icon(icon, color: yellow, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
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
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        validator: (v) =>
            v == null || v.trim().isEmpty ? '$label оруулна уу' : null,
        decoration: _decoration(label, icon),
      ),
    );
  }

  Widget _optionalField(
    TextEditingController controller,
    String label,
    IconData icon, {
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        decoration: _decoration(label, icon),
      ),
    );
  }

  Widget _dropdown(
    String label,
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration:
            _decoration(label, Icons.arrow_drop_down_circle_outlined),
        isExpanded: true,
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _dateButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.black87,
        side: BorderSide(color: Colors.grey.shade300),
        backgroundColor: const Color(0xFFF8F8F8),
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 12),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
        alignment: Alignment.centerLeft,
      ),
    );
  }

  Widget _imagePickerBox({
    required String title,
    required String subtitle,
    required Uint8List? imageBytes,
    required String imageUrlValue,
    required bool isLoading,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        height: 170,
        decoration: BoxDecoration(
          color: const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : imageBytes != null
                ? _localImage(imageBytes)
                : imageUrlValue.isNotEmpty
                    ? _networkImage(imageUrlValue)
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF3D1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.add_photo_alternate_outlined,
                              size: 32,
                              color: Color(0xFFFF6A00),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            subtitle,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600),
                          ),
                        ],
                      ),
      ),
    );
  }

  Widget _localImage(Uint8List imageBytes) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.memory(imageBytes, fit: BoxFit.cover),
        ),
        _editOverlay(),
      ],
    );
  }

  Widget _networkImage(String url) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                const Center(child: Icon(Icons.broken_image_outlined)),
          ),
        ),
        _editOverlay(),
      ],
    );
  }

  Widget _editOverlay() {
    return Positioned(
      right: 10,
      bottom: 10,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.edit, color: Colors.white, size: 14),
            SizedBox(width: 4),
            Text(
              'Солих',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _decoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFFF5C400)),
      filled: true,
      fillColor: const Color(0xFFF8F8F8),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide:
            const BorderSide(color: Color(0xFFF5C400), width: 1.5),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
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
