import 'package:flutter/material.dart';
import 'package:edstream_mobile/core/network/api_client.dart';
import 'package:edstream_mobile/core/storage/local_cache_store.dart';
import 'package:edstream_mobile/core/theme/app_colors.dart';
import 'package:edstream_mobile/core/theme/app_typography.dart';
import 'package:edstream_mobile/core/widgets/sync_status_banner.dart';
import 'package:edstream_mobile/presentation/screens/teacher/student_details_screen.dart';
import 'package:edstream_mobile/presentation/widgets/custom_text_field.dart';
import 'package:edstream_mobile/presentation/widgets/credentials_dialog.dart';
import 'package:edstream_mobile/presentation/widgets/primary_button.dart';

class StudentsManagementScreen extends StatefulWidget {
  const StudentsManagementScreen({super.key});

  @override
  State<StudentsManagementScreen> createState() => _StudentsManagementScreenState();
}

class _StudentsManagementScreenState extends State<StudentsManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  String _selectedStatusFilter = 'All'; // All, active, inactive

  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _filteredStudents = [];
  String? _selectedClassFilter;

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchStudents() async {
    const cacheKey = 'management_all_students_cache';
    final cached = LocalCacheStore.instance.getJson(cacheKey);
    if (cached is List && cached.isNotEmpty) {
      final list = List<Map<String, dynamic>>.from(cached);
      setState(() {
        _students = list;
        _filteredStudents = list;
        _isLoading = false;
      });
    }

    try {
      final res = await ApiClient.instance.get(
        'student',
        queryParams: {'limit': 100},
        cacheLocally: true,
        cacheKey: cacheKey,
      );

      final raw = res is Map
          ? (res['students'] ?? res['data'])
          : (res is List ? res : null);

      if (raw is List && raw.isNotEmpty) {
        final parsed = raw.map<Map<String, dynamic>>((s) {
          if (s is Map) {
            final fName = s['firstName'] ?? '';
            final mName = s['middleName'] ?? '';
            final lName = s['lastName'] ?? '';
            final cls = s['class'] is Map
                ? '${s['class']['code'] ?? ''} ${s['class']['subclass'] ?? ''}'.trim()
                : (s['studentClass']?.toString() ?? 'Class N/A');

            return {
              '_id': s['_id']?.toString() ?? '',
              'name': '$fName $mName $lName'.replaceAll(RegExp(r'\s+'), ' ').trim(),
              'firstName': fName,
              'middleName': mName,
              'lastName': lName,
              'registrationNumber': s['registrationNumber']?.toString() ?? 'EDS-N/A',
              'gender': s['gender']?.toString() ?? 'Other',
              'status': s['status']?.toString() ?? 'active',
              'class': cls.isNotEmpty ? cls : 'General Class',
              'classId': s['class'] is Map ? s['class']['_id']?.toString() : null,
              'enrollments': s['enrollments'] as List? ?? [],
              'hasDoubleEnrollment': (s['enrollments'] as List? ?? []).length > 1,
            };
          }
          return {};
        }).where((e) => e.isNotEmpty).toList();

        if (mounted) {
          setState(() {
            _students = parsed;
            _applyFilters();
            _isLoading = false;
          });
        }
        LocalCacheStore.instance.setJson(cacheKey, parsed);
        return;
      } else if (_students.isEmpty) {
        _loadDefaultMockStudents();
      }
    } catch (_) {
      if (_students.isEmpty) {
        _loadDefaultMockStudents();
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _loadDefaultMockStudents() {
    // No made-up records: an empty list shows the screen's empty state.
    _students = [];
    _applyFilters();
  }

  void _applyFilters() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredStudents = _students.where((s) {
        final matchesQuery = query.isEmpty ||
            (s['name']?.toString().toLowerCase().contains(query) ?? false) ||
            (s['registrationNumber']?.toString().toLowerCase().contains(query) ?? false);

        final matchesStatus = _selectedStatusFilter == 'All' ||
            s['status']?.toString().toLowerCase() == _selectedStatusFilter.toLowerCase();

        final matchesClass = _selectedClassFilter == null ||
            (s['class']?.toString().toLowerCase() == _selectedClassFilter!.toLowerCase());

        return matchesQuery && matchesStatus && matchesClass;
      }).toList();
    });
  }

  Future<void> _toggleStudentStatus(Map<String, dynamic> student) async {
    final currentStatus = student['status'] ?? 'active';
    final newStatus = currentStatus == 'active' ? 'inactive' : 'active';
    final id = student['_id'];

    try {
      final result = await ApiClient.instance.send('PATCH', 'student/deactivate/$id?status=$newStatus',
          feature: 'students', label: 'Set ${student['name']} $newStatus');
      if (mounted) {
        if (ApiClient.isQueued(result)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Saved on this phone; it will be sent when you are back online.')),
          );
        }
        setState(() {
          student['status'] = newStatus;
          _applyFilters();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${student['name']} is now $newStatus.'),
            backgroundColor: newStatus == 'active' ? AppColors.success : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: $e')),
        );
      }
    }
  }

  // Classes (with their section) for the enrol form; cached for offline use.
  Future<List<Map<String, dynamic>>> _loadClassOptions() async {
    try {
      final res = await ApiClient.instance.get('class', queryParams: {'limit': 200});
      final groups = res is Map ? res['data'] : null;
      final out = <Map<String, dynamic>>[];
      if (groups is List) {
        for (final g in groups) {
          for (final c in (g is Map ? g['classes'] as List? ?? [] : [])) {
            if (c is Map) {
              final section = c['section'];
              out.add({
                'id': c['_id']?.toString(),
                'label': '${c['code'] ?? ''} ${c['subclass'] ?? ''}'.trim(),
                'sectionId': section is Map ? section['_id']?.toString() : section?.toString(),
              });
            }
          }
        }
      }
      return out;
    } catch (_) {
      return [];
    }
  }

  void _showAddStudentModal() async {
    final classOptions = await _loadClassOptions();
    if (!mounted) return;
    final fNameController = TextEditingController();
    final mNameController = TextEditingController();
    final lNameController = TextEditingController();
    final regController = TextEditingController();
    final emailController = TextEditingController();
    final addressController = TextEditingController();
    final cityController = TextEditingController();
    final stateController = TextEditingController();
    final nokNameController = TextEditingController();
    final nokPhoneController = TextEditingController();
    final nokEmailController = TextEditingController();
    final nokRelationController = TextEditingController(text: 'Parent');

    String gender = 'male';
    String? classId;
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
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
                Text('Enroll New Student', style: AppTypography.titleLarge),
                const SizedBox(height: 4),
                Text('Fields marked * are required.', style: AppTypography.bodySmall),
                const SizedBox(height: 18),
                CustomTextField(labelText: 'First Name *', hintText: 'First name', controller: fNameController),
                const SizedBox(height: 12),
                CustomTextField(labelText: 'Middle Name', hintText: 'Optional', controller: mNameController),
                const SizedBox(height: 12),
                CustomTextField(labelText: 'Surname *', hintText: 'Surname', controller: lNameController),
                const SizedBox(height: 12),
                CustomTextField(labelText: 'Registration Number *', hintText: 'e.g. STU/2026/001', controller: regController),
                const SizedBox(height: 12),
                Text('Class *', style: AppTypography.labelMedium),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: classId,
                  isExpanded: true,
                  hint: Text(classOptions.isEmpty ? 'No classes available (connect to load them)' : 'Select class'),
                  items: classOptions
                      .map((c) => DropdownMenuItem<String>(value: c['id'] as String?, child: Text(c['label'] as String)))
                      .toList(),
                  onChanged: (v) => setModalState(() => classId = v),
                ),
                const SizedBox(height: 12),
                Text('Gender *', style: AppTypography.labelMedium),
                const SizedBox(height: 6),
                Row(
                  children: [
                    ChoiceChip(
                      label: const Text('Male'),
                      selected: gender == 'male',
                      onSelected: (_) => setModalState(() => gender = 'male'),
                    ),
                    const SizedBox(width: 12),
                    ChoiceChip(
                      label: const Text('Female'),
                      selected: gender == 'female',
                      onSelected: (_) => setModalState(() => gender = 'female'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                CustomTextField(labelText: 'Student Email', hintText: 'Needed when the student portal is on', controller: emailController, keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 12),
                CustomTextField(labelText: 'Address *', hintText: 'Home address', controller: addressController),
                const SizedBox(height: 12),
                CustomTextField(labelText: 'City *', hintText: 'City', controller: cityController),
                const SizedBox(height: 12),
                CustomTextField(labelText: 'State *', hintText: 'State', controller: stateController),
                const SizedBox(height: 18),
                Text('Parent / Guardian', style: AppTypography.titleMedium),
                const SizedBox(height: 10),
                CustomTextField(labelText: 'Full Name *', hintText: 'Guardian name', controller: nokNameController),
                const SizedBox(height: 12),
                CustomTextField(labelText: 'Relationship *', hintText: 'e.g. Father, Mother', controller: nokRelationController),
                const SizedBox(height: 12),
                CustomTextField(labelText: 'Phone Number', hintText: 'e.g. 08012345678', controller: nokPhoneController, keyboardType: TextInputType.phone),
                const SizedBox(height: 12),
                CustomTextField(labelText: 'Email', hintText: 'Needed when the student portal is on', controller: nokEmailController, keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 24),
                PrimaryButton(
                  text: 'Enroll Student',
                  isLoading: isSaving,
                  onPressed: () async {
                    final required = [fNameController, lNameController, regController, addressController, cityController, stateController, nokNameController, nokRelationController];
                    if (required.any((c) => c.text.trim().isEmpty) || classId == null) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('Please fill every field marked * and choose a class.')),
                      );
                      return;
                    }
                    final chosen = classOptions.firstWhere((c) => c['id'] == classId);
                    setModalState(() => isSaving = true);
                    String? optional(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();
                    final payload = <String, dynamic>{
                      'firstName': fNameController.text.trim(),
                      'middleName': mNameController.text.trim(),
                      'lastName': lNameController.text.trim(),
                      'registrationNumber': regController.text.trim(),
                      'gender': gender,
                      'class': classId,
                      'section': chosen['sectionId'],
                      'address': addressController.text.trim(),
                      'city': cityController.text.trim(),
                      'state': stateController.text.trim(),
                      'email': optional(emailController),
                      'nextOfKinFullname': nokNameController.text.trim(),
                      'nextOfKinRelationship': nokRelationController.text.trim(),
                      'nextOfKinPhoneNumber': nokPhoneController.text.trim(),
                      'nextOfKinEmail': optional(nokEmailController),
                    }..removeWhere((_, v) => v == null);

                    try {
                      final result = await ApiClient.instance.send('POST', 'student/create',
                          body: payload, feature: 'students', label: 'Enrol ${payload['firstName']} ${payload['lastName']}');
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (!ApiClient.isQueued(result)) _fetchStudents();
                      if (mounted) {
                        await showCreateResult(context, result,
                            name: '${payload['firstName']} ${payload['lastName']}',
                            login: payload['registrationNumber'] as String,
                            successText: 'Student registered successfully!');
                      }
                    } catch (e) {
                      setModalState(() => isSaving = false);
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Could not enrol: $e')));
                      }
                    }
                  },
                ),
              ],
            ),
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
          'Student Directory',
          style: AppTypography.titleLarge.copyWith(color: AppColors.light, fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.light),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: _showAddStudentModal,
        icon: const Icon(Icons.person_add_alt_1, color: Colors.white),
        label: const Text('Add Student', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SyncStatusBanner(),

            // Search Bar & Filter chips
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: (_) => _applyFilters(),
                    decoration: InputDecoration(
                      hintText: 'Search by student name or reg no...',
                      prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 20),
                              onPressed: () {
                                _searchController.clear();
                                _applyFilters();
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildStatusFilterChip('All'),
                      const SizedBox(width: 8),
                      _buildStatusFilterChip('Active'),
                      const SizedBox(width: 8),
                      _buildStatusFilterChip('Inactive'),
                      const Spacer(),
                      Text(
                        '${_filteredStudents.length} Students',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.color2Light,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Student List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : RefreshIndicator(
                      onRefresh: _fetchStudents,
                      color: AppColors.primary,
                      child: _filteredStudents.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.people_outline, size: 54, color: Colors.grey),
                                  const SizedBox(height: 12),
                                  Text('No Students Found', style: AppTypography.titleMedium),
                                  const SizedBox(height: 4),
                                  Text('Try clearing filters or search term.', style: AppTypography.bodySmall),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              itemCount: _filteredStudents.length,
                              itemBuilder: (context, index) {
                                final s = _filteredStudents[index];
                                final name = s['name'] ?? 'Student';
                                final reg = s['registrationNumber'] ?? 'EDS-N/A';
                                final cls = s['class'] ?? 'Class';
                                final status = s['status'] ?? 'active';
                                final isActive = status == 'active';
                                final hasDouble = s['hasDoubleEnrollment'] == true;

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(18),
                                    boxShadow: AppColors.shadowSm,
                                  ),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(18),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => StudentDetailsScreen(
                                            studentId: s['_id'],
                                            initialStudentData: s,
                                          ),
                                        ),
                                      );
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(14),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 24,
                                            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                            child: Text(
                                              name.isNotEmpty ? name[0].toUpperCase() : 'S',
                                              style: AppTypography.titleMedium.copyWith(
                                                color: AppColors.primary,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Flexible(
                                                      child: Text(
                                                        name,
                                                        style: AppTypography.titleSmall,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                    if (hasDouble) ...[
                                                      const SizedBox(width: 6),
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                        decoration: BoxDecoration(
                                                          color: Colors.purple.shade50,
                                                          borderRadius: BorderRadius.circular(6),
                                                          border: Border.all(color: Colors.purple.shade200),
                                                        ),
                                                        child: Text(
                                                          '2x Branch',
                                                          style: TextStyle(
                                                            fontSize: 10,
                                                            fontWeight: FontWeight.w700,
                                                            color: Colors.purple.shade800,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                                const SizedBox(height: 2),
                                                Text('$reg • $cls', style: AppTypography.bodySmall),
                                              ],
                                            ),
                                          ),
                                          PopupMenuButton<String>(
                                            icon: const Icon(Icons.more_vert, color: Colors.grey),
                                            onSelected: (action) {
                                              if (action == 'details') {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) => StudentDetailsScreen(
                                                      studentId: s['_id'],
                                                      initialStudentData: s,
                                                    ),
                                                  ),
                                                );
                                              } else if (action == 'toggle') {
                                                _toggleStudentStatus(s);
                                              }
                                            },
                                            itemBuilder: (context) => [
                                              const PopupMenuItem(
                                                value: 'details',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.visibility_outlined, size: 18),
                                                    SizedBox(width: 8),
                                                    Text('View Dossier'),
                                                  ],
                                                ),
                                              ),
                                              PopupMenuItem(
                                                value: 'toggle',
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      isActive ? Icons.block : Icons.check_circle_outline,
                                                      size: 18,
                                                      color: isActive ? Colors.red : Colors.green,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(isActive ? 'Deactivate' : 'Activate'),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusFilterChip(String label) {
    final isSelected = _selectedStatusFilter.toLowerCase() == label.toLowerCase();
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() => _selectedStatusFilter = label);
        _applyFilters();
      },
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.color2Light,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
        fontSize: 12,
      ),
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      side: BorderSide.none,
      showCheckmark: false,
    );
  }
}
