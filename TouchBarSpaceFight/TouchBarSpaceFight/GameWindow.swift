//
//  GameWindow.swift
//  TouchBarSpaceFight
//
//  Created by Guilherme Rambo on 09/11/16.
//  Copyright © 2016 Guilherme Rambo. All rights reserved.
//

import Cocoa

class GameWindow: NSWindow {

    var didReceiveEvent: ((NSEvent) -> Void)?
    
    override func keyDown(with event: NSEvent) {
        didReceiveEvent?(event)
    }
    
    override func keyUp(with event: NSEvent) {
        didReceiveEvent?(event)
    }
    
}
