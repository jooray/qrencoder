import CoreGraphics
import Foundation

let opts: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
if let list = CGWindowListCopyWindowInfo(opts, kCGNullWindowID) as? [[String: Any]] {
  for w in list {
    let owner = (w[kCGWindowOwnerName as String] as? String) ?? ""
    let name = (w[kCGWindowName as String] as? String) ?? ""
    let layer = (w[kCGWindowLayer as String] as? Int) ?? -1
    if layer == 0, owner.lowercased().contains("qrencoder") || name.lowercased().contains("qrencoder") {
      let number = (w[kCGWindowNumber as String] as? Int) ?? 0
      let bounds = (w[kCGWindowBounds as String] as? [String: Any]) ?? [:]
      print("\(number)\t\(owner)\t\(name)\t\(bounds)")
    }
  }
}
