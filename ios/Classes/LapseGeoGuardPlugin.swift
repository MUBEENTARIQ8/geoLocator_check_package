import Flutter
import UIKit

public class LapseGeoGuardPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "lapse_geo_guard/gnss", binaryMessenger: registrar.messenger())
    let instance = LapseGeoGuardPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "snapshot":
      result(["supported": false])
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
