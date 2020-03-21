//  Copyright © 2019 Christian Tietze. All rights reserved.
//  Distributed under the MIT License.

extension CrashReporter {
    /// Definition of the UserDefaults keys to use.
    public struct DefaultsKeys {
        public static var standard: DefaultsKeys {
            return DefaultsKeys(
                emailAddressKey: "CRR_emailAddress",
                sendCrashLogsAutomaticallyKey: "CRR_sendCrashLogsAutomatically",
                lastSeenCrashLogTimeSince1970Key: "CRR_lastSeenCrashLogTimeSince1970",
                lastSeenCrashLogMD5Key: "CRR_lastSeenCrashLogMD5")
        }

        public let emailAddressKey: String
        public let sendCrashLogsAutomaticallyKey: String
        public let lastSeenCrashLogTimeSince1970Key: String
        public let lastSeenCrashLogMD5Key: String

        public init(
            emailAddressKey: String,
            sendCrashLogsAutomaticallyKey: String,
            lastSeenCrashLogTimeSince1970Key: String,
            lastSeenCrashLogMD5Key: String) {

            self.emailAddressKey = emailAddressKey
            self.sendCrashLogsAutomaticallyKey = sendCrashLogsAutomaticallyKey
            self.lastSeenCrashLogTimeSince1970Key = lastSeenCrashLogTimeSince1970Key
            self.lastSeenCrashLogMD5Key = lastSeenCrashLogMD5Key
        }
    }
}
