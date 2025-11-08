import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../mock/mock_models.dart';

class ClassCard extends StatelessWidget {
  final ClassModel classItem;
  final VoidCallback? onTap;
  final VoidCallback? onActionPressed;
  final String? actionText;
  final bool showAction;
  final bool isCompact;

  const ClassCard({
    super.key,
    required this.classItem,
    this.onTap,
    this.onActionPressed,
    this.actionText,
    this.showAction = false,
    this.isCompact = false,
  });

  Color getStatusColor() {
    switch (classItem.status.toLowerCase()) {
      case 'attended':
        return AppColors.success;
      case 'missed':
        return AppColors.error;
      case 'ongoing':
        return AppColors.info;
      case 'upcoming':
      default:
        return AppColors.warning;
    }
  }

  String getStatusText() {
    switch (classItem.status.toLowerCase()) {
      case 'attended':
        return 'Đã điểm danh';
      case 'missed':
        return 'Vắng mặt';
      case 'ongoing':
        return 'Đang diễn ra';
      case 'upcoming':
      default:
        return 'Sắp diễn ra';
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = getStatusColor();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: classItem.status.toLowerCase() == 'ongoing'
            ? Border.all(color: statusColor.withValues(alpha: 0.3), width: 2)
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(isCompact ? 12 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  classItem.subject,
                                  style: isCompact
                                      ? AppTextStyles.heading4
                                      : AppTextStyles.heading3,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  getStatusText(),
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: statusColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (!isCompact) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  size: 16,
                                  color: AppColors.onSurface.withValues(alpha: 0.6),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Phòng ${classItem.room}',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.onSurface.withValues(alpha: 0.7),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Icon(
                                  Icons.access_time,
                                  size: 16,
                                  color: AppColors.onSurface.withValues(alpha: 0.6),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  classItem.time,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.onSurface.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                            if (classItem.teacher.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.person_outline,
                                    size: 16,
                                    color: AppColors.onSurface.withValues(alpha: 0.6),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    classItem.teacher,
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.onSurface.withValues(alpha: 0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ] else ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  size: 14,
                                  color: AppColors.onSurface.withValues(alpha: 0.6),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  classItem.room,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.onSurface.withValues(alpha: 0.7),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Icon(
                                  Icons.access_time,
                                  size: 14,
                                  color: AppColors.onSurface.withValues(alpha: 0.6),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  classItem.time,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.onSurface.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (onTap != null) ...[
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: AppColors.onSurface.withValues(alpha: 0.5),
                      ),
                    ],
                  ],
                ),
                if (showAction && onActionPressed != null) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onActionPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: statusColor,
                        foregroundColor: AppColors.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        actionText ?? (classItem.status.toLowerCase() == 'ongoing'
                            ? 'Bắt đầu điểm danh'
                            : 'Chi tiết'),
                        style: AppTextStyles.buttonMedium,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}