//  Copyright © 2020 Christian Tietze. All rights reserved.
// Distributed under the MIT License.

struct EmailAddressSetting {
    static var standard: EmailAddressSetting {
        return EmailAddressSetting(
            isVisible: true,
            userDefaults: .standard,
            emailAddressKey: CrashReporter.DefaultsKeys.standard.emailAddressKey)
    }

    let isVisible: Bool
    
    let userDefaults: UserDefaults
    let emailAddressKey: String

    var emailAddress: String? {
        get {
            return userDefaults.string(forKey: emailAddressKey)
        }
        set {
            userDefaults.set(newValue, forKey: emailAddressKey)
        }
    }
}
