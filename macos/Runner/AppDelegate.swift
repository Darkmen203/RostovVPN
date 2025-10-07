import Cocoa
import FlutterMacOS
import UserNotifications
import Darwin

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    // https://github.com/leanflutter/window_manager/issues/214
    return false
  }

  override func applicationDidFinishLaunching(_ aNotification: Notification) {
    if #available(macOS 10.14, *) {
      if launchedWithElevatedPrivileges() {
        NSLog("Skipping notification authorization because app was launched with elevated privileges")
      } else {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, error in
          if let nsError = error as NSError? {
            if nsError.domain == NSCocoaErrorDomain, nsError.code == 4099 {
              NSLog("Notification service not reachable (probably launched without a user session); continuing without notifications")
            } else {
              NSLog("Error requesting notification authorization: \(nsError)")
            }
          }
        }
      }
    }

    // Handle system shutdown/restart notifications
    NSWorkspace.shared.notificationCenter.addObserver(
      self,
      selector: #selector(self.willPowerOff(_:)),
      name: NSWorkspace.willPowerOffNotification,
      object: nil
    )

    super.applicationDidFinishLaunching(aNotification)
  }

  @objc func willPowerOff(_ note: Notification) {
    stopVpnFast()
    disableProxyFast()
  }

  private func stopVpnFast() {
    let exeDir = Bundle.main.bundlePath + "/Contents/MacOS"
    let cli = exeDir + "/RostovVPNCli"
    let p1 = Process(); p1.launchPath = cli; p1.arguments = ["tunnel", "stop"]; try? p1.run()
    usleep(600_000)
    let p2 = Process(); p2.launchPath = cli; p2.arguments = ["tunnel", "deactivate-force"]; try? p2.run()
  }

  private func disableProxyFast() {
    let exeDir = Bundle.main.bundlePath + "/Contents/MacOS"
    let cli = exeDir + "/RostovVPNCli"
    // Prefer delegating to CLI (it knows all services/interfaces)
    let p = Process(); p.launchPath = cli; p.arguments = ["proxy", "off"]; try? p.run()
    // If CLI is unavailable we could fallback to networksetup for "Wi-Fi"/"Ethernet".
  }

  private func launchedWithElevatedPrivileges() -> Bool {
    if getuid() == 0 || geteuid() == 0 {
      return true
    }

    let env = ProcessInfo.processInfo.environment
    if env["SUDO_UID"] != nil || env["SUDO_USER"] != nil || env["SUDO_COMMAND"] != nil {
      return true
    }

    return false
  }

  // // window manager restore from dock: https://leanflutter.dev/blog/click-dock-icon-to-restore-after-closing-the-window
  // override func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
  //   if !flag {
  //     for window in NSApp.windows {
  //       if !window.isVisible {
  //         window.setIsVisible(true)
  //       }
  //       window.makeKeyAndOrderFront(self)
  //       NSApp.activate(ignoringOtherApps: true)
  //     }
  //   }
  //   return true
  // }
}
