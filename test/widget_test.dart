import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallpaper/main.dart';

void main() {
  testWidgets('App opens and shows Home Screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const DepthWallpaperApp());

    // Verify that the title is displayed.
    expect(find.text('Depth Wallpaper'), findsOneWidget);

    // Verify that the empty state is displayed.
    expect(find.text('Create Your First Depth Wallpaper'), findsOneWidget);

    // Verify the FAB is present.
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });
}
