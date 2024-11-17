//  Part of <https://github.com/brentsimmons/NetNewsWire/>
//
//  Created by Brent Simmons on 12/28/18.
//  Copyright © 2018 Ranchero Software. All rights reserved.
//  Copyright © 2019 Christian Tietze. All rights reserved.
//  Distributed under the MIT License.

import AppKit

protocol SendsCrashLog {
    func send(emailAddress: String?, crashLogText: String)
}

final class CrashReportWindowController: NSWindowController, NSWindowDelegate {

    convenience init(
        appName: String,
        crashLogText: String,
        crashLogSender: SendsCrashLog,
        privacyPolicyURL: URL,
        collectEmailSetting: EmailAddressSetting,
        sendReportsAutomaticallySetting: SendReportsAutomaticallySetting
    ) {
        self.init()

        var nibTopLevelObjects: NSArray?
        CrashReporterBundle.loadNibNamed(
            "CrashReporterWindow", owner: self, topLevelObjects: &nibTopLevelObjects)
        self.window = nibTopLevelObjects?.lazy.compactMap({ $0 as? NSWindow }).first

        self.crashLogText = crashLogText
        self.crashLogSender = crashLogSender
        self.privacyPolicyURL = privacyPolicyURL
        self.collectEmailSetting = collectEmailSetting
        self.sendReportsAutomaticallySetting = sendReportsAutomaticallySetting

        // Setup window
        window?.center()
        window?.delegate = self

        window?.title = "\(appName) Crash Reporter"
        titleLabel.stringValue = "\(appName) quit unexpectedly."
        crashLogContainerView.isHidden = true

        updateCrashLogText()
        updateCollectEmailVisibility()
        updateAutomaticallySendCrashLogVisibility()
        updateButtonStates()

        if let diagnosticsReporterURL = NSWorkspace.shared.urlForApplication(
            withBundleIdentifier: "com.apple.DiagnosticsReporter")
        {
            let diagnosticsReporterIcon = NSWorkspace.shared.icon(
                forFile: diagnosticsReporterURL.path)
            diagnosticsReporterIcon.size = CGSize(width: 64, height: 64)

            warningImageView.image = diagnosticsReporterIcon
        } else {
            warningImageView.imageAlignment = .alignTopRight
        }
    }

    var onWindowWillClose: ((NSWindow?) -> Void)?

    func windowWillClose(_ notification: Notification) {
        onWindowWillClose?(notification.object as? NSWindow)
    }

    // MARK: View components

    @IBOutlet var textView: NSTextView! {
        didSet {
            textView.font = NSFont.userFixedPitchFont(ofSize: 0.0)
            textView.textContainerInset = NSSize(width: 5.0, height: 5.0)
            updateCrashLogText()
        }
    }

    @IBOutlet var warningImageView: NSImageView!
    @IBOutlet var titleLabel: NSTextField!
    @IBOutlet var bodyLabel: NSTextField!

    @IBOutlet weak var collectEmailContainerView: NSView!
    @IBOutlet weak var crashLogContainerView: NSView!
    @IBOutlet weak var sendAutomaticallyContainerView: NSView!

    @IBOutlet var sendCrashLogButton: NSButton!
    @IBOutlet var dontSendButton: NSButton!
    @IBOutlet var toggleCrashLogButton: NSButton!

    private func updateCrashLogText() {
        guard let textView = self.textView else { return }
        textView.string = crashLogText ?? ""
    }

    private func updateButtonStates() {
        sendCrashLogButton?.isEnabled = (crashLogSender != nil) && !didSendCrashLog
        dontSendButton?.isEnabled = !didSendCrashLog
    }

    private func updateCollectEmailVisibility() {
        collectEmailContainerView.isHidden = self.hideCollectEmail
        bodyLabel.stringValue =
            "Help us fix crashes by submitting this crash report."
            + (self.hideCollectEmail
                ? ""
                : " You can include your email address if you agree to being contacted for more details.")
    }

    private func updateAutomaticallySendCrashLogVisibility() {
        sendAutomaticallyContainerView.isHidden = self.hideAutomaticallySend
    }

    // MARK: Model

    internal var collectEmailSetting: EmailAddressSetting = .standard {
        didSet {
            updateCollectEmailVisibility()
        }
    }

    internal var hideCollectEmail: Bool {
        return !collectEmailSetting.isVisible
    }

    internal var sendReportsAutomaticallySetting: SendReportsAutomaticallySetting = .standard {
        didSet {
            updateAutomaticallySendCrashLogVisibility()
        }
    }

    internal var hideAutomaticallySend: Bool {
        return !sendReportsAutomaticallySetting.isVisible
    }

    /// KVC wrapper for `sendReportsAutomaticallySetting.isEnabled`
    @objc dynamic var sendCrashReportsAutomatically: Bool {
        get {
            return sendReportsAutomaticallySetting.isEnabled
        }
        set {
            sendReportsAutomaticallySetting.isEnabled = newValue
        }
    }

    /// KVC wrapper for `collectEmailSetting.emailAddress`
    @objc dynamic var emailAddress: String {
        get {
            return collectEmailSetting.emailAddress ?? ""
        }
        set {
            collectEmailSetting.emailAddress = newValue
        }
    }

    internal var privacyPolicyURL: URL?

    internal var crashLogText: String? {
        didSet {
            updateCrashLogText()
        }
    }

    internal var crashLogSender: SendsCrashLog? {
        didSet {
            updateButtonStates()
        }
    }

    private var didSendCrashLog = false {
        didSet {
            updateButtonStates()
        }
    }

    // MARK: - User Interactions

    lazy var isRunningTests: Bool = false

    @IBAction func sendCrashReport(_ sender: Any?) {
        guard !didSendCrashLog else { return }
        defer { didSendCrashLog = true }

        if !isRunningTests,
            let crashLogText = self.crashLogText,
            let crashLogSender = self.crashLogSender
        {

            let emailAddress = self.collectEmailSetting.isVisible ? self.emailAddress : nil
            crashLogSender.send(emailAddress: emailAddress, crashLogText: crashLogText)
        }

        close()
    }

    @IBAction func dontSendCrashReport(_ sender: Any?) {
        close()
    }

    override func responds(to aSelector: Selector!) -> Bool {
        if aSelector == #selector(showPrivacyPolicy(_:)) {
            return self.privacyPolicyURL != nil
        }
        return super.responds(to: aSelector)
    }

    @IBAction func showPrivacyPolicy(_ sender: Any?) {
        guard let privacyPolicyURL = self.privacyPolicyURL else { return }
        NSWorkspace.shared.open(privacyPolicyURL)
    }

    @IBAction func toggleCrashLog(_ sender: Any?) {
        crashLogContainerView.isHidden = !crashLogContainerView.isHidden
        toggleCrashLogButton.title =
            crashLogContainerView.isHidden ? "Show Details" : "Hide Details"
    }
}
