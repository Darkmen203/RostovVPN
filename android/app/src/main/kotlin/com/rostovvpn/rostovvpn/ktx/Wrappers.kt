package com.rostovvpn.rostovvpn.ktx

import android.net.IpPrefix
import android.os.Build
import androidx.annotation.RequiresApi
import io.nekohasekai.libbox.RoutePrefix
import io.nekohasekai.libbox.StringIterator
import java.net.InetAddress

/** В ЭТОЙ версии libbox StringIterator — со старыми методами hasNext()/next(). */
fun StringIterator.toList(): List<String> {
    val out = ArrayList<String>(len())
    for (i in 0 until len()) {
        out.add(get(i))
    }
    return out
}

@RequiresApi(Build.VERSION_CODES.TIRAMISU)
fun RoutePrefix.toIpPrefix() = IpPrefix(InetAddress.getByName(address()), prefix())
