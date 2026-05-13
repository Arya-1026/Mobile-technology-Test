import 'dart:io';

import 'package:flutter/material.dart';
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

  final ImagePicker picker = ImagePicker();

  File? selectedImageFile;
  File? selectedPosterFile;

  bool uploadingImage = false;
  bool uploadingPoster = false;
  bool isSaving = false;

  String category = 'Багийн';
  String scope = 'Үндэсний хэмжээний';
  String participationType = 'Багийн';
  String organizerType = 'Хувь хүн';

  DateTime? startDate;
  DateTime? endDate;

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

      category = item.category;
      scope = item.scope.isEmpty ? scope : item.scope;
      participationType = item.participationType.isEmpty
          ? participationType
          : item.participationType;
      organizerType = item.organizerType;

      startDate = item.registrationStart;
      endDate = item.registrationEnd;
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
    super.dispose();
  }

  Future<void> pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
      initialDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          startDate = picked;
        } else {
          endDate = picked;
        }
      });
    }
  }

  Future<void> pickAndUploadImage({required bool isPoster}) async {
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (pickedFile == null) return;

    final file = File(pickedFile.path);

    setState(() {
      if (isPoster) {
        selectedPosterFile = file;
        posterUrl.text = pickedFile.path;
      } else {
        selectedImageFile = file;
        imageUrl.text = pickedFile.path;
      }
    });

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception('Нэвтрээгүй байна');
      }

      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${pickedFile.name}';

      final ref = FirebaseStorage.instance
          .ref()
          .child('competition_images')
          .child(user.uid)
          .child(fileName);

      await ref.putFile(file);

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
          content: Text('Зураг upload хийхэд алдаа гарлаа: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> save() async {
    if (!_formKey.currentState!.validate()) return;

    if (startDate == null || endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Бүртгэлийн эхлэх/дуусах огноо сонгоно уу'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (selectedImageFile == null && imageUrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Үндсэн зураг сонгоно уу')));
      return;
    }

    if (selectedPosterFile == null && posterUrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Poster зураг сонгоно уу')));
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    setState(() => isSaving = true);

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
    );

    if (widget.editItem == null) {
      await CompetitionService.addCompetition(item);
    } else {
      await CompetitionService.updateCompetition(
        widget.editItem!.id,
        item.toMap(),
      );
    }

    if (!mounted) return;

    setState(() => isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.isAdmin
              ? 'Тэмцээн нийтлэгдлээ'
              : 'Тэмцээн админ руу илгээгдлээ',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );

    Navigator.pop(context);
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
              _sectionCard(
                title: 'Үндсэн мэдээлэл',
                icon: Icons.info_outline,
                children: [
                  field(title, 'Тэмцээний нэр', Icons.emoji_events_outlined),
                  field(subtitle, 'Богино тайлбар', Icons.short_text),
                  field(
                    description,
                    'Дэлгэрэнгүй тайлбар',
                    Icons.description_outlined,
                    maxLines: 5,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              _sectionCard(
                title: 'Төрөл ба зохион байгуулагч',
                icon: Icons.category_outlined,
                children: [
                  dropdown(
                    'Тэмцээний төрөл',
                    category,
                    categories,
                    (v) => setState(() => category = v!),
                  ),
                  dropdown(
                    'Оролцох хэлбэр',
                    participationType,
                    ['Багийн', 'Ганцаараа'],
                    (v) => setState(() => participationType = v!),
                  ),
                  dropdown('Хамрах хүрээ', scope, [
                    'Үндэсний хэмжээний',
                    'Дэлхийн хэмжээний',
                  ], (v) => setState(() => scope = v!)),
                  dropdown(
                    'Зохион байгуулагч',
                    organizerType,
                    ['Хувь хүн', 'Байгууллага'],
                    (v) => setState(() => organizerType = v!),
                  ),
                  if (organizerType == 'Байгууллага')
                    field(
                      organization,
                      'Байгууллагын нэр / холбоо барих',
                      Icons.business_outlined,
                    ),
                ],
              ),

              const SizedBox(height: 16),

              _sectionCard(
                title: 'Зураг оруулах',
                icon: Icons.image_outlined,
                children: [
                  imagePickerBox(
                    title: 'Үндсэн зураг сонгох',
                    subtitle: 'Дээр дараад Photos/Gallery-оос зураг сонгоно',
                    imageFile: selectedImageFile,
                    imageUrlValue: imageUrl.text,
                    isLoading: uploadingImage,
                    onTap: () => pickAndUploadImage(isPoster: false),
                  ),
                  const SizedBox(height: 14),
                  imagePickerBox(
                    title: 'Poster зураг сонгох',
                    subtitle: 'Poster эсвэл banner зураг сонгоно',
                    imageFile: selectedPosterFile,
                    imageUrlValue: posterUrl.text,
                    isLoading: uploadingPoster,
                    onTap: () => pickAndUploadImage(isPoster: true),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              _sectionCard(
                title: 'Нэмэлт мэдээлэл',
                icon: Icons.assignment_outlined,
                children: [
                  field(fee, 'Хураамж', Icons.payments_outlined),
                  field(
                    materials,
                    'Бүрдүүлэх материал',
                    Icons.fact_check_outlined,
                    maxLines: 3,
                  ),
                  field(link, 'Холбоос', Icons.link),
                  Row(
                    children: [
                      Expanded(
                        child: dateButton(
                          label: startDate == null
                              ? 'Эхлэх огноо'
                              : '${startDate!.year}.${startDate!.month}.${startDate!.day}',
                          onTap: () => pickDate(true),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: dateButton(
                          label: endDate == null
                              ? 'Дуусах огноо'
                              : '${endDate!.year}.${endDate!.month}.${endDate!.day}',
                          onTap: () => pickDate(false),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: isSaving || uploadingImage || uploadingPoster
                      ? null
                      : save,
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
            ],
          ),
        ),
      ),
    );
  }

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
                  fontSize: 17,
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

  Widget field(
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
        decoration: decoration(label, icon),
      ),
    );
  }

  Widget dropdown(
    String label,
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: decoration(label, Icons.arrow_drop_down_circle_outlined),
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget dateButton({required String label, required VoidCallback onTap}) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.calendar_month_outlined),
      label: Text(label, overflow: TextOverflow.ellipsis),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.black87,
        side: BorderSide(color: Colors.grey.shade300),
        backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Widget imagePickerBox({
    required String title,
    required String subtitle,
    required File? imageFile,
    required String imageUrlValue,
    required bool isLoading,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        height: 190,
        decoration: BoxDecoration(
          color: const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : imageFile != null
            ? _localImage(imageFile)
            : imageUrlValue.isNotEmpty
            ? _networkImage(imageUrlValue)
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3D1),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 36,
                      color: Color(0xFFFF6A00),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _localImage(File file) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Image.file(file, fit: BoxFit.cover),
        ),
        _changeImageOverlay(),
      ],
    );
  }

  Widget _networkImage(String url) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                const Center(child: Icon(Icons.image_not_supported_outlined)),
          ),
        ),
        _changeImageOverlay(),
      ],
    );
  }

  Widget _changeImageOverlay() {
    return Positioned(
      right: 12,
      bottom: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.65),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.edit, color: Colors.white, size: 15),
            SizedBox(width: 5),
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

  InputDecoration decoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFFF5C400)),
      filled: true,
      fillColor: const Color(0xFFF8F8F8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFF5C400), width: 1.5),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
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
