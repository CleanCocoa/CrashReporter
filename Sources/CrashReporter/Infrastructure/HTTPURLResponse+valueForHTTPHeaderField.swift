//  Part of <https://github.com/brentsimmons/RSWeb/>
//
//  Created by Brent Simmons on 8/14/16.
//  Copyright © 2016 Ranchero Software, LLC. All rights reserved.
//  Copyright © 2019 Christian Tietze. All rights reserved.
//  Distributed under the MIT License.

import class Foundation.HTTPURLResponse

extension HTTPURLResponse {
    /// Case-insensitive. HTTP headers may not be in the case you expect.
    internal func valueForHTTPHeaderField(_ headerField: String) -> String? {
        let lowerHeaderField = headerField.lowercased()

        for (key, value) in allHeaderFields {
            if lowerHeaderField == (key as? String)?.lowercased() {
                return value as? String
            }
        }

        return nil
    }
}
