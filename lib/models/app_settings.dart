import 'package:shared_preferences/shared_preferences.dart';

/// App-wide preferences stored in SharedPreferences.
class AppSettings {
  final String qualityPreset; // 'high' | 'balanced' | 'battery_saver'
  final bool updateEveryMinute;
  final bool use24Hour;
  final bool showGrid;
  final bool hasSeenOnboarding;

  const AppSettings({
    this.qualityPreset = 'balanced',
    this.updateEveryMinute = true,
    this.use24Hour = true,
    this.showGrid = false,
    this.hasSeenOnboarding = false,
  });

  static Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return AppSettings(
      qualityPreset: prefs.getString('quality_preset') ?? 'balanced',
      updateEveryMinute: prefs.getBool('update_every_minute') ?? true,
      use24Hour: prefs.getBool('use_24hour') ?? true,
      showGrid: prefs.getBool('show_grid') ?? false,
      hasSeenOnboarding: prefs.getBool('has_seen_onboarding') ?? false,
    );
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('quality_preset', qualityPreset);
    await prefs.setBool('update_every_minute', updateEveryMinute);
    await prefs.setBool('use_24hour', use24Hour);
    await prefs.setBool('show_grid', showGrid);
    await prefs.setBool('has_seen_onboarding', hasSeenOnboarding);
  }

  AppSettings copyWith({
    String? qualityPreset,
    bool? updateEveryMinute,
    bool? use24Hour,
    bool? showGrid,
    bool? hasSeenOnboarding,
  }) {
    return AppSettings(
      qualityPreset: qualityPreset ?? this.qualityPreset,
      updateEveryMinute: updateEveryMinute ?? this.updateEveryMinute,
      use24Hour: use24Hour ?? this.use24Hour,
      showGrid: showGrid ?? this.showGrid,
      hasSeenOnboarding: hasSeenOnboarding ?? this.hasSeenOnboarding,
    );
  }
}
