package com.yourcompany.depthwallpaper

import android.content.Context
import android.content.SharedPreferences
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Matrix
import android.graphics.Paint
import android.graphics.Rect
import android.graphics.Typeface
import android.os.Handler
import android.os.Looper
import android.service.wallpaper.WallpaperService
import android.util.Log
import android.view.SurfaceHolder
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class DepthWallpaperService : WallpaperService() {

    override fun onCreateEngine(): Engine {
        return DepthWallpaperEngine()
    }

    inner class DepthWallpaperEngine : Engine(), SharedPreferences.OnSharedPreferenceChangeListener {
        private val TAG = "DepthWallpaperEngine"
        private var backgroundBitmap: Bitmap? = null
        private var foregroundBitmap: Bitmap? = null
        private lateinit var config: WallpaperConfig
        private val clockPaint = Paint(Paint.ANTI_ALIAS_FLAG)
        private val strokePaint = Paint(Paint.ANTI_ALIAS_FLAG)

        private var canvasWidth: Int = 0
        private var canvasHeight: Int = 0
        private var isVisible = false

        private val handler = Handler(Looper.getMainLooper())
        private val updateRunnable = Runnable {
            drawWallpaper()
        }

        override fun onCreate(surfaceHolder: SurfaceHolder?) {
            super.onCreate(surfaceHolder)
            val prefs = getSharedPreferences("wallpaper_config", Context.MODE_PRIVATE)
            prefs.registerOnSharedPreferenceChangeListener(this)
            loadConfigAndBitmaps()
        }

        override fun onDestroy() {
            super.onDestroy()
            val prefs = getSharedPreferences("wallpaper_config", Context.MODE_PRIVATE)
            prefs.unregisterOnSharedPreferenceChangeListener(this)
            handler.removeCallbacks(updateRunnable)
            recycleBitmaps()
        }

        override fun onVisibilityChanged(visible: Boolean) {
            this.isVisible = visible
            if (visible) {
                loadConfigAndBitmaps()
                drawWallpaper()
            } else {
                handler.removeCallbacks(updateRunnable)
            }
        }

        override fun onSurfaceCreated(holder: SurfaceHolder?) {
            super.onSurfaceCreated(holder)
        }

        override fun onSurfaceChanged(holder: SurfaceHolder?, format: Int, width: Int, height: Int) {
            super.onSurfaceChanged(holder, format, width, height)
            this.canvasWidth = width
            this.canvasHeight = height
            loadConfigAndBitmaps()
            drawWallpaper()
        }

        override fun onSurfaceRedrawNeeded(holder: SurfaceHolder?) {
            super.onSurfaceRedrawNeeded(holder)
            drawWallpaper()
        }

        override fun onSharedPreferenceChanged(sharedPreferences: SharedPreferences?, key: String?) {
            loadConfigAndBitmaps()
            drawWallpaper()
        }

        private fun loadConfigAndBitmaps() {
            val oldConfig = if (::config.isInitialized) config else null
            config = WallpaperConfig.fromSharedPreferences(this@DepthWallpaperService)

            if (canvasWidth > 0 && canvasHeight > 0) {
                if (backgroundBitmap == null || oldConfig?.backgroundPath != config.backgroundPath) {
                    backgroundBitmap?.recycle()
                    backgroundBitmap = BitmapLoader.loadOptimizedBitmap(config.backgroundPath, canvasWidth, canvasHeight)
                }
                if (foregroundBitmap == null || oldConfig?.foregroundPath != config.foregroundPath) {
                    foregroundBitmap?.recycle()
                    foregroundBitmap = BitmapLoader.loadOptimizedBitmap(config.foregroundPath, canvasWidth, canvasHeight)
                }
            }
            setupPaints()
        }

        private fun setupPaints() {
            val density = resources.displayMetrics.density

            // Setup clock paint
            clockPaint.apply {
                color = config.fontColor
                textSize = config.fontSize * canvasWidth
                isAntiAlias = true
                textAlign = Paint.Align.CENTER
                typeface = getTypefaceForFont(config.fontFamily)
                letterSpacing = config.letterSpacing / 100f
                alpha = (config.textOpacity * 255).toInt()

                if (config.shadowEnabled) {
                    setShadowLayer(8f * density, 0f, 4f * density, Color.BLACK)
                } else {
                    clearShadowLayer()
                }
            }

            // Setup stroke paint
            strokePaint.apply {
                color = Color.BLACK // Outer stroke color
                textSize = config.fontSize * canvasWidth
                isAntiAlias = true
                textAlign = Paint.Align.CENTER
                style = Paint.Style.STROKE
                val strokeDp = (if (config.strokeEnabled) 6f else 0f) + (if (config.edgeStrokeEnabled) 2f else 0f)
                strokeWidth = strokeDp * density
                typeface = clockPaint.typeface
                letterSpacing = clockPaint.letterSpacing
            }
        }

        private fun getTypefaceForFont(fontFamily: String): Typeface {
            return when (fontFamily) {
                "Default" -> Typeface.create(Typeface.SANS_SERIF, Typeface.BOLD)
                "Roboto" -> Typeface.create("sans-serif", Typeface.BOLD)
                "Outfit" -> Typeface.create("sans-serif", Typeface.BOLD)
                "Inter" -> Typeface.create("sans-serif-condensed", Typeface.BOLD)
                "Lilita One" -> Typeface.create("sans-serif-black", Typeface.BOLD)
                "Rubik" -> Typeface.create("sans-serif-medium", Typeface.BOLD)
                else -> Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
            }
        }

        private fun recycleBitmaps() {
            backgroundBitmap?.recycle()
            backgroundBitmap = null
            foregroundBitmap?.recycle()
            foregroundBitmap = null
        }

        private fun drawWallpaper() {
            if (!isVisible || canvasWidth <= 0 || canvasHeight <= 0) return

            val canvas = surfaceHolder.lockCanvas() ?: return
            try {
                drawBackground(canvas)
                drawClock(canvas)
                drawForeground(canvas)
            } catch (e: Exception) {
                Log.e(TAG, "Error drawing wallpaper", e)
            } finally {
                surfaceHolder.unlockCanvasAndPost(canvas)
            }
        }

        private fun drawBackground(canvas: Canvas) {
            val bg = backgroundBitmap
            if (bg != null) {
                val destRect = Rect(0, 0, canvasWidth, canvasHeight)
                canvas.drawBitmap(bg, null, destRect, null)
            } else {
                canvas.drawColor(Color.parseColor("#121212")) // Secondary dark background fallback
            }
        }

        private fun drawClock(canvas: Canvas) {
            val time = getCurrentTime()

            // Centered horizontal alignment with horizontal Pos shifting
            val x = (canvasWidth / 2f) + (config.horizontalPos - 0.48f) * canvasWidth * 2f

            val clockY = config.verticalPos * canvasHeight
            val fontMetrics = clockPaint.fontMetrics
            val y = clockY - fontMetrics.ascent

            canvas.save()

            // Pivot point matches center of the text
            val pivotX = x
            val pivotY = clockY + (fontMetrics.descent - fontMetrics.ascent) / 2f

            applyTransformations(canvas, pivotX, pivotY)

            // Draw outline stroke layer if enabled
            if (config.edgeStrokeEnabled || config.strokeEnabled) {
                canvas.drawText(time, x, y, strokePaint)
            }

            // Draw main filled text layer
            canvas.drawText(time, x, y, clockPaint)

            canvas.restore()
        }

        private fun applyTransformations(canvas: Canvas, pivotX: Float, pivotY: Float) {
            if (config.rotation != 0f) {
                canvas.rotate(config.rotation, pivotX, pivotY)
            }

            if (config.stretch != 1f) {
                canvas.scale(1f, config.stretch, pivotX, pivotY)
            }

            val kx = config.horizontalSkew + config.bottomSkewH * 0.5f
            val ky = config.verticalSkew + config.leftSkew * 0.5f
            if (kx != 0f || ky != 0f) {
                val skewMatrix = Matrix()
                skewMatrix.setSkew(kx, ky, pivotX, pivotY)
                canvas.concat(skewMatrix)
            }
        }

        private fun drawForeground(canvas: Canvas) {
            val fg = foregroundBitmap
            if (fg != null) {
                val destRect = Rect(0, 0, canvasWidth, canvasHeight)
                canvas.drawBitmap(fg, null, destRect, null)
            }
        }

        private fun getCurrentTime(): String {
            val sdf = when (config.clockFormat) {
                "HH:MM:SS" -> SimpleDateFormat("HH:mm:ss", Locale.getDefault())
                "HH.MM" -> SimpleDateFormat("HH.mm", Locale.getDefault())
                "HH/MM" -> SimpleDateFormat("HH/mm", Locale.getDefault())
                else -> SimpleDateFormat("HH:mm", Locale.getDefault())
            }
            return sdf.format(Date())
        }
    }
}
