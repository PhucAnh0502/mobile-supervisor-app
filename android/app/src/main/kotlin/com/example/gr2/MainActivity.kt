package com.example.gr2

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)
		// Initialize our CellInfo handler which registers a MethodChannel on "cell_info"
		CellInfoHandler(this, flutterEngine.dartExecutor.binaryMessenger)
	}
}
