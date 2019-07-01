# CrashReporter for macOS Apps

![Swift 5.0](https://img.shields.io/badge/Swift-5.0-blue.svg?style=flat)
![Version](https://img.shields.io/github/tag/CleanCocoa/CrashReporter.svg?style=flat)
![License](https://img.shields.io/github/license/CleanCocoa/CrashReporter.svg?style=flat)
![Platform](https://img.shields.io/badge/platform-macOS-lightgrey.svg?style=flat)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

Your app will crash one day. Be prepared to collect crash data automatically, because not every user is a techno wizard capable of sending you `.crash` files from the built-in Console app.


## Requirements

- macOS 10.12+
- Xcode 10.2+
- Swift 5+

For the optional server endpoint script, you'll need PHP 7.x.


## Installation

### Carthage

    github "CleanCocoa/CrashReporter"

### CocoaPods

    pod 'CrashReporterMac'
    
### SwiftPM

    .package(url: "https://github.com/CleanCocoa/CrashReporter", from: "0.1.0")

### Manual

If you want to customize the UI, checkout the source and copy all code from `CrashReporter/` into your project.


## Usage

### Server Endpoint

You need a server endpoint to receive crash reports.

The framework does not care what the server does:

- You can email the incoming crash report from your server, or
- you can store the crash report as a timestamped file on disk for later reference, of
- you can store the crash report in a database.

The crash reporter framework will perform a HTTP POST request:

- The `User-Agent` metadata is set to `"\(APP_NAME)-\(VERSION)"` if the values are found in the app's bundle, e.g. `"Sherlock-2.0"`.
- The `crashlog` variable is to the contents of the `.crash` file the user submits.
- The server response will be ignored.

You can roll your own endpoint as long as its URL is reachable from the app.

Or you can use the simple endpoint shipped in this repository! It's located at `php/index.php`. This PHP server script will attempt to email you the crash log as an attachment with a timestamp, e.g. `20190701204853 Sherlock-2.0.crash` (where the timestamp signifies the ISO-formatted date 2019-07-01 20:48:52)

To run the script on your local machine for quick testing, run:

    $ php -S 127.0.0.1:3333 php/index.php

Then use `URL(string: "http://127.0.0.1:3333/")` in your Swift code for the endpoint.


### Application Setup

See the code in `Example/`, which is part of the Xcode project.

You can use the framework as-is in your app to check for crash reports:

```swift
import CrashReporter

let crashReporterURL = URL(string: "http://127.0.0.1:3333/")!
let crashReporter = CrashReporter(
    crashReporterURL: crashReporterURL,
    privacyPolicyURL: URL(string: "https://example.com/privacy-policy")!)

// Run the check in the background and display 
// a crash reporter window if needed
crashReporter.check()
```


### Preference Pane in Your Application

If you allow the user to tick "Send crash reports automatically" in the crash reporter window, you should add a similar option to your app's preference pane to enable undoing this setting.

Refer to `DefaultsKeys.sendCrashLogsAutomaticallyKey`.

If you want to employ Cocoa Bindings to configure a "Send crash reports automatically" checkbox in your preference panes or main menu, then you can create a simple KVC-compliant wrapper in your classes:

```swift
// Assuming this is loaded from a Nib where you set an object of this type as the
// target for "Value" Cocoa Bindings.
class PreferenceController: NSViewController {
    let crashReporter: CrashReporter = // ... setup before ...
    
    // Cocoa bindings path is `self.sendCrashReportsAutomatically`
    @objc public dynamic var sendCrashReportsAutomatically: Bool {
        get {
            return crashReporter.sendCrashReportsAutomatically
        }
        set {
            crashReporter.sendCrashReportsAutomatically = newValue
        }
    }
}
```


## API

- `CrashReporter.check()` is the default call that displays the crash reporter window for the current app if needed, and uploads the crash report to the server.
- `CrashReporter.check(appName:alwaysShowCrashReporterWindow:)` allows you to control the app name for which the reporter searches `.crash` files. Set `alwaysShowCrashReporterWindow` to `true` if you always want to show the crash reporter window instead of letting the user pick when she sees the window.
- `CrashReporter.sendCrashReportsAutomatically` exposes the user setting of sending reports automatically. Useful for preference panes.

If you don't change the `UserDefaults` keys for the crash reporter settings, use the various `DefaultsKeys.standard` properties in your app to look up the values:

- `sendCrashLogsAutomaticallyKey` is `"CRR_sendCrashLogsAutomatically"` -- use this for your preference panes to toggle automatically sending crash reports
- `lastSeenCrashLogTimeSince1970Key` is `"CRR_lastSeenCrashLogTimeSince1970"`
- `lastSeenCrashLogMD5Key` is `"CRR_lastSeenCrashLogMD5"`


## License

The whole project is distributed under the MIT license. See [the LICENSE file](LICENSE) for reference.

A quick overview:

- The Swift code is adapted from [Brent Simmons's NetNewsWire 5](https://github.com/brentsimmons/NetNewsWire), Copyright &copy; Brent Simmons 2017-2019. All rights reserved.
- Changes in this repository are Copyright &copy; Christian Tietze 2019. All rights reserved.
- The PHP server code is Copyright &copy; Christian Tietze 2019. All rights reserved.

