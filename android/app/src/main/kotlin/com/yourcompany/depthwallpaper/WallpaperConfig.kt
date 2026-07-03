package com.yourcompany.depthwallpaper

import android.content.Context

data class WallpaperConfig(
    // Basics
    val fontSize: Float = 0.24f,
    val horizontalPos: Float = 0.48f,
    val verticalPos: Float = 0.24f,

    // Typography
    val clockFormat: String = "HH:MM",
    val fontColor: Int = -1, // default white (-1 represents 0xFFFFFFFF in signed Int ARGB)
    val fontFamily: String = "Roboto",
    val letterSpacing: Float = 0.0f,
    val secondaryColor: Int? = null,

    // Effects
    val textOpacity: Float = 1.0f,
    val shadowEnabled: Boolean = true,
    val strokeEnabled: Boolean = false,
    val edgeStrokeEnabled: Boolean = false,
    val atmosphericDepthEnabled: Boolean = false,

    // Transform
    val rotation: Float = 0.0f,
    val stretch: Float = 1.0f,
    val horizontalSkew: Float = 0.0f,
    val verticalSkew: Float = 0.0f,
    val bottomSkewH: Float = 0.0f,
    val leftSkew: Float = 0.0f,

    // File paths
    val backgroundPath: String? = null,
    val foregroundPath: String? = null,
    // Date Widget
    val showDate: Boolean = false,
    val dateFontSize: Float = 0.034f,
    val dateHorizontalPos: Float = 0.78f,
    val dateVerticalPos: Float = 0.11f,
    val dateColor: Int = -1, // white
    val dateFormat: String = "EEE, MMM dd",
    val dateAllCaps: Boolean = true,
    val dateBold: Boolean = false
) {
    companion object {
        fun fromSharedPreferences(context: Context): WallpaperConfig {
            val prefs = context.getSharedPreferences("wallpaper_config", Context.MODE_PRIVATE)
            return WallpaperConfig(
                fontSize = prefs.getFloat("fontSize", 0.24f),
                horizontalPos = prefs.getFloat("horizontalPos", 0.48f),
                verticalPos = prefs.getFloat("verticalPos", 0.24f),

                clockFormat = prefs.getString("clockFormat", "HH:MM") ?: "HH:MM",
                fontFamily = prefs.getString("fontFamily", "Roboto") ?: "Roboto",
                fontColor = prefs.getInt("fontColor", -1),

                letterSpacing = prefs.getFloat("letterSpacing", 0.0f),
                textOpacity = prefs.getFloat("textOpacity", 1.0f),

                shadowEnabled = prefs.getBoolean("shadowEnabled", true),
                strokeEnabled = prefs.getBoolean("strokeEnabled", false),
                edgeStrokeEnabled = prefs.getBoolean("edgeStrokeEnabled", false),
                atmosphericDepthEnabled = prefs.getBoolean("atmosphericDepthEnabled", false),

                rotation = prefs.getFloat("rotation", 0.0f),
                stretch = prefs.getFloat("stretch", 1.0f),
                horizontalSkew = prefs.getFloat("horizontalSkew", 0.0f),
                verticalSkew = prefs.getFloat("verticalSkew", 0.0f),
                bottomSkewH = prefs.getFloat("bottomSkewH", 0.0f),
                leftSkew = prefs.getFloat("leftSkew", 0.0f),

                backgroundPath = prefs.getString("backgroundPath", null),
                foregroundPath = prefs.getString("foregroundPath", null),
                showDate = prefs.getBoolean("showDate", false),
                dateFontSize = prefs.getFloat("dateFontSize", 0.034f),
                dateHorizontalPos = prefs.getFloat("dateHorizontalPos", 0.78f),
                dateVerticalPos = prefs.getFloat("dateVerticalPos", 0.11f),
                dateColor = prefs.getInt("dateColor", -1),
                dateFormat = prefs.getString("dateFormat", "EEE, MMM dd") ?: "EEE, MMM dd",
                dateAllCaps = prefs.getBoolean("dateAllCaps", true),
                dateBold = prefs.getBoolean("dateBold", false)
            )
        }
    }
}
