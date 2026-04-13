
package com.svtrucking.svdriverapp

import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.net.ConnectivityManager.NetworkCallback

import android.Manifest
import android.app.*
import android.content.*
import android.content.pm.PackageManager
import android.os.*
import android.util.Log
import androidx.work.*
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationCompat
import com.google.android.gms.location.*
import com.svtrucking.svdriverapp.core.AndroidKeys
//import com.svtrucking.svdriverapp.BuildConfig
import okhttp3.*
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.RequestBody.Companion.toRequestBody
import okio.ByteString
import org.json.JSONArray
import org.json.JSONObject
import java.io.IOException
import java.util.ArrayDeque
import java.util.concurrent.TimeUnit

class LocationService : Service() {

    companion object {
        private const val TAG = "LocationService"
        private const val NOTIF_CHANNEL_ID = "sv_driver_notifications"
        private const val NOTIF_ID = 1001

        const val ACTION_START         = "com.svtrucking.svdriverapp.ACTION_START_LOCATION"
        const val ACTION_STOP          = "com.svtrucking.svdriverapp.ACTION_STOP_LOCATION"
        const val ACTION_RESTART       = "com.svtrucking.svdriverapp.RESTART_SERVICE"
        const val ACTION_TOKEN_UPDATED = "com.svtrucking.svdriverapp.ACTION_TOKEN_UPDATED"

        const val EXTRA_WS_URL    = "url"
        const val EXTRA_TOKEN     = "token"
        const val EXTRA_DRIVER_ID = "driverId"
    }

    // In debug/dev builds, bypass client-side drop rules so we always emit for testing.
    private fun devNoDrop(): Boolean {
        return true
        //return BuildConfig.DEBUG
        //    || BuildConfig.FLAVOR.equals("dev", ignoreCase = true)
        //    || "1" == System.getProperty("com.svtrucking.svdriverapp.dev")
        //    || "1" == System.getenv("SV_DEV_NODROP")
    }

    // --- Debug helper for why points are dropped ---
    private fun logDrop(reason: String) {
        Log.v(TAG, "⛔ drop: $reason")
    }

    // --- Location permission helpers ---
private fun hasWhileInUse(ctx: Context): Boolean {
    val fine = ActivityCompat.checkSelfPermission(ctx, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED
    val coarse = ActivityCompat.checkSelfPermission(ctx, Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED
    return fine || coarse
}

private fun hasBackground(ctx: Context): Boolean {
    // On Android Q (API 29) and above, require ACCESS_BACKGROUND_LOCATION
    return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
        val bg = ActivityCompat.checkSelfPermission(ctx, Manifest.permission.ACCESS_BACKGROUND_LOCATION) == PackageManager.PERMISSION_GRANTED
        bg && hasWhileInUse(ctx)
    } else {
        hasWhileInUse(ctx)
    }
}

    private lateinit var fused: FusedLocationProviderClient
    private var callback: LocationCallback? = null
    private var locationThread: HandlerThread? = null
    private var started = false

    // Heartbeat
    private var heartbeatHandler: Handler? = null
    private var heartbeatRunnable: Runnable? = null
    private var lastHeartbeatMs: Long = 0L          // keep
    private val HEARTBEAT_INTERVAL_MS = 20_000L     // was 25_000 (≤35s ONLINE needs cushion)
    private val HEARTBEAT_MIN_GAP_MS = 12_000L      // don't spam HB on bursts (net-up, token-update, dedupe)
    private val HEARTBEAT_AUTH_COOLDOWN_MS = 15_000L
    private val TOKEN_SETTLE_DELAY_MS = 3_000L
    @Volatile private var heartbeatCooldownUntilMs: Long = 0L
    @Volatile private var tokenSettledUntilMs: Long = 0L

    // Client-side throttle/dedupe aligned with server @15s cadence
    private val CLIENT_MIN_TIME_MS = 6_000L         // was 8_000 (accept periodic points sooner)
    private val CLIENT_MIN_DIST_M  = 15.0           // was 25.0 (more sensitive movement @15s)
    private var warmupDrops = 2 // drop first 2 fixes so GPS can converge

    private var lastSentLat = Double.NaN
    private var lastSentLng = Double.NaN
    private var lastSentTs  = 0L

    private var ws: WebSocket? = null
    private var wsRetry = 0
    private var pointSeq = 0L
    private val LOCATION_UPDATE_INTERVAL_MS = 15_000L // keep
    @Volatile private var refreshInFlight = false

    // --- Offline queue & backoff (REST flush) ---
    private val pendingLiveQueue: ArrayDeque<JSONObject> = ArrayDeque()
    private val queueLock = Any()
    private val MAX_QUEUE_SIZE = 5_000
    private val MAX_PENDING_AGE_MS = 2 * 60 * 60 * 1000L // 2 hours
    private val MAX_BATCH_FLUSH_SIZE = 50
    private var batchFlushSupported = true
    private var backoffMs = 1_000L
    private val MAX_BACKOFF_MS = 60_000L
    private var flushHandler: Handler? = null
    private var isFlushing = false

    private val client: OkHttpClient by lazy {
        OkHttpClient.Builder()
            .connectTimeout(10, TimeUnit.SECONDS)
            .readTimeout(30, TimeUnit.SECONDS)
            .writeTimeout(30, TimeUnit.SECONDS)
            .pingInterval(20, TimeUnit.SECONDS)
            .retryOnConnectionFailure(true)
            .build()
    }

    private val tokenUpdatedReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action == ACTION_TOKEN_UPDATED) {
                tokenSettledUntilMs = android.os.SystemClock.elapsedRealtime() + TOKEN_SETTLE_DELAY_MS
                Log.d(TAG, "Token updated → delay heartbeat until token settles")
                scheduleHeartbeatKick("token-update", TOKEN_SETTLE_DELAY_MS)
            }
        }
    }

    private fun hasNetwork(): Boolean = try {
        val cm = getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        val net = cm.activeNetwork ?: return false
        val caps = cm.getNetworkCapabilities(net) ?: return false
        // Require both INTERNET and VALIDATED to avoid captive/partial connectivity
        caps.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET) &&
                caps.hasCapability(NetworkCapabilities.NET_CAPABILITY_VALIDATED)
    } catch (_: Exception) { false }

    // Modern network callback (replaces deprecated CONNECTIVITY_ACTION)
    private val networkCallback = object : NetworkCallback() {
        override fun onAvailable(network: android.net.Network) {
            Log.d(TAG, "NetworkCallback.onAvailable → HB + REST flush (WS disabled)")
            maybeSendHeartbeat("net-up")
            // WS disabled: only flush REST queue
            scheduleFlush(immediate = true)
        }
        override fun onLost(network: android.net.Network) {
            Log.w(TAG, "NetworkCallback.onLost")
        }
    }

    override fun onCreate() {
        super.onCreate()
        startForegroundNotification()
        fused = LocationServices.getFusedLocationProviderClient(this)

        val filter = IntentFilter(ACTION_TOKEN_UPDATED)
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                registerReceiver(tokenUpdatedReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
            } else {
                @Suppress("DEPRECATION")
                registerReceiver(tokenUpdatedReceiver, filter)
            }
            Log.d(TAG, "tokenUpdatedReceiver registered")
        } catch (e: Exception) {
            Log.e(TAG, "registerReceiver(tokenUpdatedReceiver) failed", e)
        }
        // Register modern network callback
        try {
            val cm = getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
            cm.registerDefaultNetworkCallback(networkCallback)
            Log.d(TAG, "NetworkCallback registered")
        } catch (e: Exception) {
            Log.e(TAG, "registerDefaultNetworkCallback failed", e)
        }
        // init flush handler
        if (flushHandler == null) flushHandler = Handler(Looper.getMainLooper())
        restorePendingQueue()
        lastHeartbeatMs = 0L
        Log.d(TAG, "Service created")
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val action = intent?.action
        Log.d(TAG, "onStartCommand flags=$flags action=$action")

        logCurrentConfig("Startup")

        when (action) {
            ACTION_STOP -> {
                ConfigStore.setUserStop(this, true)
                ConfigStore.setRunning(this, false)
                try { callback?.let { fused.removeLocationUpdates(it) } } catch (_: Exception) {}
                try { ws?.close(1000, "user-stop") } catch (_: Exception) {}
                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelf()
                return START_NOT_STICKY
            }
            AndroidKeys.ACTION_PUSH_LOCATION -> {
                handlePushedLocation(intent)
                return START_STICKY
            }
        }

        // Persist extras if provided
        intent?.getStringExtra(EXTRA_WS_URL)
            ?.let { ConfigStore.write(this, ConfigStore.KEY_WS_URL to it) }
        intent?.getStringExtra(EXTRA_TOKEN)
            ?.let { ConfigStore.write(this, ConfigStore.KEY_TOKEN to it) }
        intent?.getStringExtra(EXTRA_DRIVER_ID)
            ?.let { ConfigStore.write(this, ConfigStore.KEY_DRIVER_ID to it) }

        if (!ConfigStore.hasMinimumConfig(this)) {
            Log.e(TAG, "Missing config (ws_url/token/driverId). Service will remain idle.")
            ConfigStore.setRunning(this, false) // allow watchdog to retry later
            return START_STICKY
        }

        if (!hasBackground(this)) {
            Log.w(TAG, "Background location not granted → service idle until granted")
            ConfigStore.setRunning(this, false)
            return START_STICKY
        }

        if (!started) {
            val startUrlPreview = run {
                val direct = wsUrlWithToken()
                if (direct.isNotEmpty()) {
                    maskUrl(direct)
                } else {
                    val derived = deriveWsFromBase(baseApiUrl().trimEnd('/'))
                    if (derived.isNotEmpty()) "${derived}?token=***" else "<no-url>"
                }
            }
            Log.d(TAG, "Starting location after config ready (WS disabled) → $startUrlPreview")
            // WS disabled: using REST-only for native service
            startLocationUpdatesBackgroundLooper()
            started = true
            ConfigStore.setUserStop(this, false)
            ConfigStore.setRunning(this, true) // mark alive
            tokenSettledUntilMs = android.os.SystemClock.elapsedRealtime() + TOKEN_SETTLE_DELAY_MS
            // Kick off heartbeat loop without an eager immediate POST.
            ensureHeartbeatLoop()
            scheduleHeartbeatKick("startup", TOKEN_SETTLE_DELAY_MS)
        } else {
            Log.d(TAG, "Already started; skipping WS refresh (disabled)")
        }
        return START_STICKY
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        super.onTaskRemoved(rootIntent)
        scheduleRestartAlarm(requestCode = 1002, delayMs = 2_000L)
        Log.w(TAG, "onTaskRemoved → scheduled service restart")
    }

    override fun onDestroy() {
        val shouldAutoRestart = !ConfigStore.getUserStop(this) && ConfigStore.hasMinimumConfig(this)
        try { unregisterReceiver(tokenUpdatedReceiver) } catch (_: Exception) {}
        try { callback?.let { fused.removeLocationUpdates(it) } } catch (_: Exception) {}
        try { ws?.close(1000, "destroy") } catch (_: Exception) {}
        try { locationThread?.quitSafely() } catch (_: Exception) {}
        started = false
        ConfigStore.setRunning(this, false)
        try { heartbeatHandler?.removeCallbacks(heartbeatRunnable ?: Runnable {}) } catch (_: Exception) {}
        try {
            val cm = getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
            cm.unregisterNetworkCallback(networkCallback)
        } catch (_: Exception) {}
        try { flushHandler?.removeCallbacksAndMessages(null) } catch (_: Exception) {}
        if (shouldAutoRestart) {
            scheduleRestartAlarm(requestCode = 1003, delayMs = 2_000L)
            Log.w(TAG, "onDestroy → scheduled service restart")
        }
        super.onDestroy()
        Log.d(TAG, "Service destroyed")
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun startForegroundNotification() {
        val nm = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            nm.createNotificationChannel(
                NotificationChannel(
                    NOTIF_CHANNEL_ID,
                    "Driver Tracking",
                    NotificationManager.IMPORTANCE_LOW
                )
            )
        }
        val notif: Notification = NotificationCompat.Builder(this, NOTIF_CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_truck)
            .setContentTitle("SV Trucking: Tracking Active")
            .setContentText("SV Partner is running.")
            .setOngoing(true)
            .setForegroundServiceBehavior(NotificationCompat.FOREGROUND_SERVICE_IMMEDIATE)
            .build()
        // Manifest already declares foregroundServiceType="location" (no DATA_SYNC type required)
        startForeground(NOTIF_ID, notif)
    }

    // --- Helpers / config ---

    private fun logCurrentConfig(prefix: String = "Config") {
        val ws = wsUrl()
        val api = baseApiUrl()
        Log.d(TAG, "$prefix → baseApi=${api.ifEmpty { "<empty>" }}, wsUrl=${if (ws.isEmpty()) "<empty>" else maskUrl(ws)}")
    }

    private fun deriveWsFromBase(apiBase: String): String {
        if (apiBase.isBlank()) return ""
        val base = apiBase.trimEnd('/')
        val wsBase = when {
            base.startsWith("https://", true) -> base.replaceFirst(Regex("(?i)^https://"), "wss://")
            base.startsWith("http://",  true) -> base.replaceFirst(Regex("(?i)^http://"),  "ws://")
            base.startsWith("wss://",   true) -> base
            base.startsWith("ws://",    true) -> base
            else -> "ws://$base"
        }
        return "$wsBase/ws"
    }

    private fun urlHost(u: String): String = try {
        val s = u.substringBefore('#')
        val h = s.substringAfter("//").substringBefore('/')
        h.substringBefore('?')
    } catch (_: Exception) { "" }

    // --- WebSocket (optional transport) ---
    private fun connectWebSocket() {
        var url = wsUrlWithToken()

        // If missing, derive from base API
        if (url.isEmpty()) {
            val api = baseApiUrl().trimEnd('/')
            if (api.isNotEmpty()) {
                url = deriveWsFromBase(api)
                val t = token()
                url = if (url.contains("token=")) url.replace(Regex("token=[^&]*"), "token=$t")
                else if (url.contains("?")) "$url&token=$t" else "$url?token=$t"
                Log.w(TAG, "WS url was empty; derived from baseApi → ${maskUrl(url)}")
            }
        } else {
            // If WS host does not match base API host, prefer base API
            val api = baseApiUrl().trimEnd('/')
            if (api.isNotEmpty()) {
                val wsHost  = urlHost(url)
                val apiHost = urlHost(api)
                if (wsHost.isNotEmpty() && apiHost.isNotEmpty() && !wsHost.equals(apiHost, ignoreCase = true)) {
                    val derived = deriveWsFromBase(api)
                    val t = token()
                    val withTok = if (derived.contains("token=")) derived.replace(Regex("token=[^&]*"), "token=$t")
                                  else if (derived.contains("?")) "$derived&token=$t" else "$derived?token=$t"
                    Log.w(TAG, "WS host (${wsHost}) ≠ baseApi host (${apiHost}); using derived → ${maskUrl(withTok)}")
                    url = withTok
                }
            }
        }

        if (url.isEmpty()) {
            Log.e(TAG, "ws_url empty; not connecting")
            return
        }

        val req = Request.Builder()
            .url(url)
            .addHeader("Authorization", "Bearer ${authTokenForTracking()}")
            .build()

        ws = client.newWebSocket(req, object : WebSocketListener() {
            override fun onOpen(webSocket: WebSocket, response: Response) {
                Log.d(TAG, "WS connected")
                wsRetry = 0
            }
            override fun onFailure(webSocket: WebSocket, t: Throwable, response: Response?) {
                Log.e(TAG, "WS failure: ${t.message}")
                wsRetry++
                ws = null
                val delay = (1000L * (1 shl wsRetry).coerceAtMost(32)) // 1s,2s,4s,...,32s
                Handler(Looper.getMainLooper()).postDelayed({ reconnectWebSocket() }, delay)
            }
            override fun onClosed(webSocket: WebSocket, code: Int, reason: String) {
                Log.w(TAG, "WS closed: $code $reason")
            }
            override fun onMessage(webSocket: WebSocket, text: String) {}
            override fun onMessage(webSocket: WebSocket, bytes: ByteString) {}
        })
    }
    private fun reconnectWebSocket() {
        try { ws?.close(1000, "reconnect") } catch (_: Exception) {}
        connectWebSocket()
    }

    private fun scheduleRestartAlarm(requestCode: Int, delayMs: Long) {
        val i = Intent(this, RestartReceiver::class.java).apply { action = ACTION_RESTART }
        val pi = PendingIntent.getBroadcast(
            this,
            requestCode,
            i,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_CANCEL_CURRENT
        )
        val am = getSystemService(ALARM_SERVICE) as AlarmManager
        am.setExact(
            AlarmManager.ELAPSED_REALTIME_WAKEUP,
            android.os.SystemClock.elapsedRealtime() + delayMs,
            pi
        )
    }

 // Make the FGS use REST only.
// (You can keep WS for presence or future use, but don’t use it for location.)
private fun sendLive(payload: JSONObject) {
    // Single-source logging happens inside postRestWithQueueFallback()
    postRestWithQueueFallback(payload)
}

private fun locationAuthToken(): String? {
    val tracking = trackingToken().trim()
    val sessionId = trackingSessionId().trim()
    if (sessionId.isNotEmpty()) {
        return tracking.takeIf { it.isNotEmpty() }
    }
    if (tracking.isNotEmpty()) return tracking
    return token().trim().takeIf { it.isNotEmpty() }
}

private fun heartbeatAuthToken(): String? {
    val tracking = trackingToken().trim()
    if (tracking.isNotEmpty()) return tracking
    return token().trim().takeIf { it.isNotEmpty() }
}

private fun refreshLocationAuthSync(): Boolean {
    return if (trackingSessionId().trim().isNotEmpty()) {
        refreshTrackingTokenSync()
    } else {
        refreshTrackingTokenSync() || refreshAccessTokenSync()
    }
}

/**
 * Clears only the tracking token and session ID from ConfigStore.
 * Called on HTTP 403 so the next location upload forces a fresh
 * startTrackingSession call instead of looping with a stale session.
 */
private fun clearTrackingSessionOnly() {
    ConfigStore.write(
        this,
        ConfigStore.KEY_TRACKING_TOKEN to "",
        ConfigStore.KEY_TRACKING_SESSION_ID to ""
    )
}

private fun postRestWithQueueFallback(body: JSONObject, allowAuthRetry: Boolean = true) {
    // Drop payloads with driverId=0 — they will always get a 403 from the server.
    // This happens when ConfigStore hasn't received a valid driverId yet (race at startup
    // or cold-boot). Do NOT enqueue: replaying a payload with driverId=0 later won't help.
    val payloadDriverId = body.optLong("driverId", 0L)
    if (payloadDriverId <= 0L) {
        Log.w(TAG, "REST ↑ dropped: payload driverId=$payloadDriverId (missing from ConfigStore)")
        return
    }
    val api = baseApiUrl().trimEnd('/')
    val authToken = locationAuthToken()
    if (api.isEmpty() || authToken.isNullOrBlank() || !hasNetwork()) {
        if (authToken.isNullOrBlank()) {
            Log.w(TAG, "Location write deferred: missing tracking token for session-backed payload")
        }
        enqueuePending(body)
        scheduleFlush(immediate = false)
        return
    }

    // Strip fields the server DTO doesn't know about to keep payload schema clean
    body.remove("provider")
    body.remove("timestampEpochMs")
    body.remove("clientTimeIso")

    val url = "$api/driver/location"
    val reqBody = body.toString().toRequestBody("application/json".toMediaType())
    val req = Request.Builder()
        .url(url)
        .addHeader("Authorization", "Bearer $authToken")
        .post(reqBody)
        .build()

    Log.v(TAG, "REST ↑ sending → $url payload=$body")
    client.newCall(req).enqueue(object : Callback {
        override fun onFailure(call: Call, e: IOException) {
            Log.w(TAG, "REST ↑ fail; enqueue & backoff: ${e.message}")
            enqueuePending(body)
            scheduleFlush(immediate = false)
        }
        override fun onResponse(call: Call, response: Response) {
            response.use {
                if (response.isSuccessful) {
                    Log.v(TAG, "REST ↑ OK ${response.code}")
                    // Optional WorkManager mirror once a Worker exists:
                    // enqueueWorkManagerMirror(body.toString())
                    backoffMs = 1_000L
                    scheduleFlush(immediate = true) // drain any queued items
                } else {
                    if (response.code == 403) {
                        // 403 means session/payload mismatch — a token refresh won't fix it.
                        // Clear the stale tracking session to force re-auth on next upload.
                        Log.w(TAG, "REST ↑ 403 Forbidden; clearing stale tracking session")
                        clearTrackingSessionOnly()
                        enqueuePending(body)
                        scheduleFlush(immediate = false)
                        return
                    }
                    if (allowAuthRetry && response.code == 401 && refreshLocationAuthSync()) {
                        Log.w(TAG, "REST ↑ 401; token refreshed -> retry once")
                        postRestWithQueueFallback(body, allowAuthRetry = false)
                        return
                    }
                    Log.w(TAG, "REST ↑ non-200 ${response.code}; enqueue & backoff")
                    enqueuePending(body)
                    scheduleFlush(immediate = false)
                }
            }
        }
    })
}

    private fun enqueuePending(item: JSONObject) {
        synchronized(queueLock) {
            // Purge stale records before adding new item
            while (pendingLiveQueue.isNotEmpty() && isStalePendingItem(pendingLiveQueue.peekFirst())) {
                pendingLiveQueue.pollFirst()
            }

            if (pendingLiveQueue.size >= MAX_QUEUE_SIZE) {
                pendingLiveQueue.pollFirst()
            }
            pendingLiveQueue.addLast(JSONObject(item.toString()))
            persistPendingQueueLocked()
            Log.d(TAG, "queued live point; size=${pendingLiveQueue.size}/$MAX_QUEUE_SIZE")
        }
    }

    private fun scheduleFlush(immediate: Boolean) {
        if (flushHandler == null) flushHandler = Handler(Looper.getMainLooper())
        val delay = if (immediate) 0L else backoffMs
        flushHandler?.removeCallbacks(flushRunnable)
        flushHandler?.postDelayed(flushRunnable, delay)
    }

    private val flushRunnable = Runnable { tryFlushQueue() }

    private fun tryFlushQueue() {
        if (isFlushing) return
        val item = synchronized(queueLock) {
            pendingLiveQueue.peekFirst()?.let { JSONObject(it.toString()) }
        } ?: return
        if (!hasNetwork()) {
            backoffMs = (backoffMs * 2).coerceAtMost(MAX_BACKOFF_MS)
            scheduleFlush(immediate = false)
            return
        }
        isFlushing = true
        val api = baseApiUrl().trimEnd('/')
        if (api.isEmpty()) {
            isFlushing = false
            backoffMs = (backoffMs * 2).coerceAtMost(MAX_BACKOFF_MS)
            scheduleFlush(immediate = false)
            return
        }
        val authToken = locationAuthToken()
        if (authToken.isNullOrBlank()) {
            isFlushing = false
            Log.w(TAG, "flush deferred: missing tracking token for session-backed payload")
            backoffMs = (backoffMs * 2).coerceAtMost(MAX_BACKOFF_MS)
            scheduleFlush(immediate = false)
            return
        }
        val batch = synchronized(queueLock) { snapshotPendingBatchLocked() }
        if (batchFlushSupported && batch.size > 1) {
            flushBatch(batch, api, authToken)
            return
        }
        val url = "$api/driver/location"
        val reqBody = item.toString().toRequestBody("application/json".toMediaType())
        val req = Request.Builder()
            .url(url)
            .addHeader("Authorization", "Bearer $authToken")
            .post(reqBody)
            .build()

        Log.v(TAG, "flush → retry POST $url payload=${item}")
        client.newCall(req).enqueue(object : Callback {
            override fun onFailure(call: Call, e: IOException) {
                Log.w(TAG, "flush fail: ${e.message}")
                isFlushing = false
                backoffMs = (backoffMs * 2).coerceAtMost(MAX_BACKOFF_MS)
                scheduleFlush(immediate = false)
            }
            override fun onResponse(call: Call, response: Response) {
                response.use {
                    if (response.isSuccessful) {
                        synchronized(queueLock) {
                            pendingLiveQueue.pollFirst()
                            persistPendingQueueLocked()
                        }
                        backoffMs = 1_000L
                        isFlushing = false
                        if (synchronized(queueLock) { pendingLiveQueue.isNotEmpty() }) scheduleFlush(immediate = true)
                    } else {
                        if (response.code == 403) {
                            Log.w(TAG, "flush 403 Forbidden; clearing stale tracking session")
                            clearTrackingSessionOnly()
                            isFlushing = false
                            backoffMs = (backoffMs * 2).coerceAtMost(MAX_BACKOFF_MS)
                            scheduleFlush(immediate = false)
                            return
                        }
                        if (response.code == 401 && refreshLocationAuthSync()) {
                            Log.w(TAG, "flush 401; token refreshed -> retry queued item")
                            isFlushing = false
                            scheduleFlush(immediate = true)
                            return
                        }
                        Log.w(TAG, "flush non-200: ${response.code}")
                        isFlushing = false
                        backoffMs = (backoffMs * 2).coerceAtMost(MAX_BACKOFF_MS)
                        scheduleFlush(immediate = false)
                    }
                }
            }
        })
    }

    private fun flushBatch(batch: List<JSONObject>, api: String, authToken: String) {
        val url = "$api/driver/location/batch"
        val reqBody = JSONArray().apply {
            batch.forEach { put(JSONObject(it.toString())) }
        }.toString().toRequestBody("application/json".toMediaType())
        val req = Request.Builder()
            .url(url)
            .addHeader("Authorization", "Bearer $authToken")
            .post(reqBody)
            .build()

        Log.v(TAG, "flush batch → POST $url size=${batch.size}")
        client.newCall(req).enqueue(object : Callback {
            override fun onFailure(call: Call, e: IOException) {
                Log.w(TAG, "flush batch fail: ${e.message}")
                isFlushing = false
                backoffMs = (backoffMs * 2).coerceAtMost(MAX_BACKOFF_MS)
                scheduleFlush(immediate = false)
            }

            override fun onResponse(call: Call, response: Response) {
                response.use {
                    when {
                        response.isSuccessful -> {
                            synchronized(queueLock) {
                                repeat(batch.size.coerceAtMost(pendingLiveQueue.size)) { pendingLiveQueue.pollFirst() }
                                persistPendingQueueLocked()
                            }
                            backoffMs = 1_000L
                            isFlushing = false
                            if (synchronized(queueLock) { pendingLiveQueue.isNotEmpty() }) scheduleFlush(immediate = true)
                        }
                        response.code == 404 || response.code == 405 -> {
                            Log.w(TAG, "flush batch unsupported (${response.code}); falling back to single flush")
                            batchFlushSupported = false
                            isFlushing = false
                            scheduleFlush(immediate = true)
                        }
                        response.code == 403 -> {
                            Log.w(TAG, "flush batch 403 Forbidden; clearing stale tracking session")
                            clearTrackingSessionOnly()
                            isFlushing = false
                            backoffMs = (backoffMs * 2).coerceAtMost(MAX_BACKOFF_MS)
                            scheduleFlush(immediate = false)
                        }
                        response.code == 401 && refreshLocationAuthSync() -> {
                            Log.w(TAG, "flush batch 401; token refreshed -> retry queued batch")
                            isFlushing = false
                            scheduleFlush(immediate = true)
                        }
                        else -> {
                            Log.w(TAG, "flush batch non-200: ${response.code}")
                            isFlushing = false
                            backoffMs = (backoffMs * 2).coerceAtMost(MAX_BACKOFF_MS)
                            scheduleFlush(immediate = false)
                        }
                    }
                }
            }
        })
    }

    private fun restorePendingQueue() {
        synchronized(queueLock) {
            pendingLiveQueue.clear()
            val raw = ConfigStore.pendingLocationQueue(this).trim()
            if (raw.isEmpty()) {
                return
            }
            try {
                val data = JSONArray(raw)
                val start = if (data.length() > MAX_QUEUE_SIZE) data.length() - MAX_QUEUE_SIZE else 0
                for (i in start until data.length()) {
                    val item = data.optJSONObject(i) ?: continue
                    // Drop records that are too old (prevents replaying stale points)
                    if (isStalePendingItem(item)) continue
                    pendingLiveQueue.addLast(JSONObject(item.toString()))
                }
                persistPendingQueueLocked()
                Log.d(TAG, "restored ${pendingLiveQueue.size} pending live points")
            } catch (e: Exception) {
                Log.w(TAG, "failed to restore pending queue: ${e.message}")
                ConfigStore.write(this, ConfigStore.KEY_PENDING_LOCATION_QUEUE to null)
            }
        }
    }

    private fun isStalePendingItem(item: JSONObject): Boolean {
        return try {
            val ts = item.optLong("clientTime", -1L)
            if (ts <= 0L) return false
            val age = System.currentTimeMillis() - ts
            age > MAX_PENDING_AGE_MS
        } catch (_: Exception) {
            false
        }
    }

    private fun persistPendingQueueLocked() {
        val serialized = JSONArray().apply {
            pendingLiveQueue.forEach { put(JSONObject(it.toString())) }
        }.toString()
        val ok = ConfigStore.writeCommit(this, ConfigStore.KEY_PENDING_LOCATION_QUEUE to serialized)
        if (!ok) {
            Log.w(TAG, "Failed to persist pending location queue (commit)")
        }
    }

    private fun snapshotPendingBatchLocked(): List<JSONObject> {
        return pendingLiveQueue
            .take(MAX_BATCH_FLUSH_SIZE)
            .map { JSONObject(it.toString()) }
    }

    // Optional: mirror via WorkManager (requires a real Worker class; stub enqueue only)
    private fun enqueueWorkManagerMirror(json: String) {
        try {
            val constraints = Constraints.Builder()
                .setRequiredNetworkType(NetworkType.CONNECTED)
                .build()
            val data = workDataOf("payload" to json, "auth" to authTokenForTracking(), "baseApi" to baseApiUrl())
            // Replace ListenableWorker with your concrete Worker class when you add it
            val req = OneTimeWorkRequestBuilder<androidx.work.ListenableWorker>()
                .setConstraints(constraints)
                .setInputData(data)
                .build()
            WorkManager.getInstance(applicationContext).enqueue(req)
        } catch (_: Exception) {
            // optional; ignore errors
        }
    }

    // --- REST (source of truth) ---
    private fun postRest(body: JSONObject) {
        val api = baseApiUrl().trimEnd('/')
        if (api.isEmpty()) {
            Log.e(TAG, "REST skipped: base_api_url empty")
            return
        }
        val url = "$api/driver/location"
        val reqBody = body.toString().toRequestBody("application/json".toMediaType())
        val authToken = heartbeatAuthToken() ?: return
        val req = Request.Builder()
            .url(url)
            .addHeader("Authorization", "Bearer $authToken")
            .post(reqBody)
            .build()

        Log.v(TAG, "REST ↑ (direct) → $url payload=${body}")
        client.newCall(req).enqueue(object : Callback {
            override fun onFailure(call: Call, e: IOException) {
                Log.e(TAG, "REST ↑ $url failed", e)
            }
            override fun onResponse(call: Call, response: Response) {
                val code = response.code
                val headers = response.headers.toMultimap()
                val bodyStr = try { response.body?.string() } catch (ex: Exception) { "⚠️ body read failed: ${ex.message}" }
                if (code in 200..201) {
                    Log.v(TAG, "REST ↑ OK $code\n➡️ URL: $url\n⬆️ Req headers: ${req.headers}\n⬇️ Resp headers: $headers\n⬇️ Resp body: ${bodyStr?.take(500)}")
                } else {
                    Log.w(TAG, "REST ↑ $code\n➡️ URL: $url\n⬆️ Req headers: ${req.headers}\n⬇️ Resp headers: $headers\n⬇️ Resp body: ${bodyStr?.take(1000)}")
                }
                response.close()
            }
        })
    }

    // --- Location streaming ---
    // --- Location streaming ---
    private fun startLocationUpdatesBackgroundLooper() {
        if (!hasLocationPermission()) {
            Log.e(TAG, "Location permission not granted")
            ConfigStore.setRunning(this, false)
            return
        }
        if (!hasBackground(this)) {
            Log.e(TAG, "Missing ACCESS_BACKGROUND_LOCATION; aborting location updates")
            ConfigStore.setRunning(this, false)
            return
        }
        if (locationThread == null) {
            locationThread = HandlerThread("loc-thread").apply { start() }
        }
        val looper = locationThread!!.looper

        val request = LocationRequest.Builder(Priority.PRIORITY_HIGH_ACCURACY, LOCATION_UPDATE_INTERVAL_MS)
            .setMinUpdateDistanceMeters(if (devNoDrop()) 0f else 12f)
            .setMinUpdateIntervalMillis(6_000L)                 // allow faster accepts when moving
            .setGranularity(Granularity.GRANULARITY_FINE)       // prefer fine (GPS) when permitted
            .setWaitForAccurateLocation(!devNoDrop())           // wait for a good first fix unless dev
            .build()

        // Check device/location settings and log if GPS is off or throttled
        try {
            val settingsClient = LocationServices.getSettingsClient(this)
            val settingsReq = com.google.android.gms.location.LocationSettingsRequest.Builder()
                .addLocationRequest(request)
                .setAlwaysShow(false)
                .build()
            settingsClient.checkLocationSettings(settingsReq)
                .addOnSuccessListener { Log.d(TAG, "Location settings satisfied") }
                .addOnFailureListener { e -> Log.w(TAG, "Location settings NOT satisfied: ${e.message}") }
        } catch (e: Exception) { Log.w(TAG, "checkLocationSettings failed: ${e.message}") }

        callback = object : LocationCallback() {
            override fun onLocationResult(res: LocationResult) {
                val loc = res.lastLocation ?: run { logDrop("no lastLocation"); return }

                // --- Quality gates ---
                // 1) Skip mock provider points (unless devNoDrop)
                if (!devNoDrop()) {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                        if (loc.isMock) { logDrop("mock provider (S+)"); return }
                    } else {
                        @Suppress("DEPRECATION")
                        if (loc.isFromMockProvider) { logDrop("mock provider (legacy)"); return }
                    }
                    // 2) Require finite and reasonably precise accuracy (≤50 m)
                    if (!loc.hasAccuracy() || !loc.accuracy.isFinite() || loc.accuracy > 50f) {
                        logDrop("bad accuracy=${loc.accuracy}")
                        return
                    }
                    // 3) Drop excessively stale locations (>10s old)
                    val nowElapsedMs = android.os.SystemClock.elapsedRealtimeNanos() / 1_000_000.0
                    val ageMs = nowElapsedMs - (loc.elapsedRealtimeNanos / 1_000_000.0)
                    if (ageMs > 10_000.0) { logDrop("stale ageMs=${ageMs.toInt()}"); return }
                    // 4) Warm-up: ignore first couple of fixes to let GPS converge
                    if (warmupDrops > 0) { logDrop("warmup"); warmupDrops--; return }
                } else {
                    Log.w(TAG, "⚠️ devNoDrop() active → bypassing accuracy/stale/warmup gates for development")
                }

                // Client-side throttle/dedupe (skip when devNoDrop)
                val nowWall = System.currentTimeMillis()
                val dt = nowWall - lastSentTs
                val moved = haversineMeters(lastSentLat, lastSentLng, loc.latitude, loc.longitude)
                if (!devNoDrop() && lastSentTs > 0 && dt < CLIENT_MIN_TIME_MS && moved < CLIENT_MIN_DIST_M) {
                    logDrop("dedupe dt=${dt}ms moved=${"%.1f".format(moved)}m")
                    // Skip sending location; keep presence warm
                    maybeSendHeartbeat("dedupe", nowWall)
                    return
                }

                // Build payload using the location's own timestamp (device time)
                val payload = buildPayloadFromRaw(
                    latitude = loc.latitude,
                    longitude = loc.longitude,
                    speedMps = if (loc.hasSpeed()) loc.speed.toDouble() else Double.NaN,
                    bearingDeg = if (loc.hasBearing() && loc.speed >= 1.0f) loc.bearing.toDouble() else Double.NaN,
                    accuracyM = if (loc.hasAccuracy()) loc.accuracy.toDouble() else Double.NaN,
                    deviceTimeMs = loc.time // use provider timestamp, not System.currentTimeMillis()
                )

                // Verbose log before sending
                Log.v(TAG, "emit loc lat=${loc.latitude}, lng=${loc.longitude}, acc=${loc.accuracy}, spd=${if (loc.hasSpeed()) loc.speed else Float.NaN}, dt=${dt}ms moved=${"%.1f".format(moved)}m devNoDrop=${devNoDrop()}")

                // Add provider and refine locationSource when provider says GPS
                val provider = loc.provider ?: "fused"
                payload.put("provider", provider)
                if (provider.equals("gps", ignoreCase = true)) {
                    payload.put("locationSource", "gps")
                }

                // WebSocket is the source of truth for live location
                sendLive(payload)

                // Update dedupe anchors
                lastSentLat = loc.latitude
                lastSentLng = loc.longitude
                lastSentTs  = nowWall

                // Opportunistic heartbeat with location (subject to HB rate-limit)
                maybeSendHeartbeat("location", nowWall)
            }
        }
        fused.requestLocationUpdates(request, callback!!, looper)

        // Seed with last known location (helps when GPS is cold/indoors)
        try {
            fused.lastLocation.addOnSuccessListener { last ->
                if (last != null) {
                    val accOk = !last.hasAccuracy() || last.accuracy <= 100f
                    val ageMs = (System.currentTimeMillis() - last.time)
                    val ageOk = ageMs <= 60_000 // accept up to 60s old for seed
                    if (devNoDrop() || (accOk && ageOk)) {
                        Log.d(TAG, "Seeding from lastLocation acc=${last.accuracy} ageMs=${ageMs}")
                        val seedPayload = buildPayloadFromRaw(
                            latitude = last.latitude,
                            longitude = last.longitude,
                            speedMps = if (last.hasSpeed()) last.speed.toDouble() else Double.NaN,
                            bearingDeg = if (last.hasBearing()) last.bearing.toDouble() else Double.NaN,
                            accuracyM = if (last.hasAccuracy()) last.accuracy.toDouble() else Double.NaN,
                            deviceTimeMs = last.time
                        )
                        seedPayload.put("provider", last.provider ?: "fused")
                        if (devNoDrop()) Log.w(TAG, "⚠️ devNoDrop() → seeding regardless of acc/age")
                        sendLive(seedPayload)
                    } else {
                        logDrop("seed rejected accOk=${accOk} ageMs=${ageMs}")
                    }
                } else {
                    Log.d(TAG, "No lastLocation available to seed")
                }
            }
        } catch (e: Exception) { Log.w(TAG, "lastLocation seed failed: ${e.message}") }

        Log.d(TAG, "Location updates started")
    }

    // Helper: fetch active dispatch id if you have it; otherwise null
private fun currentDispatchId(): Long? {
    // e.g. from ConfigStore or your job manager; return null if none
    // return ConfigStore.dispatchId(this).toLongOrNull()
    return null
}

// Optional: parse ISO8601 to epoch ms if you want to accept that extra
private fun parseIsoToEpochMs(iso: String): Long? = try {
    java.time.Instant.parse(iso).toEpochMilli()
} catch (_: Exception) { null }



private fun handlePushedLocation(intent: Intent?) {
    if (intent == null) return

    val lat  = intent.getDoubleExtra(AndroidKeys.EXTRA_LAT, Double.NaN)
    val lng  = intent.getDoubleExtra(AndroidKeys.EXTRA_LNG, Double.NaN)
    val acc  = intent.getFloatExtra(AndroidKeys.EXTRA_ACC, Float.NaN)
    val spd  = intent.getFloatExtra(AndroidKeys.EXTRA_SPD, Float.NaN)
    val brg  = intent.getFloatExtra(AndroidKeys.EXTRA_BRG, Float.NaN)
    val tsMs = intent.getLongExtra(AndroidKeys.EXTRA_TS, System.currentTimeMillis())

    if (lat.isNaN() || lng.isNaN()) {
        Log.w(TAG, "Ignored push: invalid lat/lng"); return
    }

    // Build the base payload (already fills: driverId, lat/lng, accuracyMeters, speed, heading, battery, clientTime, netType, locationSource, version, source)
    val payload = buildPayloadFromRaw(
        latitude = lat,
        longitude = lng,
        speedMps = if (spd.isFinite()) spd.toDouble() else Double.NaN,
        bearingDeg = if (brg.isFinite()) brg.toDouble() else Double.NaN,
        accuracyM = if (acc.isFinite()) acc.toDouble() else Double.NaN,
        deviceTimeMs = tsMs
    )

    // Add/override fields to match server schema precisely
    // 1) dispatchId
    currentDispatchId()?.let { payload.put("dispatchId", it) } ?: payload.put("dispatchId", org.json.JSONObject.NULL)

    // 2) optional overrides from intent
    intent.getStringExtra("extra_location_source")?.let { src ->
        if (src.isNotBlank()) payload.put("locationSource", src)   // e.g., "gps" | "fused"
    }
    intent.getStringExtra("extra_net")?.let { nt ->
        if (nt.isNotBlank()) payload.put("netType", nt)             // e.g., "LTE" | "WIFI"
    }
    if (intent.hasExtra("extra_battery")) {
        val b = intent.getIntExtra("extra_battery", -1)
        if (b in 0..100) payload.put("batteryLevel", b)
    }
    if (intent.hasExtra("extra_app_ver")) {
        val v = intent.getLongExtra("extra_app_ver", -1L)
        if (v > 0L) payload.put("version", v)
    }

    // 3) normalize clientTime: prefer epoch ms; if ISO provided, parse to epoch and overwrite
    intent.getStringExtra("extra_client_ts_utc")?.let { iso ->
        parseIsoToEpochMs(iso)?.let { epoch -> payload.put("clientTime", epoch) }
    }

    // 4) Do NOT include extra fields not used by server (avoid noisy keys)
    // If you previously added:
    // payload.remove("provider")
    // payload.remove("timestampEpochMs")
    payload.remove("provider")
    payload.remove("timestampEpochMs")
    payload.remove("clientTimeIso")

    Log.v(TAG, "push → $payload")
    sendLive(payload)
    maybeSendHeartbeat("push", System.currentTimeMillis())
    ConfigStore.touchHeartbeat(this)
}

    // --- Heartbeat ---
    private fun currentNetType(): String {
        return try {
            val cm = getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
            val net = cm.activeNetwork ?: return "NONE"
            val caps = cm.getNetworkCapabilities(net) ?: return "NONE"
            return when {
                caps.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) -> "WIFI"
                caps.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) -> {
                    // Very rough; detailed RAT requires TelephonyManager which may need READ_PHONE_STATE on some APIs
                    // We map to 4G/5G/NONE coarsely via LINK_DOWNSTREAM_BANDWIDTH_KBPS as a heuristic
                    val down = caps.linkDownstreamBandwidthKbps
                    when {
                        down >= 100_000 -> "5G"
                        down >= 10_000 -> "4G"
                        down > 0 -> "CELL"
                        else -> "CELL"
                    }
                }
                caps.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET) -> "ETH"
                else -> "NONE"
            }
        } catch (_: Exception) { "UNKNOWN" }
    }

    private fun postHeartbeat(reason: String = "timer", clientTsMs: Long = System.currentTimeMillis()) {
        val nowElapsed = android.os.SystemClock.elapsedRealtime()
        if (nowElapsed < tokenSettledUntilMs) {
            Log.v(TAG, "HB skipped (token settling) reason=$reason")
            return
        }
        if (nowElapsed < heartbeatCooldownUntilMs) {
            Log.v(TAG, "HB skipped (auth cooldown) reason=$reason")
            return
        }
        // Rate-limit non-timer heartbeats to avoid bursts from net-up/token-update/dedupe
        val sinceLast = nowElapsed - lastHeartbeatMs
        if (reason != "timer" && sinceLast < HEARTBEAT_MIN_GAP_MS) {
            Log.v(TAG, "HB skipped (rate-limit) reason=$reason sinceLast=${sinceLast}ms")
            return
        }
        val api = baseApiUrl().trimEnd('/')
        val driverId = driverIdStr()
        val authToken = heartbeatAuthToken()
        if (api.isEmpty() || driverId.isBlank() || authToken.isNullOrBlank()) return

        // Matches PresenceHeartbeatDto: POST /api/driver/presence/heartbeat
        val url = "$api/driver/presence/heartbeat"
        val body = JSONObject().apply {
            put("driverId", driverId.toLongOrNull() ?: 0L)
            put("battery", currentBatteryLevelInt())
            put("gpsEnabled", hasLocationPermission())
            put("device", "NATIVE_ANDROID")
            put("ts", clientTsMs)
            put("reason", reason)
            // Optional metadata (server may ignore)
            put("netType", currentNetType())
            put("appVersion", appVersion())
        }
        val reqBody = body.toString().toRequestBody("application/json".toMediaType())
        val req = Request.Builder()
            .url(url)
            .addHeader("Authorization", "Bearer $authToken")
            .post(reqBody)
            .build()

        client.newCall(req).enqueue(object : Callback {
            override fun onFailure(call: Call, e: IOException) {
                Log.w(TAG, "HB fail → ${e.message} @ $url")
            }
            override fun onResponse(call: Call, response: Response) {
                if (!response.isSuccessful) {
                    val bodyStr = try { response.body?.string() } catch (_: Exception) { null }
                    if (response.code == 403) {
                        Log.w(TAG, "HB 403 Forbidden; clearing stale tracking session")
                        clearTrackingSessionOnly()
                        response.close()
                        return
                    }
                    if (response.code == 401 && (refreshTrackingTokenSync() || refreshAccessTokenSync())) {
                        heartbeatCooldownUntilMs =
                            android.os.SystemClock.elapsedRealtime() + HEARTBEAT_AUTH_COOLDOWN_MS
                        tokenSettledUntilMs =
                            android.os.SystemClock.elapsedRealtime() + TOKEN_SETTLE_DELAY_MS
                        Log.w(TAG, "HB 401; token refreshed -> retry after cooldown")
                        response.close()
                        scheduleHeartbeatKick("auth-retry", HEARTBEAT_AUTH_COOLDOWN_MS)
                        return
                    }
                    Log.w(TAG, "HB non-200 (${response.code}) @ $url ${bodyStr?.let { " body=${it.take(200)}" } ?: ""}")
                } else {
                    heartbeatCooldownUntilMs = 0L
                    Log.v(TAG, "HB OK (${response.code}) @ $url")
                }
                response.close()
            }
        })
        lastHeartbeatMs = nowElapsed
        ConfigStore.touchHeartbeat(this)
    }

    private fun ensureHeartbeatLoop() {
        if (heartbeatHandler == null) heartbeatHandler = Handler(Looper.getMainLooper())
        if (heartbeatRunnable == null) {
            heartbeatRunnable = object : Runnable {
                override fun run() {
                    try { postHeartbeat("timer") } catch (_: Exception) {}
                    val jitter = (0..3000).random() // 0–3s jitter
                    heartbeatHandler?.postDelayed(this, HEARTBEAT_INTERVAL_MS + jitter.toLong()) // main cadence; bursts are rate-limited in postHeartbeat()
                }
            }
        }
        heartbeatHandler?.removeCallbacks(heartbeatRunnable!!)
        heartbeatHandler?.post(heartbeatRunnable!!)
    }

    private fun scheduleHeartbeatKick(reason: String, delayMs: Long) {
        if (heartbeatHandler == null) heartbeatHandler = Handler(Looper.getMainLooper())
        heartbeatHandler?.postDelayed({
            try { postHeartbeat(reason) } catch (_: Exception) {}
        }, delayMs)
    }

    private fun wsUrl(): String        = ConfigStore.wsUrl(this)
    private fun token(): String        = ConfigStore.token(this)
    private fun trackingToken(): String = ConfigStore.trackingToken(this)
    private fun trackingSessionId(): String = ConfigStore.trackingSessionId(this)
    private fun refreshToken(): String = ConfigStore.refreshToken(this)
    private fun driverIdStr(): String  = ConfigStore.driverId(this)
    private fun driverName(): String   = ConfigStore.driverName(this)
    private fun vehiclePlate(): String = ConfigStore.vehiclePlate(this)

    private fun wsUrlWithToken(): String {
        var base = wsUrl()
        val t = authTokenForTracking()
        if (base.isEmpty()) return ""
        // Normalize scheme to WebSocket to avoid HTTP upgrade attempts
        base = when {
            base.startsWith("https://", true) -> base.replaceFirst(Regex("(?i)^https://"), "wss://")
            base.startsWith("http://",  true) -> base.replaceFirst(Regex("(?i)^http://"),  "ws://")
            else -> base
        }
        return if (base.contains("token=")) base.replace(Regex("token=[^&]*"), "token=$t")
               else if (base.contains("?")) "$base&token=$t" else "$base?token=$t"
    }

    private fun baseApiUrl(): String {
        val fromPrefsRaw = ConfigStore.baseApi(this).trimEnd('/')
        if (fromPrefsRaw.isNotEmpty()) {
            return when {
                fromPrefsRaw.startsWith("wss://", true) -> fromPrefsRaw.replaceFirst(Regex("(?i)^wss://"), "https://")
                fromPrefsRaw.startsWith("ws://",  true) -> fromPrefsRaw.replaceFirst(Regex("(?i)^ws://"),  "http://")
                else -> fromPrefsRaw
            }
        }
        // Derive from WS if base not set
        val w = wsUrl()
        if (w.isEmpty()) return ""
        val scheme = when {
            w.startsWith("wss://", true) -> "https://"
            w.startsWith("ws://",  true) -> "http://"
            else -> "https://"
        }
        val host = w.removePrefix("wss://").removePrefix("ws://").substringBefore("/")
        return if (host.isNotEmpty()) "$scheme$host" else ""
    }

    private fun refreshAccessTokenSync(): Boolean {
        if (refreshInFlight) return false
        val api = baseApiUrl().trimEnd('/')
        val refresh = refreshToken().trim()
        if (api.isEmpty() || refresh.isEmpty()) return false

        refreshInFlight = true
        return try {
            val req = Request.Builder()
                .url("$api/auth/refresh")
                .addHeader("Authorization", "Bearer $refresh")
                .post("{}".toRequestBody("application/json".toMediaType()))
                .build()
            client.newCall(req).execute().use { resp ->
                if (!resp.isSuccessful) {
                    Log.w(TAG, "Token refresh failed: ${resp.code}")
                    return false
                }
                val body = resp.body?.string().orEmpty()
                val obj = try { JSONObject(body) } catch (_: Exception) { JSONObject() }
                val data = if (obj.optJSONObject("data") != null) obj.optJSONObject("data")!! else obj
                val newAccess = when {
                    data.optString("token").isNotBlank() -> data.optString("token")
                    data.optString("access_token").isNotBlank() -> data.optString("access_token")
                    data.optString("accessToken").isNotBlank() -> data.optString("accessToken")
                    else -> ""
                }
                val newRefresh = when {
                    data.optString("refresh_token").isNotBlank() -> data.optString("refresh_token")
                    data.optString("refreshToken").isNotBlank() -> data.optString("refreshToken")
                    else -> ""
                }
                if (newAccess.isBlank()) return false
                ConfigStore.write(
                    this,
                    ConfigStore.KEY_TOKEN to newAccess,
                    ConfigStore.KEY_REFRESH_TOKEN to (if (newRefresh.isBlank()) refresh else newRefresh)
                )
                Log.i(TAG, "Token refresh succeeded for background tracking")
                true
            }
        } catch (e: Exception) {
            Log.w(TAG, "Token refresh exception: ${e.message}")
            false
        } finally {
            refreshInFlight = false
        }
    }

    private fun refreshTrackingTokenSync(): Boolean {
        val tracking = trackingToken().trim()
        val api = baseApiUrl().trimEnd('/')
        if (api.isEmpty() || tracking.isEmpty()) return false
        if (refreshInFlight) return false
        refreshInFlight = true
        return try {
            val req = Request.Builder()
                .url("$api/driver/tracking/session/refresh")
                .addHeader("Authorization", "Bearer $tracking")
                .post("{}".toRequestBody("application/json".toMediaType()))
                .build()
            client.newCall(req).execute().use { resp ->
                if (!resp.isSuccessful) {
                    Log.w(TAG, "Tracking token refresh failed: ${resp.code}")
                    return false
                }
                val body = resp.body?.string().orEmpty()
                val obj = try { JSONObject(body) } catch (_: Exception) { JSONObject() }
                val data = if (obj.optJSONObject("data") != null) obj.optJSONObject("data")!! else obj
                val newTracking = when {
                    data.optString("trackingToken").isNotBlank() -> data.optString("trackingToken")
                    data.optString("tracking_token").isNotBlank() -> data.optString("tracking_token")
                    else -> ""
                }
                val sessionId = when {
                    data.optString("sessionId").isNotBlank() -> data.optString("sessionId")
                    data.optString("session_id").isNotBlank() -> data.optString("session_id")
                    else -> trackingSessionId()
                }
                if (newTracking.isBlank()) return false
                ConfigStore.write(
                    this,
                    ConfigStore.KEY_TRACKING_TOKEN to newTracking,
                    ConfigStore.KEY_TRACKING_SESSION_ID to sessionId
                )
                true
            }
        } catch (e: Exception) {
            Log.w(TAG, "Tracking token refresh exception: ${e.message}")
            false
        } finally {
            refreshInFlight = false
        }
    }

    private fun hasLocationPermission(): Boolean {
        val fine = ActivityCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED
        val coarse = ActivityCompat.checkSelfPermission(this, Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED
        return fine || coarse
    }

    private fun currentBatteryLevelInt(): Int {
        return try {
            val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED), Context.RECEIVER_EXPORTED)
            } else {
                @Suppress("DEPRECATION")
                registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
            }
            val level = intent?.getIntExtra(BatteryManager.EXTRA_LEVEL, -1) ?: -1
            val scale = intent?.getIntExtra(BatteryManager.EXTRA_SCALE, -1) ?: -1
            if (level >= 0 && scale > 0) (level * 100.0 / scale).toInt().coerceIn(0, 100) else -1
        } catch (e: Exception) {
            Log.w(TAG, "Failed to get battery level: ${e.message}")
            -1
        }
    }

    private fun appVersion(): String {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                val p = packageManager.getPackageInfo(packageName, PackageManager.PackageInfoFlags.of(0))
                p.versionName ?: ""
            } else {
                @Suppress("DEPRECATION")
                val p = packageManager.getPackageInfo(packageName, 0)
                p.versionName ?: ""
            }
        } catch (_: Exception) { "" }
    }

    private fun appVersionCode(): Long {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                packageManager.getPackageInfo(packageName, 0).longVersionCode
            } else {
                @Suppress("DEPRECATION")
                packageManager.getPackageInfo(packageName, 0).versionCode.toLong()
            }
        } catch (_: Exception) { 0L }
    }

    private fun deviceName(): String = try {
        val manu = Build.MANUFACTURER?.trim().orEmpty()
        val model = Build.MODEL?.trim().orEmpty()
        if (model.startsWith(manu, true)) model else "$manu $model".trim()
    } catch (_: Exception) { "" }

    private fun buildPayloadFromLocation(loc: android.location.Location): JSONObject =
        buildPayloadFromRaw(
            latitude = loc.latitude,
            longitude = loc.longitude,
            speedMps = if (loc.hasSpeed()) loc.speed.toDouble() else Double.NaN,
            bearingDeg = if (loc.hasBearing()) loc.bearing.toDouble() else Double.NaN,
            accuracyM = if (loc.hasAccuracy()) loc.accuracy.toDouble() else Double.NaN,
            deviceTimeMs = loc.time
        )

   // Server DTO-compatible payload (matches DriverLocationUpdateDto)
private fun buildPayloadFromRaw(
    latitude: Double,
    longitude: Double,
    speedMps: Double,
    bearingDeg: Double,
    accuracyM: Double,
    deviceTimeMs: Long
): JSONObject {
    val battery = currentBatteryLevelInt()
    val dispatchId: Long? = null // TODO: pull from active job if you have one

    // normalize heading into [0, 360) if present
    val headingNorm =
        if (bearingDeg.isFinite()) ((bearingDeg % 360 + 360) % 360) else Double.NaN

    // Normalize speed: always send a non-null numeric value (m/s)
    val safeSpeedMps =
        if (speedMps.isFinite() && speedMps >= 0.0) speedMps else 0.0

    val obj = JSONObject().apply {
        put("driverId", driverIdStr().toLongOrNull() ?: 0L)
        // include dispatchId, null when none
        if (dispatchId != null) put("dispatchId", dispatchId) else put("dispatchId", JSONObject.NULL)

        put("latitude", latitude)
        put("longitude", longitude)

        // --- Accuracy: always send (cap or null) ---
        // Heuristic: assume GPS-quality when accuracy ≤100 m (strict 200 m cap),
        // otherwise allow up to 500 m to admit coarse fused/network fixes (e.g., indoors).
        val accThreshold = if (accuracyM.isFinite() && accuracyM <= 100.0) 200.0 else 500.0
        val safeAcc: Any = when {
            !accuracyM.isFinite() || accuracyM < 0.0 -> org.json.JSONObject.NULL
            accuracyM <= 100.0 -> accuracyM
            else -> accThreshold // cap huge/coarse accuracies
        }
        put("accuracyMeters", safeAcc)

        // Always include speed (normalized to 0 when device doesn't provide one)
        put("speed", safeSpeedMps)
        put("speedKmh", safeSpeedMps * 3.6)

        // --- Heading: always send numeric + validity flag ---
        // If bearing is not finite, send 0.0 but mark headingValid=false (via speed check).
        val safeHeading = if (headingNorm.isFinite()) headingNorm else 0.0
        put("heading", safeHeading)
        put("headingValid", safeSpeedMps >= 0.5)

        if (battery in 0..100) put("batteryLevel", battery)

        put("source", "NATIVE_ANDROID")
        put("netType", currentNetType())
        put("locationSource", if (accuracyM.isFinite() && accuracyM <= 100.0) "gps" else "fused")
        put("version", appVersionCode())          // numeric app version code expected by server
        put("clientTime", deviceTimeMs)           // epoch ms
        // Do not send the cached native sessionId back on each REST write.
        // The backend can derive session identity from the tracking token, and a
        // stale cached value here can cause 403 "sessionId mismatch" loops.
        pointSeq += 1L
        put("seq", pointSeq)
        put("pointId", "${driverIdStr()}-${deviceTimeMs}-${pointSeq}")
    }
    // Defensive: ensure we never leak fields the server DTO doesn't expect
    obj.remove("provider")
    obj.remove("timestampEpochMs")
    obj.remove("clientTimeIso")
    return obj
}

    private fun maybeSendHeartbeat(reason: String, ts: Long = System.currentTimeMillis()) {
        val elapsed: Long = android.os.SystemClock.elapsedRealtime() - lastHeartbeatMs
        if (elapsed >= HEARTBEAT_INTERVAL_MS / 2L) {
            try { postHeartbeat(reason, ts) } catch (_: Exception) {}
        }
    }

    private fun haversineMeters(lat1: Double, lon1: Double, lat2: Double, lon2: Double): Double {
        if (!lat1.isFinite() || !lon1.isFinite() || !lat2.isFinite() || !lon2.isFinite()) return Double.POSITIVE_INFINITY
        val R = 6371000.0
        val dLat = Math.toRadians(lat2 - lat1)
        val dLon = Math.toRadians(lon2 - lon1)
        val a = Math.sin(dLat/2) * Math.sin(dLat/2) +
                Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2)) *
                Math.sin(dLon/2) * Math.sin(dLon/2)
        return 2 * R * Math.asin(Math.sqrt(a))
    }

    private fun maskUrl(u: String): String {
        val i = u.indexOf("token="); if (i < 0) return u
        val end = u.indexOf('&', i + 6).takeIf { it >= 0 } ?: u.length
        return u.replaceRange(i + 6, end, "***")
    }

    private fun authTokenForTracking(): String {
        val tracking = trackingToken().trim()
        if (tracking.isNotEmpty()) return tracking
        return token()
    }
}
