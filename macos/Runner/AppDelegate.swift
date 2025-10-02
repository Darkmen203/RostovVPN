import Cocoa
import FlutterMacOS

import UserNotifications
@main
class AppDelegate: FlutterAppDelegate {
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    // https://github.com/leanflutter/window_manager/issues/214
    return false
  }
  override func applicationDidFinishLaunching(_ aNotification: Notification) {
    // Request notification authorization
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge]) { granted, error in
        if let error = error {
            print("Error requesting notification authorization: \(error)")
        }
    }

    // Выключение/перезагрузка
    NSWorkspace.shared.notificationCenter.addObserver(
      self,
      selector: #selector(self.willPowerOff(_:)),
      name: NSWorkspace.willPowerOffNotification,
      object: nil
    )
  }

  @objc func willPowerOff(_ note: Notification) {
    stopVpnFast()
    disableProxyFast()
  }

  private func stopVpnFast() {
    let exeDir = Bundle.main.bundlePath + "/Contents/MacOS"
    let cli    = exeDir + "/RostovVPNCli"
    let p1 = Process(); p1.launchPath = cli; p1.arguments = ["tunnel","stop"]; try? p1.run()
    usleep(600_000)
    let p2 = Process(); p2.launchPath = cli; p2.arguments = ["tunnel","deactivate-force"]; try? p2.run()
  }

  private func disableProxyFast() {
    let exeDir = Bundle.main.bundlePath + "/Contents/MacOS"
    let cli    = exeDir + "/RostovVPNCli"
    // Предпочтительно поручить CLI (он знает все сервисы/интерфейсы)
    let p = Process(); p.launchPath = cli; p.arguments = ["proxy","off"]; try? p.run()
    // Если CLI нет — можно fallback на networksetup по "Wi-Fi"/"Ethernet"
    // (оставлено намеренно пустым, чтобы не гадать интерфейсы).
  }

  // // window manager restore from dock: https://leanflutter.dev/blog/click-dock-icon-to-restore-after-closing-the-window
  // override func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
  //     if !flag {
  //         for window in NSApp.windows {
  //             if !window.isVisible {
  //                 window.setIsVisible(true)
  //             }
  //             window.makeKeyAndOrderFront(self)
  //             NSApp.activate(ignoringOtherApps: true)
  //         }
  //     }
  //     return true
  // }
}
