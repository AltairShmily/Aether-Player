package com.example.aether

import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// gomobile default Java package is "go", class name from Go package "mobile"
import go.Mobile

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.aether/backend"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startServer" -> {
                        val port = call.argument<Int>("port") ?: 19800
                        Thread {
                            val err = Mobile.startServer(port.toLong())
                            Handler(Looper.getMainLooper()).post {
                                if (err.isEmpty()) {
                                    result.success(true)
                                } else {
                                    result.error("START_FAILED", err, null)
                                }
                            }
                        }.start()
                    }
                    "stopServer" -> {
                        Thread {
                            val err = Mobile.stopServer()
                            Handler(Looper.getMainLooper()).post {
                                if (err.isEmpty()) {
                                    result.success(true)
                                } else {
                                    result.error("STOP_FAILED", err, null)
                                }
                            }
                        }.start()
                    }
                    "isRunning" -> {
                        result.success(Mobile.isRunning())
                    }
                    "getPort" -> {
                        result.success(Mobile.getPort().toInt())
                    }
                    "ping" -> {
                        Thread {
                            val reply = Mobile.ping()
                            Handler(Looper.getMainLooper()).post {
                                result.success(reply)
                            }
                        }.start()
                    }
                    else -> {
                        result.notImplemented()
                    }
                }
            }
    }
}
