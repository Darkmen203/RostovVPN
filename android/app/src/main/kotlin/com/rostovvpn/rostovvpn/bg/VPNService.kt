package com.rostovvpn.rostovvpn.bg

import android.util.Log
import com.rostovvpn.rostovvpn.Settings
import android.content.Intent
import android.content.pm.PackageManager.NameNotFoundException
import android.net.ProxyInfo
import android.net.VpnService
import android.os.Build
import android.os.IBinder
import com.rostovvpn.rostovvpn.constant.PerAppProxyMode
import com.rostovvpn.rostovvpn.ktx.toIpPrefix
import io.nekohasekai.libbox.TunOptions
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withContext

class VPNService : VpnService(), PlatformInterfaceWrapper {

    companion object {
        private const val TAG = "A/VPNService"
    }

    private val service = BoxService(this, this)

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int) =
        service.onStartCommand(intent, flags, startId)

    override fun onBind(intent: Intent): IBinder {
        val binder = super.onBind(intent)
        if (binder != null) return binder
        return service.onBind(intent)
    }

    override fun onDestroy() {
        service.onDestroy()
    }

    override fun onRevoke() {
        runBlocking {
            withContext(Dispatchers.Main) { service.onRevoke() }
        }
    }

    // авто-детект интерфейса через protect(fd)
    override fun autoDetectInterfaceControl(fd: Int) {
        protect(fd)
    }

    var systemProxyAvailable = false
    var systemProxyEnabled = false

    fun addIncludePackage(builder: Builder, packageName: String) {
        if (packageName == this.packageName) {
            Log.d(TAG, "Cannot include myself: $packageName")
            return
        }
        try {
            Log.d(TAG, "Including $packageName")
            builder.addAllowedApplication(packageName)
        } catch (_: NameNotFoundException) {
        }
    }

    fun addExcludePackage(builder: Builder, packageName: String) {
        // Не позволяем исключить само VPN-приложение
        if (packageName == this.packageName) {
            Log.d(TAG, "Skip excluding myself: $packageName")
            return
        }
        try {
            Log.d(TAG, "Excluding $packageName")
            builder.addDisallowedApplication(packageName)
        } catch (_: NameNotFoundException) {
        }
    }

    override fun openTun(options: TunOptions): Int {
        if (prepare(this) != null) error("android: missing vpn permission")

        val builder = Builder()
            .setSession("sing-box")
            .setMtu(options.mtu)

        // Разрешаем bypass базовой сети (API 29+) — помогает стабильнее работать EXCLUDE
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                builder.allowBypass()
                Log.d(TAG, "VPN builder: allowBypass()")
            }
        } catch (t: Throwable) { Log.w(TAG, "allowBypass failed: ${t.message}") }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            builder.setMetered(false)
        }

        val inet4Address = options.inet4Address
        while (inet4Address.hasNext()) {
            val address = inet4Address.next()
            builder.addAddress(address.address(), address.prefix())
        }

        val inet6Address = options.inet6Address
        while (inet6Address.hasNext()) {
            val address = inet6Address.next()
            builder.addAddress(address.address(), address.prefix())
        }

        if (options.autoRoute) {
            // dnsServerAddress — это бокс, берём строку
            builder.addDnsServer(options.dnsServerAddress.value)

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                val inet4RouteAddress = options.inet4RouteAddress
                if (inet4RouteAddress.hasNext()) {
                    while (inet4RouteAddress.hasNext()) {
                        builder.addRoute(inet4RouteAddress.next().toIpPrefix())
                    }
                } else {
                    builder.addRoute("0.0.0.0", 0)
                }

                val inet6RouteAddress = options.inet6RouteAddress
                if (inet6RouteAddress.hasNext()) {
                    while (inet6RouteAddress.hasNext()) {
                        builder.addRoute(inet6RouteAddress.next().toIpPrefix())
                    }
                } else {
                    builder.addRoute("::", 0)
                }

                val inet4RouteExcludeAddress = options.inet4RouteExcludeAddress
                while (inet4RouteExcludeAddress.hasNext()) {
                    builder.excludeRoute(inet4RouteExcludeAddress.next().toIpPrefix())
                }

                val inet6RouteExcludeAddress = options.inet6RouteExcludeAddress
                while (inet6RouteExcludeAddress.hasNext()) {
                    builder.excludeRoute(inet6RouteExcludeAddress.next().toIpPrefix())
                }
            } else {
                val inet4RouteAddress = options.inet4RouteRange
                if (inet4RouteAddress.hasNext()) {
                    while (inet4RouteAddress.hasNext()) {
                        val address = inet4RouteAddress.next()
                        builder.addRoute(address.address(), address.prefix())
                    }
                }

                val inet6RouteAddress = options.inet6RouteRange
                if (inet6RouteAddress.hasNext()) {
                    while (inet6RouteAddress.hasNext()) {
                        val address = inet6RouteAddress.next()
                        builder.addRoute(address.address(), address.prefix())
                    }
                }
            }

            if (Settings.perAppProxyEnabled) {
                val appList = Settings.perAppProxyList
                val mode = Settings.perAppProxyMode
                Log.d(TAG, "Per-app enabled. Mode=$mode, size=${appList.size}")
                if (mode == PerAppProxyMode.INCLUDE) {
                    appList.forEach { addIncludePackage(builder, it) }
                    addIncludePackage(builder, packageName)
                } else {
                    appList.forEach { addExcludePackage(builder, it) }
                    // В EXCLUDE режиме не смешиваем allowed/disallowed.
                    // Само приложение не исключаем, значит оно остаётся внутри VPN по умолчанию.
                    Log.d(TAG, "EXCLUDE mode: do not mix allowed/disallowed; self stays included by default")
                }
            } else {
                val includePackage = options.includePackage
                if (includePackage.hasNext()) {
                    while (includePackage.hasNext()) {
                        addIncludePackage(builder, includePackage.next())
                    }
                }
                val excludePackage = options.excludePackage
                if (excludePackage.hasNext()) {
                    while (excludePackage.hasNext()) {
                        addExcludePackage(builder, excludePackage.next())
                    }
                }
            }
        }

        // --- Политика системного HTTP-прокси ---
        // Не объявляем прокси в режиме EXCLUDE при непустом списке приложений.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val perAppEnabled = Settings.perAppProxyEnabled
            val perAppMode = Settings.perAppProxyMode
            val perAppListSize = if (perAppEnabled) Settings.perAppProxyList.size else 0

            val excludeActive = perAppEnabled &&
                    perAppMode == PerAppProxyMode.EXCLUDE &&
                    perAppListSize > 0

            val allowSystemProxy =
                options.isHTTPProxyEnabled &&
                !excludeActive

            systemProxyAvailable = allowSystemProxy
            systemProxyEnabled = allowSystemProxy && Settings.systemProxyEnabled

            Log.d(
                TAG,
                "System proxy policy: allow=$allowSystemProxy, enabled=$systemProxyEnabled, " +
                        "perAppEnabled=$perAppEnabled, mode=$perAppMode, listSize=$perAppListSize"
            )

            if (systemProxyEnabled) {
                builder.setHttpProxy(
                    ProxyInfo.buildDirectProxy(
                        options.httpProxyServer,
                        options.httpProxyServerPort
                    )
                )
            }
        } else {
            systemProxyAvailable = false
            systemProxyEnabled = false
        }

        val pfd = builder.establish()
            ?: error("android: the application is not prepared or is revoked")
        service.fileDescriptor = pfd
        return pfd.fd
    }

    override fun writeLog(message: String) = service.writeLog(message)
}
