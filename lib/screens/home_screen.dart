import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/wallpaper_project.dart';
import '../services/project_repository.dart';
import '../widgets/project_card.dart';
import '../widgets/slide_page_route.dart';
import 'studio_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ProjectRepository _repo = ProjectRepository();
  List<WallpaperProject> _projects = [];
  bool _isLoading = true;
  String _sortMode = 'recent'; // 'recent' | 'name'

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    final list = await _repo.getAllProjects();
    if (!mounted) return;
    setState(() {
      _projects = list;
      if (_sortMode == 'name') {
        _projects.sort((a, b) => a.name.compareTo(b.name));
      }
      _isLoading = false;
    });
  }

  Future<void> _deleteProject(WallpaperProject project) async {
    // Confirm dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Delete Project',
            style: TextStyle(color: Colors.white)),
        content: Text(
          "Delete \"${project.name}\"?\nThis cannot be undone.",
          style: const TextStyle(color: Color(0xFFB0B0B0)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFFB0B0B0))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      HapticFeedback.mediumImpact();
      await _repo.deleteProject(project.id);
      _loadProjects();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Project deleted'),
            backgroundColor: Color(0xFF1E1E1E),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _duplicateProject(WallpaperProject project) async {
    setState(() => _isLoading = true);
    await _repo.duplicateProject(project);
    HapticFeedback.selectionClick();
    await _loadProjects();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Project duplicated'),
          backgroundColor: Color(0xFF1E1E1E),
        ),
      );
    }
  }

  void _openStudio({WallpaperProject? project}) {
    Navigator.of(context)
        .push(SlidePageRoute(
          child: StudioScreen(project: project),
        ))
        .then((_) => _loadProjects());
  }

  Future<void> _setActiveWallpaper(WallpaperProject project) async {
    await _repo.setActive(project.id);
    _loadProjects();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('"${project.name}" marked as active wallpaper'),
          backgroundColor: const Color(0xFF1E1E1E),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.layers_rounded,
                color: Color(0xFFFFD700), size: 22),
            const SizedBox(width: 10),
            const Text(
              'Depth Wallpaper',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded,
                color: Color(0xFFB0B0B0)),
            tooltip: 'Settings',
            onPressed: () => Navigator.of(context).push(
              SlidePageRoute(child: const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                  color: Color(0xFFFFD700)))
          : Column(
              children: [
                // Sort row + count
                if (_projects.isNotEmpty) _buildSortRow(),

                // Content
                Expanded(
                  child: _projects.isEmpty
                      ? _buildEmptyState()
                      : _buildProjectGrid(),
                ),
              ],
            ),

      // FAB — Create new (round button with only + icon to prevent clipping glitched text)
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openStudio(),
        backgroundColor: const Color(0xFFFFD700),
        foregroundColor: Colors.black,
        shape: const CircleBorder(),
        tooltip: 'Create New Wallpaper',
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }

  Widget _buildSortRow() {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            'My Wallpapers (${_projects.length})',
            style: const TextStyle(
                color: Color(0xFFB0B0B0),
                fontSize: 13,
                fontWeight: FontWeight.w500),
          ),
          const Spacer(),
          PopupMenuButton<String>(
            color: const Color(0xFF1E1E1E),
            icon: const Icon(Icons.sort_rounded,
                color: Color(0xFFB0B0B0), size: 20),
            onSelected: (val) {
              setState(() => _sortMode = val);
              _loadProjects();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'recent',
                child: Text('Recent',
                    style: TextStyle(color: Colors.white)),
              ),
              const PopupMenuItem(
                value: 'name',
                child: Text('Name',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProjectGrid() {
    return GridView.builder(
      padding:
          const EdgeInsets.fromLTRB(16, 4, 16, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.55, // ~9:19.5 thumbnail + name
      ),
      itemCount: _projects.length,
      itemBuilder: (_, index) {
        final project = _projects[index];
        return ProjectCard(
          key: ValueKey(project.id),
          project: project,
          index: index,
          onTap: () => _openStudio(project: project),
          onEdit: () => _openStudio(project: project),
          onDuplicate: () => _duplicateProject(project),
          onDelete: () => _deleteProject(project),
          onSetWallpaper: () => _setActiveWallpaper(project),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Glowing icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF121212),
                shape: BoxShape.circle,
                border: Border.all(
                    color:
                        const Color(0xFFFFD700).withValues(alpha: 0.5),
                    width: 2),
                boxShadow: [
                  BoxShadow(
                    color:
                        const Color(0xFFFFD700).withValues(alpha: 0.12),
                    blurRadius: 24,
                    spreadRadius: 6,
                  )
                ],
              ),
              child: const Icon(Icons.wallpaper_rounded,
                  size: 44, color: Color(0xFFFFD700)),
            ),
            const SizedBox(height: 28),
            const Text(
              'No Wallpapers Yet',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Create your first depth wallpaper\nto get started.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Color(0xFFB0B0B0),
                  fontSize: 14,
                  height: 1.5),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _openStudio(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create Wallpaper',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ],
        ),
      ),
    );
  }
}
