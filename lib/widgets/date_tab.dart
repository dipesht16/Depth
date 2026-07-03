import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/wallpaper_config.dart';

class DateTab extends StatelessWidget {
  final WallpaperConfig config;
  final ValueChanged<WallpaperConfig> onConfigChanged;
  final bool isEnabled;

  const DateTab({
    super.key,
    required this.config,
    required this.onConfigChanged,
    required this.isEnabled,
  });

  void _update(WallpaperConfig updated) {
    HapticFeedback.selectionClick();
    onConfigChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Show Date toggle
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(12),
          ),
          child: SwitchListTile(
            title: Text(
              'Show Date',
              style: TextStyle(
                color: isEnabled ? Colors.white : Colors.grey,
                fontSize: 16,
              ),
            ),
            subtitle: Text(
              'Display date below the clock',
              style: TextStyle(
                color: isEnabled ? const Color(0xFF757575) : Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
            value: config.showDate,
            activeThumbColor: const Color(0xFFFFD700),
            onChanged: isEnabled ? (val) => _update(config.copyWith(showDate: val)) : null,
          ),
        ),
        const SizedBox(height: 24),

        // Sliders — grayed out when showDate is false
        Opacity(
          opacity: config.showDate && isEnabled ? 1.0 : 0.35,
          child: AbsorbPointer(
            absorbing: !config.showDate || !isEnabled,
            child: Column(
              children: [
                _buildSlider(
                  label: 'Font Size',
                  value: config.dateFontSize,
                  min: 0.01,
                  max: 0.1,
                  display: '${(config.dateFontSize * 100).toStringAsFixed(1)}%',
                  onChanged: (v) => _update(config.copyWith(dateFontSize: v)),
                ),
                const SizedBox(height: 24),
                _buildSlider(
                  label: 'Horizontal Position',
                  value: config.dateHorizontalPos,
                  min: 0.0,
                  max: 1.0,
                  display: '${(config.dateHorizontalPos * 100).toStringAsFixed(0)}%',
                  onChanged: (v) => _update(config.copyWith(dateHorizontalPos: v)),
                ),
                const SizedBox(height: 24),
                _buildSlider(
                  label: 'Vertical Position',
                  value: config.dateVerticalPos,
                  min: 0.0,
                  max: 1.0,
                  display: '${(config.dateVerticalPos * 100).toStringAsFixed(0)}%',
                  onChanged: (v) => _update(config.copyWith(dateVerticalPos: v)),
                ),
              ],
            ),
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

  Widget _buildSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required String display,
    required ValueChanged<double> onChanged,
  }) {
    double prevValue = value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Color(0xFFB0B0B0), fontSize: 14)),
            Text(display, style: const TextStyle(color: Color(0xFFFFD700), fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: const SliderThemeData(
            trackHeight: 4,
            activeTrackColor: Color(0xFFFFD700),
            inactiveTrackColor: Color(0xFF424242),
            thumbColor: Color(0xFFFFD700),
            overlayColor: Color(0x33FFD700),
            thumbShape: RoundSliderThumbShape(enabledThumbRadius: 10),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            onChanged: (v) {
              final pct = ((v - min) / (max - min) * 100).round();
              final prevPct = ((prevValue - min) / (max - min) * 100).round();
              if (pct != prevPct) HapticFeedback.selectionClick();
              prevValue = v;
              onChanged(v);
            },
          ),
        ),
      ],
    );
  }
}
