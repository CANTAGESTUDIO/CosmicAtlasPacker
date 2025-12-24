import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow, NSWindowDelegate {
  private let surfaceColor = NSColor(red: 38.0/255.0, green: 38.0/255.0, blue: 38.0/255.0, alpha: 1.0)

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    // Set delegate for window events
    self.delegate = self

    // Remove title bar border/separator
    setupTitleBar()

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }

  private func setupTitleBar() {
    self.titlebarAppearsTransparent = true
    self.isMovableByWindowBackground = true
    self.backgroundColor = surfaceColor
    self.titleVisibility = .hidden
    self.styleMask.insert(.fullSizeContentView)

    if #available(macOS 11.0, *) {
      self.titlebarSeparatorStyle = .none
    }

    // Customize title bar container
    if let titleBarContainerView = self.standardWindowButton(.closeButton)?.superview?.superview {
      titleBarContainerView.wantsLayer = true
      titleBarContainerView.layer?.backgroundColor = surfaceColor.cgColor
    }

    if let titleBarView = self.standardWindowButton(.closeButton)?.superview {
      titleBarView.wantsLayer = true
      titleBarView.layer?.backgroundColor = surfaceColor.cgColor
    }
  }

  // NSWindowDelegate methods
  func windowWillMove(_ notification: Notification) {
    enforceTitleBarStyle()
  }

  func windowDidMove(_ notification: Notification) {
    enforceTitleBarStyle()
  }

  func windowWillStartLiveResize(_ notification: Notification) {
    enforceTitleBarStyle()
  }

  func windowDidEndLiveResize(_ notification: Notification) {
    enforceTitleBarStyle()
  }

  override func becomeKey() {
    super.becomeKey()
    enforceTitleBarStyle()
  }

  override func resignKey() {
    super.resignKey()
    enforceTitleBarStyle()
  }

  private func enforceTitleBarStyle() {
    if #available(macOS 11.0, *) {
      self.titlebarSeparatorStyle = .none
    }

    if let titleBarContainerView = self.standardWindowButton(.closeButton)?.superview?.superview {
      titleBarContainerView.layer?.backgroundColor = surfaceColor.cgColor
    }

    if let titleBarView = self.standardWindowButton(.closeButton)?.superview {
      titleBarView.layer?.backgroundColor = surfaceColor.cgColor
    }
  }
}
