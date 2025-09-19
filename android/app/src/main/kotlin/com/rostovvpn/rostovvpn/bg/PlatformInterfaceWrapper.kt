package com.rostovvpn.rostovvpn.bg

import android.app.Notification
import android.content.pm.PackageManager
import android.os.Build
import android.os.Process
import androidx.annotation.RequiresApi
import com.rostovvpn.rostovvpn.Application
import io.nekohasekai.libbox.InterfaceUpdateListener
import io.nekohasekai.libbox.NetworkInterfaceIterator
import io.nekohasekai.libbox.PlatformInterface
import io.nekohasekai.libbox.StringIterator
import io.nekohasekai.libbox.TunOptions
import io.nekohasekai.libbox.WIFIState
import java.net.Inet6Address
import java.net.InetSocketAddress
import java.net.InterfaceAddress
import java.net.NetworkInterface
import java.util.Enumeration
import io.nekohasekai.libbox.NetworkInterface as LibboxNetworkInterface

/**
 * Дефолтные реализации под Android для методов PlatformInterface.
 * (эта ревизия libbox требует sendNotification и старый StringIterator)
 */
interface PlatformInterfaceWrapper : PlatformInterface {

    override fun openTun(options: TunOptions): Int {
        error("invalid argument")
    }

    override fun useProcFS(): Boolean {
        return Build.VERSION.SDK_INT < Build.VERSION_CODES.Q
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
    override fun uidByPackageName(packageName: String): Int {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                Application.packageManager.getPackageUid(
                    packageName, PackageManager.PackageInfoFlags.of(0)
                )
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                Application.packageManager.getPackageUid(packageName, 0)
            } else {
                Application.packageManager.getApplicationInfo(packageName, 0).uid
            }
        } catch (e: PackageManager.NameNotFoundException) {
            error("android: package not found")
        }
    }

    override fun startDefaultInterfaceMonitor(listener: InterfaceUpdateListener) {
        DefaultNetworkMonitor.setListener(listener)
    }

    override fun closeDefaultInterfaceMonitor(listener: InterfaceUpdateListener) {
        DefaultNetworkMonitor.setListener(null)
    }

    override fun getInterfaces(): NetworkInterfaceIterator {
        return InterfaceArray(NetworkInterface.getNetworkInterfaces())
    }

    override fun underNetworkExtension(): Boolean = false

    override fun includeAllNetworks(): Boolean = false

    override fun clearDNSCache() { /* no-op */ }

    override fun readWIFIState(): WIFIState? = null

    // ЭТА ВЕТКА API ТРЕБУЕТ sendNotification
    override fun sendNotification(notification: Notification) {
        // no-op; уведомления ведём через ServiceNotification
    }

    private class InterfaceArray(private val iterator: Enumeration<NetworkInterface>) :
        NetworkInterfaceIterator {

        override fun hasNext(): Boolean = iterator.hasMoreElements()

        override fun next(): LibboxNetworkInterface {
            val element = iterator.nextElement()
            val prefixes = element.interfaceAddresses.map { it.toPrefix() }
            return LibboxNetworkInterface().apply {
                name = element.name
                index = element.index
                runCatching { mtu = element.mtu }
                addresses = StringArray(prefixes.iterator())
            }
        }

        private fun InterfaceAddress.toPrefix(): String {
            return if (address is Inet6Address) {
                "${Inet6Address.getByAddress(address.address).hostAddress}/${networkPrefixLength}"
            } else {
                "${address.hostAddress}/${networkPrefixLength}"
            }
        }
    }

    /** Старый итератор строк (hasNext/next). */
    private class StringArray(private val it: Iterator<String>) : StringIterator {
        override fun hasNext(): Boolean = it.hasNext()
        override fun next(): String = it.next()
    }
}
