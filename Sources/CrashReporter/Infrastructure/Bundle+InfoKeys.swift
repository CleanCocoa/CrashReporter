//  Copyright © 2017 Christian Tietze. All rights reserved.
//  Distributed under the MIT License.

import Foundation

internal struct InfoPlistKey: RawRepresentable {
    internal var rawValue: String

    internal init(rawValue: String) {
        self.rawValue = rawValue
    }

    internal static let build = InfoPlistKey(rawValue: "CFBundleVersion")
    internal static let version = InfoPlistKey(rawValue: "CFBundleShortVersionString")

    internal static let bundleName = InfoPlistKey(rawValue: "CFBundleName")
    internal static let bundleIdentifier = InfoPlistKey(rawValue: "CFBundleIdentifier")
}

extension Bundle {
    internal var infos: Infos {
        return Infos(dictionary: infoDictionary)
    }

    internal struct Infos {
        let dictionary: [String : Any]?
        internal subscript(_ key: InfoPlistKey) -> String? {
            return dictionary?[key.rawValue] as? String
        }
    }
}
