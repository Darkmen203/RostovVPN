package com.rostovvpn.rostovvpn

import android.util.Log
import com.google.gson.Gson
import com.rostovvpn.rostovvpn.utils.RvpnCommandClient
import com.rostovvpn.rostovvpn.utils.ParsedOutboundGroup
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.nekohasekai.libbox.OutboundGroup
import kotlinx.coroutines.CoroutineScope


class ActiveGroupsChannel(private val scope: CoroutineScope) : FlutterPlugin,
    RvpnCommandClient.Handler {
    companion object {
        const val TAG = "A/ActiveGroupsChannel"
        const val CHANNEL = "com.rostovvpn.app/active-groups"
        val gson = Gson()
    }

    private val client =
        RvpnCommandClient(scope, RvpnCommandClient.ConnectionType.GroupOnly, this)

    private var channel: EventChannel? = null
    private var event: EventChannel.EventSink? = null

    override fun updateGroups(groups: List<OutboundGroup>) {
        MainActivity.instance.runOnUiThread {
            val parsedGroups = groups.map { group -> ParsedOutboundGroup.fromOutbound(group) }
            event?.success(gson.toJson(parsedGroups))
        }
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = EventChannel(
            flutterPluginBinding.binaryMessenger,
            CHANNEL
        )

        channel!!.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                event = events
                Log.d(TAG, "connecting active groups command client")
                client.connect()
            }

            override fun onCancel(arguments: Any?) {
                event = null
                Log.d(TAG, "disconnecting active groups command client")
                client.disconnect()
            }
        })
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        event = null
        client.disconnect()
        channel?.setStreamHandler(null)
    }
}