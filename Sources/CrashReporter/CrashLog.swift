//  Part of <https://github.com/brentsimmons/NetNewsWire/>
//
//  Created by Brent Simmons on 12/17/18.
//  Copyright © 2018 Ranchero Software. All rights reserved.
//  Copyright © 2019 Christian Tietze. All rights reserved.
//  Distributed under the MIT License.

import struct Foundation.Date
import class Foundation.NSString

struct CrashLog {
    let url: URL
    let modificationDate: Date
    let content: String
    let contentHash: String

    init(url: URL, modificationDate: Date, content: String, contentHash: String) {
        self.url = url
        self.modificationDate = modificationDate
        self.content = content
        self.contentHash = contentHash
    }
}

extension CrashLog {
    init?(url: URL, modificationDate: Date) {
        guard let contents = try? String(contentsOf: url) else { return nil }
        guard !contents.isEmpty else { return nil }

        self.init(
            url: url,
            modificationDate: modificationDate,
            content: contents,
            contentHash: contents.md5)
    }
}
