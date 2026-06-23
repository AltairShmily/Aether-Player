package com.example.aether

import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// gomobile generates class "Mobile" in package derived from Go module path
// For module "aether-server" package "mobile" → aether_server.Mobile
import aether_server.Mobile

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
                            val err = Mobile.startServer(port)
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
                        result.success(Mobile.getPort())
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
