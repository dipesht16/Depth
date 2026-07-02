import 'package:flutter/material.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/slide_page_route.dart';
import 'studio_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Depth Wallpaper'),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Premium Glowing Icon Container for Empty State
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: const Color(0xFF121212),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                      blurRadius: 20,
                      spreadRadius: 5,
                    )
                  ],
                ),
                child: const Icon(
                  Icons.wallpaper_rounded,
                  size: 40,
                  color: Color(0xFFFFD700),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Create Your First Depth Wallpaper',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Projects will appear here. Tap the + button below to start separating layers and styling your custom depth clock.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFB0B0B0),
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            SlidePageRoute(child: const StudioScreen()),
          );
        },
        tooltip: 'Create New Wallpaper',
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }
}
