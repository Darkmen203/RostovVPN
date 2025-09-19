package com.rostovvpn.rostovvpn

import android.util.Log
import com.rostovvpn.rostovvpn.utils.RvpnCommandClient
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.JSONMethodCodec
import io.nekohasekai.libbox.StatusMessage
import kotlinx.coroutines.CoroutineScope

class StatsChannel(private val scope: CoroutineScope) : FlutterPlugin, RvpnCommandClient.Handler{
    companion object {
        const val TAG = "A/StatsChannel"
        const val STATS_CHANNEL = "com.rostovvpn.app/stats"
    }

    private val rvpnCommandClient =
            RvpnCommandClient(scope, RvpnCommandClient.ConnectionType.Status, this)

    private var statsChannel: EventChannel? = null
    private var statsEvent: EventChannel.EventSink? = null

    override fun updateStatus(status: StatusMessage) {
        MainActivity.instance.runOnUiThread {
            val map = listOf(
                    Pair("connections-in", status.connectionsIn),
                    Pair("connections-out", status.connectionsOut),
                    Pair("uplink", status.uplink),
                    Pair("downlink", status.downlink),
                    Pair("uplink-total", status.uplinkTotal),
                    Pair("downlink-total", status.downlinkTotal)
            ).associate { it.first to it.second }
            statsEvent?.success(map)
        }
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        statsChannel = EventChannel(
                flutterPluginBinding.binaryMessenger,
                STATS_CHANNEL,
                JSONMethodCodec.INSTANCE
        )

        statsChannel!!.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                statsEvent = events
                Log.d(TAG, "connecting stats command client")
                rvpnCommandClient.connect()
            }

            override fun onCancel(arguments: Any?) {
                statsEvent = null
                Log.d(TAG, "disconnecting stats command client")
                rvpnCommandClient.disconnect()
            }
        })
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        statsEvent = null
        rvpnCommandClient.disconnect()
        statsChannel?.setStreamHandler(null)
    }
}