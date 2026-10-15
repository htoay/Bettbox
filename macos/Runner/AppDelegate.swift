import Cocoa
import FlutterMacOS
import window_ext

@main
class AppDelegate: FlutterAppDelegate {
    
    override func applicationWillFinishLaunching(_ notification: Notification) {
        if UserDefaults.standard.object(forKey: "flutter.keepDockIcon") as? Bool == false {
            NSApp.setActivationPolicy(.accessory)
        }
        super.applicationWillFinishLaunching(notification)
    }

    override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
    
    override func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        WindowExtPlugin.instance?.handleShouldTerminate()
        return .terminateCancel
    }

    override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
      return true
    }
    
    override func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        guard let window = mainFlutterWindow else {
            return true
        }
        if window.isMiniaturized {
            window.deminiaturize(self)
        }
        window.makeKeyAndOrderFront(self)
        NSApp.activate(ignoringOtherApps: true)
        return false
    }
}
