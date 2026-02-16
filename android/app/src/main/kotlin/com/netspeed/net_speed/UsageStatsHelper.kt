package com.netspeed.net_speed

import android.app.usage.NetworkStats
import android.app.usage.NetworkStatsManager
import android.content.Context
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.net.ConnectivityManager
import android.telephony.TelephonyManager
import java.io.ByteArrayOutputStream
import java.util.Calendar

/**
 * Queries NetworkStatsManager for data usage statistics.
 *
 * Returns aggregated download/upload bytes for WiFi and Mobile
 * over configurable time ranges (today, week, month).
 */
class UsageStatsHelper(private val context: Context) {

    private val networkStatsManager: NetworkStatsManager by lazy {
        context.getSystemService(Context.NETWORK_STATS_SERVICE) as NetworkStatsManager
    }

    /**
     * Get data usage for a specific network type and time range.
     * @param networkType 1 = WiFi, 0 = Mobile, -1 = All
     * @param timeRange "today", "week", "month"
     * @return Map with downloadBytes, uploadBytes, totalBytes
     */
    fun getUsage(networkType: Int, timeRange: String): Map<String, Long> {
        val (startTime, endTime) = getTimeRange(timeRange)

        var totalRx = 0L
        var totalTx = 0L

        try {
            if (networkType == 1 || networkType == -1) {
                val wifiStats = queryStats(ConnectivityManager.TYPE_WIFI, startTime, endTime)
                totalRx += wifiStats.first
                totalTx += wifiStats.second
            }
            if (networkType == 0 || networkType == -1) {
                val mobileStats = queryStats(ConnectivityManager.TYPE_MOBILE, startTime, endTime)
                totalRx += mobileStats.first
                totalTx += mobileStats.second
            }
        } catch (e: SecurityException) {
            return mapOf(
                "downloadBytes" to 0L,
                "uploadBytes" to 0L,
                "totalBytes" to 0L,
                "error" to 1L
            )
        } catch (e: Exception) {
            return mapOf(
                "downloadBytes" to 0L,
                "uploadBytes" to 0L,
                "totalBytes" to 0L,
                "error" to 2L
            )
        }

        return mapOf(
            "downloadBytes" to totalRx,
            "uploadBytes" to totalTx,
            "totalBytes" to (totalRx + totalTx),
            "error" to 0L
        )
    }

    /**
     * Get hourly breakdown for a specific day (for daily chart).
     */
    fun getHourlyUsage(networkType: Int, dayOffset: Int): List<Map<String, Long>> {
        val result = mutableListOf<Map<String, Long>>()
        val cal = Calendar.getInstance()
        cal.add(Calendar.DAY_OF_YEAR, -dayOffset)
        cal.set(Calendar.HOUR_OF_DAY, 0)
        cal.set(Calendar.MINUTE, 0)
        cal.set(Calendar.SECOND, 0)
        cal.set(Calendar.MILLISECOND, 0)

        for (hour in 0..23) {
            val startTime = cal.timeInMillis + (hour * 3600000L)
            val endTime = startTime + 3600000L

            var rx = 0L
            var tx = 0L

            try {
                if (networkType == 1 || networkType == -1) {
                    val stats = queryStats(ConnectivityManager.TYPE_WIFI, startTime, endTime)
                    rx += stats.first
                    tx += stats.second
                }
                if (networkType == 0 || networkType == -1) {
                    val stats = queryStats(ConnectivityManager.TYPE_MOBILE, startTime, endTime)
                    rx += stats.first
                    tx += stats.second
                }
            } catch (_: Exception) { }

            result.add(mapOf(
                "hour" to hour.toLong(),
                "downloadBytes" to rx,
                "uploadBytes" to tx
            ))
        }

        return result
    }

    /**
     * Get daily totals for the last N days (for weekly/monthly charts).
     */
    fun getDailyUsage(networkType: Int, days: Int): List<Map<String, Long>> {
        val result = mutableListOf<Map<String, Long>>()

        for (dayOffset in (days - 1) downTo 0) {
            val cal = Calendar.getInstance()
            cal.add(Calendar.DAY_OF_YEAR, -dayOffset)
            cal.set(Calendar.HOUR_OF_DAY, 0)
            cal.set(Calendar.MINUTE, 0)
            cal.set(Calendar.SECOND, 0)
            cal.set(Calendar.MILLISECOND, 0)
            val startTime = cal.timeInMillis
            val endTime = startTime + 86400000L

            var rx = 0L
            var tx = 0L

            try {
                if (networkType == 1 || networkType == -1) {
                    val stats = queryStats(ConnectivityManager.TYPE_WIFI, startTime, endTime)
                    rx += stats.first
                    tx += stats.second
                }
                if (networkType == 0 || networkType == -1) {
                    val stats = queryStats(ConnectivityManager.TYPE_MOBILE, startTime, endTime)
                    rx += stats.first
                    tx += stats.second
                }
            } catch (_: Exception) { }

            result.add(mapOf(
                "day" to dayOffset.toLong(),
                "downloadBytes" to rx,
                "uploadBytes" to tx
            ))
        }

        return result
    }

    /**
     * Get per-app usage for a specific network type and time range.
     * Returns list of maps with packageName, appName, icon (PNG bytes), usage data.
     */
    fun getAppUsage(networkType: Int, timeRange: String): List<Map<String, Any>> {
        val (startTime, endTime) = getTimeRange(timeRange)
        val usageMap = mutableMapOf<Int, AppUsageData>()

        try {
            if (networkType == 1 || networkType == -1) {
                val wifiStats = networkStatsManager.querySummary(
                    ConnectivityManager.TYPE_WIFI, null, startTime, endTime
                )
                aggregateStats(wifiStats, usageMap)
                wifiStats.close()
            }

            if (networkType == 0 || networkType == -1) {
                val subscriberId = getSubscriberId()
                val mobileStats = networkStatsManager.querySummary(
                    ConnectivityManager.TYPE_MOBILE, subscriberId, startTime, endTime
                )
                aggregateStats(mobileStats, usageMap)
                mobileStats.close()
            }
        } catch (e: Exception) {
            return emptyList()
        }

        val pm = context.packageManager
        val result = mutableListOf<Map<String, Any>>()

        usageMap.forEach { (uid, data) ->
            val packages = pm.getPackagesForUid(uid)
            if (packages != null && packages.isNotEmpty()) {
                val packageName = packages[0]

                // Resolve app name
                val appName = try {
                    val appInfo = pm.getApplicationInfo(packageName, 0)
                    pm.getApplicationLabel(appInfo).toString()
                } catch (_: PackageManager.NameNotFoundException) {
                    packageName
                }

                // Resolve app icon as PNG bytes
                val iconBytes = try {
                    val appInfo = pm.getApplicationInfo(packageName, 0)
                    val drawable = pm.getApplicationIcon(appInfo)
                    drawableToBytes(drawable)
                } catch (_: Exception) {
                    null
                }

                val entry = mutableMapOf<String, Any>(
                    "packageName" to packageName,
                    "appName" to appName,
                    "uid" to uid,
                    "downloadBytes" to data.rx,
                    "uploadBytes" to data.tx,
                    "totalBytes" to (data.rx + data.tx)
                )
                if (iconBytes != null) {
                    entry["icon"] = iconBytes
                }
                result.add(entry)
            }
        }

        result.sortByDescending { it["totalBytes"] as Long }
        return result
    }

    // --- Private helpers ---

    private fun drawableToBytes(drawable: Drawable): ByteArray? {
        val bitmap = if (drawable is BitmapDrawable) {
            drawable.bitmap
        } else {
            val w = drawable.intrinsicWidth.coerceAtLeast(1)
            val h = drawable.intrinsicHeight.coerceAtLeast(1)
            val bmp = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bmp)
            drawable.setBounds(0, 0, canvas.width, canvas.height)
            drawable.draw(canvas)
            bmp
        }
        val stream = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.PNG, 80, stream)
        return stream.toByteArray()
    }

    private fun aggregateStats(stats: NetworkStats, map: MutableMap<Int, AppUsageData>) {
        val bucket = NetworkStats.Bucket()
        while (stats.hasNextBucket()) {
            stats.getNextBucket(bucket)
            if (bucket.tag == NetworkStats.Bucket.TAG_NONE) {
                val uid = bucket.uid
                val current = map.getOrPut(uid) { AppUsageData() }
                current.rx += bucket.rxBytes
                current.tx += bucket.txBytes
            }
        }
    }

    private data class AppUsageData(var rx: Long = 0, var tx: Long = 0)

    private fun queryStats(type: Int, startTime: Long, endTime: Long): Pair<Long, Long> {
        var rx = 0L
        var tx = 0L

        val subscriberId = if (type == ConnectivityManager.TYPE_MOBILE) {
            getSubscriberId()
        } else null

        val bucket = networkStatsManager.querySummaryForDevice(
            type, subscriberId, startTime, endTime
        )
        rx = bucket.rxBytes
        tx = bucket.txBytes

        return Pair(rx, tx)
    }

    private fun getSubscriberId(): String? {
        return try {
            val tm = context.getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager
            tm.subscriberId
        } catch (_: SecurityException) {
            null
        }
    }

    private fun getTimeRange(range: String): Pair<Long, Long> {
        val cal = Calendar.getInstance()
        val endTime = cal.timeInMillis

        when (range) {
            "today" -> {
                cal.set(Calendar.HOUR_OF_DAY, 0)
                cal.set(Calendar.MINUTE, 0)
                cal.set(Calendar.SECOND, 0)
                cal.set(Calendar.MILLISECOND, 0)
            }
            "week" -> {
                cal.set(Calendar.DAY_OF_WEEK, cal.firstDayOfWeek)
                cal.set(Calendar.HOUR_OF_DAY, 0)
                cal.set(Calendar.MINUTE, 0)
                cal.set(Calendar.SECOND, 0)
                cal.set(Calendar.MILLISECOND, 0)
            }
            "month" -> {
                cal.set(Calendar.DAY_OF_MONTH, 1)
                cal.set(Calendar.HOUR_OF_DAY, 0)
                cal.set(Calendar.MINUTE, 0)
                cal.set(Calendar.SECOND, 0)
                cal.set(Calendar.MILLISECOND, 0)
            }
        }

        return Pair(cal.timeInMillis, endTime)
    }
}
