import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = NSRect(x: 0, y: 0, width: 1440, height: 900)
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)
    self.setContentSize(NSSize(width: 1440, height: 900))
    self.minSize = NSSize(width: 980, height: 640)
    self.center()

    RegisterGeneratedPlugins(registry: flutterViewController)

    let clipboardChannel = FlutterMethodChannel(
      name: "qrencoder/clipboard",
      binaryMessenger: flutterViewController.engine.binaryMessenger)
    clipboardChannel.setMethodCallHandler { (call, result) in
      guard call.method == "setPng" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard let payload = call.arguments as? FlutterStandardTypedData,
            let image = NSImage(data: payload.data) else {
        result(FlutterError(code: "bad-image", message: "PNG could not be decoded", details: nil))
        return
      }
      let pasteboard = NSPasteboard.general
      pasteboard.clearContents()
      pasteboard.writeObjects([image])
      result(nil)
    }

    // Keeps the window chrome (title bar, menus) in step with the theme the
    // editor has picked, so forcing Light or Dark does not leave a title bar
    // from the other appearance.
    let windowChannel = FlutterMethodChannel(
      name: "qrencoder/window",
      binaryMessenger: flutterViewController.engine.binaryMessenger)
    windowChannel.setMethodCallHandler { [weak self] (call, result) in
      switch call.method {
      case "setAppearance":
        let chosen: NSAppearance.Name?
        switch call.arguments as? String {
        case "light": chosen = .aqua
        case "dark": chosen = .darkAqua
        default: chosen = nil
        }
        let appearance: NSAppearance? = chosen.flatMap { NSAppearance(named: $0) }
        self?.appearance = appearance
        NSApp.appearance = appearance
        result(nil)

      case "revealPath":
        // A sandboxed app cannot shell out to `open`, so reveal through
        // NSWorkspace, which is allowed for a file the user just chose.
        guard let path = call.arguments as? String, !path.isEmpty else {
          result(FlutterError(code: "bad-path", message: "no path", details: nil))
          return
        }
        NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: path)])
        result(nil)

      default:
        result(FlutterMethodNotImplemented)
      }
    }

    super.awakeFromNib()
  }
}
