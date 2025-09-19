package com.rostovvpn.rostovvpn.ktx

import android.net.IpPrefix
import android.os.Build
import androidx.annotation.RequiresApi
import io.nekohasekai.libbox.RoutePrefix
import io.nekohasekai.libbox.StringIterator
import java.net.InetAddress

/**
 * Новый формат StringIterator: массивоподобный доступ.
 * Конвертируем в List<String> через len() и индекс.
 */
fun StringIterator.toList(): List<String> {
    val out = ArrayList<String>(len())
    for (i in 0 until len()) {
        // В наших адаптерах доступ по индексу называется get(i)
        out.add(get(i))
    }
    return out
}

@RequiresApi(Build.VERSION_CODES.TIRAMISU)
fun RoutePrefix.toIpPrefix() = IpPrefix(InetAddress.getByName(address()), prefix())
