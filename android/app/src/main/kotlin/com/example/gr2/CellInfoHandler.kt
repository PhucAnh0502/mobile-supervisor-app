package com.example.gr2

import android.content.Context
import android.os.Build
import android.telephony.CellInfo
import android.telephony.CellInfoCdma
import android.telephony.CellInfoGsm
import android.telephony.CellInfoLte
import android.telephony.CellInfoNr
import android.telephony.CellInfoWcdma
import android.telephony.CellSignalStrength
import android.telephony.TelephonyManager
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject

class CellInfoHandler(context: Context, messenger: BinaryMessenger) : MethodChannel.MethodCallHandler {
    private val channel = MethodChannel(messenger, "cell_info")
    private val context: Context = context

    init {
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getAllCellInfo", "cell_info", "getCellInfo" -> {
                try {
                    val telephony = context.getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager
                    val cells = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR1) {
                        telephony.allCellInfo
                    } else {
                        emptyList<CellInfo>()
                    }

                    val arr = JSONArray()
                    for (cell in cells) {
                        val obj = JSONObject()
                        when (cell) {
                            is CellInfoGsm -> {
                                obj.put("type", "GSM")
                                val cid = try { cell.cellIdentity.cid } catch (e: Exception) { JSONObject.NULL }
                                obj.put("cid", cid)
                                val mcc = try { cell.cellIdentity.mcc } catch (e: Exception) { JSONObject.NULL }
                                val mnc = try { cell.cellIdentity.mnc } catch (e: Exception) { JSONObject.NULL }
                                obj.put("mcc", mcc)
                                obj.put("mnc", mnc)
                                obj.put("signalDbm", cell.cellSignalStrength.dbm)
                            }
                            is CellInfoLte -> {
                                obj.put("type", "LTE")
                                obj.put("ci", cell.cellIdentity.ci)
                                obj.put("tac", cell.cellIdentity.tac)
                                obj.put("mcc", cell.cellIdentity.mcc)
                                obj.put("mnc", cell.cellIdentity.mnc)
                                obj.put("pci", cell.cellIdentity.pci)
                                obj.put("signalDbm", cell.cellSignalStrength.dbm)
                            }
                            is CellInfoWcdma -> {
                                obj.put("type", "WCDMA")
                                obj.put("cid", cell.cellIdentity.cid)
                                obj.put("lac", cell.cellIdentity.lac)
                                obj.put("mcc", cell.cellIdentity.mcc)
                                obj.put("mnc", cell.cellIdentity.mnc)
                                obj.put("signalDbm", cell.cellSignalStrength.dbm)
                            }
                            is CellInfoNr -> {
                                obj.put("type", "NR")
                                // Use reflection to access NR-specific fields to avoid compile-time errors
                                try {
                                    val identity = cell.cellIdentity
                                    val idClass = identity.javaClass
                                    fun safeGet(name: String): Any? {
                                        return try {
                                            val m = idClass.getMethod(name)
                                            m.invoke(identity)
                                        } catch (ex: Exception) {
                                            null
                                        }
                                    }
                                    val nci = safeGet("getNci") ?: safeGet("nci")
                                    val tac = safeGet("getTac") ?: safeGet("tac")
                                    val mcc = safeGet("getMcc") ?: safeGet("mcc")
                                    val mnc = safeGet("getMnc") ?: safeGet("mnc")
                                    val pci = safeGet("getPci") ?: safeGet("pci")
                                    if (nci != null) obj.put("nci", nci) else obj.put("nci", JSONObject.NULL)
                                    if (tac != null) obj.put("tac", tac) else obj.put("tac", JSONObject.NULL)
                                    if (mcc != null) obj.put("mcc", mcc) else obj.put("mcc", JSONObject.NULL)
                                    if (mnc != null) obj.put("mnc", mnc) else obj.put("mnc", JSONObject.NULL)
                                    if (pci != null) obj.put("pci", pci) else obj.put("pci", JSONObject.NULL)
                                } catch (e: Exception) {
                                    // reflection failed - leave fields absent or null
                                }
                                // For NR the signal strength object methods vary by API; attempt to get dbm via reflection
                                try {
                                    val ss = cell.cellSignalStrength
                                    val ssClass = ss.javaClass
                                    val dbmMethod = try { ssClass.getMethod("getDbm") } catch (ex: Exception) { null }
                                    val dbm = dbmMethod?.invoke(ss) ?: try { ssClass.getMethod("getAsuLevel")?.invoke(ss) } catch (ex: Exception) { null }
                                    if (dbm != null) obj.put("signalDbm", dbm) else obj.put("signalDbm", JSONObject.NULL)
                                } catch (e: Exception) {
                                    // ignore
                                }
                            }
                            is CellInfoCdma -> {
                                obj.put("type", "CDMA")
                                obj.put("systemId", cell.cellIdentity.systemId)
                                obj.put("networkId", cell.cellIdentity.networkId)
                                try { obj.put("signalDbm", cell.cellSignalStrength.dbm) } catch (e: Exception) {}
                            }
                            else -> {
                                obj.put("type", "UNKNOWN")
                            }
                        }
                        arr.put(obj)
                    }

                    result.success(arr.toString())
                } catch (se: SecurityException) {
                    result.error("security_exception", se.message, null)
                } catch (e: Exception) {
                    result.error("error", e.message, null)
                }
            }
            else -> result.notImplemented()
        }
    }
}
