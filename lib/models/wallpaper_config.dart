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
    );
  }
}
