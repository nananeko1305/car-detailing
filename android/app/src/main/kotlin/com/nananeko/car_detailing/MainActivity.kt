package com.nananeko.car_detailing

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createChannels()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SETTINGS_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openNotificationSettings" -> {
                        startActivity(
                            Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                                .putExtra(Settings.EXTRA_APP_PACKAGE, packageName),
                        )
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    // One channel per kind of push, so anyone can silence one kind alone in
    // the phone settings. Creating an existing channel is a no-op. The ids must
    // match push_worker/src/message.js and the release push in CI.
    private fun createChannels() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(NotificationManager::class.java)
        val channels = listOf(
            "jobs" to R.string.channel_jobs,
            "reminders" to R.string.channel_reminders,
            "updates" to R.string.channel_updates,
        )
        for ((id, name) in channels) {
            manager.createNotificationChannel(
                NotificationChannel(id, getString(name), NotificationManager.IMPORTANCE_HIGH),
            )
        }
    }

    private companion object {
        const val SETTINGS_CHANNEL = "car_detailing/settings"
    }
}
