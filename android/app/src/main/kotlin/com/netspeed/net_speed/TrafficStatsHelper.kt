package com.netspeed.net_speed

import android.net.TrafficStats
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.content.Context

/**
 * Efficient speed calculator using TrafficStats.
 * 
 * Uses cumulative byte counters — only two long reads per tick,
 * no network I/O, no allocations. Adapts polling interval based
 * on screen state to save battery.
 */
class TrafficStatsHelper(private val context: Context) {

    private var lastRxBytes: Long = 0
    private var lastTxBytes: Long = 0
    private var lastTimestamp: Long = 0

    // Adaptive intervals: 1s screen-on, 4s screen-off
    companion object {
        const val INTERVAL_ACTIVE_MS = 1000L
        const val INTERVAL_IDLE_MS = 4000L
    }

    /**
     * Initialize baseline counters.
     * Call once before starting periodic reads.
     */
    fun init() {
        lastRxBytes = TrafficStats.getTotalRxBytes()
        lastTxBytes = TrafficStats.getTotalTxBytes()
        lastTimestamp = System.currentTimeMillis()
    }

    /**
     * Calculate current speed (bytes/sec) since last call.
     * Returns map: {downloadSpeed, uploadSpeed, totalRxBytes, totalTxBytes}
     */
    fun getSpeed(): Map<String, Long> {
        val currentRxBytes = TrafficStats.getTotalRxBytes()
        val currentTxBytes = TrafficStats.getTotalTxBytes()
        val currentTime = System.currentTimeMillis()

        val timeDelta = currentTime - lastTimestamp
        if (timeDelta <= 0) {
            return mapOf(
                "downloadSpeed" to 0L,
                "uploadSpeed" to 0L,
                "totalRxBytes" to currentRxBytes,
                "totalTxBytes" to currentTxBytes
            )
        }

        val rxDelta = currentRxBytes - lastRxBytes
        val txDelta = currentTxBytes - lastTxBytes

        // bytes per second
        val downloadSpeed = (rxDelta * 1000) / timeDelta
        val uploadSpeed = (txDelta * 1000) / timeDelta

        // Update baseline
        lastRxBytes = currentRxBytes
        lastTxBytes = currentTxBytes
        lastTimestamp = currentTime

        return mapOf(
            "downloadSpeed" to downloadSpeed,
            "uploadSpeed" to uploadSpeed,
            "totalRxBytes" to currentRxBytes,
            "totalTxBytes" to currentTxBytes
        )
    }

    /**
     * Get current adaptive interval based on screen state.
     * No wake lock — lets CPU doze between polls.
     */
    fun getCurrentInterval(): Long {
        val pm = context.getSystemService(Context.POWER_SERVICE) as PowerManager
        return if (pm.isInteractive) INTERVAL_ACTIVE_MS else INTERVAL_IDLE_MS
    }
}
