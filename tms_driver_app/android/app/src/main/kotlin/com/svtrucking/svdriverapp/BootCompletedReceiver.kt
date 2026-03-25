package com.svtrucking.svdriverapp

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

class BootCompletedReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "BootCompletedReceiver"
        private const val BOOT_START_DELAY_MS = 3000L
    }

    override fun onReceive(ctx: Context, intent: Intent?) {
        val action = intent?.action ?: return
        Log.i(TAG, "onReceive: $action")

        // Only try if config exists; we ignore userStop (auto-restart behavior)
        if (!ConfigStore.hasMinimumConfig(ctx)) {
            Log.w(TAG, "Skip auto-start: missing minimum config")
            return
        }
        scheduleStart(ctx, BOOT_START_DELAY_MS)
    }

    private fun scheduleStart(ctx: Context, delayMs: Long) {
        val am = ctx.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val startIntent = Intent(ctx, LocationService::class.java).apply {
            action = LocationService.ACTION_START
        }
        val pi = PendingIntent.getService(
            ctx,
            9911,
            startIntent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )
        val triggerAt = System.currentTimeMillis() + delayMs
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                am.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAt, pi)
            } else {
                am.setExact(AlarmManager.RTC_WAKEUP, triggerAt, pi)
            }
            Log.i(TAG, "Scheduled LocationService start in ${delayMs}ms")
        } catch (e: Exception) {
            Log.e(TAG, "scheduleStart failed: ${e.message}", e)
        }
    }
}