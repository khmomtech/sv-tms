package com.svtrucking.svdriverapp

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.SystemClock
import android.util.Log
import androidx.work.Worker
import androidx.work.WorkerParameters

class HealthWatchdogWorker(ctx: Context, params: WorkerParameters) : Worker(ctx, params) {

    companion object {
        private const val TAG = "HealthWatchdog"
        private const val HEARTBEAT_FRESH_MS = 75_000L
        private const val MIN_ATTEMPT_GAP_MS = 10_000L
        private const val RESTART_ALARM_DELAY_MS = 2_000L
    }

    override fun doWork(): Result {
        val appCtx = applicationContext

        // Always try to auto-restart if config exists.
        if (!ConfigStore.hasMinimumConfig(appCtx)) return Result.success()

        val now = SystemClock.elapsedRealtime()
        val lastAttempt = ConfigStore.lastWatchdogAttempt(appCtx)
        if (lastAttempt > 0L && (now - lastAttempt) < MIN_ATTEMPT_GAP_MS) {
            Log.w(TAG, "Backoff active; skipping (${now - lastAttempt}ms since last)")
            return Result.success()
        }

        val alive = ConfigStore.isProbablyRunning(appCtx, maxAgeMs = HEARTBEAT_FRESH_MS)
        if (!alive) {
            // Clear stop flags before restart
            ConfigStore.setUserStop(appCtx, false)

            startServiceNow(appCtx)
            ConfigStore.setWatchdogLastAttempt(appCtx, now)
            armRestartAlarm(appCtx, RESTART_ALARM_DELAY_MS)
        } else {
            Log.d(TAG, "Service healthy (fresh heartbeat)")
        }
        return Result.success()
    }

    private fun startServiceNow(ctx: Context) {
        val i = Intent(ctx, LocationService::class.java).apply {
            action = LocationService.ACTION_START
        }
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) ctx.startForegroundService(i)
            else ctx.startService(i)
            Log.i(TAG, "Requested LocationService start")
        } catch (e: Exception) {
            Log.e(TAG, "startForegroundService failed: ${e.message}", e)
        }
    }

    private fun armRestartAlarm(ctx: Context, delayMs: Long) {
        val am = ctx.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val pi = PendingIntent.getBroadcast(
            ctx,
            1002,
            Intent(ctx, RestartReceiver::class.java)
                .setAction(LocationService.ACTION_RESTART)
                .setPackage(ctx.packageName),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val whenMs = SystemClock.elapsedRealtime() + delayMs
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                if (am.canScheduleExactAlarms()) {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        am.setExactAndAllowWhileIdle(AlarmManager.ELAPSED_REALTIME_WAKEUP, whenMs, pi)
                    } else am.setExact(AlarmManager.ELAPSED_REALTIME_WAKEUP, whenMs, pi)
                } else {
                    am.set(AlarmManager.ELAPSED_REALTIME_WAKEUP, whenMs, pi)
                }
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                am.setExactAndAllowWhileIdle(AlarmManager.ELAPSED_REALTIME_WAKEUP, whenMs, pi)
            } else {
                am.setExact(AlarmManager.ELAPSED_REALTIME_WAKEUP, whenMs, pi)
            }
        } catch (_: Exception) { /* ignore OEM quirks */ }
    }
}
