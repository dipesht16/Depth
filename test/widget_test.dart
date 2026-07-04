import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wallpaper/models/app_settings.dart';
import 'package:wallpaper/models/wallpaper_config.dart';
import 'package:wallpaper/models/wallpaper_project.dart';
import 'package:wallpaper/services/project_repository.dart';
import 'package:wallpaper/screens/mask_editor_screen.dart';
import 'package:wallpaper/widgets/project_card.dart';
import 'package:wallpaper/screens/home_screen.dart';
import 'package:wallpaper/screens/onboarding_screen.dart';
import 'package:wallpaper/screens/settings_screen.dart';

void main() {
  setUpAll(() async {
    // Set up mock method channels for SharedPreferences
    SharedPreferences.setMockInitialValues({});
    
    // Initialize Hive in memory
    Hive.init('.');
    await ProjectRepository.init();
  });

  tearDownAll(() async {
    await Hive.deleteBoxFromDisk('projects');
    await Hive.close();
  });

  tearDown(() async {
    final box = Hive.box<Map>('projects');
    await box.clear();
  });

  group('Model Serialization Tests', () {
    test('WallpaperConfig serialization and defaults', () {
      final config = WallpaperConfig();
      expect(config.fontSize, 0.24);
      expect(config.clockFormat, 'HH:MM');
      expect(config.showDate, false);

      final json = config.toJson();
      expect(json['fontSize'], 0.24);
      expect(json['clockFormat'], 'HH:MM');
      expect(json['showDate'], false);

      final restored = WallpaperConfig.fromJson(json);
      expect(restored.fontSize, 0.24);
      expect(restored.clockFormat, 'HH:MM');
      expect(restored.showDate, false);
    });

    test('WallpaperConfig custom parameters serialization', () {
      final config = WallpaperConfig(
        fontSize: 0.35,
        clockFormat: 'HH:MM:SS',
        showDate: true,
        dateFontSize: 0.05,
        dateBold: true,
      );
      final json = config.toJson();
      final restored = WallpaperConfig.fromJson(json);
      expect(restored.fontSize, 0.35);
      expect(restored.clockFormat, 'HH:MM:SS');
      expect(restored.showDate, true);
      expect(restored.dateFontSize, 0.05);
      expect(restored.dateBold, true);
    });

    test('WallpaperProject map serialization', () {
      final now = DateTime.now();
      final project = WallpaperProject(
        id: 'test_id',
        name: 'Sunset',
        createdAt: now,
        modifiedAt: now,
        configJson: jsonEncode(WallpaperConfig().toJson()),
      );

      final map = project.toMap();
      expect(map['id'], 'test_id');
      expect(map['name'], 'Sunset');

      final restored = WallpaperProject.fromMap(map);
      expect(restored.id, 'test_id');
      expect(restored.name, 'Sunset');
      expect(restored.config.fontSize, 0.24);
    });

    test('AppSettings shared preferences backup', () async {
      const settings = AppSettings(
        qualityPreset: 'high',
        showGrid: true,
        updateEveryMinute: false,
      );
      await settings.save();

      final loaded = await AppSettings.load();
      expect(loaded.qualityPreset, 'high');
      expect(loaded.showGrid, true);
      expect(loaded.updateEveryMinute, false);
    });
  });

  group('ProjectRepository CRUD Tests', () {
    final repo = ProjectRepository();

    test('Save and retrieve projects', () async {
      final now = DateTime.now();
      final project = WallpaperProject(
        id: 'proj_1',
        name: 'Project 1',
        createdAt: now,
        modifiedAt: now,
        configJson: jsonEncode(WallpaperConfig().toJson()),
      );

      await repo.saveProject(project);

      final list = await repo.getAllProjects();
      expect(list.length, 1);
      expect(list.first.id, 'proj_1');
      expect(list.first.name, 'Project 1');
    });

    test('Active project flag management', () async {
      final now = DateTime.now();
      final p1 = WallpaperProject(
        id: 'p1',
        name: 'P1',
        createdAt: now,
        modifiedAt: now,
        configJson: jsonEncode(WallpaperConfig().toJson()),
      );
      final p2 = WallpaperProject(
        id: 'p2',
        name: 'P2',
        createdAt: now,
        modifiedAt: now,
        configJson: jsonEncode(WallpaperConfig().toJson()),
      );

      await repo.saveProject(p1);
      await repo.saveProject(p2);

      await repo.setActive('p2');

      final active = await repo.getActiveProject();
      expect(active, isNotNull);
      expect(active!.id, 'p2');

      final updatedList = await repo.getAllProjects();
      final activeCount = updatedList.where((p) => p.isActive).length;
      expect(activeCount, 1);
    });

    test('Delete project operations', () async {
      final now = DateTime.now();
      final p = WallpaperProject(
        id: 'to_delete',
        name: 'Delete Me',
        createdAt: now,
        modifiedAt: now,
        configJson: jsonEncode(WallpaperConfig().toJson()),
      );

      await repo.saveProject(p);
      var list = await repo.getAllProjects();
      expect(list.length, 1);

      await repo.deleteProject('to_delete');
      list = await repo.getAllProjects();
      expect(list.length, 0);
    });
  });

  group('UI & Screen Widget Tests', () {
    testWidgets('OnboardingScreen navigation slides and Skip action',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: OnboardingScreen(),
      ));
      await tester.pumpAndSettle();

      // Verify page 1 content is visible
      expect(find.textContaining('Create iOS-Style'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);

      // Tap Next to navigate through slides
      expect(find.text('Next'), findsOneWidget);
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Verify page 2 content is loaded
      expect(find.text('Select Any Photo'), findsOneWidget);

      // Tap Skip to exit onboarding
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();
    });

    testWidgets('HomeScreen empty state presentation and circular FAB',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: HomeScreen(),
      ));
      await tester.pump(); // Start async retrieval

      // HomeScreen shows empty state by default when database is clean
      expect(find.text('No Wallpapers Yet'), findsOneWidget);
      expect(find.text('Create Wallpaper'), findsOneWidget);

      // Verify circular FAB design
      final fabFinder = find.byType(FloatingActionButton);
      expect(fabFinder, findsOneWidget);
      
      final FloatingActionButton fab = tester.widget(fabFinder);
      expect(fab.shape, const CircleBorder());
      expect(fab.child, isA<Icon>());
      expect((fab.child as Icon).icon, Icons.add_rounded);
    });

    testWidgets('SettingsScreen quality toggles and display switches',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(const MaterialApp(
        home: SettingsScreen(),
      ));
      await tester.pump(const Duration(milliseconds: 200));
      
      // Verify layout headers
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('PERFORMANCE'), findsOneWidget);
      expect(find.text('CLOCK UPDATES'), findsOneWidget);

      // Verify list options are rendered
      expect(find.text('High Quality'), findsOneWidget);
      expect(find.text('Balanced'), findsOneWidget);
      expect(find.text('Battery Saver'), findsOneWidget);

      // Verify switch list tile exists
      expect(find.text('Update Every Minute'), findsOneWidget);
      expect(find.text('Show Grid in Preview'), findsOneWidget);

      // Drag ListView up (scroll down) to reveal lower options
      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pump();

      // Verify cache and reset options are now built and visible
      expect(find.text('Clear Cache'), findsOneWidget);
      expect(find.text('Reset All Settings'), findsOneWidget);
    });

    testWidgets('ProjectCard custom staggered animations and active badges',
        (WidgetTester tester) async {
      final now = DateTime.now();
      final project = WallpaperProject(
        id: 'card_test',
        name: 'Autumn Vibe',
        createdAt: now,
        modifiedAt: now,
        isActive: true,
        configJson: jsonEncode(WallpaperConfig().toJson()),
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ProjectCard(
            project: project,
            index: 0,
            onTap: () {},
            onEdit: () {},
            onDuplicate: () {},
            onDelete: () {},
            onSetWallpaper: () {},
          ),
        ),
      ));

      await tester.pumpAndSettle();

      // Verify card layout details
      expect(find.text('Autumn Vibe'), findsOneWidget);
      expect(find.text('ACTIVE'), findsOneWidget);
      expect(find.byIcon(Icons.more_vert_rounded), findsOneWidget);
    });

    test('Mask Editor DrawingStroke model and configurations', () {
      final stroke = DrawingStroke(
        points: [const Offset(10.0, 15.0), const Offset(20.0, 25.0)],
        brushSize: 12.0,
        isErase: true,
      );

      expect(stroke.points.length, 2);
      expect(stroke.points.first.dx, 10.0);
      expect(stroke.points.first.dy, 15.0);
      expect(stroke.brushSize, 12.0);
      expect(stroke.isErase, isTrue);
    });
  });
}
