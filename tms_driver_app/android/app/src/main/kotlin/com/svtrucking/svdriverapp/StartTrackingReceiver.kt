package com.svtrucking.svdriverapp

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

class StartTrackingReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val i = Intent(context, LocationService::class.java)
            .setAction(LocationService.ACTION_START)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context.startForegroundService(i)
        } else {
            context.startService(i)
        }
    }
}