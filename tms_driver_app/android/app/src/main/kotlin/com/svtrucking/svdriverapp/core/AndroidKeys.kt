package com.svtrucking.svdriverapp.core

/**
 * Centralized constants for Intent actions and extras.
 * Keeps IPC contracts separate from SharedPreferences (ConfigStore).
 */
object AndroidKeys {
    // Actions
    const val ACTION_PUSH_LOCATION = "com.svtrucking.svdriverapp.PUSH_LOCATION"

    // Location extras (Intent keys)
    const val EXTRA_LAT = "extra_lat"   // Double
    const val EXTRA_LNG = "extra_lng"   // Double
    const val EXTRA_ACC = "extra_acc"   // Float (accuracy meters)
    const val EXTRA_SPD = "extra_spd"   // Float (m/s)
    const val EXTRA_BRG = "extra_brg"   // Float (bearing degrees)
    const val EXTRA_TS  = "extra_ts"    // Long  (epoch millis, UTC)
}