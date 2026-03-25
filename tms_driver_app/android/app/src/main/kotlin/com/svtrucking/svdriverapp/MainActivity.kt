package com.svtrucking.svdriverapp

import android.app.AlarmManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodCall
import androidx.work.Constraints
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.ExistingWorkPolicy
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import java.util.concurrent.TimeUnit
import android.app.NotificationManager
import androidx.core.app.NotificationManagerCompat

class MainActivity : FlutterActivity() {

    private val ROUTE_CHANNEL = "app_route"
    private var routeChannel: MethodChannel? = null

    private val DIAG_CHANNEL = "diag"
    private var diagChannel: MethodChannel? = null

    private companion object {
        private const val BATTERY_CHANNEL = "battery_optimization"
        private const val LOCATION_CHANNEL = "sv/native_service"
        private const val WATCHDOG_UNIQUE = "svdriver_health_watchdog"
        private const val WATCHDOG_NOW = "svdriver_health_watchdog_now"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Battery optimization helpers
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BATTERY_CHANNEL)
            .setMethodCallHandler { call: MethodCall, result: MethodChannel.Result ->
                when (call.method) {
                    "disableBatteryOptimization" -> {
                        requestIgnoreBatteryOptimizations()
                        result.success(null)
                    }
                    "isIgnoringBatteryOptimization" -> {
                        result.success(isIgnoringBatteryOptimizations())
                    }
                    else -> result.notImplemented()
                }
            }

        // Unified native service channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, LOCATION_CHANNEL)
            .setMethodCallHandler { call: MethodCall, result: MethodChannel.Result ->
                when (call.method) {
                    "startService" -> {
                        val token: String?        = call.argument("token")
                        val refreshToken: String? = call.argument("refreshToken")
                        val trackingToken: String? = call.argument("trackingToken")
                        val trackingSessionId: String? = call.argument("trackingSessionId")
                        val driverId: String?     = call.argument("driverId")
                        val wsUrl: String?        = call.argument("wsUrl")
                        val baseApi: String?      = call.argument("baseApiUrl")
                        val driverName: String?   = call.argument("driverName")
                        val vehiclePlate: String? = call.argument("vehiclePlate")

                        ConfigStore.write(
                            this,
                            ConfigStore.KEY_TOKEN to token,
                            ConfigStore.KEY_REFRESH_TOKEN to refreshToken,
                            ConfigStore.KEY_TRACKING_TOKEN to trackingToken,
                            ConfigStore.KEY_TRACKING_SESSION_ID to trackingSessionId,
                            ConfigStore.KEY_DRIVER_ID to driverId,
                            ConfigStore.KEY_WS_URL to wsUrl,
                            ConfigStore.KEY_BASE_API to baseApi,
                            ConfigStore.KEY_DRIVER_NAME to driverName,
                            ConfigStore.KEY_VEHICLE_PLATE to vehiclePlate
                        )

                        ensureExactAlarms()
                        ensureHealthWatchdog()
                        pokeWatchdogNow() // run the watchdog immediately once
                        requestIgnoreBatteryOptimizationsIfNeeded()

                        val started = safeStartService()
                        result.success(started)
                    }

                    "updateToken" -> {
                        val token: String? = call.argument("token")
                        val refreshToken: String? = call.argument("refreshToken")
                        val trackingToken: String? = call.argument("trackingToken")
                        val trackingSessionId: String? = call.argument("trackingSessionId")
                        if (!token.isNullOrBlank() || !refreshToken.isNullOrBlank() || !trackingToken.isNullOrBlank()) {
                            ConfigStore.write(
                                this,
                                ConfigStore.KEY_TOKEN to token,
                                ConfigStore.KEY_REFRESH_TOKEN to refreshToken,
                                ConfigStore.KEY_TRACKING_TOKEN to trackingToken,
                                ConfigStore.KEY_TRACKING_SESSION_ID to trackingSessionId
                            )
                            applicationContext.sendBroadcast(
                                Intent(LocationService.ACTION_TOKEN_UPDATED)
                                    .setPackage(packageName)
                            )
                        }
                        result.success(true)
                    }

                    "notifyTokenUpdated" -> {
                        val token: String? = call.argument("token")
                        val refreshToken: String? = call.argument("refreshToken")
                        val trackingToken: String? = call.argument("trackingToken")
                        val trackingSessionId: String? = call.argument("trackingSessionId")
                        if (!token.isNullOrBlank() || !refreshToken.isNullOrBlank() || !trackingToken.isNullOrBlank()) {
                            ConfigStore.write(
                                this,
                                ConfigStore.KEY_TOKEN to token,
                                ConfigStore.KEY_REFRESH_TOKEN to refreshToken,
                                ConfigStore.KEY_TRACKING_TOKEN to trackingToken,
                                ConfigStore.KEY_TRACKING_SESSION_ID to trackingSessionId
                            )
                        }
                        applicationContext.sendBroadcast(
                            Intent(LocationService.ACTION_TOKEN_UPDATED)
                                .setPackage(packageName)
                        )
                        result.success(true)
                    }

                    "stopService" -> {
                        userStopService()
                        result.success(true)
                    }

                    "isServiceRunning" -> result.success(ConfigStore.isRunning(this))

                    else -> result.notImplemented()
                }
            }

        // Route bridge: allow native to push routes and Dart to pull initial route
        routeChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ROUTE_CHANNEL)
        routeChannel?.setMethodCallHandler { call: MethodCall, result: MethodChannel.Result ->
            when (call.method) {
                "getInitialRoute" -> {
                    val r = intent?.getStringExtra("route")
                    if (!r.isNullOrBlank()) result.success(mapOf("route" to r)) else result.success(null)
                }
                else -> result.notImplemented()
            }
        }
        // If launched with an initial route, push it immediately
        intent?.getStringExtra("route")?.let { r ->
            try { routeChannel?.invokeMethod("openRoute", mapOf("route" to r)) } catch (_: Exception) {}
        }

        // Diagnostics bridge: surface config, permissions, channel presence, and last heartbeat
        diagChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DIAG_CHANNEL)
        diagChannel?.setMethodCallHandler { call: MethodCall, result: MethodChannel.Result ->
            when (call.method) {
                "getDiagnostics" -> {
                    try {
                        val ctx = this@MainActivity
                        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                        fun hasChannel(id: String): Boolean =
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) nm.getNotificationChannel(id) != null else true
                        val notifEnabled = NotificationManagerCompat.from(ctx).areNotificationsEnabled()
                        val pendingQueueRaw = ConfigStore.pendingLocationQueue(ctx)
                        val data = mapOf(
                            "baseApi" to ConfigStore.baseApi(ctx),
                            "wsUrl" to ConfigStore.wsUrl(ctx),
                            "driverId" to ConfigStore.driverId(ctx),
                            "driverName" to ConfigStore.driverName(ctx),
                            "vehiclePlate" to ConfigStore.vehiclePlate(ctx),
                            "running" to ConfigStore.isRunning(ctx),
                            "alive" to ConfigStore.isProbablyRunning(ctx),
                            "userStop" to ConfigStore.isUserStop(ctx),
                            "lastHeartbeatMs" to ConfigStore.lastHeartbeatMs(ctx),
                            "pendingQueueDepth" to ConfigStore.pendingLocationQueueDepth(ctx),
                            "pendingQueueBytes" to pendingQueueRaw.toByteArray().size,
                            "hasAccessToken" to ConfigStore.token(ctx).isNotBlank(),
                            "hasTrackingToken" to ConfigStore.trackingToken(ctx).isNotBlank(),
                            "hasTrackingSessionId" to ConfigStore.trackingSessionId(ctx).isNotBlank(),
                            "notifEnabled" to notifEnabled,
                            "hasAlertsChannel" to hasChannel("sv_driver_alerts"),
                            "hasUpdatesChannel" to hasChannel("sv_driver_notifications")
                        )
                        result.success(data)
                    } catch (e: Exception) {
                        result.error("DIAG_FAIL", e.message, null)
                    }
                }
                "getInfo" -> {
                    try {
                        val ctx = this@MainActivity
                        result.success(
                            mapOf(
                                "baseApi" to ConfigStore.baseApi(ctx),
                                "wsUrl" to ConfigStore.wsUrl(ctx),
                                "driverId" to ConfigStore.driverId(ctx),
                                "driverName" to ConfigStore.driverName(ctx),
                                "vehiclePlate" to ConfigStore.vehiclePlate(ctx),
                                "running" to ConfigStore.isRunning(ctx),
                                "alive" to ConfigStore.isProbablyRunning(ctx),
                                "lastHeartbeatMs" to ConfigStore.lastHeartbeatMs(ctx),
                                "pendingQueueDepth" to ConfigStore.pendingLocationQueueDepth(ctx),
                                "hasTrackingToken" to ConfigStore.trackingToken(ctx).isNotBlank(),
                                "hasTrackingSessionId" to ConfigStore.trackingSessionId(ctx).isNotBlank()
                            )
                        )
                    } catch (e: Exception) {
                        result.error("DIAG_FAIL", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val r = intent.getStringExtra("route")
        if (!r.isNullOrBlank()) {
            try { routeChannel?.invokeMethod("openRoute", mapOf("route" to r)) } catch (_: Exception) {}
        }
    }

    /** Starts the location service when minimum config is present. Always clears userStop. */
    private fun safeStartService(): Boolean {
        // User tapped "Start" → clear any previous stop flag
        ConfigStore.setUserStop(this, false)

        if (!ConfigStore.hasMinimumConfig(this)) return false

        val intent = Intent(this, LocationService::class.java).apply {
            action = LocationService.ACTION_START
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
        return true
    }

    private fun userStopService() {
        ConfigStore.setUserStop(this, true)
        val i = Intent(this, LocationService::class.java).apply {
            action = LocationService.ACTION_STOP
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(i)
        } else {
            startService(i)
        }
        ConfigStore.clearTrackingConfig(this)
    }

    private fun ensureExactAlarms() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val am = getSystemService(Context.ALARM_SERVICE) as AlarmManager
            if (!am.canScheduleExactAlarms()) {
                // Only nudge; user can grant later in Settings
                Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM).apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    startActivityCatching(this)
                }
            }
        }
    }

    // Battery optimization helpers
    private fun requestIgnoreBatteryOptimizations() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
            if (!pm.isIgnoringBatteryOptimizations(packageName)) {
                val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                    data = Uri.parse("package:$packageName")
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                startActivityCatching(intent)
            }
        }
    }

    private fun requestIgnoreBatteryOptimizationsIfNeeded() {
        if (!isIgnoringBatteryOptimizations()) requestIgnoreBatteryOptimizations()
    }

    private fun isIgnoringBatteryOptimizations(): Boolean =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
            pm.isIgnoringBatteryOptimizations(packageName)
        } else true

    /** Periodic watchdog (15 min) */
    private fun ensureHealthWatchdog() {
        val periodic = PeriodicWorkRequestBuilder<HealthWatchdogWorker>(15, TimeUnit.MINUTES)
            .setConstraints(Constraints.Builder().build())
            .build()
        WorkManager.getInstance(applicationContext).enqueueUniquePeriodicWork(
            WATCHDOG_UNIQUE,
            ExistingPeriodicWorkPolicy.UPDATE,
            periodic
        )
    }

    /** One-time immediate watchdog to kick things off right away */
    private fun pokeWatchdogNow() {
        val once = OneTimeWorkRequestBuilder<HealthWatchdogWorker>()
            .setConstraints(Constraints.Builder().build())
            .build()
        WorkManager.getInstance(applicationContext).enqueueUniqueWork(
            WATCHDOG_NOW,
            ExistingWorkPolicy.REPLACE,
            once
        )
    }

    private fun startActivityCatching(intent: Intent) {
        try { startActivity(intent) } catch (_: Exception) { /* ignore */ }
    }
}
