//  Copyright © 2017 Christian Tietze. All rights reserved.
//  Distributed under the MIT License.

import Foundation

public struct InfoPlistKey: RawRepresentable {
    public var rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static let build = InfoPlistKey(rawValue: "CFBundleVersion")
    public static let version = InfoPlistKey(rawValue: "CFBundleShortVersionString")

    public static let bundleName = InfoPlistKey(rawValue: "CFBundleName")
    public static let bundleIdentifier = InfoPlistKey(rawValue: "CFBundleIdentifier")
}

extension Bundle {
    public var infos: Infos {
        return Infos(dictionary: infoDictionary)
    }

    public struct Infos {
        let dictionary: [String : Any]?
        public subscript(_ key: InfoPlistKey) -> String? {
            return dictionary?[key.rawValue] as? String
        }
    }
}
