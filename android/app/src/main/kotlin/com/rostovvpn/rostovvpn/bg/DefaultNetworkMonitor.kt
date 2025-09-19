package com.rostovvpn.rostovvpn.bg

import android.net.Network
import android.net.NetworkCapabilities
import android.os.Build
import com.rostovvpn.rostovvpn.Application
import io.nekohasekai.libbox.InterfaceUpdateListener
import java.net.NetworkInterface

object DefaultNetworkMonitor {

    var defaultNetwork: Network? = null
    private var listener: InterfaceUpdateListener? = null

    suspend fun start() {
        DefaultNetworkListener.start(this) { net ->
            defaultNetwork = net
            checkDefaultInterfaceUpdate(net)
        }
        defaultNetwork = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Application.connectivity.activeNetwork
        } else {
            DefaultNetworkListener.get()
        }
        // при старте тоже пушнём актуальное состояние
        checkDefaultInterfaceUpdate(defaultNetwork)
    }

    suspend fun stop() {
        DefaultNetworkListener.stop(this)
    }

    suspend fun require(): Network {
        val network = defaultNetwork
        if (network != null) return network
        return DefaultNetworkListener.get()
    }

    fun setListener(listener: InterfaceUpdateListener?) {
        this.listener = listener
        checkDefaultInterfaceUpdate(defaultNetwork)
    }

    private fun checkDefaultInterfaceUpdate(newNetwork: Network?) {
        val l = listener ?: return

        if (newNetwork != null) {
            val lp = Application.connectivity.getLinkProperties(newNetwork) ?: run {
                // если нет LP, сбросим интерфейс
                l.updateDefaultInterface("", -1, false, false)
                return
            }

            val interfaceName = lp.interfaceName

            // Вычисляем флаги из NetworkCapabilities
            val nc = Application.connectivity.getNetworkCapabilities(newNetwork)

            // "Expensive" трактуем как "metered": платный/дорогой трафик
            val isExpensive: Boolean = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR1) {
                // надёжный способ — системная метрика "активная сеть с метерингом"
                Application.connectivity.isActiveNetworkMetered
            } else {
                // для очень старых API падаем обратно на отсутствие NOT_METERED
                nc?.hasCapability(NetworkCapabilities.NET_CAPABILITY_NOT_METERED)?.not() ?: false
            }

            // "Constrained" — сеть с ограничениями (нет NOT_RESTRICTED)
            val isConstrained: Boolean = nc?.let {
                !it.hasCapability(NetworkCapabilities.NET_CAPABILITY_NOT_RESTRICTED)
            } ?: false

            // Индекс интерфейса может появиться не сразу — подождём немного
            for (times in 0 until 10) {
                try {
                    val ifaceIndex = NetworkInterface.getByName(interfaceName).index
                    l.updateDefaultInterface(interfaceName, ifaceIndex, isExpensive, isConstrained)
                    return
                } catch (_: Exception) {
                    Thread.sleep(100)
                }
            }
            // если так и не получили индекс — сброс
            l.updateDefaultInterface("", -1, isExpensive, isConstrained)
        } else {
            // Нет дефолтной сети
            l.updateDefaultInterface("", -1, false, false)
        }
    }
}
