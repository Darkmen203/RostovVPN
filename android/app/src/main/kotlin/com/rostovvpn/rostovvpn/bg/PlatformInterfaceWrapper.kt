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
 * Дефолтные реализации под Android для методов PlatformInterface. Требуемый localDNSTransport()
 * есть; sendNotification в этой ветке API отсутствует.
 */
interface PlatformInterfaceWrapper : PlatformInterface {

    // --- Управление TUN/интерфейсами ---

    override fun openTun(options: TunOptions): Int {
        error("invalid argument")
    }

    override fun useProcFS(): Boolean {
        return Build.VERSION.SDK_INT < Build.VERSION_CODES.Q
    }

    // Требуется текущей версией интерфейса
    override fun localDNSTransport(): LocalDNSTransport = LocalDNSTransport.SYSTEM

    // --- Идентификация владельцев соединений/пакетов ---

    @RequiresApi(Build.VERSION_CODES.Q)
    override fun findConnectionOwner(
            ipProtocol: Int,
            sourceAddress: String,
            sourcePort: Int,
            destinationAddress: String,
            destinationPort: Int
    ): Int {
        val uid =
                Application.connectivity.getConnectionOwnerUid(
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
                        packageName,
                        PackageManager.PackageInfoFlags.of(0)
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

    // --- Мониторинг дефолтного интерфейса ---

    override fun startDefaultInterfaceMonitor(listener: InterfaceUpdateListener) {
        DefaultNetworkMonitor.setListener(listener)
    }

    override fun closeDefaultInterfaceMonitor(listener: InterfaceUpdateListener) {
        DefaultNetworkMonitor.setListener(null)
    }

    // --- Перечень интерфейсов ---

    override fun getInterfaces(): NetworkInterfaceIterator {
        return InterfaceArray(NetworkInterface.getNetworkInterfaces())
    }

    // --- Прочее ---

    override fun underNetworkExtension(): Boolean = false

    override fun includeAllNetworks(): Boolean = false

    override fun clearDNSCache() {
        /* no-op */
    }

    override fun readWIFIState(): WIFIState? = null

    // === Вспомогательные адаптеры ===

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
                // Эта ревизия libbox ждёт StringIterator с len()/get(i)
                addresses = StringArray(prefixes)
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

    /** Совместимая реализация StringIterator (новая форма). */
    private class StringArray(private val data: List<String>) : StringIterator {
        override fun len(): Int = data.size
        override fun get(i: Int): String = data[i]
    }
}
