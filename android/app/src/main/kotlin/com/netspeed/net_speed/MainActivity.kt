package com.netspeed.net_speed

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel
import android.content.Intent
import android.content.Context
import android.os.Build
import android.provider.Settings
import android.app.AppOpsManager
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.Manifest
import android.content.pm.PackageManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat

/**
 * MainActivity: Entry point and MethodChannel/EventChannel bridge.
 * 
 * Registers three channels:
 * 1. "com.netspeed/speed" — EventChannel streaming speed readings
 * 2. "com.netspeed/service" — MethodChannel to start/stop foreground service
 * 3. "com.netspeed/usage" — MethodChannel to query data usage stats
 */
class MainActivity : FlutterActivity() {

    private val SPEED_CHANNEL = "com.netspeed/speed"
    private val SERVICE_CHANNEL = "com.netspeed/service"
    private val USAGE_CHANNEL = "com.netspeed/usage"

    private lateinit var trafficHelper: TrafficStatsHelper
    private lateinit var usageHelper: UsageStatsHelper
    private var speedEventSink: EventChannel.EventSink? = null
    private val handler = android.os.Handler(android.os.Looper.getMainLooper())
    private var isStreaming = false

    private val speedRunnable = object : Runnable {
        override fun run() {
            if (!isStreaming) return
            val speed = trafficHelper.getSpeed()
            val networkType = getNetworkType()
            
            speedEventSink?.success(mapOf(
                "downloadSpeed" to speed["downloadSpeed"],
                "uploadSpeed" to speed["uploadSpeed"],
                "totalRxBytes" to speed["totalRxBytes"],
                "totalTxBytes" to speed["totalTxBytes"],
                "networkType" to networkType
            ))

            val interval = trafficHelper.getCurrentInterval()
            handler.postDelayed(this, interval)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        trafficHelper = TrafficStatsHelper(this)
        usageHelper = UsageStatsHelper(this)

        // Speed EventChannel — streams speed data to Flutter
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, SPEED_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    speedEventSink = events
                    trafficHelper.init()
                    isStreaming = true
                    handler.post(speedRunnable)
                }

                override fun onCancel(arguments: Any?) {
                    isStreaming = false
                    handler.removeCallbacks(speedRunnable)
                    speedEventSink = null
                }
            })

        // Service MethodChannel — start/stop foreground service
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SERVICE_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startService" -> {
                        val intent = Intent(this, SpeedMonitorService::class.java)
                        startForegroundService(intent)
                        
                        // Save state to SharedPreferences
                        getSharedPreferences("net_speed_prefs", Context.MODE_PRIVATE)
                            .edit()
                            .putBoolean("service_enabled", true)
                            .apply()
                        
                        result.success(true)
                    }
                    "stopService" -> {
                        val intent = Intent(this, SpeedMonitorService::class.java).apply {
                            action = SpeedMonitorService.ACTION_STOP
                        }
                        startService(intent)
                        
                        getSharedPreferences("net_speed_prefs", Context.MODE_PRIVATE)
                            .edit()
                            .putBoolean("service_enabled", false)
                            .apply()
                        
                        result.success(true)
                    }
                    "isServiceRunning" -> {
                        val prefs = getSharedPreferences("net_speed_prefs", Context.MODE_PRIVATE)
                        result.success(prefs.getBoolean("service_enabled", false))
                    }
                    "setAutoStart" -> {
                        val enabled = call.argument<Boolean>("enabled") ?: false
                        getSharedPreferences("net_speed_prefs", Context.MODE_PRIVATE)
                            .edit()
                            .putBoolean("auto_start_on_boot", enabled)
                            .apply()
                        result.success(true)
                    }
                    "hasUsagePermission" -> {
                        result.success(hasUsageStatsPermission())
                    }
                    "openUsageSettings" -> {
                        val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
                        startActivity(intent)
                        result.success(true)
                    }
                    "openBatterySettings" -> {
                        val intent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
                        startActivity(intent)
                        result.success(true)
                    }
                    "requestNotificationPermission" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                            if (ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS)
                                != PackageManager.PERMISSION_GRANTED) {
                                ActivityCompat.requestPermissions(
                                    this,
                                    arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                                    1001
                                )
                            }
                        }
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }

        // Usage MethodChannel — query data usage
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, USAGE_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getUsage" -> {
                        val networkType = call.argument<Int>("networkType") ?: -1
                        val timeRange = call.argument<String>("timeRange") ?: "today"
                        val usage = usageHelper.getUsage(networkType, timeRange)
                        result.success(usage)
                    }
                    "getHourlyUsage" -> {
                        val networkType = call.argument<Int>("networkType") ?: -1
                        val dayOffset = call.argument<Int>("dayOffset") ?: 0
                        val usage = usageHelper.getHourlyUsage(networkType, dayOffset)
                        result.success(usage)
                    }
                    "getDailyUsage" -> {
                        val networkType = call.argument<Int>("networkType") ?: -1
                        val days = call.argument<Int>("days") ?: 7
                        val usage = usageHelper.getDailyUsage(networkType, days)
                        result.success(usage)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun getNetworkType(): String {
        val cm = getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        val network = cm.activeNetwork ?: return "none"
        val capabilities = cm.getNetworkCapabilities(network) ?: return "none"

        return when {
            capabilities.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) -> "wifi"
            capabilities.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) -> "mobile"
            capabilities.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET) -> "ethernet"
            else -> "other"
        }
    }

    private fun hasUsageStatsPermission(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = appOps.unsafeCheckOpNoThrow(
            AppOpsManager.OPSTR_GET_USAGE_STATS,
            android.os.Process.myUid(),
            packageName
        )
        return mode == AppOpsManager.MODE_ALLOWED
    }

    override fun onDestroy() {
        isStreaming = false
        handler.removeCallbacks(speedRunnable)
        speedEventSink = null
        super.onDestroy()
    }
}
