import 'package:flutter/material.dart';

class WallpaperConfig {
  final double fontSize;
  final double horizontalPos;
  final double verticalPos;
  final String clockFormat;
  final Color fontColor;
  final String fontFamily;

  // Placeholder and Advanced properties for future modules
  final double letterSpacing;
  final double textOpacity;
  final bool shadowEnabled;
  final double rotation; // in degrees
  final double stretch; // Y scale factor
  final double horizontalSkew;
  final double verticalSkew;
  final double bottomSkewH;
  final double leftSkew;
  final Color? secondaryColor;
  final String depthMode;
  final bool atmosphericDepthEnabled;
  final bool edgeStrokeEnabled;
  final bool strokeEnabled;

  // Date Widget properties
  final bool showDate;
  final double dateFontSize;
  final double dateHorizontalPos;
  final double dateVerticalPos;
  final Color dateColor;
  final String dateFormat;
  final bool dateAllCaps;
  final bool dateBold;

  WallpaperConfig({
    this.fontSize = 0.24,
    this.horizontalPos = 0.48,
    this.verticalPos = 0.24,
    this.clockFormat = 'HH:MM',
    this.fontColor = Colors.white,
    this.fontFamily = 'Roboto',
    this.letterSpacing = 0.0,
    this.textOpacity = 1.0,
    this.shadowEnabled = true,
    this.rotation = 0.0,
    this.stretch = 1.0,
    this.horizontalSkew = 0.0,
    this.verticalSkew = 0.0,
    this.bottomSkewH = 0.0,
    this.leftSkew = 0.0,
    this.secondaryColor,
    this.depthMode = 'Standard',
    this.atmosphericDepthEnabled = false,
    this.edgeStrokeEnabled = false,
    this.strokeEnabled = false,
    // Date Widget defaults
    this.showDate = false,
    this.dateFontSize = 0.034,
    this.dateHorizontalPos = 0.78,
    this.dateVerticalPos = 0.11,
    this.dateColor = Colors.white,
    this.dateFormat = 'EEE, MMM dd',
    this.dateAllCaps = true,
    this.dateBold = false,
  });

  // Helper method to clone with modifications
  WallpaperConfig copyWith({
    double? fontSize,
    double? horizontalPos,
    double? verticalPos,
    String? clockFormat,
    Color? fontColor,
    String? fontFamily,
    double? letterSpacing,
    double? textOpacity,
    bool? shadowEnabled,
    double? rotation,
    double? stretch,
    double? horizontalSkew,
    double? verticalSkew,
    double? bottomSkewH,
    double? leftSkew,
    Color? secondaryColor,
    String? depthMode,
    bool? atmosphericDepthEnabled,
    bool? edgeStrokeEnabled,
    bool? strokeEnabled,
    // Date Widget
    bool? showDate,
    double? dateFontSize,
    double? dateHorizontalPos,
    double? dateVerticalPos,
    Color? dateColor,
    String? dateFormat,
    bool? dateAllCaps,
    bool? dateBold,
  }) {
    return WallpaperConfig(
      fontSize: fontSize ?? this.fontSize,
      horizontalPos: horizontalPos ?? this.horizontalPos,
      verticalPos: verticalPos ?? this.verticalPos,
      clockFormat: clockFormat ?? this.clockFormat,
      fontColor: fontColor ?? this.fontColor,
      fontFamily: fontFamily ?? this.fontFamily,
      letterSpacing: letterSpacing ?? this.letterSpacing,
      textOpacity: textOpacity ?? this.textOpacity,
      shadowEnabled: shadowEnabled ?? this.shadowEnabled,
      rotation: rotation ?? this.rotation,
      stretch: stretch ?? this.stretch,
      horizontalSkew: horizontalSkew ?? this.horizontalSkew,
      verticalSkew: verticalSkew ?? this.verticalSkew,
      bottomSkewH: bottomSkewH ?? this.bottomSkewH,
      leftSkew: leftSkew ?? this.leftSkew,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      depthMode: depthMode ?? this.depthMode,
      atmosphericDepthEnabled: atmosphericDepthEnabled ?? this.atmosphericDepthEnabled,
      edgeStrokeEnabled: edgeStrokeEnabled ?? this.edgeStrokeEnabled,
      strokeEnabled: strokeEnabled ?? this.strokeEnabled,
      showDate: showDate ?? this.showDate,
      dateFontSize: dateFontSize ?? this.dateFontSize,
      dateHorizontalPos: dateHorizontalPos ?? this.dateHorizontalPos,
      dateVerticalPos: dateVerticalPos ?? this.dateVerticalPos,
      dateColor: dateColor ?? this.dateColor,
      dateFormat: dateFormat ?? this.dateFormat,
      dateAllCaps: dateAllCaps ?? this.dateAllCaps,
      dateBold: dateBold ?? this.dateBold,
    );
  }

  /// Serialize all fields to a flat JSON map for Hive storage.
  Map<String, dynamic> toJson() => {
        'fontSize': fontSize,
        'horizontalPos': horizontalPos,
        'verticalPos': verticalPos,
        'clockFormat': clockFormat,
        'fontColor': fontColor.toARGB32(),
        'fontFamily': fontFamily,
        'letterSpacing': letterSpacing,
        'textOpacity': textOpacity,
        'shadowEnabled': shadowEnabled,
        'rotation': rotation,
        'stretch': stretch,
        'horizontalSkew': horizontalSkew,
        'verticalSkew': verticalSkew,
        'bottomSkewH': bottomSkewH,
        'leftSkew': leftSkew,
        'depthMode': depthMode,
        'atmosphericDepthEnabled': atmosphericDepthEnabled,
        'edgeStrokeEnabled': edgeStrokeEnabled,
        'strokeEnabled': strokeEnabled,
        'showDate': showDate,
        'dateFontSize': dateFontSize,
        'dateHorizontalPos': dateHorizontalPos,
        'dateVerticalPos': dateVerticalPos,
        'dateColor': dateColor.toARGB32(),
        'dateFormat': dateFormat,
        'dateAllCaps': dateAllCaps,
        'dateBold': dateBold,
      };

  /// Restore a WallpaperConfig from a JSON map.
  factory WallpaperConfig.fromJson(Map<String, dynamic> j) => WallpaperConfig(
        fontSize: (j['fontSize'] as num?)?.toDouble() ?? 0.24,
        horizontalPos: (j['horizontalPos'] as num?)?.toDouble() ?? 0.48,
        verticalPos: (j['verticalPos'] as num?)?.toDouble() ?? 0.24,
        clockFormat: j['clockFormat'] as String? ?? 'HH:MM',
        fontColor: Color(j['fontColor'] as int? ?? 0xFFFFFFFF),
        fontFamily: j['fontFamily'] as String? ?? 'Roboto',
        letterSpacing: (j['letterSpacing'] as num?)?.toDouble() ?? 0.0,
        textOpacity: (j['textOpacity'] as num?)?.toDouble() ?? 1.0,
        shadowEnabled: j['shadowEnabled'] as bool? ?? true,
        rotation: (j['rotation'] as num?)?.toDouble() ?? 0.0,
        stretch: (j['stretch'] as num?)?.toDouble() ?? 1.0,
        horizontalSkew: (j['horizontalSkew'] as num?)?.toDouble() ?? 0.0,
        verticalSkew: (j['verticalSkew'] as num?)?.toDouble() ?? 0.0,
        bottomSkewH: (j['bottomSkewH'] as num?)?.toDouble() ?? 0.0,
        leftSkew: (j['leftSkew'] as num?)?.toDouble() ?? 0.0,
        depthMode: j['depthMode'] as String? ?? 'Standard',
        atmosphericDepthEnabled: j['atmosphericDepthEnabled'] as bool? ?? false,
        edgeStrokeEnabled: j['edgeStrokeEnabled'] as bool? ?? false,
        strokeEnabled: j['strokeEnabled'] as bool? ?? false,
        showDate: j['showDate'] as bool? ?? false,
        dateFontSize: (j['dateFontSize'] as num?)?.toDouble() ?? 0.034,
        dateHorizontalPos: (j['dateHorizontalPos'] as num?)?.toDouble() ?? 0.78,
        dateVerticalPos: (j['dateVerticalPos'] as num?)?.toDouble() ?? 0.11,
        dateColor: Color(j['dateColor'] as int? ?? 0xFFFFFFFF),
        dateFormat: j['dateFormat'] as String? ?? 'EEE, MMM dd',
        dateAllCaps: j['dateAllCaps'] as bool? ?? true,
        dateBold: j['dateBold'] as bool? ?? false,
      );
}
