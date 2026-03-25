package com.svtrucking.svdriverapp

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

class RestartReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "RestartReceiver"

        // Some OEMs use this legacy quick-boot action
        private const val ACTION_QUICKBOOT = "android.intent.action.QUICKBOOT_POWERON"
    }

    override fun onReceive(context: Context, intent: Intent?) {
        val incoming = intent?.action ?: return
        val appCtx = context.applicationContext

        Log.i(TAG, "onReceive: $incoming")

        // Always require minimum config; otherwise do nothing to avoid churn
        if (!ConfigStore.hasMinimumConfig(appCtx)) {
            Log.w(TAG, "Skip restart: missing config (token/driverId/ws_url)")
            return
        }

        // We do NOT respect userStop here (auto-restart behavior by request)
        ConfigStore.setUserStop(appCtx, false)

        val shouldStart = when (incoming) {
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_LOCKED_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            ACTION_QUICKBOOT,
            LocationService.ACTION_RESTART -> true

            else -> false
        }

        if (!shouldStart) return

        val start = Intent(appCtx, LocationService::class.java).apply {
            action = LocationService.ACTION_START
        }
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                appCtx.startForegroundService(start)
            } else {
                appCtx.startService(start)
            }
            Log.i(TAG, "Requested LocationService start from $incoming")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start service from $incoming: ${e.message}", e)
        }
    }
}