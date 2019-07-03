//  Copyright © 2019 Christian Tietze. All rights reserved.
//  Distributed under the MIT License.

import Foundation
import CommonCrypto

// For iOS 13 and macOS 10.15, we can eventually switch to CryptoKit:
// https://developer.apple.com/documentation/cryptokit

extension String {
    /// Computes a MD5 hash from the recipient.
    /// Implementation based on <https://stackoverflow.com/a/32166735/1460929>
    internal var md5: String {
        let length = Int(CC_MD5_DIGEST_LENGTH)
        let messageData = self.data(using: .utf8)!
        var digestData = Data(count: length)

        digestData.withUnsafeMutableBytes { digestBytes -> Void in
            messageData.withUnsafeBytes { messageBytes -> Void in
                guard let messageBytesBaseAddress = messageBytes.baseAddress else { return }
                guard let digestBytesBlindMemory = digestBytes.bindMemory(to: UInt8.self).baseAddress else { return }
                let messageLength = CC_LONG(messageData.count)
                CC_MD5(messageBytesBaseAddress, messageLength, digestBytesBlindMemory)
            }
        }

        return digestData.map { String(format: "%02hhx", $0) }.joined()
    }
}
