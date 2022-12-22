//  Part of <https://github.com/brentsimmons/NetNewsWire/>
//
//  Created by Brent Simmons on 12/17/18.
//  Copyright © 2018 Ranchero Software. All rights reserved.
//  Copyright © 2019 Christian Tietze. All rights reserved.
//  Distributed under the MIT License.

import Foundation

public final class CrashReporter {

    public let crashReporterURL: URL
    public let privacyPolicyURL: URL
    public let userDefaults: UserDefaults
    public let defaultsKeys: DefaultsKeys

    /// Convenience accessor for `sendCrashLogsAutomaticallyKey` defaults.
    ///
    /// Can be wrapped for KVC/Cocoa bindings in your preference panes when you access it through
    /// a property wrapping it as a `@objc dynamic var`:
    ///
    ///     let var crashReporter = // ...
    ///     
    ///     @objc dynamic var sendCrashReportsAutomatically: Bool {
    ///         get {
    ///             return crashReporter.sendCrashReportsAutomatically
    ///         }
    ///         set {
    ///             crashReporter.sendCrashReportsAutomatically = newValue
    ///         }
    ///     }
    ///
    public var sendCrashReportsAutomatically: Bool {
        get {
            return userDefaults.bool(forKey: defaultsKeys.sendCrashLogsAutomaticallyKey)
        }
        set {
            userDefaults.set(newValue, forKey: defaultsKeys.sendCrashLogsAutomaticallyKey)
        }
    }

    /// - param crashReporterURL: Server endpoint to send the crash log to.
    /// - param privacyPolicyURL: Web address that points to your privacy policy with details on how you handle crash log data.
    /// - param userDefaults: `UserDefaults` to store the last crash info in. Useful for defaults in app groups. Default is `UserDefaults.standard`.
    /// - param defaultsKeys: Configuration of the defaults keys to use. Default is `DefaultsKeys.standard`.
    public init(
        crashReporterURL: URL,
        privacyPolicyURL: URL,
        userDefaults: UserDefaults = .standard,
        defaultsKeys: DefaultsKeys = DefaultsKeys.standard) {
        self.crashReporterURL = crashReporterURL
        self.privacyPolicyURL = privacyPolicyURL
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
    internal lazy var crashReportFolderURL: URL = self.fileManager.diagnosticsReportsFolderURL

    /// Testing seam.
    internal var fileManager: FileManager {
        return .default
    }

    // MARK: - Check for crashes

    /// Look in ~/Library/Logs/DiagnosticReports/ for a new crash log for this app.
    ///
    /// Checks for crashes using the `CFBundleName` from the main app bundle as `appName`.
    ///
    /// - Parameters:
    ///   - collectEmailAddress: Ask users for their email addresses when sending in reports. Default is true.
    ///   - alwaysShowCrashReporterWindow: Overrides the user setting `shouldSendCrashLogsAutomaticallyKey`. Default is false.
    ///   - displayCrashReporterWindowAsModal: Whether to show the window on top of other app windows. Default is false.
    /// - Note: When `collectEmailAddress` is disabled, you will not even get previously stored value from user defaults.
    public func check(collectEmailAddress: Bool = true,
                      alwaysShowCrashReporterWindow: Bool = false,
                      displayCrashReporterWindowAsModal: Bool = false) {
        self.check(
            appName: Bundle.main.infos[.bundleName]!,
            collectEmailAddress: collectEmailAddress,
            alwaysShowCrashReporterWindow: alwaysShowCrashReporterWindow,
            displayCrashReporterWindowAsModal: displayCrashReporterWindowAsModal)
    }

    /// Look in ~/Library/Logs/DiagnosticReports/ for a new crash log for `appName`.
    ///
    /// If a new crash log was found, show the reporter window or automatically
    /// upload the report, depending on the `shouldSendCrashLogsAutomaticallyKey`.
    /// Set `alwaysShowCrashReporterWindow` to override this behavior.
    ///
    /// - Parameters:
    ///   - appName: Name of the application to search recent crash reports for.
    ///   - collectEmailAddress: Ask users for their email addresses when sending in reports. Default is true.
    ///   - alwaysShowCrashReporterWindow: Overrides the user setting `shouldSendCrashLogsAutomaticallyKey`. Default is false.
    ///   - displayCrashReporterWindowAsModal: Whether to show the window on top of other app windows. Default is false.
    /// - Note: When `collectEmailAddress` is disabled, you will not even get previously stored value from user defaults.
    public func check(appName: String,
                      collectEmailAddress: Bool = true,
                      alwaysShowCrashReporterWindow: Bool = false,
                      displayCrashReporterWindowAsModal: Bool = false) {
        guard let crashLog = mostRecentCrashInfo(appName: appName)?.crashLog() else { return }

//        if hasSeen(crashLog) {
//            return
//        }
//        remember(crashLog)

        if shouldSendCrashLogsAutomatically && alwaysShowCrashReporterWindow == false {
            let emailSetting = EmailAddressSetting(isVisible: false, userDefaults: self.userDefaults, emailAddressKey: self.defaultsKeys.emailAddressKey)
            let emailAddress = collectEmailAddress ? emailSetting.emailAddress : nil
            send(emailAddress: emailAddress, crashLogText: crashLog.content)
        } else {
            runCrashReporterWindow(
                crashLog: crashLog,
                displayAsModal: displayCrashReporterWindowAsModal,
                hideEmailCollection: !collectEmailAddress,
                hideSendReportsAutomaticallyOption: alwaysShowCrashReporterWindow)
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

    internal var crashReportWindowController: CrashReportWindowController?

    internal func runCrashReporterWindow(
        crashLog: CrashLog,
        displayAsModal: Bool,
        hideEmailCollection: Bool,
        hideSendReportsAutomaticallyOption: Bool) {
        let collectEmailSetting = EmailAddressSetting(
            isVisible: !hideEmailCollection,
            userDefaults: self.userDefaults,
            emailAddressKey: self.defaultsKeys.emailAddressKey)
        let sendAutomaticallySetting = SendReportsAutomaticallySetting(
            isVisible: !hideSendReportsAutomaticallyOption,
            userDefaults: self.userDefaults,
            sendCrashLogsAutomaticallyKey: self.defaultsKeys.sendCrashLogsAutomaticallyKey)

        self.crashReportWindowController = CrashReportWindowController(
            crashLogText: crashLog.content,
            // Produces a retain cycle that we'll break when the window closes:
            crashLogSender: self,
            privacyPolicyURL: self.privacyPolicyURL,
            collectEmailSetting: collectEmailSetting,
            sendReportsAutomaticallySetting: sendAutomaticallySetting)

        // Drop reference to window after closing to eventually free memory.
        // Call this before potentially making the window run in a modal loop.
        self.crashReportWindowController?.onWindowWillClose = { [unowned self] _ in
            if displayAsModal {
                NSApp.stopModal()
            }
            self.crashReportWindowController = nil
        }

        self.crashReportWindowController?.showWindow(self)
        self.crashReportWindowController?.window?.makeKeyAndOrderFront(self)

        if displayAsModal,
            let window = self.crashReportWindowController?.window {
            NSApp.runModal(for: window)
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

// MARK: - SendsCrashLog

extension CrashReporter: SendsCrashLog {
    internal func send(emailAddress: String?, crashLogText: String) {
        var request = URLRequest(url: self.crashReporterURL)
        request.httpMethod = "POST"

        let boundary = UUID().uuidString.md5

        let contentType = "multipart/form-data; boundary=\(boundary)"
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")

        let form: [String : String?] = [
            "userEmail" : nil,
            "crashlog" : crashLogText
        ]
        // See <https://www.w3.org/TR/html401/interact/forms.html#h-17.13.4> for a specification.
        // Example:
        //    Content-Type: multipart/form-data; boundary=AaB03x
        //
        //    --AaB03x
        //    Content-Disposition: form-data; name="submit-name"
        //
        //    Larry
        //    --AaB03x
        //    Content-Disposition: form-data; name="files"; filename="file1.txt"
        //    Content-Type: text/plain
        //
        //    ... contents of file1.txt ...
        //    --AaB03x--
        let CRLF = "\r\n"
        let separator = "--\(boundary)" + CRLF
        let terminator = "--\(boundary)--" + CRLF
        let formString =
            separator
            + form.compactMap { key, value -> String? in
                guard let value = value, !value.isEmpty else { return nil }
                let lines = [
                    "Content-Disposition: form-data; name=\"\(key)\"",
                    "", // Key and value are separated by an empty line
                    value
                ]
                return lines.joined(separator: "\r\n") + CRLF
            }.joined(separator: separator) + CRLF
            + terminator
        let formData = formString.data(using: .utf8, allowLossyConversion: true)
        request.httpBody = formData

        download(request) { (data, response, error) in
            // Ignore result of the upload.
            // Uncomment to debug the server response:
            //print(response, data.flatMap { String(data: $0, encoding: .utf8) })
            return
        }
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

    fileprivate var diagnosticsReportsFolderURL: URL {
        let homeDirectory: URL

        if #available(OSX 10.12, *) {
            homeDirectory = self.homeDirectoryForCurrentUser
        } else {
            homeDirectory = URL(fileURLWithPath: ("~" as NSString).expandingTildeInPath)
        }

        return homeDirectory
            .appendingPathComponent("Library")
            .appendingPathComponent("Logs")
            .appendingPathComponent("DiagnosticReports")
    }
}

fileprivate func newerThan(_ referenceDate: Date) -> (_ crashInfo: CrashInfo) -> Bool {
    return { crashInfo in
        crashInfo.date > referenceDate
    }
}

fileprivate func matches(appName: String) -> (_ url: URL) -> Bool {
    let lowerAppName = appName.lowercased()

    var crashSuffixes: [String] = [".crash"]
    if #available(macOS 12, *) {
        crashSuffixes.append(".ips")
    }

    return { url in
        let filename = url.lastPathComponent
        return filename.lowercased().hasPrefix(lowerAppName)
            && crashSuffixes.contains { filename.hasSuffix($0) }
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
