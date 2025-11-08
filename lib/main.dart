import 'package:flutter/material.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_text_styles.dart';
import 'screens/login/login_screen_api.dart';
import 'screens/home/student_home_screen.dart';
import 'screens/home/teacher_home_screen.dart';
import 'screens/result_screen.dart';
import 'screens/schedule/schedule_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'widgets/camera_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Mock data is already initialized through static variables
  // In a real app, this would load from a database or API

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FaceID Attendance',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.surface,
          error: AppColors.error,
          onPrimary: AppColors.onPrimary,
          onSecondary: AppColors.onSecondary,
          onSurface: AppColors.onSurface,
          onError: AppColors.onPrimary,
        ),
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.onBackground,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: AppTextStyles.heading3.copyWith(
            color: AppColors.onBackground,
          ),
          iconTheme: const IconThemeData(
            color: AppColors.onBackground,
            size: 24,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AppColors.divider),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AppColors.divider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.error, width: 2),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.error, width: 2),
          ),
          labelStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.onSurface.withValues(alpha: 0.7),
          ),
          hintStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.onSurface.withValues(alpha: 0.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        cardTheme: CardThemeData(
          color: AppColors.surface,
          elevation: 2,
          shadowColor: Colors.black.withValues(alpha: 0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: EdgeInsets.zero,
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.onSurface.withValues(alpha: 0.6),
          type: BottomNavigationBarType.fixed,
          elevation: 8,
          selectedLabelStyle: AppTextStyles.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: AppTextStyles.bodySmall,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          elevation: 4,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColors.onBackground,
          contentTextStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.surface,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          behavior: SnackBarBehavior.floating,
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: AppColors.surface,
          titleTextStyle: AppTextStyles.heading3.copyWith(
            color: AppColors.onBackground,
          ),
          contentTextStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.onBackground,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreenApi(),
        '/student_home': (context) => const StudentHomeScreen(),
        '/teacher_home': (context) => const TeacherHomeScreen(),
        '/camera': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          return CameraView(classItem: args);
        },
        '/result': (context) => const ResultScreen(),
        '/schedule': (context) => const ScheduleScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
      onGenerateRoute: (settings) {
        // Handle dynamic routes with arguments
        switch (settings.name) {
          case '/camera':
            final args = settings.arguments;
            return MaterialPageRoute(
              builder: (context) => CameraView(classItem: args),
              settings: settings,
            );
          case '/result':
            return MaterialPageRoute(
              builder: (context) => const ResultScreen(),
              settings: settings,
            );
          default:
            return null;
        }
      },
    );
  }
}
