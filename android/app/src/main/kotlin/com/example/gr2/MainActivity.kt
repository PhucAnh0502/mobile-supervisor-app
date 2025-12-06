package com.example.gr2

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
	override fun onCreate(savedInstanceState: Bundle?) {
		super.onCreate(savedInstanceState)

		// Ensure notification channel exists for the background service
		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
			val channelId = "gr2_bg_channel"
			val name = "GR2 Background"
			val descriptionText = "Notifications for GR2 background service"
			val importance = NotificationManager.IMPORTANCE_LOW
			val channel = NotificationChannel(channelId, name, importance)
			channel.description = descriptionText
			val manager = getSystemService(NotificationManager::class.java)
			manager.createNotificationChannel(channel)
		}
	}

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)
		// Initialize our CellInfo handler which registers a MethodChannel on "cell_info"
		CellInfoHandler(this, flutterEngine.dartExecutor.binaryMessenger)
	}
}
