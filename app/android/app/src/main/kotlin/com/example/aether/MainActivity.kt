package com.example.aether

import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.aether/backend"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startServer" -> {
                        val port = call.argument<Int>("port") ?: 19800
                        // Run on background thread to avoid blocking UI
                        Thread {
                            val err = AetherServer.startServer(port)
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
                            val err = AetherServer.stopServer()
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
                        result.success(AetherServer.isRunning())
                    }
                    "getPort" -> {
                        result.success(AetherServer.getPort())
                    }
                    "ping" -> {
                        Thread {
                            val reply = AetherServer.ping()
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
