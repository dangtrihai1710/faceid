import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'screens/login/login_screen.dart';

List<CameraDescription>? cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // ⚠️ Bắt buộc
  cameras = await availableCameras();         // ✅ Lấy danh sách camera
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FaceID Attendance Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: LoginScreen(),
    );
  }
}
