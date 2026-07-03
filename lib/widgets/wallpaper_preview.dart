import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/wallpaper_data.dart';
import '../models/wallpaper_config.dart';
import 'package:google_fonts/google_fonts.dart';

class WallpaperPreview extends StatelessWidget {
  final WallpaperData data;
  final WallpaperConfig config;
  final bool showFrame;

  const WallpaperPreview({
    super.key,
    required this.data,
    required this.config,
    this.showFrame = true,
  });

  @override
  Widget build(BuildContext context) {
    // Core preview area containing the multi-layer Stack
    final Widget previewArea = LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final double height = constraints.maxHeight;

        // Dynamic cache width to prevent OOM crash on high-res photos
        // We decode at 2x constraints width to support high-DPI retina screens crispness
        final int targetCacheWidth = (width * 2.0).toInt();

        // Position coordinates based on container dimensions
        final double clockY = config.verticalPos * height;
        final double clockFontSize = config.fontSize * width;

        // Base text style configuration
        final TextStyle baseClockStyle = TextStyle(
          fontSize: clockFontSize,
          fontWeight: FontWeight.bold,
          color: config.fontColor,
          letterSpacing: config.letterSpacing * clockFontSize,
          shadows: config.shadowEnabled
              ? [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    offset: const Offset(0, 4),
                    blurRadius: 8,
                  ),
                ]
              : null,
        );

        // Apply Google Fonts dynamically if not system default Roboto
        TextStyle clockStyle;
        if (config.fontFamily == 'Roboto') {
          clockStyle = baseClockStyle.copyWith(fontFamily: 'Roboto');
        } else {
          try {
            clockStyle = GoogleFonts.getFont(
              config.fontFamily,
              textStyle: baseClockStyle,
            );
          } catch (e) {
            clockStyle = baseClockStyle.copyWith(fontFamily: config.fontFamily);
          }
        }

        // Build combined Matrix4 for transformations
        final Matrix4 transformMatrix = Matrix4.identity();

        // 1. Apply skews
        if (config.horizontalSkew != 0.0) {
          transformMatrix.setEntry(0, 1, config.horizontalSkew);
        }
        if (config.verticalSkew != 0.0) {
          transformMatrix.setEntry(1, 0, config.verticalSkew);
        }
        if (config.bottomSkewH != 0.0) {
          transformMatrix.setEntry(0, 1, transformMatrix.entry(0, 1) + config.bottomSkewH * 0.5);
        }
        if (config.leftSkew != 0.0) {
          transformMatrix.setEntry(1, 0, transformMatrix.entry(1, 0) + config.leftSkew * 0.5);
        }

        // 2. Apply stretch (Y-scaling)
        if (config.stretch != 1.0) {
          transformMatrix.setEntry(1, 1, config.stretch);
        }

        // 3. Apply rotation
        if (config.rotation != 0.0) {
          final double radians = config.rotation * 3.141592653589793 / 180.0;
          transformMatrix.rotateZ(radians);
        }

        // Clock layers list to compile stroke and fill
        final List<Widget> clockLayers = [];

        // 1. Draw outline/stroke layer if enabled
        if (config.edgeStrokeEnabled || config.strokeEnabled) {
          final double strokeWidth = (config.strokeEnabled ? 6.0 : 0.0) + (config.edgeStrokeEnabled ? 2.0 : 0.0);
          clockLayers.add(
            Text(
              '12:30', // Static time for Module 4 preview validation
              textAlign: TextAlign.center,
              style: clockStyle.copyWith(
                color: null, // Clear color to let foreground paint take effect
                foreground: Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = strokeWidth
                  ..color = Colors.black87,
              ),
            ),
          );
        }

        // 2. Draw fill layer (the main text)
        clockLayers.add(
          Text(
            '12:30', // Static time for Module 4 preview validation
            textAlign: TextAlign.center,
            style: clockStyle,
          ),
        );

        // Positioned Clock Widget (Layer 2)
        // Positioned horizontally centered by default, shifted by config.horizontalPos slide offset
        final Widget clockWidget = Positioned(
          left: 0,
          right: 0,
          top: clockY,
          child: Transform.translate(
            // Shift offset: map 0.0 -> -width/2, 0.5 -> 0.0, 1.0 -> width/2
            offset: Offset((config.horizontalPos - 0.48) * width * 2, 0),
            child: Center(
              child: Opacity(
                opacity: config.textOpacity,
                child: Transform(
                  transform: transformMatrix,
                  alignment: Alignment.center,
                  child: Stack(
                    alignment: Alignment.center,
                    children: clockLayers,
                  ),
                ),
              ),
            ),
          ),
        );

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Layer 1: Background Image (or black background placeholder)
            if (data.originalImagePath != null)
              Positioned.fill(
                child: Image.file(
                  File(data.originalImagePath!),
                  fit: BoxFit.cover,
                  cacheWidth: targetCacheWidth > 0 ? targetCacheWidth : null,
                ),
              )
            else
              Positioned.fill(
                child: Container(
                  color: const Color(0xFF121212),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.wallpaper_rounded,
                          size: 48,
                          color: const Color(0xFFFFD700).withValues(alpha: 0.6),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Tap Gallery Icon',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'to select background image',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFFB0B0B0),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Layer 2: Positioned Clock (only rendered when background is loaded)
            if (data.originalImagePath != null) clockWidget,

            // Layer 3a: Foreground subject drop shadow (for 3D depth separation / uplift effect)
            if (data.originalImagePath != null && data.foregroundImagePath != null)
              Positioned.fill(
                child: Transform.translate(
                  // Shift shadow down and right for realistic depth lighting
                  offset: Offset(width * 0.015, width * 0.025),
                  child: ImageFiltered(
                    // Soften the shadow using a responsive Gaussian blur
                    imageFilter: ui.ImageFilter.blur(
                      sigmaX: width * 0.02,
                      sigmaY: width * 0.02,
                    ),
                    child: Image.file(
                      File(data.foregroundImagePath!),
                      fit: BoxFit.cover,
                      color: Colors.black.withValues(alpha: 0.55),
                      colorBlendMode: BlendMode.srcIn,
                      cacheWidth: targetCacheWidth > 0 ? targetCacheWidth : null,
                    ),
                  ),
                ),
              ),

            // Layer 3b: Foreground transparent cutout subject (actual subject)
            if (data.originalImagePath != null && data.foregroundImagePath != null)
              Positioned.fill(
                child: Image.file(
                  File(data.foregroundImagePath!),
                  fit: BoxFit.cover,
                  cacheWidth: targetCacheWidth > 0 ? targetCacheWidth : null,
                ),
              ),

            // Layer 4: Date widget (always on top of foreground — HUD element)
            if (config.showDate)
              Positioned(
                left: config.dateHorizontalPos * width,
                top: config.dateVerticalPos * height,
                child: Text(
                  _getFormattedDate(config.dateFormat, config.dateAllCaps),
                  style: TextStyle(
                    fontSize: config.dateFontSize * width,
                    color: config.dateColor,
                    fontWeight: config.dateBold ? FontWeight.bold : FontWeight.normal,
                    shadows: const [
                      Shadow(
                        color: Colors.black54,
                        offset: Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );

    if (showFrame) {
      return AspectRatio(
        aspectRatio: 9 / 19.5, // Standard smartphone ratio
        child: Container(
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
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22), // Fit within border
            child: previewArea,
          ),
        ),
      );
    } else {
      return previewArea;
    }
  }

  String _getFormattedDate(String format, bool allCaps) {
    try {
      final dateStr = DateFormat(format).format(DateTime.now());
      return allCaps ? dateStr.toUpperCase() : dateStr;
    } catch (_) {
      final fallback = DateFormat('EEE, MMM dd').format(DateTime.now());
      return allCaps ? fallback.toUpperCase() : fallback;
    }
  }
}
