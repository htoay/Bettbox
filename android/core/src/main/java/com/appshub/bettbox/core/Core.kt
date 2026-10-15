package com.appshub.bettbox.core

import android.util.Log
import java.net.InetSocketAddress

object Core {

    private external fun startTun(fd: Int, cb: TunInterface)
    private external fun suspend(suspended: Int)
    external fun stopTun()

    init {
        System.loadLibrary("core")
    }

    private fun parseInetSocketAddress(address: String): InetSocketAddress {
        val lastColonIndex = address.lastIndexOf(':')
        if (lastColonIndex == -1) {
            return InetSocketAddress(address, 0)
        }

        val host = address.substring(0, lastColonIndex).removeSurrounding("[", "]")
        val port = address.substring(lastColonIndex + 1).toIntOrNull() ?: 0

        return InetSocketAddress(host, port)
    }

    fun startTun(
        fd: Int,
        protect: (Int) -> Boolean,
        resolverProcess: (protocol: Int, source: InetSocketAddress, target: InetSocketAddress, uid: Int) -> String
    ) {
        startTun(fd, object : TunInterface {
            override fun protect(fd: Int) {
                runCatching { protect(fd) }
                    .onFailure { Log.e("Core", "protect JNI callback error: ${it.message}") }
            }

            override fun resolverProcess(
                protocol: Int,
                source: String,
                target: String,
                uid: Int
            ): String = runCatching {
                resolverProcess(
                    protocol,
                    parseInetSocketAddress(source),
                    parseInetSocketAddress(target),
                    uid
                )
            }.onFailure {
                Log.e("Core", "resolverProcess JNI callback error: ${it.message}")
            }.getOrDefault("")
        })
    }

    fun suspended(value: Boolean) {
        runCatching {
            Log.d("Core", "suspended called with value: $value")
            suspend(if (value) 1 else 0)
            Log.d("Core", "suspend JNI call completed")
        }.onFailure {
            Log.e("Core", "Error calling suspend: ${it.message}", it)
        }
    }

    fun dozeSuspend(value: Boolean) {
        runCatching {
            Log.d("Core", "dozeSuspend called with value: $value")
            suspend(if (value) 2 else 0)
            Log.d("Core", "dozeSuspend JNI call completed")
        }.onFailure {
            Log.e("Core", "Error calling dozeSuspend: ${it.message}", it)
        }
    }
}
