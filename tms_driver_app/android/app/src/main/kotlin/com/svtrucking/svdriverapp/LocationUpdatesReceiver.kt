package com.svtrucking.svdriverapp

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.SystemClock
import android.util.Log
import com.google.android.gms.location.LocationResult
import com.svtrucking.svdriverapp.core.AndroidKeys
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.os.BatteryManager
import android.content.pm.PackageManager
import java.time.Instant

class LocationUpdatesReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "LocationUpdatesReceiver"
        private const val DEBOUNCE_MS = 800L
        private var lastForwardAtElapsed: Long = 0L
    }

    private fun getNetworkType(ctx: Context): String {
        val cm = ctx.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        val net = cm.activeNetwork ?: return "NONE"
        val caps = cm.getNetworkCapabilities(net) ?: return "NONE"
        return when {
            caps.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) -> "WIFI"
            caps.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) -> "CELL"
            caps.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET) -> "ETH"
            else -> "OTHER"
        }
    }

    private fun getBatteryLevel(ctx: Context): Int {
        val bm = ctx.getSystemService(Context.BATTERY_SERVICE) as BatteryManager
        val level = bm.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
        return level.coerceIn(0, 100)
    }

    private fun getAppVersionCode(ctx: Context): Int {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                val p = ctx.packageManager.getPackageInfo(ctx.packageName, PackageManager.PackageInfoFlags.of(0))
                p.longVersionCode.toInt()
            } else {
                @Suppress("DEPRECATION")
                ctx.packageManager.getPackageInfo(ctx.packageName, 0).longVersionCode.toInt()
            }
        } catch (e: Exception) { 0 }
    }

    override fun onReceive(context: Context, intent: Intent) {
        val appCtx = context.applicationContext
        val action = intent.action ?: ""

        if (!ConfigStore.hasMinimumConfig(appCtx)) {
            Log.v(TAG, "Skip (missing minimum config); action=$action")
            return
        }

        val hasFusedResult = LocationResult.hasResult(intent)
        val isOurPush = action == AndroidKeys.ACTION_PUSH_LOCATION

        val forwardIntent: Intent? = when {
            isOurPush -> {
                // Forward our normalized push as-is
                Intent(appCtx, LocationService::class.java)
                    .setAction(AndroidKeys.ACTION_PUSH_LOCATION)
                    .putExtras(intent)
            }
            hasFusedResult -> {
                val result = LocationResult.extractResult(intent)
                val loc = result?.lastLocation

                // Debounce only fused bursts (don't block explicit ACTION_PUSH_LOCATION)
                val now = SystemClock.elapsedRealtime()
                if (now - lastForwardAtElapsed < DEBOUNCE_MS) {
                    Log.v(TAG, "Debounced fused burst: ${now - lastForwardAtElapsed}ms since last")
                    null
                }
                else {
                    lastForwardAtElapsed = now

                    if (loc == null) {
                        Log.v(TAG, "Fused result had no lastLocation; ignoring")
                        null
                    } else {
                        // Ignore mock locations
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                            if (loc.isMock) {
                                Log.v(TAG, "Ignored mock location")
                                null
                            } else {
                                val provider = (loc.provider ?: "fused")
                                val accuracy = if (loc.hasAccuracy()) loc.accuracy.toDouble() else Double.NaN
                                val derivedSource = when {
                                    provider.equals("gps", ignoreCase = true) -> "gps"
                                    accuracy.isFinite() && accuracy <= 50.0 -> "gps"
                                    else -> "fused"
                                }
                                val tsMs = System.currentTimeMillis()
                                Intent(appCtx, LocationService::class.java)
                                    .setAction(AndroidKeys.ACTION_PUSH_LOCATION)
                                    .putExtra(AndroidKeys.EXTRA_LAT, loc.latitude)
                                    .putExtra(AndroidKeys.EXTRA_LNG, loc.longitude)
                                    .putExtra(AndroidKeys.EXTRA_ACC, if (loc.hasAccuracy()) loc.accuracy else Float.NaN)
                                    .putExtra(AndroidKeys.EXTRA_SPD, if (loc.hasSpeed()) loc.speed else Float.NaN)
                                    .putExtra(AndroidKeys.EXTRA_BRG, if (loc.hasBearing()) loc.bearing else Float.NaN)
                                    .putExtra(AndroidKeys.EXTRA_TS, tsMs)
                                    // Additional enriched fields (use literal keys to avoid dependency)
                                    .putExtra("extra_provider", loc.provider ?: "fused")
                                    .putExtra("extra_net", getNetworkType(appCtx))
                                    .putExtra("extra_battery", getBatteryLevel(appCtx))
                                    .putExtra("extra_app_ver", getAppVersionCode(appCtx))
                                    .putExtra("extra_source", "native-android")
                                    .putExtra("extra_location_source", derivedSource)
                                    .putExtra("extra_provider_raw", provider)
                                    .putExtra("extra_client_ts_utc", Instant.ofEpochMilli(tsMs).toString())
                            }
                        } else {
                            @Suppress("DEPRECATION")
                            if (loc.isFromMockProvider) {
                                Log.v(TAG, "Ignored mock location (legacy)")
                                null
                            } else {
                                val provider = (loc.provider ?: "fused")
                                val accuracy = if (loc.hasAccuracy()) loc.accuracy.toDouble() else Double.NaN
                                val derivedSource = when {
                                    provider.equals("gps", ignoreCase = true) -> "gps"
                                    accuracy.isFinite() && accuracy <= 50.0 -> "gps"
                                    else -> "fused"
                                }
                                val tsMs = System.currentTimeMillis()
                                Intent(appCtx, LocationService::class.java)
                                    .setAction(AndroidKeys.ACTION_PUSH_LOCATION)
                                    .putExtra(AndroidKeys.EXTRA_LAT, loc.latitude)
                                    .putExtra(AndroidKeys.EXTRA_LNG, loc.longitude)
                                    .putExtra(AndroidKeys.EXTRA_ACC, if (loc.hasAccuracy()) loc.accuracy else Float.NaN)
                                    .putExtra(AndroidKeys.EXTRA_SPD, if (loc.hasSpeed()) loc.speed else Float.NaN)
                                    .putExtra(AndroidKeys.EXTRA_BRG, if (loc.hasBearing()) loc.bearing else Float.NaN)
                                    .putExtra(AndroidKeys.EXTRA_TS, tsMs)
                                    // Additional enriched fields (use literal keys to avoid dependency)
                                    .putExtra("extra_provider", loc.provider ?: "fused")
                                    .putExtra("extra_net", getNetworkType(appCtx))
                                    .putExtra("extra_battery", getBatteryLevel(appCtx))
                                    .putExtra("extra_app_ver", getAppVersionCode(appCtx))
                                    .putExtra("extra_source", "native-android")
                                    .putExtra("extra_location_source", derivedSource)
                                    .putExtra("extra_provider_raw", provider)
                                    .putExtra("extra_client_ts_utc", Instant.ofEpochMilli(tsMs).toString())
                            }
                        }
                    }
                }
            }
            else -> {
                Log.v(TAG, "Ignoring unknown action: $action")
                null
            }
        }

        if (forwardIntent == null) return

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                appCtx.startForegroundService(forwardIntent)
            } else {
                appCtx.startService(forwardIntent)
            }
            Log.v(TAG, "Forwarded → LocationService (${forwardIntent.action})")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start LocationService from receiver", e)
        }
        forwardIntent?.let {
            Log.d(TAG, "→ Forwarded lat=${it.getDoubleExtra(AndroidKeys.EXTRA_LAT, Double.NaN)}, lng=${it.getDoubleExtra(AndroidKeys.EXTRA_LNG, Double.NaN)}, acc=${it.getFloatExtra(AndroidKeys.EXTRA_ACC, Float.NaN)}, src=${it.getStringExtra("extra_location_source")}")
        }
    }
}