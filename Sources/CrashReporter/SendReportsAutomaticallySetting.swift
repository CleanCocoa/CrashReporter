//  Copyright © 2019 Christian Tietze. All rights reserved.
//  Distributed under the MIT License.

import Foundation

struct SendReportsAutomaticallySetting {
    static var standard: SendReportsAutomaticallySetting {
        return SendReportsAutomaticallySetting(
            isVisible: true,
            userDefaults: .standard,
            sendCrashLogsAutomaticallyKey: CrashReporter.DefaultsKeys.standard.sendCrashLogsAutomaticallyKey)
    }

    let isVisible: Bool

    let userDefaults: UserDefaults
    let sendCrashLogsAutomaticallyKey: String

    var isEnabled: Bool {
        get {
            return userDefaults.bool(forKey: sendCrashLogsAutomaticallyKey)
        }
        set {
            userDefaults.set(newValue, forKey: sendCrashLogsAutomaticallyKey)
        }
    }
}
