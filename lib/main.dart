import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/project_repository.dart';
import 'models/app_settings.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for project storage
  await Hive.initFlutter();
  await ProjectRepository.init();

  // Determine first-launch routing
  final settings = await AppSettings.load();

  runApp(DepthWallpaperApp(showOnboarding: !settings.hasSeenOnboarding));
}

class DepthWallpaperApp extends StatelessWidget {
  final bool showOnboarding;
  const DepthWallpaperApp({super.key, required this.showOnboarding});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Depth Wallpaper',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: showOnboarding ? const OnboardingScreen() : const HomeScreen(),
    );
  }
}
