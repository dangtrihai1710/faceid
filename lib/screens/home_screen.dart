import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import '../widgets/camera_view.dart';

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
        setState(() => _statusMessage = " Chưa cấp quyền định vị");
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() => _statusMessage = " Quyền GPS bị từ chối vĩnh viễn");
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _latitude = position.latitude;
      _longitude = position.longitude;
    });

    print("📡 GPS: ${position.latitude}, ${position.longitude}");
  }

  /// 📷 Sự kiện bấm nút "Điểm danh ngay"
  Future<void> _onAttendancePressed() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      setState(() => _statusMessage = " Camera chưa sẵn sàng");
      return;
    }

    setState(() {
      _loading = true;
      _statusMessage = "Đang chụp & xử lý...";
    });

    final XFile file = await _cameraController!.takePicture();

    // 🧠 Giả lập gửi ảnh & xử lý
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _loading = false;
      _statusMessage = " Điểm danh thành công (Demo)";
    });

    print(" Ảnh lưu tạm: ${file.path}");
  }

  ///  Giao diện chính
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("FaceID Attendance Demo")),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: CameraView(
              cameras: widget.cameras,
              onControllerReady: (controller) {
                _cameraController = controller;
              },
            ),
          ),

          // --- Phần dưới: trạng thái, toạ độ, nút điểm danh ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  _statusMessage,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),

                if (_latitude != null && _longitude != null)
                  Column(
                    children: [
                      const Text(
                        " Vị trí hiện tại:",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Vĩ độ: ${_latitude!.toStringAsFixed(5)}",
                        style: const TextStyle(color: Colors.grey),
                      ),
                      Text(
                        "Kinh độ: ${_longitude!.toStringAsFixed(5)}",
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  )
                else
                  const Text(
                    " Đang lấy toạ độ GPS...",
                    style: TextStyle(color: Colors.orange),
                  ),

                const SizedBox(height: 10),

                ElevatedButton(
                  onPressed: _loading ? null : _onAttendancePressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 50,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    "Điểm danh ngay",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
