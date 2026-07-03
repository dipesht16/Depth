import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/app_settings.dart';
import '../widgets/custom_app_bar.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  AppSettings _settings = const AppSettings();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final s = await AppSettings.load();
    if (!mounted) return;
    setState(() {
      _settings = s;
      _isLoading = false;
    });
  }

  Future<void> _update(AppSettings updated) async {
    HapticFeedback.selectionClick();
    await updated.save();
    if (!mounted) return;
    setState(() => _settings = updated);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: const CustomAppBar(title: 'Settings'),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFFD700)))
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                // ── Performance ──
                _sectionHeader('Performance'),
                _buildQualitySection(),

                // ── Clock Updates ──
                _sectionHeader('Clock Updates'),
                _buildSwitchTile(
                  title: 'Update Every Minute',
                  subtitle: 'Clock redraws every 60 seconds',
                  value: _settings.updateEveryMinute,
                  onChanged: (v) =>
                      _update(_settings.copyWith(updateEveryMinute: v)),
                ),

                // ── Display ──
                _sectionHeader('Display'),
                _buildSwitchTile(
                  title: 'Show Grid in Preview',
                  subtitle: 'Overlay 3×3 grid for positioning',
                  value: _settings.showGrid,
                  onChanged: (v) =>
                      _update(_settings.copyWith(showGrid: v)),
                ),

                // ── Data & Storage ──
                _sectionHeader('Data & Storage'),
                _buildActionTile(
                  icon: Icons.delete_sweep_rounded,
                  title: 'Clear Cache',
                  subtitle: 'Remove temporary files',
                  onTap: _clearCache,
                ),
                _buildActionTile(
                  icon: Icons.restart_alt_rounded,
                  title: 'Reset All Settings',
                  subtitle: 'Restore defaults',
                  onTap: _resetSettings,
                  isDestructive: true,
                ),

                // ── About ──
                _sectionHeader('About'),
                _buildInfoTile('Version', '1.0.0'),
                _buildInfoTile('Package', 'com.yourcompany.depthwallpaper'),
                const SizedBox(height: 40),
              ],
            ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFFFFD700),
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildQualitySection() {
    final options = [
      ('high', 'High Quality', '4K rendering, higher battery'),
      ('balanced', 'Balanced', '1080p rendering (recommended)'),
      ('battery_saver', 'Battery Saver', '720p, minimal updates'),
    ];
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: options.map((opt) {
          final isSelected = _settings.qualityPreset == opt.$1;
          return ListTile(
            leading: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFFFD700)
                      : const Color(0xFF424242),
                  width: 2,
                ),
                color: isSelected
                    ? const Color(0xFFFFD700)
                    : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check_rounded,
                      size: 14, color: Colors.black)
                  : null,
            ),
            title: Text(opt.$2,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFFB0B0B0),
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
                )),
            subtitle: Text(opt.$3,
                style: const TextStyle(
                    color: Color(0xFF757575), fontSize: 12)),
            onTap: () => _update(_settings.copyWith(qualityPreset: opt.$1)),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: SwitchListTile(
        title: Text(title,
            style: const TextStyle(color: Colors.white, fontSize: 15)),
        subtitle: Text(subtitle,
            style: const TextStyle(
                color: Color(0xFF757575), fontSize: 12)),
        value: value,
        activeThumbColor: const Color(0xFFFFD700),
        activeTrackColor: const Color(0xFFFFD700).withValues(alpha: 0.3),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? Colors.redAccent : Colors.white;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: Icon(icon, color: color, size: 22),
        title: Text(title,
            style: TextStyle(
                color: color,
                fontSize: 15,
                fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle,
            style: const TextStyle(
                color: Color(0xFF757575), fontSize: 12)),
        onTap: onTap,
      ),
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        title: Text(label,
            style: const TextStyle(color: Colors.white, fontSize: 15)),
        trailing: Text(value,
            style: const TextStyle(
                color: Color(0xFF757575), fontSize: 13)),
      ),
    );
  }

  Future<void> _clearCache() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Clear Cache',
            style: TextStyle(color: Colors.white)),
        content: const Text(
            'This will remove temporary cached files.',
            style: TextStyle(color: Color(0xFFB0B0B0))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel',
                  style: TextStyle(color: Color(0xFFB0B0B0)))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Clear',
                  style: TextStyle(color: Color(0xFFFFD700)))),
        ],
      ),
    );
    if (ok == true && mounted) {
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Cache cleared'),
            backgroundColor: Color(0xFF1E1E1E)),
      );
    }
  }

  Future<void> _resetSettings() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Reset Settings',
            style: TextStyle(color: Colors.white)),
        content: const Text('All customizations will be lost.',
            style: TextStyle(color: Color(0xFFB0B0B0))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel',
                  style: TextStyle(color: Color(0xFFB0B0B0)))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Reset',
                  style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
    if (ok == true) {
      await _update(const AppSettings());
    }
  }
}
