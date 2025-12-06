package com.example.gr2

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.telephony.*
import androidx.core.app.ActivityCompat
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject
import java.util.concurrent.Executor

class CellInfoHandler(private val context: Context, messenger: BinaryMessenger) : MethodChannel.MethodCallHandler {
    private val channel = MethodChannel(messenger, "cell_info")
    private val mainHandler = Handler(Looper.getMainLooper())

    init {
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getAllCellInfo", "cell_info", "getCellInfo" -> {
                getCellInfoSafe(result)
            }
            else -> result.notImplemented()
        }
    }

    private fun getCellInfoSafe(result: MethodChannel.Result) {
        if (ActivityCompat.checkSelfPermission(context, Manifest.permission.ACCESS_FINE_LOCATION) != PackageManager.PERMISSION_GRANTED) {
            result.error("PERMISSION_DENIED", "Location permission not granted", null)
            return
        }

        val telephony = context.getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            try {
                telephony.requestCellInfoUpdate(
                    context.mainExecutor,
                    object : TelephonyManager.CellInfoCallback() {
                        override fun onCellInfo(cellInfo: MutableList<CellInfo>) {
                            // Thành công: Trả dữ liệu mới về Flutter
                            result.success(parseCellsToJson(cellInfo))
                        }

                        override fun onError(errorCode: Int, detail: Throwable?) {
                            // Thất bại: Cố gắng lấy dữ liệu cached cũ
                            try {
                                val cachedCells = telephony.allCellInfo
                                result.success(parseCellsToJson(cachedCells))
                            } catch (e: Exception) {
                                result.success("[]")
                            }
                        }
                    }
                )
            } catch (e: Exception) {
                try {
                    val cells = telephony.allCellInfo
                    result.success(parseCellsToJson(cells))
                } catch (ex: Exception) {
                    result.error("ERROR", ex.message, null)
                }
            }
        } else {
            try {
                val cells = telephony.allCellInfo
                result.success(parseCellsToJson(cells))
            } catch (e: Exception) {
                result.error("ERROR", e.message, null)
            }
        }
    }

    private fun parseCellsToJson(cells: List<CellInfo>?): String {
        if (cells == null) return "[]"

        val arr = JSONArray()
        for (cell in cells) {
            val obj = JSONObject()
            try {
                when (cell) {
                    is CellInfoGsm -> {
                        obj.put("type", "GSM")
                        obj.put("cid", cell.cellIdentity.cid)
                        obj.put("lac", cell.cellIdentity.lac)
                        obj.put("mcc", cell.cellIdentity.mcc)
                        obj.put("mnc", cell.cellIdentity.mnc)
                        obj.put("signalDbm", cell.cellSignalStrength.dbm)
                    }
                    is CellInfoLte -> {
                        obj.put("type", "LTE")
                        obj.put("ci", cell.cellIdentity.ci)
                        obj.put("cid", cell.cellIdentity.ci) 
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
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                            val id = cell.cellIdentity as CellIdentityNr
                            val ss = cell.cellSignalStrength as CellSignalStrengthNr
                            
                            obj.put("nci", id.nci)
                            obj.put("cid", id.nci) 
                            obj.put("tac", id.tac)
                            obj.put("mcc", id.mccString)
                            obj.put("mnc", id.mncString)
                            obj.put("pci", id.pci)
                            obj.put("signalDbm", ss.dbm)
                        }
                    }
                    is CellInfoCdma -> {
                        obj.put("type", "CDMA")
                        obj.put("systemId", cell.cellIdentity.systemId)
                        obj.put("networkId", cell.cellIdentity.networkId)
                        obj.put("signalDbm", cell.cellSignalStrength.dbm)
                    }
                }
                if (obj.length() > 0) {
                    arr.put(obj)
                }
            } catch (e: Exception) {
                // Ignore lỗi parse từng cell lẻ
            }
        }
        return arr.toString()
    }
}