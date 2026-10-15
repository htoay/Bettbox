package com.appshub.bettbox.plugins

import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class TilePlugin : FlutterPlugin, MethodChannel.MethodCallHandler {

    private var channel: MethodChannel? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    companion object {
        private const val TAG = "TilePlugin"
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "tile").apply {
            setMethodCallHandler(this@TilePlugin)
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        runCatching { channel?.invokeMethod("detached", null) }
            .onFailure { Log.e(TAG, "Failed to invoke detached: ${it.message}") }
        channel?.setMethodCallHandler(null)
        channel = null
    }

    fun handleStart() = safeInvokeMethod("start")
    fun handleStop() = safeInvokeMethod("stop")
    fun handleReconnectIpc() = safeInvokeMethod("reconnectIpc")

    private fun safeInvokeMethod(method: String) {
        val ch = channel ?: return
        if (Looper.myLooper() == Looper.getMainLooper()) {
            runCatching { ch.invokeMethod(method, null) }
                .onFailure { Log.e(TAG, "Failed to invoke $method: ${it.message}") }
        } else {
            mainHandler.post {
                runCatching { ch.invokeMethod(method, null) }
                    .onFailure { Log.e(TAG, "Failed to invoke $method: ${it.message}") }
            }
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) = result.notImplemented()
}
