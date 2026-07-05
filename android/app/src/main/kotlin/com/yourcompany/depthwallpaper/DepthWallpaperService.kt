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
import java.util.Calendar
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
        private val updateRunnable = object : Runnable {
            override fun run() {
                Log.d(TAG, "Updating time: ${getCurrentTime()}")
                drawWallpaper()
                if (isVisible) {
                    scheduleNextUpdate()
                }
            }
        }

        private val midnightRunnable = object : Runnable {
            override fun run() {
                Log.d(TAG, "Midnight update: refreshing date")
                drawWallpaper()
                if (isVisible && config.showDate) {
                    // Schedule next midnight 24 hours from now
                    handler.postDelayed(this, 24 * 60 * 60 * 1000L)
                }
            }
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
            // Critical: remove all pending callbacks to prevent memory leaks
            handler.removeCallbacks(updateRunnable)
            handler.removeCallbacks(midnightRunnable)
            recycleBitmaps()
        }

        override fun onVisibilityChanged(visible: Boolean) {
            this.isVisible = visible
            if (visible) {
                loadConfigAndBitmaps()
                // Draw immediately so user sees current time on screen wake
                drawWallpaper()
                // Remove any stale pending callbacks before scheduling fresh one
                handler.removeCallbacks(updateRunnable)
                handler.removeCallbacks(midnightRunnable)
                scheduleNextUpdate()
                if (config.showDate) scheduleMidnightUpdate()
            } else {
                // Screen off / wallpaper hidden — stop all updates to conserve battery
                handler.removeCallbacks(updateRunnable)
                handler.removeCallbacks(midnightRunnable)
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
            // Kick off update loop once the surface is ready
            if (isVisible) {
                handler.removeCallbacks(updateRunnable)
                scheduleNextUpdate()
            }
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
            return try {
                when (fontFamily) {
                    "Default" -> Typeface.create(Typeface.SANS_SERIF, Typeface.BOLD)
                    "Roboto" -> Typeface.create("sans-serif", Typeface.BOLD)
                    "Outfit" -> Typeface.create("sans-serif", Typeface.BOLD)
                    "Inter" -> Typeface.create("sans-serif-condensed", Typeface.BOLD)
                    "Lilita One" -> Typeface.create("sans-serif-black", Typeface.BOLD)
                    "Rubik" -> Typeface.create("sans-serif-medium", Typeface.BOLD)
                    
                    // Custom Local Fonts from Flutter Assets
                    "New York Heavy" -> Typeface.createFromAsset(applicationContext.assets, "flutter_assets/assets/fonts/NewYork-Heavy.otf")
                    "New York Semibold" -> Typeface.createFromAsset(applicationContext.assets, "flutter_assets/assets/fonts/NewYork-Semibold.otf")
                    "SF Pro Rails" -> Typeface.createFromAsset(applicationContext.assets, "flutter_assets/assets/fonts/SFPro-Semibold-Rails.otf")
                    "SF Pro Rounded" -> Typeface.createFromAsset(applicationContext.assets, "flutter_assets/assets/fonts/SFPro-Semibold-Rounded.otf")
                    "SF Pro Soft" -> Typeface.createFromAsset(applicationContext.assets, "flutter_assets/assets/fonts/SFPro-Semibold-Soft.otf")
                    "SF Pro Stencil" -> Typeface.createFromAsset(applicationContext.assets, "flutter_assets/assets/fonts/SFPro-Semibold-Stencil.otf")
                    "SF Pro Semibold" -> Typeface.createFromAsset(applicationContext.assets, "flutter_assets/assets/fonts/SFPro-Semibold.otf")
                    "SF Pro Display" -> Typeface.createFromAsset(applicationContext.assets, "flutter_assets/assets/fonts/SFProDisplay-Bold.otf")
                    "SF Pro Mono" -> Typeface.createFromAsset(applicationContext.assets, "flutter_assets/assets/fonts/SFMono-Bold.otf")
                    
                    else -> Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error loading custom font $fontFamily from assets", e)
                Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
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
                // Layer 4: Date (on top of everything — HUD element)
                if (::config.isInitialized && config.showDate) {
                    drawDate(canvas)
                }
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

        /**
         * Schedules the next time update, syncing to the nearest minute boundary
         * when the clock format does not include seconds. This prevents drift and
         * ensures the clock flips at exactly :00 seconds every minute.
         */
        private fun scheduleNextUpdate() {
            if (!isVisible) return
            val intervalMs = getUpdateInterval()
            if (intervalMs == 1000L) {
                // Seconds visible — just re-fire every second without fancy sync
                handler.postDelayed(updateRunnable, 1000L)
            } else {
                // Sync precisely to the next minute boundary
                val now = Calendar.getInstance()
                val seconds = now.get(Calendar.SECOND)
                val milliseconds = now.get(Calendar.MILLISECOND)
                val delayToNextMinute = ((60 - seconds) * 1000 - milliseconds).toLong()
                // Clamp to at least 100ms to avoid hammering when exactly on boundary
                val safeDelay = if (delayToNextMinute < 100L) 60000L else delayToNextMinute
                Log.d(TAG, "Next update in ${safeDelay}ms (at next minute boundary)")
                handler.postDelayed(updateRunnable, safeDelay)
            }
        }

        /**
         * Returns the appropriate update interval based on whether the clock
         * format includes seconds display.
         */
        private fun getUpdateInterval(): Long {
            return if (::config.isInitialized && config.clockFormat.contains("SS")) {
                1000L  // Update every second for HH:MM:SS formats
            } else {
                60000L // Update every minute for all other formats
            }
        }

        /**
         * Draws the date text on top of all layers (HUD element).
         */
        private fun drawDate(canvas: Canvas) {
            val datePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = config.dateColor
                textSize = config.dateFontSize * canvasWidth
                textAlign = Paint.Align.LEFT
                typeface = if (config.dateBold) {
                    Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
                } else {
                    Typeface.create(Typeface.DEFAULT, Typeface.NORMAL)
                }
                setShadowLayer(4f, 0f, 2f, Color.argb(128, 0, 0, 0))
            }

            var dateText = getFormattedDate()
            if (config.dateAllCaps) dateText = dateText.uppercase()

            val x = config.dateHorizontalPos * canvasWidth
            val y = config.dateVerticalPos * canvasHeight
            canvas.drawText(dateText, x, y, datePaint)
        }

        private fun getFormattedDate(): String {
            return try {
                val pattern = when (config.dateFormat) {
                    "MMM dd, yyyy" -> "MMM dd, yyyy"
                    "dd/MM/yyyy"   -> "dd/MM/yyyy"
                    "MM-dd-yyyy"   -> "MM-dd-yyyy"
                    "EEEE, MMMM dd" -> "EEEE, MMMM dd"
                    else           -> "EEE, MMM dd"
                }
                SimpleDateFormat(pattern, Locale.getDefault()).format(Date())
            } catch (e: Exception) {
                SimpleDateFormat("EEE, MMM dd", Locale.getDefault()).format(Date())
            }
        }

        /**
         * Schedules a redraw at the next midnight (00:00:00) to refresh the date.
         */
        private fun scheduleMidnightUpdate() {
            if (!isVisible || !::config.isInitialized || !config.showDate) return
            val now = Calendar.getInstance()
            val tomorrow = Calendar.getInstance().apply {
                add(Calendar.DAY_OF_MONTH, 1)
                set(Calendar.HOUR_OF_DAY, 0)
                set(Calendar.MINUTE, 0)
                set(Calendar.SECOND, 0)
                set(Calendar.MILLISECOND, 0)
            }
            val delayToMidnight = tomorrow.timeInMillis - now.timeInMillis
            Log.d(TAG, "Next midnight update in ${delayToMidnight / 1000}s")
            handler.postDelayed(midnightRunnable, delayToMidnight)
        }
    }
}
