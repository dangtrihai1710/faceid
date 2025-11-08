import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/widgets/primary_button.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with TickerProviderStateMixin {
  bool _isSuccess = false;
  DateTime? _timestamp;
  dynamic _classItem;
  bool _isTeacher = false;

  late AnimationController _scaleController;
  late AnimationController _checkController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _checkAnimation;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _setupAnimations();
  }

  void _initializeData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        setState(() {
          _isSuccess = args['success'] ?? false;
          _timestamp = args['timestamp'] as DateTime?;
          _classItem = args['classItem'];
          _isTeacher = _classItem != null;
        });
      }
    });
  }

  void _setupAnimations() {
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _checkController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _checkAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _checkController,
      curve: Curves.elasticOut,
    ));

    // Start animations after a brief delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _scaleController.forward();
        _checkController.forward();
      }
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _checkController.dispose();
    super.dispose();
  }

  String _formatTime(DateTime? timestamp) {
    if (timestamp == null) return '';
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  void _navigateToHome() {
    final homeRoute = _isTeacher ? '/teacher_home' : '/student_home';
    Navigator.pushNamedAndRemoveUntil(
      context,
      homeRoute,
      (route) => false,
    );
  }

  void _navigateToCamera() {
    Navigator.pushReplacementNamed(
      context,
      '/camera',
      arguments: _classItem,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Result Icon with Animation
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: _isSuccess
                              ? AppColors.success.withValues(alpha: 0.1)
                              : AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(60),
                          boxShadow: [
                            BoxShadow(
                              color: (_isSuccess ? AppColors.success : AppColors.error)
                                  .withValues(alpha: 0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Icon(
                              _isSuccess ? Icons.check_circle : Icons.cancel,
                              size: 80,
                              color: _isSuccess ? AppColors.success : AppColors.error,
                            ),
                            if (_isSuccess)
                              ScaleTransition(
                                scale: _checkAnimation,
                                child: Icon(
                                  Icons.check,
                                  size: 40,
                                  color: AppColors.onPrimary,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Result Title
                    AnimatedBuilder(
                      animation: _scaleAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _scaleAnimation.value,
                          child: Text(
                            _isSuccess ? 'Điểm danh thành công!' : 'Điểm danh thất bại',
                            style: AppTextStyles.heading2.copyWith(
                              color: _isSuccess ? AppColors.success : AppColors.error,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    // Result Message
                    AnimatedBuilder(
                      animation: _scaleAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _scaleAnimation.value,
                          child: Text(
                            _isSuccess
                                ? 'Điểm danh đã được ghi nhận thành công'
                                : 'Không thể nhận diện khuôn mặt. Vui lòng thử lại.',
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: AppColors.onSurface.withValues(alpha: 0.8),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        );
                      },
                    ),

                    if (_isSuccess && _timestamp != null) ...[
                      const SizedBox(height: 12),
                      AnimatedBuilder(
                        animation: _scaleAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _scaleAnimation.value,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Thời gian: ${_formatTime(_timestamp)}',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],

                    // Class Information (for teachers)
                    if (_isTeacher && _classItem != null && _isSuccess) ...[
                      const SizedBox(height: 32),
                      AnimatedBuilder(
                        animation: _scaleAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _scaleAnimation.value,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
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
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Thông tin lớp học',
                                    style: AppTextStyles.heading4,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildInfoRow(
                                    Icons.subject_outlined,
                                    'Môn học',
                                    _classItem?.subject ?? '',
                                  ),
                                  const SizedBox(height: 8),
                                  _buildInfoRow(
                                    Icons.location_on_outlined,
                                    'Phòng',
                                    _classItem?.room ?? '',
                                  ),
                                  const SizedBox(height: 8),
                                  _buildInfoRow(
                                    Icons.access_time,
                                    'Thời gian',
                                    _classItem?.time ?? '',
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Action Buttons
              Column(
                children: [
                  if (_isSuccess) ...[
                    PrimaryButton(
                      text: _isTeacher ? 'Tiếp tục điểm danh' : 'Về trang chủ',
                      onPressed: _isTeacher ? _navigateToCamera : _navigateToHome,
                    ),
                    if (!_isTeacher) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: _navigateToCamera,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            'Điểm danh lại',
                            style: AppTextStyles.buttonMedium.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ] else ...[
                    PrimaryButton(
                      text: 'Thử lại',
                      onPressed: _navigateToCamera,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: _navigateToHome,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          'Về trang chủ',
                          style: AppTextStyles.buttonMedium.copyWith(
                            color: AppColors.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: AppColors.onSurface.withValues(alpha: 0.6),
        ),
        const SizedBox(width: 12),
        Text(
          '$label:',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.onBackground,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}