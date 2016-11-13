//
//  GameViewController.swift
//  TouchBarSpaceFight
//
//  Created by Guilherme Rambo on 09/11/16.
//  Copyright © 2016 Guilherme Rambo. All rights reserved.
//

import Cocoa
import SpriteKit

extension Notification.Name {
    static let GameStateDidChange = Notification.Name(rawValue: "TouchBarSpaceFightStateDidChange")
}

extension GameModels.Scene {
    
    var instance: SKScene? {
        switch self {
        case .main: return GameScene(fileNamed: rawValue)
        default: return nil
        }
    }
    
}

class GameViewController: NSViewController, GameSceneDelegate {
    
    var state: GameModels.GameState = GameModels.GameState() {
        didSet {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .GameStateDidChange, object: self.state)
            }
        }
    }
    
    private lazy var gameView: SKView = {
        let v = SKView(frame: self.view.bounds)
        v.autoresizingMask = [.viewWidthSizable, .viewHeightSizable]
        
        return v
    }()
    
    init() {
        super.init(nibName: nil, bundle: nil)!
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        view = NSView()
        view.addSubview(gameView)
    }
    
    private var wasPausedWhenAppResignedActive = false
    
    override func viewDidLayout() {
        super.viewDidLayout()
        
        gameView.frame = view.bounds
        
        NotificationCenter.default.addObserver(forName: .GameOver, object: nil, queue: nil) { [weak self] _ in
            self?.gameView.isPaused = true
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(forName: .DidPauseGame, object: nil, queue: nil) { [weak self] _ in
            self?.gameView.isPaused = true
        }
        NotificationCenter.default.addObserver(forName: .DidContinueGame, object: nil, queue: nil) { [weak self] _ in
            self?.gameView.isPaused = false
        }
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        if gameView.scene == nil {
            showGameScene()
        }
    }
    
    func showGameScene() {
        let scene = GameModels.Scene.main.instance as! GameScene
        scene.gameDelegate = self
        gameView.presentScene(scene)
    }
    
    func didReceive(event: NSEvent) {
        guard let eventHandler = gameView.scene as? EventHandler else { return }
        
        guard let key = GameModels.Key(rawValue: Int(event.keyCode)) else { return }
        
        switch event.type {
        case .keyUp:
            eventHandler.key(event: .up(key))
        case .keyDown:
            eventHandler.key(event: .down(key))
        default: break
        }
    }
    
    func reset() {
        gameView.presentScene(nil)
        state = GameModels.GameState()
        showGameScene()
    }
    
}
