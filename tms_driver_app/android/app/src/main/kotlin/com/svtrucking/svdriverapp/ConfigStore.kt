package com.svtrucking.svdriverapp

import android.content.Context
import android.content.SharedPreferences
import android.os.Build
import android.os.SystemClock
import org.json.JSONArray

object ConfigStore {
    private const val SP_NAME = "sv_native"

    // String keys
    const val KEY_TOKEN         = "token"
    const val KEY_REFRESH_TOKEN = "refreshToken"
    const val KEY_TRACKING_TOKEN = "trackingToken"
    const val KEY_TRACKING_SESSION_ID = "trackingSessionId"
    const val KEY_DRIVER_ID     = "driverId"
    const val KEY_DRIVER_NAME   = "driverName"
    const val KEY_VEHICLE_PLATE = "vehiclePlate"
    const val KEY_WS_URL        = "ws_url"
    const val KEY_BASE_API      = "base_api_url"
    const val KEY_PENDING_LOCATION_QUEUE = "pendingLocationQueue"

    // State flags
    private const val KEY_SERVICE_RUN = "service_running"
    private const val KEY_USER_STOP   = "service_user_stop"

    // Heartbeat (elapsedRealtime)
    private const val KEY_HEARTBEAT_ELAPSED_MS = "service_heartbeat_elapsed_ms"

    // Watchdog backoff (elapsedRealtime)
    private const val KEY_WATCHDOG_LAST_ATTEMPT_ELAPSED_MS = "watchdog_last_attempt_elapsed_ms"

    @Volatile private var cachedSp: SharedPreferences? = null

    /** Device-Protected Storage so receivers/workers can read before unlock. */
    private fun sp(ctx: Context): SharedPreferences {
        cachedSp?.let { return it }
        val app = ctx.applicationContext
        val prefs = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            val dps = app.createDeviceProtectedStorageContext()
            try { dps.moveSharedPreferencesFrom(app, SP_NAME) } catch (_: Throwable) {}
            dps.getSharedPreferences(SP_NAME, Context.MODE_PRIVATE)
        } else {
            app.getSharedPreferences(SP_NAME, Context.MODE_PRIVATE)
        }
        cachedSp = prefs
        return prefs
    }

    // Generic writes/reads
    fun write(ctx: Context, vararg pairs: Pair<String, String?>) {
        val ed = sp(ctx).edit()
        pairs.forEach { (k, v) -> if (v == null) ed.remove(k) else ed.putString(k, v) }
        ed.apply()
    }
    fun writeCommit(ctx: Context, vararg pairs: Pair<String, String?>): Boolean {
        val ed = sp(ctx).edit()
        pairs.forEach { (k, v) -> if (v == null) ed.remove(k) else ed.putString(k, v) }
        return ed.commit()
    }
    fun read(ctx: Context, key: String, def: String = ""): String =
        sp(ctx).getString(key, def) ?: def

    // Running flag + heartbeat
    fun setRunning(ctx: Context, running: Boolean) {
        sp(ctx).edit().putBoolean(KEY_SERVICE_RUN, running).apply()
        if (running) touchHeartbeat(ctx) else clearHeartbeat(ctx)
    }
    fun isRunning(ctx: Context): Boolean = sp(ctx).getBoolean(KEY_SERVICE_RUN, false)

    /** Alive iff running flag is set AND heartbeat is fresh. */
    fun isProbablyRunning(ctx: Context, maxAgeMs: Long = 60_000L): Boolean {
        if (!isRunning(ctx)) return false
        val last = lastHeartbeat(ctx)
        return last > 0L && (SystemClock.elapsedRealtime() - last <= maxAgeMs)
    }

    // User stop (watchdog will IGNORE this — it auto restarts)
    fun setUserStop(ctx: Context, value: Boolean) =
        sp(ctx).edit().putBoolean(KEY_USER_STOP, value).apply()
    fun wasUserStop(ctx: Context): Boolean = sp(ctx).getBoolean(KEY_USER_STOP, false)
    fun getUserStop(ctx: Context): Boolean = wasUserStop(ctx)

    // --- Back-compat helpers for diagnostics / MainActivity ---
    /** Alias for legacy name expected by diagnostics bridge. */
    fun isUserStop(ctx: Context): Boolean = getUserStop(ctx)

    /**
     * Convert the last heartbeat stored in elapsedRealtime() units to a wall-clock epoch millis.
     * Returns 0 if there is no heartbeat recorded yet.
     */
    fun lastHeartbeatMs(ctx: Context): Long {
        val lastElapsed = lastHeartbeat(ctx)
        if (lastElapsed <= 0L) return 0L
        val nowElapsed = SystemClock.elapsedRealtime()
        val nowWall = java.lang.System.currentTimeMillis()
        val delta = nowElapsed - lastElapsed
        return (nowWall - delta).coerceAtLeast(0L)
    }

    // Convenience getters
    fun token(ctx: Context)        = read(ctx, KEY_TOKEN)
    fun refreshToken(ctx: Context) = read(ctx, KEY_REFRESH_TOKEN)
    fun trackingToken(ctx: Context)= read(ctx, KEY_TRACKING_TOKEN)
    fun trackingSessionId(ctx: Context)= read(ctx, KEY_TRACKING_SESSION_ID)
    fun driverId(ctx: Context)     = read(ctx, KEY_DRIVER_ID)
    fun wsUrl(ctx: Context)        = read(ctx, KEY_WS_URL)
    fun baseApi(ctx: Context)      = read(ctx, KEY_BASE_API)
    fun pendingLocationQueue(ctx: Context) = read(ctx, KEY_PENDING_LOCATION_QUEUE)
    fun pendingLocationQueueDepth(ctx: Context): Int = try {
        val raw = pendingLocationQueue(ctx).trim()
        if (raw.isEmpty()) 0 else JSONArray(raw).length()
    } catch (_: Exception) {
        0
    }
    fun driverName(ctx: Context)   = read(ctx, KEY_DRIVER_NAME)
    fun vehiclePlate(ctx: Context) = read(ctx, KEY_VEHICLE_PLATE)

    // Readiness
    fun hasMinimumConfig(ctx: Context): Boolean {
        val hasIdentity = token(ctx).isNotBlank() && driverId(ctx).isNotBlank()
        val hasEndpoint = baseApi(ctx).isNotBlank() || wsUrl(ctx).isNotBlank()
        return hasIdentity && hasEndpoint
    }

    // Heartbeat
    fun touchHeartbeat(ctx: Context) =
        sp(ctx).edit().putLong(KEY_HEARTBEAT_ELAPSED_MS, SystemClock.elapsedRealtime()).apply()
    fun lastHeartbeat(ctx: Context): Long =
        sp(ctx).getLong(KEY_HEARTBEAT_ELAPSED_MS, 0L)
    private fun clearHeartbeat(ctx: Context) =
        sp(ctx).edit().remove(KEY_HEARTBEAT_ELAPSED_MS).apply()

    // Watchdog backoff
    fun setWatchdogLastAttempt(ctx: Context, elapsedMs: Long = SystemClock.elapsedRealtime()) =
        sp(ctx).edit().putLong(KEY_WATCHDOG_LAST_ATTEMPT_ELAPSED_MS, elapsedMs).apply()
    fun lastWatchdogAttempt(ctx: Context): Long =
        sp(ctx).getLong(KEY_WATCHDOG_LAST_ATTEMPT_ELAPSED_MS, 0L)

    fun clearAll(ctx: Context) { sp(ctx).edit().clear().apply() }

    fun clearTrackingConfig(ctx: Context) {
        sp(ctx).edit()
            .remove(KEY_TOKEN)
            .remove(KEY_REFRESH_TOKEN)
            .remove(KEY_DRIVER_ID)
            .remove(KEY_DRIVER_NAME)
            .remove(KEY_VEHICLE_PLATE)
            .remove(KEY_TRACKING_TOKEN)
            .remove(KEY_TRACKING_SESSION_ID)
            .remove(KEY_WS_URL)
            .remove(KEY_BASE_API)
            .remove(KEY_SERVICE_RUN)
            .remove(KEY_HEARTBEAT_ELAPSED_MS)
            .apply()
    }
}
