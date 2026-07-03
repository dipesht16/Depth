package com.yourcompany.depthwallpaper

import android.app.WallpaperManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.yourcompany.depthwallpaper/wallpaper"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "saveConfig" -> {
                    val configMap = call.arguments as? Map<String, Any>
                    if (configMap != null) {
                        saveConfigToPrefs(configMap)
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGUMENTS", "Config map was null", null)
                    }
                }
                "setWallpaper" -> {
                    val success = launchWallpaperPicker()
                    if (success) {
                        result.success(true)
                    } else {
                        result.error("LAUNCH_FAILED", "Failed to launch wallpaper picker", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun saveConfigToPrefs(config: Map<String, Any>) {
        val prefs = getSharedPreferences("wallpaper_config", Context.MODE_PRIVATE)
        prefs.edit().apply {
            // Put float values (using Number to safely handle Double/Int coercion from Flutter)
            putFloat("fontSize", (config["fontSize"] as? Number)?.toFloat() ?: 0.24f)
            putFloat("horizontalPos", (config["horizontalPos"] as? Number)?.toFloat() ?: 0.48f)
            putFloat("verticalPos", (config["verticalPos"] as? Number)?.toFloat() ?: 0.24f)

            // Put string values
            putString("clockFormat", config["clockFormat"] as? String ?: "HH:MM")
            putString("fontFamily", config["fontFamily"] as? String ?: "Roboto")

            // Put int values
            putInt("fontColor", (config["fontColor"] as? Number)?.toInt() ?: -1)

            // Put letter spacing, opacity, effects toggles
            putFloat("letterSpacing", (config["letterSpacing"] as? Number)?.toFloat() ?: 0.0f)
            putFloat("textOpacity", (config["textOpacity"] as? Number)?.toFloat() ?: 1.0f)

            putBoolean("shadowEnabled", config["shadowEnabled"] as? Boolean ?: true)
            putBoolean("strokeEnabled", config["strokeEnabled"] as? Boolean ?: false)
            putBoolean("edgeStrokeEnabled", config["edgeStrokeEnabled"] as? Boolean ?: false)
            putBoolean("atmosphericDepthEnabled", config["atmosphericDepthEnabled"] as? Boolean ?: false)

            // Put transform properties
            putFloat("rotation", (config["rotation"] as? Number)?.toFloat() ?: 0.0f)
            putFloat("stretch", (config["stretch"] as? Number)?.toFloat() ?: 1.0f)
            putFloat("horizontalSkew", (config["horizontalSkew"] as? Number)?.toFloat() ?: 0.0f)
            putFloat("verticalSkew", (config["verticalSkew"] as? Number)?.toFloat() ?: 0.0f)
            putFloat("bottomSkewH", (config["bottomSkewH"] as? Number)?.toFloat() ?: 0.0f)
            putFloat("leftSkew", (config["leftSkew"] as? Number)?.toFloat() ?: 0.0f)

            // Put file paths
            putString("backgroundPath", config["backgroundPath"] as? String)
            putString("foregroundPath", config["foregroundPath"] as? String)

            // Date Widget
            putBoolean("showDate", config["showDate"] as? Boolean ?: false)
            putFloat("dateFontSize", (config["dateFontSize"] as? Number)?.toFloat() ?: 0.034f)
            putFloat("dateHorizontalPos", (config["dateHorizontalPos"] as? Number)?.toFloat() ?: 0.78f)
            putFloat("dateVerticalPos", (config["dateVerticalPos"] as? Number)?.toFloat() ?: 0.11f)
            putInt("dateColor", (config["dateColor"] as? Number)?.toInt() ?: -1)
            putString("dateFormat", config["dateFormat"] as? String ?: "EEE, MMM dd")
            putBoolean("dateAllCaps", config["dateAllCaps"] as? Boolean ?: true)
            putBoolean("dateBold", config["dateBold"] as? Boolean ?: false)

            apply()
        }
    }

    private fun launchWallpaperPicker(): Boolean {
        return try {
            val intent = Intent(WallpaperManager.ACTION_CHANGE_LIVE_WALLPAPER).apply {
                putExtra(
                    WallpaperManager.EXTRA_LIVE_WALLPAPER_COMPONENT,
                    ComponentName(this@MainActivity, DepthWallpaperService::class.java)
                )
            }
            startActivity(intent)
            true
        } catch (e: Exception) {
            try {
                val intent = Intent(WallpaperManager.ACTION_LIVE_WALLPAPER_CHOOSER)
                startActivity(intent)
                true
            } catch (e2: Exception) {
                false
            }
        }
    }
}
