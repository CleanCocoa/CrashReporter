//  Copyright © 2020 Christian Tietze. All rights reserved.
//  Distributed under the MIT License.

import XCTest
@testable import CrashReporter

class EmailAddressSettingTests: XCTestCase {

    func testStandardReusesDefaultsKey() {
        XCTAssertEqual(EmailAddressSetting.standard.emailAddressKey,
                       CrashReporter.DefaultsKeys.standard.emailAddressKey)
    }

}
