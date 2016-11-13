//
//  ScreenViewController.swift
//  TouchBarSpaceFight
//
//  Created by Guilherme Rambo on 09/11/16.
//  Copyright © 2016 Guilherme Rambo. All rights reserved.
//

import Cocoa

extension Notification.Name {
    static let DidPauseGame = Notification.Name(rawValue: "TouchBarSpaceFightDidPause")
    static let DidContinueGame = Notification.Name(rawValue: "TouchBarSpaceFightDidContinue")
    static let RestartGame = Notification.Name(rawValue: "TouchBarSpaceFightRestartGame")
}

class ScreenViewController: NSViewController {
    
    var isGameOver = false {
        didSet {
            if isGameOver != oldValue {
                if isGameOver {
                    pauseButton.title = "Game Over (Click to Try Again)"
                } else {
                    pauseButton.title = "Pause"
                }
            }
        }
    }
    
    var isPaused = false {
        didSet {
            if isPaused != oldValue {
                if isPaused {
                    pauseButton.title = "Continue"
                    NotificationCenter.default.post(name: .DidPauseGame, object: nil)
                } else {
                    pauseButton.title = "Pause"
                    NotificationCenter.default.post(name: .DidContinueGame, object: nil)
                }
            }
        }
    }
    
    @IBOutlet weak var livesLabel: NSTextField!
    @IBOutlet weak var hitsLabel: NSTextField!
    @IBOutlet weak var destroyedLabel: NSTextField!
    @IBOutlet weak var lostLabel: NSTextField!
    @IBOutlet weak var shotsWastedLabel: NSTextField!
    @IBOutlet weak var pauseButton: NSButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(forName: .GameStateDidChange, object: nil, queue: nil) { [weak self] note in
            guard let state = note.object as? GameModels.GameState else { return }
            self?.stateDidChange(to: state)
        }
        NotificationCenter.default.addObserver(forName: .GameOver, object: nil, queue: nil) { [weak self] _ in
            self?.isGameOver = true
        }
    }
    
    func stateDidChange(to state: GameModels.GameState) {
        livesLabel.stringValue = "\(state.score.lives)"
        hitsLabel.stringValue = "\(state.score.numberOfHits)"
        destroyedLabel.stringValue = "\(state.score.destroyedEnemies)"
        lostLabel.stringValue = "\(state.score.escapedEnemies)"
        shotsWastedLabel.stringValue = "\(state.score.wastedShots)"
    }
    
    @IBAction func pause(_ sender: Any) {
        if isGameOver {
            NotificationCenter.default.post(name: .RestartGame, object: nil)
            isGameOver = false
        } else {
            isPaused = !isPaused
        }
    }
    
}
