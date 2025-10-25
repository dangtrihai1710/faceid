import 'package:camera/camera.dart';
import 'package:faceid/widgets/camera_view.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class HomeScreen extends StatefulWidget {
  final List<CameraDescription>? cameras;
  const HomeScreen({super.key, this.cameras});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  CameraController? _cameraController;
  bool _loading = false;
  String _statusMessage = "Sẵn sàng điểm danh";
  double? _latitude;
  double? _longitude;
  DateTime? _attendanceTime;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  /// 📍 Lấy vị trí GPS
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _statusMessage = "⚠ Vui lòng bật GPS");
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _statusMessage = "Chưa cấp quyền định vị");
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() => _statusMessage = "Quyền GPS bị từ chối vĩnh viễn");
      return;
    }

    setState(() {
      _statusMessage = "Đang lấy toạ độ GPS...";
    });

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _latitude = position.latitude;
      _longitude = position.longitude;
      _statusMessage = "Sẵn sàng điểm danh";
    });

    print("📡 GPS: ${position.latitude}, ${position.longitude}");
  }

  /// 📷 Sự kiện bấm nút "Điểm danh ngay"
  Future<void> _onAttendancePressed() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      setState(() => _statusMessage = "Camera chưa sẵn sàng");
      return;
    }

    setState(() {
      _loading = true;
      _statusMessage = "Đang chụp & xử lý...";
      _attendanceTime = null; // Xoá thời gian cũ khi bắt đầu lần mới
    });

    try {
      final XFile file = await _cameraController!.takePicture();

      // 🧠 Giả lập gửi ảnh & xử lý
      await Future.delayed(const Duration(seconds: 2));

      setState(() {
        _loading = false;
        _statusMessage = "Điểm danh thành công (Demo)";
        _attendanceTime = DateTime.now(); // Ghi lại thời gian thành công
      });
      print("Ảnh lưu tạm: ${file.path}");
    } catch (e) {
      setState(() {
        _loading = false;
        _statusMessage = "Lỗi khi chụp ảnh: ${e.toString()}";
      });
    }
  }

  // --- Giao diện ---

  @override
  Widget build(BuildContext context) {
    // Nút điểm danh chỉ được bật khi không loading, và có đủ thông tin
    final isReady = _cameraController?.value.isInitialized == true &&
        _latitude != null &&
        !_loading;

    return Scaffold(
      extendBodyBehindAppBar: true, // Cho camera view tràn ra sau app bar
      appBar: AppBar(
        title: const Text("FaceID Attendance"),
        backgroundColor: Colors.transparent, // App bar trong suốt
        elevation: 0,
        centerTitle: true,
      ),
      drawer: _buildDrawer(), // Thêm menu ở đây
      body: Stack(
        children: [
          // Lớp 1: Camera Preview
          Positioned.fill(
            child: CameraView(
              cameras: widget.cameras,
              onControllerReady: (controller) {
                // Cần setState để build lại UI khi camera sẵn sàng
                if (mounted) {
                  setState(() {
                    _cameraController = controller;
                  });
                }
              },
            ),
          ),

          // Lớp 2: Bảng điều khiển dưới cùng
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding:
                  const EdgeInsets.all(20.0).copyWith(bottom: 40.0), // Thêm padding dưới cho an toàn
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 10,
                    color: Colors.black12,
                    offset: Offset(0, -2),
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // --- Trạng thái & Vị trí ---
                  _buildStatusAndLocationInfo(),

                  // --- Thời gian điểm danh (nếu có) ---
                  if (_attendanceTime != null) _buildAttendanceTimeInfo(),

                  const SizedBox(height: 20),

                  // --- Nút Điểm danh ---
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isReady ? _onAttendancePressed : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: Colors.blue,
                        disabledBackgroundColor: Colors.grey.shade300,
                      ),
                      child: _loading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                          : const Text(
                              "Điểm danh ngay",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  /// Widget cho menu (Drawer)
  Drawer _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
            child: Text(
              'Menu',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home_outlined),
            title: const Text('Trang chủ'),
            onTap: () {
              Navigator.pop(context); // Đóng drawer
            },
          ),
          ListTile(
            leading: const Icon(Icons.history_outlined),
            title: const Text('Lịch sử điểm danh'),
            onTap: () {
              Navigator.pop(context); // Đóng drawer
              // TODO: Điều hướng đến trang lịch sử
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chức năng đang được phát triển')),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Widget hiển thị trạng thái và vị trí
  Widget _buildStatusAndLocationInfo() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getIconForStatus(),
              color: _getColorForStatus(),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              _statusMessage,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: _getColorForStatus(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_latitude != null && _longitude != null)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_on_outlined, color: Colors.grey, size: 16),
              const SizedBox(width: 4),
              Text(
                "Vĩ độ: ${_latitude!.toStringAsFixed(5)}, Kinh độ: ${_longitude!.toStringAsFixed(5)}",
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          )
        else if (!_statusMessage.contains("GPS"))
          const Text(
            "Đang lấy toạ độ GPS...",
            style: TextStyle(color: Colors.orange, fontSize: 12),
          ),
      ],
    );
  }

  /// Widget hiển thị thời gian đã điểm danh thành công
  Widget _buildAttendanceTimeInfo() {
    final time = _attendanceTime!;
    final formattedTime =
        "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')} - ${time.day}/${time.month}/${time.year}";

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.timer_outlined, color: Colors.grey, size: 16),
          const SizedBox(width: 4),
          Text(
            "Thời gian: $formattedTime",
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  IconData _getIconForStatus() {
    if (_statusMessage.contains("thành công")) return Icons.check_circle_outline;
    if (_statusMessage.contains("⚠") ||
        _statusMessage.contains("chưa") ||
        _statusMessage.contains("từ chối") ||
        _statusMessage.contains("Lỗi")) return Icons.warning_amber_rounded;
    if (_loading) return Icons.sync_rounded;
    return Icons.info_outline_rounded;
  }

  Color _getColorForStatus() {
    if (_statusMessage.contains("thành công")) return Colors.green.shade700;
    if (_statusMessage.contains("⚠") ||
        _statusMessage.contains("chưa") ||
        _statusMessage.contains("từ chối") ||
        _statusMessage.contains("Lỗi")) return Colors.red.shade600;
    if (_loading) return Colors.blue;
    return Colors.black87;
  }
}
