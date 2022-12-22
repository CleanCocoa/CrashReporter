//  Copyright © 2022 Christian Tietze. All rights reserved. Distributed under the MIT License.

import Cocoa

class NoClippingLayer: CALayer {
    override var masksToBounds: Bool {
        set {}
        get {
            return false
        }
    }
}

class NoClippingView: NSView {
    override var wantsDefaultClipping: Bool {
        return false
    }

    override func makeBackingLayer() -> CALayer {
        return NoClippingLayer()
    }
}
