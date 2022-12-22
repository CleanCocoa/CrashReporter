//  Copyright © 2019 Christian Tietze. All rights reserved.
//  Distributed under the MIT License.

import Cocoa
import CrashReporter


//
// Please Note
// -----------
//
// The Example.app scheme is configured to run without a debugger attached.
// This way, the app can crash and produce a crash log.
//
// That meant you cannot use breakpoints inside the app, too.
//


/// Assuming you run the server script from `php -S 127.0.0.1:3333`.
let crashReporterURL = URL(string: "https://crashreport.christiantietze.de/")!

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!

    lazy var crashReporter = CrashReporter(
        crashReporterURL: crashReporterURL,
        privacyPolicyURL: URL(string: "https://example.com/privacy-policy")!)

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        crashReporter.check(collectEmailAddress: true,
                            alwaysShowCrashReporterWindow: false,
                            displayCrashReporterWindowAsModal: true)
    }

    /// Cocoa binding-enabled wrapper for the preference setting.
    ///
    /// Will not update the crash reporter window checkbox state, because that one
    /// doesn't use a `NSUserDefaultsController` which would be notified by the
    /// underlying defaults setting. (I think that's overkill for this simple task.)
    @objc public dynamic var sendCrashReportsAutomatically: Bool {
        get {
            return crashReporter.sendCrashReportsAutomatically
        }
        set {
            crashReporter.sendCrashReportsAutomatically = newValue
        }
    }

    @IBAction func crashApp(_ sender: Any?) {
        if isDebuggerAttached {
            showDebugWarning()
        } else {
            fatalError("Intentional crash.")
        }
    }

    private func showDebugWarning() {
        let alert = NSAlert()
        alert.accessoryView = {
            let imageView = NSImageView(frame: .init(x: 0, y: 0, width: 415, height: 84))
            imageView.image = NSImage(named: "scheme")!  // Force-try ok in example app :)
            return imageView
        }()
        alert.messageText = "Cannot create crash log in DEBUG mode"
        alert.informativeText = "Change your Example.app scheme in Xcode:  run this with the \"Release\" build configuration and disable running as \"Debug Executable\"    ."
        alert.addButton(withTitle: "Continue")
        _ = alert.runModal()
    }
}

let isDebuggerAttached: Bool = {
    var debuggerIsAttached = false

    var name: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
    var info: kinfo_proc = kinfo_proc()
    var info_size = MemoryLayout<kinfo_proc>.size

    let success = name.withUnsafeMutableBytes { (nameBytePtr: UnsafeMutableRawBufferPointer) -> Bool in
        guard let nameBytesBlindMemory = nameBytePtr.bindMemory(to: Int32.self).baseAddress else { return false }
        return -1 != sysctl(nameBytesBlindMemory, 4, &info, &info_size, nil, 0)
    }

    if !success {
        debuggerIsAttached = false
    }

    if !debuggerIsAttached && (info.kp_proc.p_flag & P_TRACED) != 0 {
        debuggerIsAttached = true
    }

    return debuggerIsAttached
}()
