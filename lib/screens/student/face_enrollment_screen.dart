import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../../widgets/camera_view.dart';
import '../../services/face_enrollment_service.dart';
import '../../models/face_model.dart';
import '../../models/user.dart';

class FaceEnrollmentScreen extends StatefulWidget {
  final User user;
  final List<CameraDescription>? cameras;

  const FaceEnrollmentScreen({
    super.key,
    required this.user,
    this.cameras,
  });

  @override
  State<FaceEnrollmentScreen> createState() => _FaceEnrollmentScreenState();
}

class _FaceEnrollmentScreenState extends State<FaceEnrollmentScreen> {
  CameraController? _cameraController;
  EnrollmentState _enrollmentState = const EnrollmentState(step: EnrollmentStep.initial);
  String? _capturedImagePath;
  String? _description;
  List<FaceModel> _enrolledFaces = [];
  bool _isLoadingFaces = true;

  // Form controllers
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadEnrolledFaces();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadEnrolledFaces() async {
    try {
      setState(() {
        _isLoadingFaces = true;
      });
      final faces = await FaceEnrollmentService.getEnrolledFaces(widget.user.id);
      if (mounted) {
        setState(() {
          _enrolledFaces = faces;
          _isLoadingFaces = false;
        });
      }
    } catch (e) {
      print('Error loading enrolled faces: $e');
      if (mounted) {
        setState(() {
          _isLoadingFaces = false;
        });
      }
    }
  }

  Future<void> _startEnrollment() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      setState(() {
        _enrollmentState = _enrollmentState.copyWith(
          step: EnrollmentStep.error,
          message: 'Camera chưa sẵn sàng. Vui lòng kiểm tra lại.',
        );
      });
      return;
    }

    setState(() {
      _enrollmentState = const EnrollmentState(
        step: EnrollmentStep.capture,
        message: 'Hãy nhìn thẳng vào camera và nhấn nút chụp',
        currentCapture: 1,
        totalCaptures: 1,
      );
    });
  }

  Future<void> _capturePhoto() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      setState(() {
        _enrollmentState = _enrollmentState.copyWith(
          step: EnrollmentStep.error,
          message: 'Camera chưa sẵn sàng.',
        );
      });
      return;
    }

    setState(() {
      _enrollmentState = const EnrollmentState(
        step: EnrollmentStep.processing,
        message: 'Đang xử lý ảnh...',
      );
    });

    try {
      final XFile file = await _cameraController!.takePicture();
      setState(() {
        _capturedImagePath = file.path;
        _enrollmentState = _enrollmentState.copyWith(
          step: EnrollmentStep.success,
          message: 'Ảnh đã được chụp thành công!',
          photoPath: file.path,
        );
      });
    } catch (e) {
      setState(() {
        _enrollmentState = _enrollmentState.copyWith(
          step: EnrollmentStep.error,
          message: 'Lỗi khi chụp ảnh: $e',
        );
      });
    }
  }

  Future<void> _confirmEnrollment() async {
    if (_capturedImagePath == null) return;

    setState(() {
      _enrollmentState = const EnrollmentState(
        step: EnrollmentStep.processing,
        message: 'Đang đăng ký khuôn mặt...',
      );
    });

    try {
      final face = await FaceEnrollmentService.enrollFace(
        widget.user.id,
        _capturedImagePath!,
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : 'Đăng ký ngày ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
      );

      // Reload enrolled faces
      await _loadEnrolledFaces();

      setState(() {
        _enrollmentState = const EnrollmentState(
          step: EnrollmentStep.success,
          message: 'Đăng ký khuôn mặt thành công!',
        );
        _capturedImagePath = null;
        _descriptionController.clear();
      });

      // Show success dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('✅ Đăng ký thành công!'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Khuôn mặt đã được đăng ký thành công vào hệ thống.'),
                const SizedBox(height: 8),
                Text('ID: ${face.id}'),
                const SizedBox(height: 4),
                Text('Ngày đăng ký: ${face.formattedEnrolledAt}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() {
        _enrollmentState = _enrollmentState.copyWith(
          step: EnrollmentStep.error,
          message: 'Lỗi khi đăng ký khuôn mặt: $e',
        );
      });
    }
  }

  Future<void> _resetEnrollment() async {
    setState(() {
      _enrollmentState = const EnrollmentState(step: EnrollmentStep.initial);
      _capturedImagePath = null;
      _descriptionController.clear();
    });
  }

  Future<void> _deleteFace(String faceId) async {
    try {
      await FaceEnrollmentService.deleteEnrolledFace(faceId);
      await _loadEnrolledFaces();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã xóa khuôn mặt thành công'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi xóa khuôn mặt: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Đăng ký khuôn mặt",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Info Card
            _buildUserInfoCard(),
            const SizedBox(height: 20),

            // Guidelines Card
            _buildGuidelinesCard(),
            const SizedBox(height: 20),

            // Camera Section
            _buildCameraSection(),
            const SizedBox(height: 20),

            // Description Input
            _buildDescriptionSection(),
            const SizedBox(height: 20),

            // Action Buttons
            _buildActionButtons(),
            const SizedBox(height: 20),

            // Enrolled Faces Section
            _buildEnrolledFacesSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.blue[700],
              child: Text(
                widget.user.fullName.isNotEmpty
                    ? widget.user.fullName[0].toUpperCase()
                    : 'U',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.user.fullName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    widget.user.email,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'MSSV: ${widget.user.userId}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuidelinesCard() {
    final guidelines = FaceEnrollmentService.getEnrollmentGuidelines();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700]),
                const SizedBox(width: 8),
                const Text(
                  'Hướng dẫn đăng ký khuôn mặt',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...guidelines.map((guideline) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      guideline,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.camera_alt, color: Colors.blue[700]),
                const SizedBox(width: 8),
                const Text(
                  'Chụp ảnh khuôn mặt',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Camera View
            Container(
              height: 250,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CameraView(
                  cameras: widget.cameras,
                  onControllerReady: (controller) {
                    _cameraController = controller;
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Status Message
            if (_enrollmentState.message != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getStatusColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _getStatusColor()),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getStatusIcon(),
                      color: _getStatusColor(),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _enrollmentState.message!,
                        style: TextStyle(
                          color: _getStatusColor(),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Captured Image Preview
            if (_capturedImagePath != null)
              Column(
                children: [
                  const SizedBox(height: 16),
                  Text(
                    'Ảnh đã chụp:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        _capturedImagePath!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Text(
                              'Không thể tải ảnh',
                              style: TextStyle(color: Colors.grey),
                            ),
                          );
                        },
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

  Widget _buildDescriptionSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.description, color: Colors.blue[700]),
                const SizedBox(width: 8),
                const Text(
                  'Mô tả (không bắt buộc)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                hintText: 'Nhập mô tả cho khuôn mặt này...',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    switch (_enrollmentState.step) {
      case EnrollmentStep.initial:
        return SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _startEnrollment,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.camera_alt),
                SizedBox(width: 8),
                Text(
                  'Bắt đầu đăng ký',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );

      case EnrollmentStep.capture:
        return SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _capturePhoto,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.camera),
                SizedBox(width: 8),
                Text(
                  'Chụp ảnh',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );

      case EnrollmentStep.success:
        return Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _resetEnrollment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[600],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: const Text('Chụp lại'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _confirmEnrollment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: const Text('Xác nhận đăng ký'),
              ),
            ),
          ],
        );

      case EnrollmentStep.processing:
        return SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[400],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
                SizedBox(width: 12),
                Text('Đang xử lý...'),
              ],
            ),
          ),
        );

      case EnrollmentStep.error:
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _resetEnrollment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[700],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: const Text('Thử lại'),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _enrollmentState.message ?? 'Đã xảy ra lỗi',
              style: TextStyle(
                color: Colors.red[700],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        );

      default:
        return const SizedBox();
    }
  }

  Widget _buildEnrolledFacesSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.face, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Text(
                  'Các khuôn mặt đã đăng ký',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_enrolledFaces.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_enrolledFaces.where((f) => f.isActive).length} đang hoạt động',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            if (_isLoadingFaces)
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Đang tải khuôn mặt đã đăng ký...'),
                  ],
                ),
              )
            else if (_enrolledFaces.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      'Chưa có khuôn mặt nào được đăng ký',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              )
            else
              ..._enrolledFaces.map((face) => _buildFaceCard(face)),
          ],
        ),
      ),
    );
  }

  Widget _buildFaceCard(FaceModel face) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: face.statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.face,
              color: face.statusColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ID: ${face.id}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                Text(
                  face.statusText,
                  style: TextStyle(
                    color: face.statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  face.formattedEnrolledAt,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 11,
                  ),
                ),
                if (face.description != null && face.description!.isNotEmpty)
                  Text(
                    face.description!,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => _showDeleteConfirmation(face),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(FaceModel face) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa khuôn mặt này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteFace(face.id);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (_enrollmentState.step) {
      case EnrollmentStep.success:
        return Colors.green;
      case EnrollmentStep.error:
        return Colors.red;
      case EnrollmentStep.processing:
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  IconData _getStatusIcon() {
    switch (_enrollmentState.step) {
      case EnrollmentStep.success:
        return Icons.check_circle;
      case EnrollmentStep.error:
        return Icons.error;
      case EnrollmentStep.processing:
        return Icons.hourglass_empty;
      default:
        return Icons.info;
    }
  }
}