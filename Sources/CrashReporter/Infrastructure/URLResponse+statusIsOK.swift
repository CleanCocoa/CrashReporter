//  Part of <https://github.com/brentsimmons/RSWeb/>
//
//  Created by Brent Simmons on 8/14/16.
//  Copyright © 2016 Ranchero Software, LLC. All rights reserved.
//  Copyright © 2019 Christian Tietze. All rights reserved.
//  Distributed under the MIT License.

import class Foundation.URLResponse
import class Foundation.HTTPURLResponse

extension URLResponse {
    internal var statusIsOK: Bool {
        guard let response = self as? HTTPURLResponse else { return false }
        return (200...299).contains(response.statusCode)
    }
}
