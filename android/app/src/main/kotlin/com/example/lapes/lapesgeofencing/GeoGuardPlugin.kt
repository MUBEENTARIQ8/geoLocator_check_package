package com.example.lapes.lapesgeofencing

import android.content.Context
import android.location.GnssStatus
import android.location.LocationManager
import android.os.Build
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class GeoGuardPlugin: FlutterPlugin, MethodChannel.MethodCallHandler {
  private lateinit var channel: MethodChannel
  private lateinit var context: Context
  private var locationManager: LocationManager? = null
  private var callback: GnssStatus.Callback? = null

  private var satsUsed: Int = 0
  private var avgCn0: Double = 0.0
  private var supported: Boolean = false

  override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(binding.binaryMessenger, "lapse_geo_guard/gnss")
    channel.setMethodCallHandler(this)
    context = binding.applicationContext
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
      } catch (se: SecurityException) {
        // Missing location permission: keep supported=true but zeros for metrics
      } catch (_: Exception) {}
    } else {
      supported = false
    }
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: MethodChannel.Result) {
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

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    try {
      if (callback != null) {
        locationManager?.unregisterGnssStatusCallback(callback!!)
      }
    } catch (_: Exception) {}
    channel.setMethodCallHandler(null)
  }
}
