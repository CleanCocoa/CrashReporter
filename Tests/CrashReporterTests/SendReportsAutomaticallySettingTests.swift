//  Copyright © 2019 Christian Tietze. All rights reserved.
//  Distributed under the MIT License.

import XCTest
@testable import CrashReporter

class SendReportsAutomaticallySettingTests: XCTestCase {

    func testStandardReusesDefaultsKey() {
        XCTAssertEqual(SendReportsAutomaticallySetting.standard.sendCrashLogsAutomaticallyKey,
                       DefaultsKeys.standard.sendCrashLogsAutomaticallyKey)
    }

}
