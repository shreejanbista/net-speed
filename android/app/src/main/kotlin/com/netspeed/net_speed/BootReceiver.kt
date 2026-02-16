package com.netspeed.net_speed

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build

/**
 * Boot receiver to auto-start the speed monitor service
 * if the user has enabled auto-start in settings.
 * 
 * Checks SharedPreferences for the auto_start flag before
 * starting the foreground service.
 */
class BootReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_BOOT_COMPLETED) return

        val prefs = context.getSharedPreferences(
            "net_speed_prefs", Context.MODE_PRIVATE
        )
        val autoStart = prefs.getBoolean("auto_start_on_boot", false)
        val serviceEnabled = prefs.getBoolean("service_enabled", false)

        if (autoStart && serviceEnabled) {
            val serviceIntent = Intent(context, SpeedMonitorService::class.java)
            context.startForegroundService(serviceIntent)
        }
    }
}
