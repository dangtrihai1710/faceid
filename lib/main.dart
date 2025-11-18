import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'screens/shared/home_screen.dart';
import 'screens/shared/login_screen.dart';
import 'services/auth_service.dart';
import 'models/user.dart';
import 'services/performance_optimizer.dart';
import 'themes/mobile_theme.dart';
import 'widgets/mobile_optimized.dart';

List<CameraDescription>? cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize performance optimizer first
  await _initializePerformanceOptimizations();

  // Initialize cameras for all platforms with error handling
  try {
    cameras = await availableCameras();
    print('✅ Available cameras: ${cameras?.length ?? 0}');
  } catch (e) {
    print('⚠️ Camera initialization failed: $e');
    cameras = [];
  }

  // Set preferred device orientation for mobile
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Optimize for mobile performance
  await _optimizeForDevice();

  runApp(const MyApp());
}

// Initialize performance optimizations
Future<void> _initializePerformanceOptimizations() async {
  try {
    final performanceOptimizer = PerformanceOptimizer();
    await performanceOptimizer.initialize();

    // Initialize mobile theme
    MobileTheme().initialize();

    // Create demo users for mobile testing
    await AuthService.createDemoUsers();

    print('✅ Performance optimizations initialized');
  } catch (e) {
    print('⚠️ Performance optimization failed: $e');
  }
}

// Device-specific optimizations
Future<void> _optimizeForDevice() async {
  try {
    final isLowEnd = await PerformanceOptimizer.isLowEndDevice();

    if (isLowEnd) {
      print('📱 Optimizing for low-end device...');
      await PerformanceOptimizer.setPerformancePreset('battery_saver');
    } else {
      print('🚀 Using balanced performance preset');
      await PerformanceOptimizer.setPerformancePreset('balanced');
    }

    // Set system UI overlay for better mobile experience
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));
  } catch (e) {
    print('⚠️ Device optimization failed: $e');
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  bool _isDarkMode = false;
  final PerformanceOptimizer _performanceOptimizer = PerformanceOptimizer();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeApp();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _initializeApp() async {
    try {
      await _performanceOptimizer.initialize();
      setState(() {}); // Trigger rebuild with optimizations
    } catch (e) {
      print('⚠️ App initialization error: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        print('📱 App resumed - enabling full performance');
        PerformanceOptimizer.handleAppLifecycle();
        break;
      case AppLifecycleState.paused:
        print('⏸️ App paused - optimizing for battery');
        break;
      case AppLifecycleState.detached:
        print('🔌 App detached - cleaning up resources');
        PerformanceOptimizer.clearCache();
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FaceID Attendance',
      theme: MobileTheme.optimizedTheme(false),
      darkTheme: MobileTheme.optimizedTheme(true),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(
              MediaQuery.of(context).textScaler.scale(1).clamp(0.8, 1.2),
            ),
          ),
          child: child!,
        );
      },
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    await PerformanceMonitor.measureAsync('auth_check', () async {
      try {
        final isLoggedIn = await _authService.isLoggedIn();
        if (isLoggedIn) {
          final user = await _authService.getCurrentUser();
          setState(() {
            _currentUser = user;
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
          });
        }
      } catch (e) {
        print('Error checking auth status: $e');
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: Center(
          child: MobileOptimizedWidgets.loadingIndicator(
            message: 'Đang tải...',
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    }

    // If user is logged in, show home screen, otherwise show login screen
    if (_currentUser != null) {
      return HomeScreen(cameras: cameras, currentUser: _currentUser!);
    }

    // Show login screen with quick login options
    return LoginScreen(cameras: cameras);
  }
}