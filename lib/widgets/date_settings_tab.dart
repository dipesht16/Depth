import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/wallpaper_config.dart';

class DateSettingsTab extends StatelessWidget {
  final WallpaperConfig config;
  final ValueChanged<WallpaperConfig> onConfigChanged;
  final bool isEnabled;

  const DateSettingsTab({
    super.key,
    required this.config,
    required this.onConfigChanged,
    required this.isEnabled,
  });

  void _update(WallpaperConfig updated) {
    HapticFeedback.selectionClick();
    onConfigChanged(updated);
  }

  static const List<Color> _swatchColors = [
    Colors.white,
    Color(0xFFFFD700), // Yellow
    Color(0xFF64B5F6), // Blue
    Color(0xFFA5D6A7), // Green
    Color(0xFFEF9A9A), // Red
    Color(0xFFCE93D8), // Purple
    Color(0xFFFFCC80), // Orange
    Color(0xFF80DEEA), // Cyan
  ];

  static const List<Map<String, String>> _formats = [
    {'value': 'EEE, MMM dd', 'preview': 'Mon, Jan 15'},
    {'value': 'MMM dd, yyyy', 'preview': 'Jan 15, 2024'},
    {'value': 'dd/MM/yyyy', 'preview': '15/01/2024'},
    {'value': 'MM-dd-yyyy', 'preview': '01-15-2024'},
    {'value': 'EEEE, MMMM dd', 'preview': 'Monday, January 15'},
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Font Color
        _buildSectionHeader('Font Color', onReset: isEnabled ? () => _update(config.copyWith(dateColor: Colors.white)) : null),
        const SizedBox(height: 12),
        Opacity(
          opacity: isEnabled ? 1.0 : 0.5,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: _swatchColors.map((color) {
              final isSelected = config.dateColor.toARGB32() == color.toARGB32();
              return GestureDetector(
                onTap: isEnabled ? () => _update(config.copyWith(dateColor: color)) : null,
                child: Container(
                  width: 36,
                  height: 36,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                    border: Border.all(
                      color: isSelected ? const Color(0xFFFFD700) : Colors.transparent,
                      width: 3,
                    ),
                  ),
                  child: isSelected
                      ? Icon(Icons.check, size: 18, color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white)
                      : null,
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 28),

        // Date Format
        _buildSectionHeader('Date Format', onReset: isEnabled ? () => _update(config.copyWith(dateFormat: 'EEE, MMM dd')) : null),
        const SizedBox(height: 12),
        Opacity(
          opacity: isEnabled ? 1.0 : 0.5,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _formats.map((fmt) {
              final isSelected = config.dateFormat == fmt['value'];
              return ChoiceChip(
                label: Text(
                  fmt['preview']!,
                  style: TextStyle(
                    color: isSelected ? Colors.black : const Color(0xFFB0B0B0),
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                selected: isSelected,
                onSelected: isEnabled ? (_) => _update(config.copyWith(dateFormat: fmt['value'])) : null,
                selectedColor: const Color(0xFFFFD700),
                backgroundColor: const Color(0xFF2C2C2C),
                side: BorderSide(color: isSelected ? const Color(0xFFFFD700) : const Color(0xFF424242)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 28),

        // Text Style toggles
        _buildSectionHeader('Text Style'),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              SwitchListTile(
                title: Text(
                  'All Caps',
                  style: TextStyle(
                    color: isEnabled ? Colors.white : Colors.grey,
                    fontSize: 15,
                  ),
                ),
                subtitle: Text(
                  'MON, JAN 15',
                  style: TextStyle(
                    color: isEnabled ? const Color(0xFF757575) : Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
                value: config.dateAllCaps,
                activeThumbColor: const Color(0xFFFFD700),
                onChanged: isEnabled ? (val) => _update(config.copyWith(dateAllCaps: val)) : null,
              ),
              const Divider(color: Color(0xFF2C2C2C), height: 1),
              SwitchListTile(
                title: Text(
                  'Bold Text',
                  style: TextStyle(
                    color: isEnabled ? Colors.white : Colors.grey,
                    fontSize: 15,
                  ),
                ),
                subtitle: Text(
                  'Heavier font weight',
                  style: TextStyle(
                    color: isEnabled ? const Color(0xFF757575) : Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
                value: config.dateBold,
                activeThumbColor: const Color(0xFFFFD700),
                onChanged: isEnabled ? (val) => _update(config.copyWith(dateBold: val)) : null,
              ),
            ],
          ),
        ),

        if (!isEnabled) ...[
          const SizedBox(height: 32),
          Center(
            child: Text(
              'Please select an image to unlock controls',
              style: TextStyle(
                color: const Color(0xFFFFD700).withValues(alpha: 0.6),
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onReset}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
        if (onReset != null)
          GestureDetector(
            onTap: onReset,
            child: const Icon(Icons.restore_rounded, color: Color(0xFF757575), size: 18),
          ),
      ],
    );
  }
}
