//  Part of <https://github.com/brentsimmons/NetNewsWire/>
//
//  Created by Brent Simmons on 12/28/18.
//  Copyright © 2018 Ranchero Software. All rights reserved.
//  Copyright © 2019 Christian Tietze. All rights reserved.
//  Distributed under the MIT License.

import AppKit

protocol SendsCrashLog {
    func send(crashLogText: String)
}

final class CrashReportWindowController: NSWindowController, NSWindowDelegate {

    convenience init(
        crashLogText: String,
        crashLogSender: SendsCrashLog,
        privacyPolicyURL: URL) {

        self.init(windowNibName: "CrashReporterWindow")

        self.crashLogText = crashLogText
        self.crashLogSender = crashLogSender
        self.privacyPolicyURL = privacyPolicyURL
    }

    override func windowDidLoad() {
        super.windowDidLoad()
        window?.center()
        window?.delegate = self
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

	@IBOutlet var sendCrashLogButton: NSButton!
	@IBOutlet var dontSendButton: NSButton!

    private func updateCrashLogText() {
        guard let textView = self.textView else { return }
        textView.string = crashLogText ?? ""
    }

    private func updateButtonStates() {
        sendCrashLogButton.isEnabled = (crashLogSender != nil) && !didSendCrashLog
        dontSendButton.isEnabled = !didSendCrashLog
    }

    // MARK: Model

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

		if  !isRunningTests,
            let crashLogText = self.crashLogText,
            let crashLogSender = self.crashLogSender {

            crashLogSender.send(crashLogText: crashLogText)
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
}

