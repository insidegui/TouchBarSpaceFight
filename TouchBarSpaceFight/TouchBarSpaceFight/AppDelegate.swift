//
//  AppDelegate.swift
//  TouchBarSpaceFight
//
//  Created by Guilherme Rambo on 09/11/16.
//  Copyright © 2016 Guilherme Rambo. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    fileprivate var gameViewController: GameViewController!
    
    fileprivate var screenViewController: ScreenViewController!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        screenViewController = NSApp.windows.first!.contentViewController as! ScreenViewController
        
        NotificationCenter.default.addObserver(forName: .RestartGame, object: nil, queue: nil) { _ in
            self.gameViewController.reset()
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    fileprivate var window: GameWindow? {
        return NSApp.mainWindow as? GameWindow
    }

}

@available(OSX 10.12.1, *)
extension NSTouchBarItemIdentifier {
    static let gameViewController = NSTouchBarItemIdentifier("br.com.guilhermerambo.touchasteroids")
}

@available(OSX 10.12.2, *)
extension AppDelegate: NSTouchBarDelegate, NSTouchBarProvider {
    
    var touchBar: NSTouchBar? {
        let bar = NSTouchBar()
        
        bar.delegate = self
        bar.defaultItemIdentifiers = [.gameViewController]
        
        return bar
    }
    
    func touchBar(_ touchBar: NSTouchBar, makeItemForIdentifier identifier: NSTouchBarItemIdentifier) -> NSTouchBarItem? {
        switch identifier {
        case NSTouchBarItemIdentifier.gameViewController:
            let item = NSCustomTouchBarItem(identifier: .gameViewController)
            
            if gameViewController == nil {
                gameViewController = GameViewController()
            }
            
            item.viewController = gameViewController
            window?.didReceiveEvent = gameViewController.didReceive
            
            return item
        default: return nil
        }
    }
    
}
