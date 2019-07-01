//  Part of <https://github.com/brentsimmons/NetNewsWire/>
//
//  Created by Brent Simmons on 12/17/18.
//  Copyright © 2018 Ranchero Software. All rights reserved.
//  Copyright © 2019 Christian Tietze. All rights reserved.
//  Distributed under the MIT License.

import Foundation

public final class CrashReporter: SendsCrashLog {

    /// Definition of the UserDefaults keys to use.
    public struct DefaultsKeys {
        public static var standard: DefaultsKeys {
            return DefaultsKeys(
                sendCrashLogsAutomaticallyKey: "CRR_sendCrashLogsAutomatically",
                lastSeenCrashLogTimeSince1970Key: "CRR_lastSeenCrashLogTimeSince1970",
                lastSeenCrashLogMD5Key: "CRR_lastSeenCrashLogMD5")
        }

        public let sendCrashLogsAutomaticallyKey: String
        public let lastSeenCrashLogTimeSince1970Key: String
        public let lastSeenCrashLogMD5Key: String

        public init(
            sendCrashLogsAutomaticallyKey: String,
            lastSeenCrashLogTimeSince1970Key: String,
            lastSeenCrashLogMD5Key: String) {

            self.sendCrashLogsAutomaticallyKey = sendCrashLogsAutomaticallyKey
            self.lastSeenCrashLogTimeSince1970Key = lastSeenCrashLogTimeSince1970Key
            self.lastSeenCrashLogMD5Key = lastSeenCrashLogMD5Key
        }
    }

    public let crashReporterURL: URL
    public let userDefaults: UserDefaults
    public let defaultsKeys: DefaultsKeys

    /// - param crashReporterURL: Server endpoint to send the crash log to.
    /// - param userDefaults: `UserDefaults` to store the last crash info in. Useful for defaults in app groups. Default is `UserDefaults.standard`.
    /// - param defaultsKeys: Configuration of the defaults keys to use. Default is `DefaultsKeys.standard`.
    public init(
        crashReporterURL: URL,
        userDefaults: UserDefaults = .standard,
        defaultsKeys: DefaultsKeys = DefaultsKeys.standard) {
        self.crashReporterURL = crashReporterURL
        self.userDefaults = userDefaults
        self.defaultsKeys = defaultsKeys
    }

    // MARK: - Testing seams

    /// Testing seam reading the `lastSeenCrashLogTimeSince1970Key` from user defaults.
    internal var lastSeenCrashLogDate: Date {
        return Date(timeIntervalSince1970: userDefaults.double(forKey: defaultsKeys.lastSeenCrashLogTimeSince1970Key))
    }

    /// Testing seam reading the `sendCrashLogsAutomaticallyKey` from user defaults.
    internal var shouldSendCrashLogsAutomatically: Bool {
        return userDefaults.bool(forKey: defaultsKeys.sendCrashLogsAutomaticallyKey)
    }

    /// Testing seam reading the `lastSeenCrashLogMD5Key` from user defaults.
    internal var lastSeenCrashLogMD5Hash: String? {
        return userDefaults.string(forKey: defaultsKeys.lastSeenCrashLogMD5Key)
    }

    /// Testing seam and configuration option to fetch reports.
    /// Default is `"~/Library/Logs/DiagnosticReports/"`
    internal lazy var crashReportFolderURL: URL = self.fileManager
        .homeDirectoryForCurrentUser
        .appendingPathComponent("Library")
        .appendingPathComponent("Logs")
        .appendingPathComponent("DiagnosticReports")

    /// Testing seam.
    internal var fileManager: FileManager {
        return .default
    }

    // MARK: - Check for crashes

    /// Checks for crashes using the `CFBundleName` from the main app bundle as `appName`.
    public func check() {
        self.check(appName: Bundle.main.infos[.bundleName]!)
    }

    /// Look in ~/Library/Logs/DiagnosticReports/ for a new crash log for this app.
    /// Show a crash log reporter window if .
    public func check(appName: String) {
        guard let crashLog = mostRecentCrashInfo(appName: appName)?.crashLog()
            else { return }

        if hasSeen(crashLog) {
            return
        }
        remember(crashLog)

        if shouldSendCrashLogsAutomatically {
            send(crashLogText: crashLog.content)
        } else {
            runCrashReporterWindow(crashLog)
        }
    }

    internal func mostRecentCrashInfo(appName: String) -> CrashInfo? {
        guard let fileURLs = try? allCrashReportFolderFiles() else { return nil }

        let relevantCrashInfos: [CrashInfo] = fileURLs
            .filter(matches(appName: appName))
            .compactMap { CrashInfo(url: $0, fileManager: fileManager) }
            .filter(newerThan(lastSeenCrashLogDate))

        return findMostRecent(crashInfos: relevantCrashInfos)
    }

    internal func allCrashReportFolderFiles() throws -> [URL] {
        return try fileManager.contentsOfDirectory(
            at: crashReportFolderURL,
            includingPropertiesForKeys: nil,
            options: [])
    }

    internal func send(crashLogText: String) {
        var request = URLRequest(url: crashReporterURL)
        request.httpMethod = "POST"

        let boundary = UUID().uuidString.md5

        let contentType = "multipart/form-data; boundary=\(boundary)"
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")

        let formString = "--\(boundary)\r\nContent-Disposition: form-data; name=\"crashlog\"\r\n\r\n\(crashLogText)\r\n--\(boundary)--\r\n"
        let formData = formString.data(using: .utf8, allowLossyConversion: true)
        request.httpBody = formData

        download(request) { (data, result, error) in
            print(data.flatMap { String(data: $0, encoding: .utf8) })
            // Ignore result of the upload.
            return
        }
    }

    internal var crashReportWindowController: CrashReportWindowController?

    internal func runCrashReporterWindow(_ crashLog: CrashLog) {
        self.crashReportWindowController = CrashReportWindowController(
            crashLogText: crashLog.content,
            crashLogSender: self)
        self.crashReportWindowController?.showWindow(self)
        self.crashReportWindowController?.window?.makeKeyAndOrderFront(self)

        // Drop reference to window after closing to eventually free memory.
        self.crashReportWindowController?.onWindowWillClose = { [unowned self] _ in
            self.crashReportWindowController = nil
        }
    }

    internal func hasSeen(_ crashLog: CrashLog) -> Bool {
        // No need to compare dates, because that's done in the file loop.
        // Check to see if we've already reported this exact crash log.
        return crashLog.contentHash == self.lastSeenCrashLogMD5Hash
    }

    internal func remember(_ crashLog: CrashLog) {
        userDefaults.set(crashLog.contentHash, forKey: defaultsKeys.lastSeenCrashLogMD5Key)
        userDefaults.set(crashLog.modificationDate.timeIntervalSince1970, forKey: defaultsKeys.lastSeenCrashLogTimeSince1970Key)
    }
}


// MARK: - Crash report file metadata

internal struct CrashInfo {
    let url: URL
    let date: Date

    init(url: URL, date: Date) {
        self.url = url
        self.date = date
    }

    func crashLog() -> CrashLog? {
        return CrashLog(url: url, modificationDate: date)
    }
}

extension CrashInfo {
    init?(url: URL, fileManager: FileManager) {
        self.init(
            url: url,
            getModificationDate: fileManager.fileModificationDate(url:))
    }

    init?(url: URL, getModificationDate: (URL) -> Date? = FileManager.default.fileModificationDate(url:)) {
        guard let modificationDate = getModificationDate(url) else { return nil}
        self.init(url: url, date: modificationDate)
    }
}

extension FileManager {
    fileprivate func fileModificationDate(url: URL) -> Date? {
        let fileAttributes: [FileAttributeKey: Any] = (try? self.attributesOfItem(atPath: url.path)) ?? [:]
        return fileAttributes[.modificationDate] as? Date
    }
}

fileprivate func newerThan(_ referenceDate: Date) -> (_ crashInfo: CrashInfo) -> Bool {
    return { crashInfo in
        crashInfo.date > referenceDate
    }
}

fileprivate func matches(appName: String, crashSuffix: String = ".crash") -> (_ url: URL) -> Bool {
    let lowerAppName = appName.lowercased()
    return { url in
        let filename = url.lastPathComponent
        return filename.lowercased().hasPrefix(lowerAppName)
            && filename.hasSuffix(crashSuffix)
    }
}

fileprivate func findMostRecent(crashInfos: [CrashInfo]) -> CrashInfo? {
    // Pairwise comparison; returns the most recent of the two.
    func moreRecent(_ lhs: CrashInfo?, _ rhs: CrashInfo) -> CrashInfo {
        guard let lhs = lhs else {
            return rhs
        }
        if lhs.date > rhs.date {
            return lhs
        }
        return rhs
    }

    return crashInfos.reduce(nil) { (mostRecent: CrashInfo?, next: CrashInfo) -> CrashInfo? in
        return moreRecent(mostRecent, next)
    }
}
