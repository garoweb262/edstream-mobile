import 'package:flutter/material.dart';
import 'package:edstream_mobile/core/network/api_client.dart';
import 'package:edstream_mobile/core/storage/local_cache_store.dart';
import 'package:edstream_mobile/core/theme/app_colors.dart';
import 'package:edstream_mobile/core/theme/app_typography.dart';
import 'package:edstream_mobile/core/widgets/sync_status_banner.dart';
import 'package:edstream_mobile/presentation/widgets/custom_text_field.dart';
import 'package:edstream_mobile/presentation/widgets/primary_button.dart';

class SchoolSettingsScreen extends StatefulWidget {
  const SchoolSettingsScreen({super.key});

  @override
  State<SchoolSettingsScreen> createState() => _SchoolSettingsScreenState();
}

class _SchoolSettingsScreenState extends State<SchoolSettingsScreen> {
  bool _isLoading = true;
  bool _isSaving = false;

  int _noOfCa = 2; // 2 or 3 Continuous Assessments
  final TextEditingController _ca1MaxController = TextEditingController(text: '20');
  final TextEditingController _ca2MaxController = TextEditingController(text: '20');
  final TextEditingController _ca3MaxController = TextEditingController(text: '20');
  final TextEditingController _examMaxController = TextEditingController(text: '60');
  final TextEditingController _passMarkController = TextEditingController(text: '50');

  String _schoolName = 'EdStream Model Academy';
  String _schoolMotto = 'Knowledge and Excellence';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _ca1MaxController.dispose();
    _ca2MaxController.dispose();
    _ca3MaxController.dispose();
    _examMaxController.dispose();
    _passMarkController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    const cacheKey = 'management_school_settings_cache';
    final cached = LocalCacheStore.instance.getJson(cacheKey);
    if (cached is Map<String, dynamic>) {
      _applySettings(cached);
    }

    try {
      final res = await ApiClient.instance.get('school-settings/', cacheLocally: true, cacheKey: cacheKey);
      if (res is Map && res['data'] is Map) {
        final data = Map<String, dynamic>.from(res['data']);
        setState(() {
          _applySettings(data);
          _isLoading = false;
        });
        LocalCacheStore.instance.setJson(cacheKey, data);
        return;
      }
    } catch (_) {}

    if (mounted) setState(() => _isLoading = false);
  }

  void _applySettings(Map<String, dynamic> data) {
    _noOfCa = (data['noOfCa'] as num?)?.toInt() ?? 2;
    if (data['ca1Max'] != null) _ca1MaxController.text = data['ca1Max'].toString();
    if (data['ca2Max'] != null) _ca2MaxController.text = data['ca2Max'].toString();
    if (data['ca3Max'] != null) _ca3MaxController.text = data['ca3Max'].toString();
    if (data['examMax'] != null) _examMaxController.text = data['examMax'].toString();
    if (data['passMark'] != null) _passMarkController.text = data['passMark'].toString();
    if (data['schoolName'] != null) _schoolName = data['schoolName'].toString();
    if (data['schoolMotto'] != null) _schoolMotto = data['schoolMotto'].toString();
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    final payload = {
      'noOfCa': _noOfCa,
      'ca1Max': double.tryParse(_ca1MaxController.text) ?? 20.0,
      'ca2Max': double.tryParse(_ca2MaxController.text) ?? 20.0,
      if (_noOfCa >= 3) 'ca3Max': double.tryParse(_ca3MaxController.text) ?? 20.0,
      'examMax': double.tryParse(_examMaxController.text) ?? 60.0,
      'passMark': double.tryParse(_passMarkController.text) ?? 50.0,
    };

    try {
      await ApiClient.instance.post('school-settings/', body: payload);
      await LocalCacheStore.instance.setInt('school_settings_noOfCa', _noOfCa);
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Institutional Academic Settings Saved!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update settings: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'School & Academic Settings',
          style: AppTypography.titleLarge.copyWith(color: AppColors.light, fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.light),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SyncStatusBanner(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Institution Identity Card
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: AppColors.shadowSm,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.school, color: AppColors.primary, size: 32),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(_schoolName, style: AppTypography.titleMedium),
                                      const SizedBox(height: 2),
                                      Text(_schoolMotto, style: AppTypography.bodySmall),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Continuous Assessment (CA) System
                          Text('Academic Assessment Policy', style: AppTypography.titleMedium),
                          const SizedBox(height: 6),
                          Text(
                            'Configure the number of termly test evaluations and examination score allocation across the institution.',
                            style: AppTypography.bodySmall,
                          ),
                          const SizedBox(height: 14),

                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: AppColors.shadowSm,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Number of CAs per Term', style: AppTypography.labelMedium),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        style: OutlinedButton.styleFrom(
                                          backgroundColor: _noOfCa == 2 ? AppColors.primary : Colors.transparent,
                                          foregroundColor: _noOfCa == 2 ? Colors.white : AppColors.primary,
                                          side: const BorderSide(color: AppColors.primary),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                        ),
                                        onPressed: () => setState(() => _noOfCa = 2),
                                        child: const Text('2 Assessments (CA1 & CA2)', style: TextStyle(fontWeight: FontWeight.w700)),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: OutlinedButton(
                                        style: OutlinedButton.styleFrom(
                                          backgroundColor: _noOfCa == 3 ? AppColors.primary : Colors.transparent,
                                          foregroundColor: _noOfCa == 3 ? Colors.white : AppColors.primary,
                                          side: const BorderSide(color: AppColors.primary),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                        ),
                                        onPressed: () => setState(() => _noOfCa = 3),
                                        child: const Text('3 Assessments (CA1, 2, 3)', style: TextStyle(fontWeight: FontWeight.w700)),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),

                                Row(
                                  children: [
                                    Expanded(
                                      child: CustomTextField(
                                        labelText: '1st CA Max (pts)',
                                        hintText: '20',
                                        controller: _ca1MaxController,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: CustomTextField(
                                        labelText: '2nd CA Max (pts)',
                                        hintText: '20',
                                        controller: _ca2MaxController,
                                      ),
                                    ),
                                  ],
                                ),
                                if (_noOfCa >= 3) ...[
                                  const SizedBox(height: 12),
                                  CustomTextField(
                                    labelText: '3rd CA Max (pts)',
                                    hintText: '20',
                                    controller: _ca3MaxController,
                                  ),
                                ],
                                const SizedBox(height: 12),

                                Row(
                                  children: [
                                    Expanded(
                                      child: CustomTextField(
                                        labelText: 'Terminal Exam Max (pts)',
                                        hintText: '60',
                                        controller: _examMaxController,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: CustomTextField(
                                        labelText: 'Pass Benchmark (%)',
                                        hintText: '50',
                                        controller: _passMarkController,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          PrimaryButton(
                            text: 'Save Institutional Settings',
                            isLoading: _isSaving,
                            onPressed: _saveSettings,
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
