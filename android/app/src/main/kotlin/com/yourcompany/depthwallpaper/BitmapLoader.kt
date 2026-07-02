package com.yourcompany.depthwallpaper

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.util.Log
import java.io.File

object BitmapLoader {
    private const val TAG = "BitmapLoader"

    fun loadOptimizedBitmap(path: String?, targetWidth: Int, targetHeight: Int): Bitmap? {
        if (path.isNullOrEmpty()) return null
        val file = File(path)
        if (!file.exists()) {
            Log.e(TAG, "File does not exist: $path")
            return null
        }

        return try {
            val options = BitmapFactory.Options().apply {
                inJustDecodeBounds = true
            }
            BitmapFactory.decodeFile(path, options)

            val srcWidth = options.outWidth
            val srcHeight = options.outHeight

            if (srcWidth <= 0 || srcHeight <= 0) {
                Log.e(TAG, "Invalid image dimensions for: $path")
                return null
            }

            // Downsample aggressively if larger than target
            // Calculate optimal sample size (power of 2)
            options.inSampleSize = calculateInSampleSize(srcWidth, srcHeight, targetWidth, targetHeight)
            options.inJustDecodeBounds = false
            options.inPreferredConfig = Bitmap.Config.ARGB_8888

            val decodedBitmap = BitmapFactory.decodeFile(path, options) ?: return null

            // Scale to exact target dimensions if necessary
            if (decodedBitmap.width != targetWidth || decodedBitmap.height != targetHeight) {
                val scaledBitmap = Bitmap.createScaledBitmap(decodedBitmap, targetWidth, targetHeight, true)
                if (scaledBitmap != decodedBitmap) {
                    decodedBitmap.recycle()
                }
                scaledBitmap
            } else {
                decodedBitmap
            }
        } catch (e: OutOfMemoryError) {
            Log.e(TAG, "OutOfMemoryError loading bitmap: $path", e)
            System.gc()
            null
        } catch (e: Exception) {
            Log.e(TAG, "Error loading bitmap: $path", e)
            null
        }
    }

    private fun calculateInSampleSize(srcWidth: Int, srcHeight: Int, reqWidth: Int, reqHeight: Int): Int {
        var inSampleSize = 1
        if (srcWidth > reqWidth * 2 || srcHeight > reqHeight * 2) {
            val halfWidth = srcWidth / 2
            val halfHeight = srcHeight / 2
            while (halfWidth / inSampleSize >= reqWidth && halfHeight / inSampleSize >= reqHeight) {
                inSampleSize *= 2
            }
        }
        return inSampleSize
    }
}
