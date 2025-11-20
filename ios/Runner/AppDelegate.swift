import UIKit
import Flutter
import CoreTelephony

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let cellChannel = FlutterMethodChannel(name: "cell_info", binaryMessenger: controller.binaryMessenger)

    cellChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
        var payload = Self.getCellInfoPayload()
      switch call.method {
      case "getAllCellInfo", "getCellInfo", "cell_info":
        // produce JSON array string describing available cellular providers/technologies
        
          // Attempt to augment with private info (best-effort). This will not crash if private selectors are absent.
          let extras = PrivateCellInfo.getExtraInfo()
          if !extras.isEmpty {
            for i in 0..<payload.count {
              if let serviceId = payload[i]["serviceId"] as? String,
                 let add = extras[serviceId] {
                for (k, v) in add {
                  payload[i][k] = v
                }
              }
            }
          }
        if let data = try? JSONSerialization.data(withJSONObject: payload, options: []),
           let jsonString = String(data: data, encoding: .utf8) {
          result(jsonString)
        } else {
          result(FlutterError(code: "encode_error", message: "Failed to encode cell info", details: nil))
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private static func getCellInfoPayload() -> [[String: Any]] {
    var output: [[String: Any]] = []

    let telephony = CTTelephonyNetworkInfo()

    // Per-SIM providers (iOS 12+)
    // serviceSubscriberCellularProviders is [String: CTCarrier] — keys are service identifiers (sim slot)
    if #available(iOS 12.0, *) {
      if let providers = telephony.serviceSubscriberCellularProviders {
        // Current radio tech per service (may be nil)
        let currentRadio = telephony.serviceCurrentRadioAccessTechnology ?? [:]

        for (serviceId, carrier) in providers {
          var obj: [String: Any] = [:]
          // map radio technology to friendly type string
          let radio = currentRadio[serviceId] ?? telephony.currentRadioAccessTechnology ?? ""
          obj["type"] = mapRadioAccessTechnology(radio)

          // Provide carrier info where available
          obj["carrierName"] = carrier.carrierName ?? NSNull()
          obj["isoCountryCode"] = carrier.isoCountryCode ?? NSNull()
          obj["mobileCountryCode"] = carrier.mobileCountryCode ?? NSNull()
          obj["mobileNetworkCode"] = carrier.mobileNetworkCode ?? NSNull()

          // The Android code supplies many fields (cid, tac, pci, signalDbm, etc.)
          // Most of these are NOT available via public iOS APIs; we return nulls for them
          obj["cid"] = NSNull()
          obj["ci"] = NSNull()
          obj["tac"] = NSNull()
          obj["pci"] = NSNull()
          obj["nci"] = NSNull()
          obj["signalDbm"] = NSNull()

          // include serviceId so caller can correlate multi-SIM
          obj["serviceId"] = serviceId

          output.append(obj)
        }
      } else {
        // Fallback: use single provider if available
        if let carrier = telephony.subscriberCellularProvider {
          var obj: [String: Any] = [:]
          let radio = telephony.currentRadioAccessTechnology ?? ""
          obj["type"] = mapRadioAccessTechnology(radio)
          obj["carrierName"] = carrier.carrierName ?? NSNull()
          obj["isoCountryCode"] = carrier.isoCountryCode ?? NSNull()
          obj["mobileCountryCode"] = carrier.mobileCountryCode ?? NSNull()
          obj["mobileNetworkCode"] = carrier.mobileNetworkCode ?? NSNull()
          obj["cid"] = NSNull()
          obj["tac"] = NSNull()
          obj["pci"] = NSNull()
          obj["nci"] = NSNull()
          obj["signalDbm"] = NSNull()
          output.append(obj)
        }
      }
    } else {
      // iOS < 12 fallback: limited info from subscriberCellularProvider
      if let carrier = telephony.subscriberCellularProvider {
        var obj: [String: Any] = [:]
        let radio = telephony.currentRadioAccessTechnology ?? ""
        obj["type"] = mapRadioAccessTechnology(radio)
        obj["carrierName"] = carrier.carrierName ?? NSNull()
        obj["isoCountryCode"] = carrier.isoCountryCode ?? NSNull()
        obj["mobileCountryCode"] = carrier.mobileCountryCode ?? NSNull()
        obj["mobileNetworkCode"] = carrier.mobileNetworkCode ?? NSNull()
        obj["cid"] = NSNull()
        obj["tac"] = NSNull()
        obj["pci"] = NSNull()
        obj["nci"] = NSNull()
        obj["signalDbm"] = NSNull()
        output.append(obj)
      }
    }

    return output
  }

  private static func mapRadioAccessTechnology(_ tech: String?) -> String {
    guard let tech = tech else { return "UNKNOWN" }
    // Common iOS CTRadioAccessTechnology constants -> map to cell types similar to Android
    switch tech {
    case CTRadioAccessTechnologyGPRS:
      return "GSM"
    case CTRadioAccessTechnologyEdge:
      return "GSM"
    case CTRadioAccessTechnologyWCDMA:
      return "WCDMA"
    case CTRadioAccessTechnologyHSDPA:
      return "WCDMA"
    case CTRadioAccessTechnologyHSUPA:
      return "WCDMA"
    case CTRadioAccessTechnologyCDMA1x:
      return "CDMA"
    case CTRadioAccessTechnologyCDMAEVDORev0, CTRadioAccessTechnologyCDMAEVDORevA, CTRadioAccessTechnologyCDMAEVDORevB:
      return "CDMA"
    case CTRadioAccessTechnologyLTE:
      return "LTE"
    case CTRadioAccessTechnologyNRNSA, CTRadioAccessTechnologyNR:
      return "NR"
    default:
      return "UNKNOWN"
    }
  }
}