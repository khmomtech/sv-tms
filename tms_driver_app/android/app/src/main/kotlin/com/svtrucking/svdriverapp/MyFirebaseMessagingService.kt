package com.svtrucking.svdriverapp

import android.Manifest
import android.app.ActivityManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.media.AudioAttributes
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import android.provider.Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage

class MyFirebaseMessagingService : FirebaseMessagingService() {

    companion object {
        private const val TAG = "MyFirebaseMessagingService"

        // ⚠️ FINAL, STABLE CHANNEL IDS (match Flutter NotificationHelper)
        private const val ALERTS_CHANNEL_ID  = "sv_driver_alerts"          // HIGH importance
        private const val UPDATES_CHANNEL_ID = "sv_driver_notifications"   // DEFAULT importance
        private const val ALERTS_CHANNEL_NAME = "Smart Truck Driver Alerts"
        private const val UPDATES_CHANNEL_NAME = "Smart Truck Driver Notifications"
        private const val ALERTS_CHANNEL_DESC = "Urgent driver alerts (dispatch, issues)."
        private const val UPDATES_CHANNEL_DESC = "General notifications and updates."

        // De-dup tiny store
        private const val PREF_FILE      = "sv_driver_fcm_prefs"
        private const val PREF_IDS_SET   = "handled_fcm_ids"
        private const val MAX_IDS_STORED = 100

        // Optional grouping
        private const val GROUP_KEY = "sv_driver_push_group"

        // Optional: Location service action for force-track
        private const val ACTION_FORCE_TRACK = "com.svtrucking.svdriverapp.ACTION_FORCE_TRACK"
    }

    // -------------------- Helpers: permissions / service start --------------------
    private fun hasLocationPermission(): Boolean {
        val fine = ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED
        val coarse = ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED
        return fine || coarse
    }

    private fun hasBackgroundLocationPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_BACKGROUND_LOCATION) == PackageManager.PERMISSION_GRANTED
        } else true
    }

    private fun isIgnoringBatteryOptimizations(): Boolean {
        val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
        return pm.isIgnoringBatteryOptimizations(packageName)
    }

    /**
     * Try to start foreground LocationService. If permissions or battery opts are missing,
     * show a high-priority notification to prompt the user to open the app and grant them.
     */
    private fun startTrackingOrPrompt(reason: String) {
        if (hasLocationPermission() && hasBackgroundLocationPermission()) {
            try {
                val intent = Intent(this, LocationService::class.java).setAction(LocationService.ACTION_START)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) startForegroundService(intent) else startService(intent)
                Log.d(TAG, "LocationService started (reason=$reason)")
                return
            } catch (e: Exception) {
                Log.e(TAG, "Failed to start LocationService (reason=$reason)", e)
            }
        }

        // If we reach here, we need user action → heads-up prompt
        ensureChannels()
        val openIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_NEW_TASK
            putExtra("route", "permissions")
            putExtra("source", reason)
        }
        val pi = PendingIntent.getActivity(this, 101, openIntent, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)

        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val builder = NotificationCompat.Builder(this, ALERTS_CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle("Enable background tracking")
            .setContentText("Open the app to grant location/battery permissions.")
            .setStyle(NotificationCompat.BigTextStyle().bigText("Open the app to grant location (including background) and disable battery optimization for reliable tracking."))
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .setContentIntent(pi)
            .setCategory(NotificationCompat.CATEGORY_ALARM)

        nm.notify(("perm|" + System.currentTimeMillis()).hashCode(), builder.build())
    }

    // -------------------- FCM entrypoints --------------------

    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        super.onMessageReceived(remoteMessage)
        Log.d(TAG, "From: ${remoteMessage.from} data=${remoteMessage.data.keys}")

        // 0) If notifications are disabled at OS level, log it so you know why it's quiet
        if (!NotificationManagerCompat.from(this).areNotificationsEnabled()) {
            Log.w(TAG, "Notifications are disabled for this app at OS level")
        }

        val data = remoteMessage.data
        val type = (data["type"] ?: "").lowercase()
        val priority = (data["priority"] ?: "").lowercase()
        val forceNative = (data["force_native"] ?: "0") == "1"

        // 🔧 Handle data-only special commands (e.g., force-track) regardless of UI
        if (type == "force-track") {
            try {
                val intent = Intent(this, LocationService::class.java).setAction(ACTION_FORCE_TRACK)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) startForegroundService(intent) else startService(intent)
                Log.d(TAG, "Force-track command dispatched to LocationService")
            } catch (e: Exception) {
                Log.e(TAG, "Failed to start LocationService for force-track", e)
            }
            // You may also want to fall-through and show a small banner; otherwise return
            // return
        }

        // 🔧 Handle force-open (start/restart foreground LocationService or prompt user)
        if (type == "force_open" || type == "force-open" || type == "forceopen") {
            startTrackingOrPrompt("force-open")
            // Optional: return here if you do NOT want a banner notification for force-open
            // return
        }

        // 1) If app is foreground → let Flutter show local notification; unless forced
        if (isAppInForeground() && !forceNative) {
            Log.d(TAG, "Foreground → Flutter handles (onMessage). Skipping native.")
            return
        }

        // 2) If push includes 'notification' payload → system displays in bg; skip native to avoid dup (unless forced)
        if (remoteMessage.notification != null && !forceNative) {
            Log.d(TAG, "Has notification payload → system will render in background. Skipping native.")
            return
        }

        // 3) Data-only message → show native banner (heads-up on alerts channel)
        val msgId = data["msg_id"] ?: remoteMessage.messageId ?: ""
        if (msgId.isNotEmpty() && alreadyHandled(msgId)) {
            Log.d(TAG, "Duplicate message id=$msgId → skip")
            return
        }

        val title = data["title"] ?: "SV Trucking"
        val body  = data["body"] ?: data["message"] ?: "You have a new update."
        val deeplink = data["deeplink"]

        ensureChannels()

        val useAlerts = forceNative || priority == "high" ||
                type == "dispatch" || type == "issue" || type == "alert"

        showNotification(
            channelId = if (useAlerts) ALERTS_CHANNEL_ID else UPDATES_CHANNEL_ID,
            title = title,
            message = body,
            deeplink = deeplink,
            stableIdSeed = msgId.ifEmpty { "$title|$body" },
            dataExtras = data
        )

        if (msgId.isNotEmpty()) markHandled(msgId)
    }

    override fun onNewToken(token: String) {
        Log.d(TAG, "FCM refreshed token: $token")
        sendRegistrationToServer(token) // implement API call
    }

    // -------------------- Notification utils --------------------

    private fun ensureChannels() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        val audio = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_NOTIFICATION)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()

        // HIGH importance alerts channel (heads-up)
        if (nm.getNotificationChannel(ALERTS_CHANNEL_ID) == null) {
            val high = NotificationChannel(
                ALERTS_CHANNEL_ID,
                ALERTS_CHANNEL_NAME,
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = ALERTS_CHANNEL_DESC
                enableVibration(true)
                vibrationPattern = longArrayOf(0, 200, 150, 200)
                setSound(Settings.System.DEFAULT_NOTIFICATION_URI, audio)
                setShowBadge(true)
                lockscreenVisibility = Notification.VISIBILITY_PRIVATE
            }
            nm.createNotificationChannel(high)
        }

        // DEFAULT importance updates channel
        if (nm.getNotificationChannel(UPDATES_CHANNEL_ID) == null) {
            val def = NotificationChannel(
                UPDATES_CHANNEL_ID,
                UPDATES_CHANNEL_NAME,
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = UPDATES_CHANNEL_DESC
                enableVibration(true)
                setSound(Settings.System.DEFAULT_NOTIFICATION_URI, audio)
                setShowBadge(true)
                lockscreenVisibility = Notification.VISIBILITY_PRIVATE
            }
            nm.createNotificationChannel(def)
        }
    }

    private fun showNotification(
        channelId: String,
        title: String,
        message: String,
        deeplink: String? = null,
        stableIdSeed: String,
        dataExtras: Map<String, String>? = null
    ) {
        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        // Tap → open app (or deep link)
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            if (!deeplink.isNullOrBlank()) data = Uri.parse(deeplink)
            // Also pass a simple route hint if provided in data payload
            if (dataExtras != null) {
                putExtra("route", dataExtras["route"])
                putExtra("referenceId", dataExtras["referenceId"])
            }
        }
        val contentPi = PendingIntent.getActivity(
            this, 0, intent, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        val builder = NotificationCompat.Builder(this, channelId)
            .setSmallIcon(R.mipmap.ic_launcher) // use app launcher as status icon (consider a monochrome drawable)
            .setContentTitle(title)
            .setContentText(message)
            .setStyle(NotificationCompat.BigTextStyle().bigText(message))
            .setContentIntent(contentPi)
            .setAutoCancel(true)
            .setCategory(NotificationCompat.CATEGORY_MESSAGE)
            .setVisibility(NotificationCompat.VISIBILITY_PRIVATE)
            .setGroup(GROUP_KEY)
            // Pre-O heads-up behavior:
            .setPriority(
                if (channelId == ALERTS_CHANNEL_ID) NotificationCompat.PRIORITY_HIGH
                else NotificationCompat.PRIORITY_DEFAULT
            )
            .setDefaults(NotificationCompat.DEFAULT_ALL)

        // Stable-ish ID: ensures same message replaces, different text shows new card
        val notifId = stableIdSeed.hashCode()
        nm.notify(notifId, builder.build())
    }

    // -------------------- De-dup helpers --------------------

    private fun alreadyHandled(id: String): Boolean {
        val prefs = getSharedPreferences(PREF_FILE, Context.MODE_PRIVATE)
        val set = prefs.getStringSet(PREF_IDS_SET, emptySet()) ?: emptySet()
        return set.contains(id)
    }

    private fun markHandled(id: String) {
        val prefs = getSharedPreferences(PREF_FILE, Context.MODE_PRIVATE)
        val current = prefs.getStringSet(PREF_IDS_SET, emptySet())?.toMutableSet() ?: mutableSetOf()
        current.add(id)
        // bound size (naive LRU)
        while (current.size > MAX_IDS_STORED) {
            val it = current.iterator()
            if (it.hasNext()) { it.next(); it.remove() } else break
        }
        prefs.edit().putStringSet(PREF_IDS_SET, current).apply()
    }

    // -------------------- App state / token --------------------

    private fun isAppInForeground(): Boolean {
        val am = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            for (proc in am.runningAppProcesses ?: emptyList()) {
                if (proc.processName == packageName) {
                    return proc.importance == ActivityManager.RunningAppProcessInfo.IMPORTANCE_FOREGROUND ||
                           proc.importance == ActivityManager.RunningAppProcessInfo.IMPORTANCE_VISIBLE
                }
            }
            return false
        } else {
            @Suppress("DEPRECATION")
            val tasks = am.getRunningTasks(1)
            if (tasks.isNullOrEmpty()) return false
            @Suppress("DEPRECATION")
            return tasks[0].topActivity?.packageName == packageName
        }
    }

    private fun sendRegistrationToServer(token: String) {
        // Implement your API call here (POST /api/admin/drivers/update-device-token)
        Log.d(TAG, "sendRegistrationTokenToServer($token)")
    }
}
