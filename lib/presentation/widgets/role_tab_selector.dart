import 'package:flutter/material.dart';
import 'package:edstream_mobile/core/constants/app_constants.dart';
import 'package:edstream_mobile/core/theme/app_colors.dart';
import 'package:edstream_mobile/core/theme/app_typography.dart';

class RoleTabSelector extends StatelessWidget {
  const RoleTabSelector({
    super.key,
    required this.selectedRole,
    required this.onRoleChanged,
  });

  final UserRole selectedRole;
  final ValueChanged<UserRole> onRoleChanged;

  @override
  Widget build(BuildContext context) {
    final isTeacher = selectedRole == UserRole.teacher;

    return Container(
      height: 54,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppColors.color3Light,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Teacher Tab
          Expanded(
            child: GestureDetector(
              onTap: () => onRoleChanged(UserRole.teacher),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  color: isTeacher ? AppColors.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isTeacher ? AppColors.shadowSm : null,
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.co_present_rounded,
                        size: 20,
                        color: isTeacher ? AppColors.primary : AppColors.color2Light,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Teacher',
                        style: AppTypography.titleSmall.copyWith(
                          fontWeight: isTeacher ? FontWeight.w600 : FontWeight.w500,
                          color: isTeacher ? AppColors.primary : AppColors.color2Light,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Student Tab
          Expanded(
            child: GestureDetector(
              onTap: () => onRoleChanged(UserRole.student),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  color: !isTeacher ? AppColors.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: !isTeacher ? AppColors.shadowSm : null,
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.school_rounded,
                        size: 20,
                        color: !isTeacher ? AppColors.primary : AppColors.color2Light,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Student',
                        style: AppTypography.titleSmall.copyWith(
                          fontWeight: !isTeacher ? FontWeight.w600 : FontWeight.w500,
                          color: !isTeacher ? AppColors.primary : AppColors.color2Light,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
