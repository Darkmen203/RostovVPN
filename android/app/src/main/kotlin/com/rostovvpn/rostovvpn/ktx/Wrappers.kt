package com.rostovvpn.rostovvpn.ktx

import android.net.IpPrefix
import android.os.Build
import androidx.annotation.RequiresApi
import io.nekohasekai.libbox.RoutePrefix
import io.nekohasekai.libbox.StringIterator
import java.net.InetAddress

// В твоём AAR у StringIterator есть и len(), и hasNext()/next(), но метода get(i) НЕТ.
// Самый безопасный toList — через hasNext()/next().
fun StringIterator.toList(): List<String> {
    val out = mutableListOf<String>()
    while (hasNext()) out.add(next())
    return out
}

@RequiresApi(Build.VERSION_CODES.TIRAMISU)
fun RoutePrefix.toIpPrefix() = IpPrefix(InetAddress.getByName(address()), prefix())
