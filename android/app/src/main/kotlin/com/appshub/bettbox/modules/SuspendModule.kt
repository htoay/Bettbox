package com.appshub.bettbox.modules

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import androidx.core.content.getSystemService
import com.appshub.bettbox.core.Core

class SuspendModule(private val context: Context) {
    private var isInstalled = false
    private var isSuspended = false

    private val handler = Handler(Looper.getMainLooper())
    private val suspendRunnable = Runnable {
        if (shouldSuspend && !isSuspended) {
            Core.dozeSuspend(true)
            isSuspended = true
        }
    }

    private val powerManager: PowerManager? by lazy { context.getSystemService<PowerManager>() }

    private val isScreenOn: Boolean get() = powerManager?.isInteractive ?: true

    private val isDeviceIdleMode: Boolean
        get() = Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && powerManager?.isDeviceIdleMode == true

    private val shouldSuspend: Boolean get() = !isScreenOn && isDeviceIdleMode

    private fun resume() {
        handler.removeCallbacks(suspendRunnable)
        if (isSuspended) {
            Core.dozeSuspend(false)
            isSuspended = false
            com.appshub.bettbox.plugins.VpnPlugin.onUpdateNetwork()
        }
    }

    private fun updateSuspendState() {
        if (shouldSuspend) {
            handler.removeCallbacks(suspendRunnable)
            handler.postDelayed(suspendRunnable, 3000L)
        } else {
            resume()
        }
    }

    private val receiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            when (intent?.action) {
                Intent.ACTION_SCREEN_ON, Intent.ACTION_USER_PRESENT -> {
                    resume()
                }
                else -> {
                    updateSuspendState()
                }
            }
        }
    }

    fun install() {
        if (isInstalled) return
        isInstalled = true
        isSuspended = false

        val filter = IntentFilter().apply {
            addAction(Intent.ACTION_SCREEN_ON)
            addAction(Intent.ACTION_SCREEN_OFF)
            addAction(Intent.ACTION_USER_PRESENT)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                addAction(PowerManager.ACTION_DEVICE_IDLE_MODE_CHANGED)
            }
        }
        context.registerReceiver(receiver, filter)
        updateSuspendState()
    }

    fun uninstall() {
        if (!isInstalled) return
        isInstalled = false

        runCatching {
            handler.removeCallbacks(suspendRunnable)
            context.unregisterReceiver(receiver)
            if (isSuspended) {
                Core.dozeSuspend(false)
                isSuspended = false
            }
        }
    }
}
