import 'package:flutter/material.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/slide_page_route.dart';
import 'preview_screen.dart';

class StudioScreen extends StatefulWidget {
  const StudioScreen({super.key});

  @override
  State<StudioScreen> createState() => _StudioScreenState();
}

class _StudioScreenState extends State<StudioScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> _tabs = [
    'Basics',
    'Typography',
    'Effects',
    'Transform',
    'Date',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Studio',
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_library_outlined),
            tooltip: 'Select Image',
            onPressed: () {
              // Action will be implemented in Module 2
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Image picker will be implemented in Module 2')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Reset Settings',
            onPressed: () {
              // Action will be implemented in future modules
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Reset settings will be implemented in future modules')),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Section 1: Preview Area (400dp height, phone-shaped container)
            Center(
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    SlidePageRoute(child: const PreviewScreen()),
                  );
                },
                child: Container(
                  height: 400,
                  width: 400 * (9 / 19.5), // Aspect ratio constraints for phone frame
                  decoration: BoxDecoration(
                    color: const Color(0xFF121212),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0xFF424242),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      )
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Centered Placeholder Text and Icon
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.wallpaper_rounded,
                              size: 48,
                              color: const Color(0xFFFFD700).withValues(alpha: 0.6),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Tap to Preview',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'No background image selected',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.4),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Top Right Expand Icon Indicator
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.fullscreen_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Section 2: Tab Bar (5 tabs)
            TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: _tabs.map((tabName) => Tab(text: tabName)).toList(),
            ),
            // Section 3: Tab Content Area (fills remaining space)
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: _tabs.map((tabName) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _getTabIcon(tabName),
                          size: 40,
                          color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$tabName Tab Placeholder',
                          style: const TextStyle(
                            color: Color(0xFFB0B0B0),
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getTabIcon(String tabName) {
    switch (tabName) {
      case 'Basics':
        return Icons.tune_rounded;
      case 'Typography':
        return Icons.text_fields_rounded;
      case 'Effects':
        return Icons.auto_awesome_rounded;
      case 'Transform':
        return Icons.transform_rounded;
      case 'Date':
        return Icons.calendar_today_rounded;
      default:
        return Icons.star_rounded;
    }
  }
}
