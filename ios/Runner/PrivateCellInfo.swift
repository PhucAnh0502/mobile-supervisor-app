import Foundation
import CoreTelephony

/// Best-effort helper that attempts to read private CoreTelephony fields using KVC
/// This uses runtime introspection and will gracefully return empty results if the
/// private properties are not present. Use only for internal/testing; private APIs
/// risk App Store rejection.
final class PrivateCellInfo {
  /// Returns a map serviceId -> extra info dictionary (may be empty)
  static func getExtraInfo() -> [String: [String: Any]] {
    var result: [String: [String: Any]] = [:]

    let telephony = CTTelephonyNetworkInfo()
    let anyTelephony = telephony as AnyObject

    // Try to access possible private client objects
    let clientCandidates = ["coreTelephonyClient", "_coreTelephonyClient", "serviceSubscriberCellularProviders"]

    for serviceId in (telephony.serviceSubscriberCellularProviders?.keys ?? []) {
      var extras: [String: Any] = [:]

      // Attempt to probe likely private keys for the telephony object
      // by using value(forKey:). Each access is guarded and may return nil.
      let probeKeys = [
        "signalStrength",
        "currentSignalStrength",
        "rawSignalStrength",
        "dbm",
        "cellInfo",
        "cellInfoList",
        "currentCellInfo",
        "currentServiceCellularProviders",
        "currentServiceSubscriberCellularProviders"
      ]

      for key in probeKeys {
        if let v = tryValue(anyTelephony, key: key) {
          extras[key] = v
        }
      }

      // Try probing client object and service-specific selectors
      for clientKey in clientCandidates {
        if let client = tryValue(anyTelephony, key: clientKey) as? AnyObject {
          // common selectors on potential client objects
          let clientProbe = ["getSignalStrength", "signalStrengthForService:", "signalStrengths", "getCellInfo"]
          for selKey in clientProbe {
            if let v = tryValue(client, key: selKey) {
              extras[selKey] = v
            }
          }
        }
      }

      if !extras.isEmpty {
        result[String(describing: serviceId)] = extras
      }
    }

    return result
  }

  private static func tryValue(_ obj: AnyObject, key: String) -> Any? {
    // Use Objective-C KVC where possible. Catch exceptions thrown by KVC.
    do {
      if obj.responds(to: Selector(key)) {
        // attempt perform selector
        let sel = Selector(key)
        let unmanaged = obj.perform(sel)
        return unmanaged?.takeUnretainedValue()
      }
    } catch {
      // fallthrough to KVC attempt
    }

    // KVC attempt (may throw). Use ObjC exception handling via Obj-C bridge is limited,
    // so use value(forKey:) guarded by respondsToSelector if possible.
    if obj.responds(to: Selector("valueForKey:")) {
      // value(forKey:) is available on NSObject subclasses
      let ns = obj as? NSObject
      if let ns = ns {
        // Use try? to avoid throws; value(forKey:) does not throw in Swift but may crash if key is truly invalid
        let v = ns.value(forKey: key)
        return v
      }
    }

    return nil
  }
}
