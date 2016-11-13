//
//  GameModels.swift
//  TouchBarSpaceFight
//
//  Created by Guilherme Rambo on 09/11/16.
//  Copyright © 2016 Guilherme Rambo. All rights reserved.
//

import Cocoa

struct GameModels {
    
    struct Score {
        var numberOfHits = 0
        var escapedEnemies = 0
        var destroyedEnemies = 0
        var wastedShots = 0
        var lives = 3
    }
    
    struct GameState {
        var score = Score()
        
        var enemySpawnInterval: CGFloat = 1.0
        var maxEnemySpeed: CGFloat = 2
        
        var lastShotTime: TimeInterval = 0
        var maxShotSpeed: CGFloat = 2
        var maxShotRate: TimeInterval = 0.15
        var maxShotsPerEnemy = 2
        
        var maxDifficultyIncreaseCount = 10
        var difficultyIncreaseCount = 0
        var difficultyIncreaseRate: TimeInterval = 15.0
        var enemySpeedIncreaseRate: CGFloat = 0.15
        var enemySpawnIntervalIncreaseRate: CGFloat = 0.15
        
        var playerSpeed = CGVector(dx: 3, dy: 1.5)
        
        var isHit = false
        var hitTime = TimeInterval(0)
        var hitDuration = TimeInterval(3.0)
        
        var lifeSpawnRate = TimeInterval(15)
        var maxLifeSpeed: CGFloat = 4
    }
    
    struct PhysicsCategory {
        static let none: UInt32 = 0
        static let all: UInt32 = UInt32.max
        static let enemy: UInt32 = 0b1
        static let shot: UInt32 = 0b10
        static let player: UInt32 = 0b100
        static let life: UInt32 = 0b1000
    }
    
    enum Scene: String {
        case menu = "Menu"
        case main = "Game"
        case gameOver = "GameOver"
    }
    
    enum Sprite: String {
        case player
        case enemy
        case shot
        case life
    }
    
    enum Key: Int, CustomDebugStringConvertible {
        case arrowUp = 126
        case arrowDown = 125
        case arrowLeft = 123
        case arrowRight = 124
        case space = 49
        
        var debugDescription: String {
            switch self {
            case .arrowUp: return "UP ARROW"
            case .arrowDown: return "DOWN ARROW"
            case .arrowLeft: return "LEFT ARROW"
            case .arrowRight: return "RIGHT ARROW"
            case .space: return "SPACE"
            }
        }
    }
    
    enum KeyEvent: CustomDebugStringConvertible {
        case down(Key)
        case up(Key)
        
        var debugDescription: String {
            switch self {
            case .down(let key):
                return "\(key) - PRESSED"
            case .up(let key):
                return "\(key) - RELEASED"
            }
        }
    }
    
    enum Sound: String {
        case enemykilled
        case gameover
        case life
        case music
        case playerhit
        case shot
    }
        
}

protocol EventHandler: class {
    func key(event: GameModels.KeyEvent)
}
