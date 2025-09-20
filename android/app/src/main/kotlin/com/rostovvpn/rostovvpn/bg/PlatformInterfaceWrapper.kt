package com.rostovvpn.rostovvpn.bg

import android.content.pm.PackageManager
import android.os.Build
import android.os.Process
import androidx.annotation.RequiresApi
import com.rostovvpn.rostovvpn.Application
import io.nekohasekai.libbox.InterfaceUpdateListener
import io.nekohasekai.libbox.LocalDNSTransport
import io.nekohasekai.libbox.NetworkInterface as LibboxNetworkInterface
import io.nekohasekai.libbox.NetworkInterfaceIterator
import io.nekohasekai.libbox.Notification // Важно: libbox.Notification, не android.app.Notification
import io.nekohasekai.libbox.PlatformInterface
import io.nekohasekai.libbox.StringIterator
import io.nekohasekai.libbox.TunOptions
import io.nekohasekai.libbox.WIFIState
import java.net.Inet6Address
import java.net.InetSocketAddress
import java.net.InterfaceAddress
import java.net.NetworkInterface
import java.util.Enumeration

/**
 * Совместимо с твоим AAR:
 *  - обязателен sendNotification(Notification)
 *  - обязателен localDNSTransport()
 *  - есть usePlatformAutoDetectInterfaceControl()
 *  - StringIterator: обязателен len() + hasNext()/next()
 *  - (опционально) systemCertificates()
 */
interface PlatformInterfaceWrapper : PlatformInterface {

    // --- Общие фичи ядра ---
    override fun usePlatformAutoDetectInterfaceControl(): Boolean = true
    override fun autoDetectInterfaceControl(fd: Int) {
        /* no-op; VPNService переопределяет protect(fd) */
    }

    override fun openTun(options: TunOptions): Int = error("invalid argument")
    override fun useProcFS(): Boolean = Build.VERSION.SDK_INT < Build.VERSION_CODES.Q

    // Требуется этой ревизией libbox
    override fun localDNSTransport(): LocalDNSTransport =
        object : LocalDNSTransport {
            override fun raw(): Boolean = true
            override fun exchange(ctx: io.nekohasekai.libbox.ExchangeContext, msg: ByteArray) { /* no-op */ }
            override fun lookup(
                ctx: io.nekohasekai.libbox.ExchangeContext,
                name: String,
                qtype: String
            ) { /* no-op */ }
        }

    // Можно вернуть пусто (если не используешь). ОБЯЗАТЕЛЕН len().
    override fun systemCertificates(): StringIterator =
        object : StringIterator {
            override fun len(): Int = 0
            override fun hasNext(): Boolean = false
            override fun next(): String = ""
        }

    @RequiresApi(Build.VERSION_CODES.Q)
    override fun findConnectionOwner(
        ipProtocol: Int,
        sourceAddress: String,
        sourcePort: Int,
        destinationAddress: String,
        destinationPort: Int
    ): Int {
        val uid = Application.connectivity.getConnectionOwnerUid(
            ipProtocol,
            InetSocketAddress(sourceAddress, sourcePort),
            InetSocketAddress(destinationAddress, destinationPort)
        )
        if (uid == Process.INVALID_UID) error("android: connection owner not found")
        return uid
    }

    override fun packageNameByUid(uid: Int): String {
        val packages = Application.packageManager.getPackagesForUid(uid)
        if (packages.isNullOrEmpty()) error("android: package not found")
        return packages[0]
    }

    @Suppress("DEPRECATION")
    override fun uidByPackageName(packageName: String): Int =
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                Application.packageManager.getPackageUid(
                    packageName,
                    PackageManager.PackageInfoFlags.of(0)
                )
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                Application.packageManager.getPackageUid(packageName, 0)
            } else {
                Application.packageManager.getApplicationInfo(packageName, 0).uid
            }
        } catch (_: PackageManager.NameNotFoundException) {
            error("android: package not found")
        }

    override fun startDefaultInterfaceMonitor(listener: InterfaceUpdateListener) {
        DefaultNetworkMonitor.setListener(listener)
    }

    override fun closeDefaultInterfaceMonitor(listener: InterfaceUpdateListener) {
        DefaultNetworkMonitor.setListener(null)
    }

    override fun getInterfaces(): NetworkInterfaceIterator =
        InterfaceArray(NetworkInterface.getNetworkInterfaces())

    override fun underNetworkExtension(): Boolean = false
    override fun includeAllNetworks(): Boolean = false
    override fun clearDNSCache() { /* no-op */ }
    override fun readWIFIState(): WIFIState? = null

    // Этой ревизией PlatformInterface метод обязателен (тип из libbox!)
    override fun sendNotification(notification: Notification) {
        // no-op: уведомления показываем через ServiceNotification
    }

    // === адаптеры ===
    private class InterfaceArray(private val iterator: Enumeration<NetworkInterface>) :
        NetworkInterfaceIterator {
        override fun hasNext(): Boolean = iterator.hasMoreElements()
        override fun next(): LibboxNetworkInterface {
            val element = iterator.nextElement()
            val prefixes: List<String> = element.interfaceAddresses.map { it.toPrefix() }
            return LibboxNetworkInterface().apply {
                name = element.name
                index = element.index
                runCatching { mtu = element.mtu }
                // ВАЖНО: передаём сам список, чтобы реализовать len()
                addresses = StringArray(prefixes)
            }
        }
        private fun InterfaceAddress.toPrefix(): String =
            if (address is Inet6Address)
                "${Inet6Address.getByAddress(address.address).hostAddress}/${networkPrefixLength}"
            else
                "${address.hostAddress}/${networkPrefixLength}"
    }

    /** Совместимый StringIterator: len() + hasNext()/next() */
    private class StringArray(private val data: List<String>) : StringIterator {
        private var i = 0
        override fun len(): Int = data.size
        override fun hasNext(): Boolean = i < data.size
        override fun next(): String = data[i++]
    }
}
