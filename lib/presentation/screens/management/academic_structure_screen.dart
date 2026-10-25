import 'package:flutter/material.dart';
import 'package:edstream_mobile/core/network/api_client.dart';
import 'package:edstream_mobile/core/storage/local_cache_store.dart';
import 'package:edstream_mobile/core/theme/app_colors.dart';
import 'package:edstream_mobile/core/theme/app_typography.dart';
import 'package:edstream_mobile/core/widgets/sync_status_banner.dart';
import 'package:edstream_mobile/presentation/widgets/custom_text_field.dart';
import 'package:edstream_mobile/presentation/widgets/primary_button.dart';

class AcademicStructureScreen extends StatefulWidget {
  const AcademicStructureScreen({super.key});

  @override
  State<AcademicStructureScreen> createState() => _AcademicStructureScreenState();
}

class _AcademicStructureScreenState extends State<AcademicStructureScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  List<Map<String, dynamic>> _classes = [];
  List<Map<String, dynamic>> _sections = [];
  List<Map<String, dynamic>> _subjects = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAcademicData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAcademicData() async {
    const classKey = 'management_classes_cache';
    const sectionKey = 'management_sections_cache';
    const subjectKey = 'management_subjects_cache';

    final cachedClasses = LocalCacheStore.instance.getJson(classKey);
    final cachedSections = LocalCacheStore.instance.getJson(sectionKey);
    final cachedSubjects = LocalCacheStore.instance.getJson(subjectKey);

    if (cachedClasses is List) setState(() => _classes = List<Map<String, dynamic>>.from(cachedClasses));
    if (cachedSections is List) setState(() => _sections = List<Map<String, dynamic>>.from(cachedSections));
    if (cachedSubjects is List) setState(() => _subjects = List<Map<String, dynamic>>.from(cachedSubjects));

    try {
      final cRes = await ApiClient.instance.get('class', cacheLocally: true, cacheKey: classKey);
      final sRes = await ApiClient.instance.get('section', cacheLocally: true, cacheKey: sectionKey);
      final subRes = await ApiClient.instance.get('subject', cacheLocally: true, cacheKey: subjectKey);

      // Unpack classes
      if (cRes is Map && cRes['data'] is List) {
        final List<Map<String, dynamic>> flattenedClasses = [];
        for (var sectionItem in cRes['data']) {
          if (sectionItem is Map && sectionItem['classes'] is List) {
            for (var c in sectionItem['classes']) {
              if (c is Map) flattenedClasses.add(Map<String, dynamic>.from(c));
            }
          } else if (sectionItem is Map) {
            flattenedClasses.add(Map<String, dynamic>.from(sectionItem));
          }
        }
        setState(() => _classes = flattenedClasses);
        LocalCacheStore.instance.setJson(classKey, flattenedClasses);
      }

      // Unpack sections
      final rawSections = sRes is List ? sRes : (sRes is Map ? (sRes['sections'] ?? sRes['data']) : null);
      if (rawSections is List) {
        final parsedSec = List<Map<String, dynamic>>.from(rawSections.whereType<Map>());
        setState(() => _sections = parsedSec);
        LocalCacheStore.instance.setJson(sectionKey, parsedSec);
      }

      // Unpack subjects
      final rawSubjects = subRes is List ? subRes : (subRes is Map ? (subRes['subjects'] ?? subRes['data']) : null);
      if (rawSubjects is List) {
        final parsedSub = List<Map<String, dynamic>>.from(rawSubjects.whereType<Map>());
        setState(() => _subjects = parsedSub);
        LocalCacheStore.instance.setJson(subjectKey, parsedSub);
      }
    } catch (_) {
      if (_classes.isEmpty) _loadMockData();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _loadMockData() {
    // No made-up records: an empty list shows the screen's empty state.
    _classes = [];
    _sections = [];
    _subjects = [];
  }

  void _showAddClassModal() {
    final codeController = TextEditingController();
    final armController = TextEditingController();
    String? selectedSectionId = _sections.isNotEmpty ? _sections.first['_id']?.toString() : null;
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Create New Class Arm', style: AppTypography.titleLarge),
              const SizedBox(height: 16),
              CustomTextField(labelText: 'Class Code', hintText: 'e.g. JSS 1, Basic 5', controller: codeController),
              const SizedBox(height: 12),
              CustomTextField(labelText: 'Subclass / Arm', hintText: 'e.g. A, Gold, Science', controller: armController),
              const SizedBox(height: 12),
              Text('Academic Section', style: AppTypography.labelMedium),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButton<String>(
                  isExpanded: true,
                  underline: const SizedBox(),
                  value: selectedSectionId,
                  items: _sections.map((sec) {
                    return DropdownMenuItem<String>(
                      value: sec['_id']?.toString(),
                      child: Text(sec['name'] ?? 'Section'),
                    );
                  }).toList(),
                  onChanged: (val) => setModalState(() => selectedSectionId = val),
                ),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                text: 'Save Class Arm',
                isLoading: isSaving,
                onPressed: () async {
                  if (codeController.text.trim().isEmpty || selectedSectionId == null) {
                    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Enter the class code and choose a section.')));
                    return;
                  }
                  setModalState(() => isSaving = true);
                  try {
                    await ApiClient.instance.send('POST', 'class', feature: 'academics', label: 'New class ${codeController.text.trim()}', body: {
                      'code': codeController.text.trim(),
                      'subclass': armController.text.trim(),
                      'sectionId': selectedSectionId,
                    });
                    if (ctx.mounted) Navigator.pop(ctx);
                    _loadAcademicData();
                  } catch (e) {
                    setModalState(() => isSaving = false);
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddSectionModal() {
    final nameController = TextEditingController();
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Create Section', style: AppTypography.titleLarge),
              const SizedBox(height: 16),
              CustomTextField(labelText: 'Section Name', hintText: 'e.g. Nursery, Junior Secondary', controller: nameController),
              const SizedBox(height: 24),
              PrimaryButton(
                text: 'Create Section',
                isLoading: isSaving,
                onPressed: () async {
                  if (nameController.text.trim().isEmpty) return;
                  setModalState(() => isSaving = true);
                  try {
                    await ApiClient.instance.send('POST', 'section/create', feature: 'academics', label: 'academics update', body: {
                      'name': nameController.text.trim(),
                    });
                    if (ctx.mounted) Navigator.pop(ctx);
                    _loadAcademicData();
                  } catch (e) {
                    setModalState(() => isSaving = false);
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddSubjectModal() {
    final nameController = TextEditingController();
    final codeController = TextEditingController();
    bool optional = false;
    bool isSaving = false;
    String? subjectSection = _sections.isNotEmpty ? _sections.first['name']?.toString() : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Add New Subject', style: AppTypography.titleLarge),
              const SizedBox(height: 16),
              CustomTextField(labelText: 'Subject Name', hintText: 'e.g. Mathematics', controller: nameController),
              const SizedBox(height: 12),
              CustomTextField(labelText: 'Subject Code', hintText: 'e.g. MTH', controller: codeController),
              const SizedBox(height: 12),
              Text('Section', style: AppTypography.labelMedium),
              const SizedBox(height: 6),
              DropdownButton<String>(
                isExpanded: true,
                value: subjectSection,
                hint: const Text('Choose section'),
                items: _sections
                    .map((sec) => DropdownMenuItem<String>(value: sec['name']?.toString(), child: Text(sec['name']?.toString() ?? 'Section')))
                    .toList(),
                onChanged: (val) => setModalState(() => subjectSection = val),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Elective / Optional Subject', style: AppTypography.bodyMedium),
                  Switch(
                    value: optional,
                    activeThumbColor: AppColors.primary,
                    onChanged: (val) => setModalState(() => optional = val),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                text: 'Save Subject',
                isLoading: isSaving,
                onPressed: () async {
                  if (nameController.text.trim().isEmpty || subjectSection == null) {
                    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Enter the subject name and choose a section.')));
                    return;
                  }
                  setModalState(() => isSaving = true);
                  try {
                    await ApiClient.instance.send('POST', 'subject', feature: 'academics', label: 'New subject ${nameController.text.trim()}', body: {
                      'section': subjectSection,
                      'subjectName': nameController.text.trim(),
                      'subjectCode': codeController.text.trim(),
                      'optional': optional,
                    });
                    if (ctx.mounted) Navigator.pop(ctx);
                    _loadAcademicData();
                  } catch (e) {
                    setModalState(() => isSaving = false);
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Academic Structure',
          style: AppTypography.titleLarge.copyWith(color: AppColors.light, fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.light),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.color2Light,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700),
          tabs: const [
            Tab(text: 'Classes & Arms'),
            Tab(text: 'Sections'),
            Tab(text: 'Subjects'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () {
          if (_tabController.index == 0) _showAddClassModal();
          if (_tabController.index == 1) _showAddSectionModal();
          if (_tabController.index == 2) _showAddSubjectModal();
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SyncStatusBanner(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildClassesTab(),
                        _buildSectionsTab(),
                        _buildSubjectsTab(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassesTab() {
    return RefreshIndicator(
      onRefresh: _loadAcademicData,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _classes.length,
        itemBuilder: (context, index) {
          final c = _classes[index];
          final code = c['code'] ?? 'Class';
          final sub = c['subclass'] ?? '';
          final sec = c['section'] is Map ? (c['section']['name'] ?? '') : '';

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppColors.shadowSm,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.meeting_room_outlined, color: AppColors.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$code $sub'.trim(), style: AppTypography.titleMedium),
                      if (sec.isNotEmpty)
                        Text(sec.toString(), style: AppTypography.bodySmall),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Active Arm',
                    style: TextStyle(color: Colors.green.shade800, fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionsTab() {
    return RefreshIndicator(
      onRefresh: _loadAcademicData,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _sections.length,
        itemBuilder: (context, index) {
          final s = _sections[index];
          final name = s['name'] ?? 'Section';

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppColors.shadowSm,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.domain_outlined, color: Colors.purple.shade700),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(name.toString(), style: AppTypography.titleMedium),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSubjectsTab() {
    return RefreshIndicator(
      onRefresh: _loadAcademicData,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _subjects.length,
        itemBuilder: (context, index) {
          final sub = _subjects[index];
          final name = sub['subjectName'] ?? 'Subject';
          final code = sub['subjectCode'] ?? '';
          final isOptional = sub['optional'] == true;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppColors.shadowSm,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.menu_book_outlined, color: AppColors.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name.toString(), style: AppTypography.titleMedium),
                      if (code.isNotEmpty) Text('Code: $code', style: AppTypography.bodySmall),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isOptional ? Colors.orange.shade50 : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isOptional ? 'Elective' : 'Core',
                    style: TextStyle(
                      color: isOptional ? Colors.orange.shade800 : Colors.blue.shade800,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
