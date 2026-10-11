import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:edstream_mobile/core/network/api_client.dart';
import 'package:edstream_mobile/core/storage/local_cache_store.dart';
import 'package:edstream_mobile/core/theme/app_colors.dart';
import 'package:edstream_mobile/core/theme/app_typography.dart';
import 'package:edstream_mobile/core/widgets/sync_status_banner.dart';
import 'package:edstream_mobile/presentation/widgets/custom_text_field.dart';
import 'package:edstream_mobile/presentation/widgets/primary_button.dart';

class StaffDirectoryScreen extends StatefulWidget {
  const StaffDirectoryScreen({super.key});

  @override
  State<StaffDirectoryScreen> createState() => _StaffDirectoryScreenState();
}

class _StaffDirectoryScreenState extends State<StaffDirectoryScreen> {
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedRoleFilter = 'All';
  List<Map<String, dynamic>> _staffList = [];

  final List<String> _roleFilters = [
    'All',
    'Teacher',
    'Principal',
    'Director',
    'Exam Officer',
    'Finance Officer',
  ];

  @override
  void initState() {
    super.initState();
    _fetchStaffMembers();
  }

  Future<void> _fetchStaffMembers() async {
    const cacheKey = 'management_staff_directory_cache';
    final cached = LocalCacheStore.instance.getJson(cacheKey);
    if (cached is List && cached.isNotEmpty) {
      setState(() {
        _staffList = List<Map<String, dynamic>>.from(cached);
        _isLoading = false;
      });
    }

    try {
      final res = await ApiClient.instance.get(
        'staff',
        cacheLocally: true,
        cacheKey: cacheKey,
      );

      final rawList = res is List
          ? res
          : (res is Map ? (res['staffMembers'] ?? res['data'] ?? res['staff']) : null);

      if (rawList is List && rawList.isNotEmpty) {
        final mapped = rawList.map<Map<String, dynamic>>((s) {
          if (s is Map) {
            return {
              'staffId': s['staffId']?.toString() ?? 'STF-000',
              'firstName': s['firstName']?.toString() ?? '',
              'surname': s['surname']?.toString() ?? '',
              'otherName': s['otherName']?.toString() ?? '',
              'email': s['email']?.toString() ?? '',
              'phoneNumber': s['phoneNumber']?.toString() ?? '',
              'gender': s['gender']?.toString() ?? 'Other',
              'staffType': s['staffType']?.toString() ?? 'Staff',
              'status': s['status']?.toString() ?? 'active',
              'department': s['department']?.toString() ?? 'Academic',
            };
          }
          return {};
        }).where((s) => s.isNotEmpty).toList();

        if (mounted) {
          setState(() {
            _staffList = mapped;
            _isLoading = false;
          });
        }
        LocalCacheStore.instance.setJson(cacheKey, mapped);
      } else if (_staffList.isEmpty) {
        _loadDefaultMockStaff();
      }
    } catch (_) {
      if (_staffList.isEmpty) {
        _loadDefaultMockStaff();
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _loadDefaultMockStaff() {
    _staffList = [
      {
        'staffId': 'STF-001',
        'firstName': 'Dr. Idi',
        'surname': 'Sule',
        'otherName': '',
        'email': 'sulefango1@gmail.com',
        'phoneNumber': '+234 803 123 4567',
        'gender': 'Male',
        'staffType': 'Teacher',
        'status': 'active',
        'department': 'Mathematics & Sciences',
      },
      {
        'staffId': 'STF-002',
        'firstName': 'Maryam',
        'surname': 'Bello',
        'otherName': 'Amina',
        'email': 'm.bello@edstream.edu',
        'phoneNumber': '+234 802 987 6543',
        'gender': 'Female',
        'staffType': 'Principal',
        'status': 'active',
        'department': 'Administration',
      },
      {
        'staffId': 'STF-003',
        'firstName': 'Alhaji Ibrahim',
        'surname': 'Danjuma',
        'otherName': '',
        'email': 'i.danjuma@edstream.edu',
        'phoneNumber': '+234 809 111 2233',
        'gender': 'Male',
        'staffType': 'Director',
        'status': 'active',
        'department': 'Board of Trustees',
      },
      {
        'staffId': 'STF-004',
        'firstName': 'Chidi',
        'surname': 'Okonkwo',
        'otherName': 'Peter',
        'email': 'c.okonkwo@edstream.edu',
        'phoneNumber': '+234 814 555 6677',
        'gender': 'Male',
        'staffType': 'Exam Officer',
        'status': 'active',
        'department': 'Academic Examinations',
      },
      {
        'staffId': 'STF-005',
        'firstName': 'Fatima',
        'surname': 'Garba',
        'otherName': '',
        'email': 'f.garba@edstream.edu',
        'phoneNumber': '+234 805 444 3322',
        'gender': 'Female',
        'staffType': 'Finance Officer',
        'status': 'active',
        'department': 'Bursary & Accounts',
      },
      {
        'staffId': 'STF-006',
        'firstName': 'Grace',
        'surname': 'Adeyemi',
        'otherName': 'Funke',
        'email': 'g.adeyemi@edstream.edu',
        'phoneNumber': '+234 803 777 8899',
        'gender': 'Female',
        'staffType': 'Teacher',
        'status': 'active',
        'department': 'English & Literature',
      },
      {
        'staffId': 'STF-007',
        'firstName': 'Kabir',
        'surname': 'Mustapha',
        'otherName': '',
        'email': 'k.mustapha@edstream.edu',
        'phoneNumber': '+234 816 222 3344',
        'gender': 'Male',
        'staffType': 'Teacher',
        'status': 'inactive',
        'department': 'Social Sciences',
      },
    ];
  }

  List<Map<String, dynamic>> get _filteredStaff {
    return _staffList.where((s) {
      final role = (s['staffType'] ?? '').toString().toLowerCase();
      final filter = _selectedRoleFilter.toLowerCase();
      final matchesRole = _selectedRoleFilter == 'All' || role == filter;

      final name = '${s['firstName'] ?? ''} ${s['surname'] ?? ''}'.toLowerCase();
      final id = (s['staffId'] ?? '').toString().toLowerCase();
      final email = (s['email'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();

      final matchesQuery = _searchQuery.isEmpty ||
          name.contains(query) ||
          id.contains(query) ||
          email.contains(query);

      return matchesRole && matchesQuery;
    }).toList();
  }

  void _showAddStaffModal() {
    final fNameController = TextEditingController();
    final surnameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();

    String staffType = 'teacher';
    String gender = 'Male';
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
                Text('Add Staff Member', style: AppTypography.titleLarge),
                const SizedBox(height: 4),
                Text('Enroll a new academic teacher or administrative faculty member.', style: AppTypography.bodySmall),
                const SizedBox(height: 16),

                CustomTextField(labelText: 'First Name', hintText: 'e.g. Ahmad', controller: fNameController),
                const SizedBox(height: 12),
                CustomTextField(labelText: 'Surname', hintText: 'e.g. Garo', controller: surnameController),
                const SizedBox(height: 12),
                CustomTextField(labelText: 'Work Email Address', hintText: 'e.g. staff@edstream.org', controller: emailController),
                const SizedBox(height: 12),
                CustomTextField(labelText: 'Phone Number', hintText: 'e.g. 08012345678', controller: phoneController),
                const SizedBox(height: 14),

                Text('Institutional Role', style: AppTypography.labelMedium),
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
                    value: staffType,
                    items: const [
                      DropdownMenuItem(value: 'teacher', child: Text('Teacher / Form Master')),
                      DropdownMenuItem(value: 'principal', child: Text('Principal')),
                      DropdownMenuItem(value: 'director', child: Text('School Director')),
                      DropdownMenuItem(value: 'exam-officer', child: Text('Examination Officer')),
                      DropdownMenuItem(value: 'finance-officer', child: Text('Finance / Bursar')),
                      DropdownMenuItem(value: 'non-academic', child: Text('Administrative Support')),
                    ],
                    onChanged: (val) {
                      if (val != null) setModalState(() => staffType = val);
                    },
                  ),
                ),
                const SizedBox(height: 14),

                Text('Gender', style: AppTypography.labelMedium),
                const SizedBox(height: 6),
                Row(
                  children: [
                    ChoiceChip(
                      label: const Text('Male'),
                      selected: gender == 'Male',
                      onSelected: (val) => setModalState(() => gender = 'Male'),
                    ),
                    const SizedBox(width: 12),
                    ChoiceChip(
                      label: const Text('Female'),
                      selected: gender == 'Female',
                      onSelected: (val) => setModalState(() => gender = 'Female'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                PrimaryButton(
                  text: 'Enroll Staff Member',
                  isLoading: isSaving,
                  onPressed: () async {
                    if (fNameController.text.trim().isEmpty || surnameController.text.trim().isEmpty || emailController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please complete required name and email fields.')),
                      );
                      return;
                    }

                    setModalState(() => isSaving = true);
                    final payload = {
                      'firstName': fNameController.text.trim(),
                      'surname': surnameController.text.trim(),
                      'email': emailController.text.trim(),
                      'phoneNumber': phoneController.text.trim(),
                      'staffType': staffType,
                      'gender': gender,
                    };

                    try {
                      await ApiClient.instance.post('staff/create', body: payload);
                      if (ctx.mounted) Navigator.pop(ctx);
                      _fetchStaffMembers();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Staff member registered successfully!'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      }
                    } catch (e) {
                      setModalState(() => isSaving = false);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Registration error: $e')),
                        );
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
    final filtered = _filteredStaff;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Staff Directory',
          style: AppTypography.titleLarge.copyWith(color: AppColors.light, fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.light),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: _showAddStaffModal,
        icon: const Icon(Icons.person_add_alt, color: Colors.white),
        label: const Text('Add Staff', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SyncStatusBanner(),
            _buildSearchAndFilters(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : RefreshIndicator(
                      onRefresh: _fetchStaffMembers,
                      color: AppColors.primary,
                      child: filtered.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                return _buildStaffCard(filtered[index]);
                              },
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: InputDecoration(
              hintText: 'Search staff by name, ID or email...',
              hintStyle: AppTypography.bodySmall.copyWith(color: AppColors.color2Light),
              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.secondary, size: 20),
              filled: true,
              fillColor: AppColors.color3Light,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _roleFilters.map((role) {
                final isSelected = _selectedRoleFilter == role;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(role),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedRoleFilter = role),
                    selectedColor: AppColors.primary,
                    checkmarkColor: Colors.white,
                    backgroundColor: AppColors.color3Light,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.dark,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 12,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffCard(Map<String, dynamic> staff) {
    final fName = staff['firstName'] ?? '';
    final sName = staff['surname'] ?? '';
    final fullName = '$fName $sName'.trim();
    final staffId = staff['staffId'] ?? 'STF-000';
    final role = staff['staffType'] ?? 'Staff';
    final email = staff['email'] ?? '';
    final phone = staff['phoneNumber'] ?? '';
    final isActive = staff['status'] == 'active';
    final dept = staff['department'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.shadowCard,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: _getRoleColor(role).withValues(alpha: 0.12),
                  child: Text(
                    fullName.isNotEmpty ? fullName[0] : 'S',
                    style: TextStyle(
                      color: _getRoleColor(role),
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              fullName,
                              style: AppTypography.titleSmall.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.light,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? AppColors.success.withValues(alpha: 0.12)
                                  : AppColors.danger.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isActive ? 'Active' : 'Inactive',
                              style: AppTypography.labelSmall.copyWith(
                                color: isActive ? AppColors.success : AppColors.danger,
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getRoleColor(role).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              role,
                              style: TextStyle(
                                color: _getRoleColor(role),
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            staffId,
                            style: AppTypography.bodySmall.copyWith(color: AppColors.color2Light),
                          ),
                        ],
                      ),
                      if (dept.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          dept,
                          style: AppTypography.labelSmall.copyWith(color: AppColors.color4Light, fontSize: 11),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // Contact actions
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: email));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Copied email: $email')),
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.email_outlined, size: 16, color: AppColors.secondary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              email,
                              style: AppTypography.bodySmall.copyWith(fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Dialing $phone...')),
                    );
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.phone_outlined, size: 14, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          'Call',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'director':
        return const Color(0xFF7C3AED);
      case 'principal':
        return AppColors.primary;
      case 'exam officer':
        return const Color(0xFF0EA5E9);
      case 'finance officer':
        return AppColors.success;
      case 'teacher':
        return AppColors.secondary;
      default:
        return AppColors.dark;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_search_outlined, size: 64, color: AppColors.color2Light),
          const SizedBox(height: 12),
          Text('No Staff Members Found', style: AppTypography.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Try adjusting your role filter or search term.',
            style: AppTypography.bodySmall,
          ),
        ],
      ),
    );
  }
}
