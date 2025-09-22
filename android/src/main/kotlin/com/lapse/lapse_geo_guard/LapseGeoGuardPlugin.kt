package com.lapse.lapse_geo_guard

import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import android.location.GnssStatus
import android.location.LocationManager
import android.content.Context
import android.os.Build

/** LapseGeoGuardPlugin */
class LapseGeoGuardPlugin: FlutterPlugin, MethodCallHandler {
  private lateinit var channel : MethodChannel
  private lateinit var context: Context
  private var locationManager: LocationManager? = null
  private var callback: GnssStatus.Callback? = null
  private var satsUsed: Int = 0
  private var avgCn0: Double = 0.0
  private var supported: Boolean = false

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "lapse_geo_guard/gnss")
    channel.setMethodCallHandler(this)
    context = flutterPluginBinding.applicationContext
    locationManager = context.getSystemService(Context.LOCATION_SERVICE) as LocationManager

    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
      supported = true
      callback = object : GnssStatus.Callback() {
        override fun onSatelliteStatusChanged(status: GnssStatus) {
          var used = 0
          var cn0Sum = 0.0
          var cnt = 0
          for (i in 0 until status.satelliteCount) {
            if (status.usedInFix(i)) used++
            val c = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) status.getCn0DbHz(i).toDouble() else 0.0
            if (!c.isNaN()) { cn0Sum += c; cnt++ }
          }
          satsUsed = used
          avgCn0 = if (cnt > 0) cn0Sum / cnt else 0.0
        }
      }
      try {
        locationManager?.registerGnssStatusCallback(callback!!, null)
      } catch (_: SecurityException) {
      } catch (_: Exception) {}
    } else {
      supported = false
    }
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      "snapshot" -> {
        if (supported) {
          result.success(mapOf("supported" to true, "satsUsed" to satsUsed, "avgCn0" to avgCn0))
        } else {
          result.success(mapOf("supported" to false))
        }
      }
      else -> result.notImplemented()
    }
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    try {
      if (callback != null) locationManager?.unregisterGnssStatusCallback(callback!!)
    } catch (_: Exception) {}
    channel.setMethodCallHandler(null)
  }
}
