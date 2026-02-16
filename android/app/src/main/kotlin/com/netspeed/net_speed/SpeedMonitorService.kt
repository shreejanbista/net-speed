package com.netspeed.net_speed

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Typeface
import android.graphics.drawable.Icon
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager

/**
 * Foreground service for persistent speed monitoring notification.
 *
 * Battery-optimized design:
 * - No wake locks: uses Handler.postDelayed(), CPU sleeps between polls
 * - Adaptive interval: 1s screen-on, 4s screen-off
 * - setOnlyAlertOnce(true): silent notification updates
 * - Notification channel importance LOW: no sound/vibration
 * - stopSelf() on toggle-off: fully releases resources
 */
class SpeedMonitorService : Service() {

    companion object {
        const val CHANNEL_ID = "speed_monitor"
        const val NOTIFICATION_ID = 1001
        const val ACTION_STOP = "com.netspeed.STOP_SERVICE"
    }

    private lateinit var trafficHelper: TrafficStatsHelper
    private val handler = Handler(Looper.getMainLooper())
    private lateinit var powerManager: PowerManager
    private var isRunning = false

    private val pollRunnable = object : Runnable {
        override fun run() {
            if (!isRunning) return

            val speed = trafficHelper.getSpeed()
            val downloadSpeed = speed["downloadSpeed"] ?: 0L
            val uploadSpeed = speed["uploadSpeed"] ?: 0L

            updateNotification(downloadSpeed, uploadSpeed)

            // Adaptive interval: poll less when screen is off
            val interval = trafficHelper.getCurrentInterval()
            handler.postDelayed(this, interval)
        }
    }

    override fun onCreate() {
        super.onCreate()
        powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        trafficHelper = TrafficStatsHelper(this)
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            stopMonitoring()
            return START_NOT_STICKY
        }

        startMonitoring()
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun startMonitoring() {
        if (isRunning) return
        isRunning = true
        trafficHelper.init()

        // Initial notification with static icon
        val notification = buildNotification(0, 0)
        startForeground(NOTIFICATION_ID, notification)

        handler.post(pollRunnable)
    }

    private fun stopMonitoring() {
        isRunning = false
        handler.removeCallbacks(pollRunnable)
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    private fun createNotificationChannel() {
        val channel = NotificationChannel(
            CHANNEL_ID,
            "Speed Monitor",
            NotificationManager.IMPORTANCE_LOW  // No sound, no vibration
        ).apply {
            description = "Shows real-time internet speed"
            setShowBadge(false)
            lockscreenVisibility = Notification.VISIBILITY_PUBLIC
        }

        val notificationManager = getSystemService(NotificationManager::class.java)
        notificationManager.createNotificationChannel(channel)
    }

    private fun buildNotification(downloadSpeed: Long, uploadSpeed: Long): Notification {
        val downStr = formatSpeed(downloadSpeed)
        val upStr = formatSpeed(uploadSpeed)
        val contentText = "Down: $downStr   Up: $upStr"

        // Launch app when notification is tapped
        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
        val pendingIntent = PendingIntent.getActivity(
            this, 0, launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Stop action
        val stopIntent = Intent(this, SpeedMonitorService::class.java).apply {
            action = ACTION_STOP
        }
        val stopPendingIntent = PendingIntent.getService(
            this, 1, stopIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val stopAction = Notification.Action.Builder(
            Icon.createWithResource(this, android.R.drawable.ic_menu_close_clear_cancel),
            "Stop",
            stopPendingIntent
        ).build()

        val builder = Notification.Builder(this, CHANNEL_ID)
            .setContentTitle("NetSpeed")
            .setContentText(contentText)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setContentIntent(pendingIntent)
            .addAction(stopAction)
            .setCategory(Notification.CATEGORY_STATUS)
            .setVisibility(Notification.VISIBILITY_PUBLIC)

        // Generate dynamic icon
        try {
            val bitmap = createSpeedIconBitmap(downStr)
            val icon = Icon.createWithBitmap(bitmap)
            builder.setSmallIcon(icon)
        } catch (e: Exception) {
            builder.setSmallIcon(R.mipmap.ic_launcher)
        }

        return builder.build()
    }

    private fun updateNotification(downloadSpeed: Long, uploadSpeed: Long) {
        val notification = buildNotification(downloadSpeed, uploadSpeed)
        val notificationManager = getSystemService(NotificationManager::class.java)
        notificationManager.notify(NOTIFICATION_ID, notification)
    }

    private fun createSpeedIconBitmap(text: String): Bitmap {
        val size = 96
        val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val paint = Paint().apply {
            color = Color.WHITE
            textAlign = Paint.Align.CENTER
            typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
            isAntiAlias = true
        }

        // Parse "1.2 MB/s" -> "1.2" and "MB"
        val parts = text.split(" ")
        val number = parts.firstOrNull() ?: "0"
        val unit = if (parts.size > 1) parts[1].replace("/s", "") else ""

        // Vertical Layout (Stacked)
        
        // Draw number (larger)
        // Dynamic text size to prevent cropping for 4+ digits (e.g. 1200)
        paint.textSize = if (number.length > 3) 42f else 56f
        
        val yCenter = (size / 2f) - ((paint.descent() + paint.ascent()) / 2)
        canvas.drawText(number, size / 2f, yCenter - 10, paint)

        // Draw unit (smaller below)
        paint.textSize = 28f
        canvas.drawText(unit, size / 2f, yCenter + 25, paint)

        return bitmap
    }

    private fun formatSpeed(bytesPerSec: Long): String {
        return when {
            bytesPerSec < 1024 * 1024 -> {
                val kb = bytesPerSec / 1024.0
                String.format("%.2f KB/s", kb)
            }
            bytesPerSec < 1024L * 1024 * 1024 -> {
                val mb = bytesPerSec / (1024.0 * 1024)
                String.format("%.2f MB/s", mb)
            }
            else -> {
                val gb = bytesPerSec / (1024.0 * 1024 * 1024)
                String.format("%.2f GB/s", gb)
            }
        }
    }

    override fun onDestroy() {
        stopMonitoring()
        super.onDestroy()
    }
}
