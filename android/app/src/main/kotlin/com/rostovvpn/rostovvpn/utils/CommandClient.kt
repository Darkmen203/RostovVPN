package com.rostovvpn.rostovvpn.utils

import go.Seq
import io.nekohasekai.libbox.CommandClient as LibboxCommandClient
import io.nekohasekai.libbox.CommandClientHandler
import io.nekohasekai.libbox.CommandClientOptions
import io.nekohasekai.libbox.Connections
import io.nekohasekai.libbox.Libbox
import io.nekohasekai.libbox.OutboundGroup
import io.nekohasekai.libbox.OutboundGroupIterator
import io.nekohasekai.libbox.StatusMessage
import io.nekohasekai.libbox.StringIterator
import com.rostovvpn.rostovvpn.ktx.toList
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch

open class CommandClient(
    private val scope: CoroutineScope,
    private val connectionType: ConnectionType,
    private val handler: Handler
) {

    enum class ConnectionType {
        Status, Groups, Log, ClashMode, GroupOnly
    }

    interface Handler {
        fun onConnected() {}
        fun onDisconnected() {}
        fun updateStatus(status: StatusMessage) {}
        fun updateGroups(groups: List<OutboundGroup>) {}
        fun clearLog() {}
        fun appendLog(message: String) {}
        fun initializeClashMode(modeList: List<String>, currentMode: String) {}
        fun updateClashMode(newMode: String) {}
    }

    private var client: LibboxCommandClient? = null
    private val clientHandler = ClientHandler()

    fun connect() {
        disconnect()
        val options = CommandClientOptions().apply {
            command = when (connectionType) {
                ConnectionType.Status -> Libbox.CommandStatus
                ConnectionType.Groups -> Libbox.CommandGroup
                ConnectionType.Log -> Libbox.CommandLog
                ConnectionType.ClashMode -> Libbox.CommandClashMode
                ConnectionType.GroupOnly -> Libbox.CommandGroup // fallback
            }
            statusInterval = 2 * 1_000_000_000 // ns
        }

        val libboxClient = LibboxCommandClient(clientHandler, options)
        scope.launch(Dispatchers.IO) {
            for (i in 1..10) {
                delay(100 + i.toLong() * 50)
                try {
                    libboxClient.connect()
                } catch (_: Exception) {
                    continue
                }
                if (!isActive) {
                    runCatching { libboxClient.disconnect() }
                    return@launch
                }
                this@CommandClient.client = libboxClient
                return@launch
            }
            runCatching { libboxClient.disconnect() }
        }
    }

    fun disconnect() {
        client?.apply {
            runCatching { disconnect() }
            Seq.destroyRef(refnum)
        }
        client = null
    }

    private inner class ClientHandler : CommandClientHandler {

        override fun connected() {
            handler.onConnected()
        }

        override fun disconnected(message: String?) {
            handler.onDisconnected()
        }

        override fun writeGroups(message: OutboundGroupIterator?) {
            if (message == null) return
            val groups = mutableListOf<OutboundGroup>()
            while (message.hasNext()) {
                groups.add(message.next())
            }
            handler.updateGroups(groups)
        }

        // В этой ветке есть clearLogs()
        override fun clearLogs() {
            handler.clearLog()
        }

        // В этой ветке нет writeLog(...), зато есть writeLogs(StringIterator)
        override fun writeLogs(messageList: StringIterator) {
            // Склеим пачку логов в одну строку (можно и по одной отправлять)
            messageList.toList().forEach { handler.appendLog(it) }
        }

        override fun writeStatus(message: StatusMessage?) {
            if (message == null) return
            handler.updateStatus(message)
        }

        override fun initializeClashMode(modeList: StringIterator, currentMode: String) {
            handler.initializeClashMode(modeList.toList(), currentMode)
        }

        override fun updateClashMode(newMode: String) {
            handler.updateClashMode(newMode)
        }

        override fun writeConnections(message: Connections) {
            // no-op для нашего UI
        }
    }
}
