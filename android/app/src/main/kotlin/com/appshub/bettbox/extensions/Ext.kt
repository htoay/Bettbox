package com.appshub.bettbox.extensions

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.drawable.Drawable
import android.net.ConnectivityManager
import android.net.Network
import android.os.Build
import android.system.OsConstants.IPPROTO_TCP
import android.system.OsConstants.IPPROTO_UDP
import android.util.Base64
import androidx.core.graphics.drawable.toBitmap
import com.appshub.bettbox.TempActivity
import com.appshub.bettbox.models.CIDR
import com.appshub.bettbox.models.Metadata
import com.appshub.bettbox.models.VpnOptions
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.withContext
import java.io.ByteArrayOutputStream
import java.net.Inet4Address
import java.net.Inet6Address
import java.net.InetAddress
import java.util.concurrent.locks.ReentrantLock
import kotlin.coroutines.resume
import kotlin.coroutines.suspendCoroutine

suspend fun Drawable.getBase64(maxSizePx: Int = 128): String = withContext(Dispatchers.IO) {
    val defaultSize = 96
    val intrinsicWidth = if (intrinsicWidth > 0) intrinsicWidth else defaultSize
    val intrinsicHeight = if (intrinsicHeight > 0) intrinsicHeight else defaultSize
    val maxDim = maxOf(intrinsicWidth, intrinsicHeight)
    val targetSize = minOf(maxDim, maxSizePx)
    val scale = targetSize.toFloat() / maxDim.toFloat()
    val targetWidth = (intrinsicWidth * scale).toInt().coerceAtLeast(1)
    val targetHeight = (intrinsicHeight * scale).toInt().coerceAtLeast(1)
    val bitmap = toBitmap(targetWidth, targetHeight, Bitmap.Config.ARGB_8888)
    ByteArrayOutputStream().use { byteArrayOutputStream ->
        bitmap.compress(Bitmap.CompressFormat.PNG, 80, byteArrayOutputStream)
        Base64.encodeToString(byteArrayOutputStream.toByteArray(), Base64.NO_WRAP)
    }
}

fun Metadata.getProtocol(): Int? = when {
    network.startsWith("tcp") -> IPPROTO_TCP
    network.startsWith("udp") -> IPPROTO_UDP
    else -> null
}

fun VpnOptions.getIpv4RouteAddress(): List<CIDR> = routeAddress.filter { it.isIpv4() }.map { it.toCIDR() }

fun VpnOptions.getIpv6RouteAddress(): List<CIDR> = routeAddress.filter { it.isIpv6() }.map { it.toCIDR() }

fun String.isIpv4(): Boolean {
    val parts = split("/")
    require(parts.size == 2) { "Invalid CIDR format" }
    val ip = parts[0]
    return ip.contains('.') && !ip.contains(':')
}

fun String.isIpv6(): Boolean {
    val parts = split("/")
    require(parts.size == 2) { "Invalid CIDR format" }
    val ip = parts[0]
    return ip.contains(':') && !ip.contains('.')
}

fun String.toCIDR(): CIDR {
    val parts = split("/")
    require(parts.size == 2) { "Invalid CIDR format" }
    val ipAddress = parts[0]
    val prefixLength = parts[1].toIntOrNull() ?: throw IllegalArgumentException("Invalid prefix length")
    val address = InetAddress.getByName(ipAddress)
    val maxPrefix = if (address.address.size == 4) 32 else 128
    require(prefixLength in 0..maxPrefix) { "Invalid prefix length for IP version" }
    return CIDR(address, prefixLength)
}

fun ConnectivityManager.resolveDns(network: Network?): List<String> =
    getLinkProperties(network)?.dnsServers?.map { it.asSocketAddressText(53) } ?: emptyList()

fun InetAddress.asSocketAddressText(port: Int): String = when (this) {
    is Inet6Address -> "[${numericToTextFormat(this)}]:$port"
    is Inet4Address -> "$hostAddress:$port"
    else -> throw IllegalArgumentException("Unsupported Inet type ${javaClass}")
}

fun Context.wrapAction(action: String): String = "${packageName}.action.$action"

fun Context.getActionIntent(action: String): Intent =
    Intent(this, TempActivity::class.java).apply {
        this.action = wrapAction(action)
        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_MULTIPLE_TASK)
    }

fun Context.getActionPendingIntent(action: String): PendingIntent {
    val flags = if (Build.VERSION.SDK_INT >= 31) {
        PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
    } else {
        PendingIntent.FLAG_UPDATE_CURRENT
    }
    return PendingIntent.getActivity(this, 0, getActionIntent(action), flags)
}

private fun numericToTextFormat(address: Inet6Address): String = buildString(39) {
    val src = address.address
    for (i in 0 until 8) {
        append(Integer.toHexString(src[i shl 1].toInt() shl 8 and 0xff00 or (src[(i shl 1) + 1].toInt() and 0xff)))
        if (i < 7) append(":")
    }
    if (address.scopeId > 0) {
        append("%")
        append(address.scopeId)
    }
}

suspend fun <T> MethodChannel.awaitResult(method: String, arguments: Any? = null): T? =
    withContext(Dispatchers.Main) {
        suspendCancellableCoroutine { continuation ->
            invokeMethod(method, arguments, object : MethodChannel.Result {
                @Suppress("UNCHECKED_CAST")
                override fun success(result: Any?) {
                    if (continuation.isActive) continuation.resume(result as? T)
                }
                override fun error(code: String, message: String?, details: Any?) {
                    if (continuation.isActive) continuation.resume(null)
                }
                override fun notImplemented() {
                    if (continuation.isActive) continuation.resume(null)
                }
            })
        }
    }

fun ReentrantLock.safeLock() {
    if (!isHeldByCurrentThread) lock()
}

fun ReentrantLock.safeUnlock() {
    if (isHeldByCurrentThread) unlock()
}
