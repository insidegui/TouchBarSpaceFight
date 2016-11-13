//
//  GameScene.swift
//  TouchBarSpaceFight
//
//  Created by Guilherme Rambo on 09/11/16.
//  Copyright © 2016 Guilherme Rambo. All rights reserved.
//

import Cocoa
import SpriteKit

extension Notification.Name {
    static let GameOver = Notification.Name(rawValue: "TouchBarSpaceFightGameOver")
}

protocol GameSceneDelegate: class {
    var state: GameModels.GameState { get set }
}

extension SKScene {
    
    func childNode<N: SKNode>(for sprite: GameModels.Sprite) -> N {
        return self.childNode(withName: sprite.rawValue) as! N
    }
    
}

extension CGFloat {
    
    static func random() -> CGFloat {
        return CGFloat(Float(arc4random()) / 0xFFFFFFFF)
    }
    
    static func random(min: CGFloat, max: CGFloat) -> CGFloat {
        return random() * (max - min) + min
    }
    
}

extension GameModels.Sound {
    
    var instance: SKAudioNode {
        return SKAudioNode(fileNamed: rawValue)
    }
    
}

class GameScene: SKScene, EventHandler, SKPhysicsContactDelegate {
    
    weak var gameDelegate: GameSceneDelegate!
    
    private var playerDirection: CGVector = .zero
    
    private var isShooting = false
    
    private lazy var player: SKSpriteNode = {
        let p: SKSpriteNode = self.childNode(for: .player)
        
        p.physicsBody = SKPhysicsBody(rectangleOf: p.size)
        p.physicsBody?.isDynamic = true
        p.physicsBody?.categoryBitMask = GameModels.PhysicsCategory.player
        p.physicsBody?.contactTestBitMask = GameModels.PhysicsCategory.enemy
        p.physicsBody?.collisionBitMask = GameModels.PhysicsCategory.none
        
        return p
    }()
    
    private lazy var enemyPrototype: SKSpriteNode = {
        return self.childNode(for: .enemy)
    }()

    private lazy var lifePrototype: SKSpriteNode = {
        return self.childNode(for: .life)
    }()
    
    private lazy var shotPrototype: SKSpriteNode = {
        return self.childNode(for: .shot)
    }()
    
    private var numberOfActiveEnemies: Int {
        return children.filter({ $0.name?.contains("enemy") ?? false }).count
    }
    
    private var numberOfActiveShots: Int {
        return children.filter({ $0.name?.contains("shot") ?? false }).count
    }
    
    private var statisticsTimer: Timer!
    
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self
        
        run(SKAction.repeatForever(
            SKAction.sequence([
                SKAction.run(spawnEnemy),
                SKAction.wait(forDuration: 1.0)
                ])
        ))
        
        statisticsTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateGameStatistics(_:)), userInfo: nil, repeats: true)
        
        let musicNode = GameModels.Sound.music.instance
        musicNode.autoplayLooped = true
        addChild(musicNode)
    }
    
    private var gameStartTime: TimeInterval!
    private var gameTime: TimeInterval = 0
    
    override func update(_ currentTime: TimeInterval) {
        super.update(currentTime)
        
        if gameStartTime == nil {
            gameStartTime = currentTime
        }
        
        gameTime = currentTime - gameStartTime
        
        // move player according to keyboard commands
        if playerDirection.dy < 0 && player.position.y > 0 {
            player.position.y -= gameDelegate.state.playerSpeed.dy
        } else if playerDirection.dy > 0 && player.position.y < size.height - player.size.height {
            player.position.y += gameDelegate.state.playerSpeed.dy
        }
        
        if playerDirection.dx < 0 && player.position.x > 10 {
            player.position.x -= gameDelegate.state.playerSpeed.dx
        } else if playerDirection.dx > 0 && player.position.x < size.width - 10 {
            player.position.x += gameDelegate.state.playerSpeed.dx
        }
        
        // keep track of player's hit status
        if gameDelegate.state.isHit {
            player.alpha = 0.5
            
            if gameTime - gameDelegate.state.hitTime >= gameDelegate.state.hitDuration {
                gameDelegate.state.isHit = false
                gameDelegate.state.hitTime = 0
                // reset player hit state
                player.alpha = 1
            }
        }
        
        // shoot if needed
        if isShooting {
            if numberOfActiveShots < numberOfActiveEnemies * gameDelegate.state.maxShotsPerEnemy {
                spawnShot()
            }
        }
    }
    
    private var statisticsTime: TimeInterval = 0.0
    
    @objc private func updateGameStatistics(_ sender: Any?) {
        statisticsTime += 1.0
        
        // update difficulty level if needed
        if abs(statisticsTime.truncatingRemainder(dividingBy: gameDelegate.state.difficultyIncreaseRate)) == 0 {
            // time to increase difficulty
            if gameDelegate.state.difficultyIncreaseCount < gameDelegate.state.maxDifficultyIncreaseCount {
                gameDelegate.state.enemySpawnInterval += gameDelegate.state.enemySpawnIntervalIncreaseRate
                gameDelegate.state.maxEnemySpeed += gameDelegate.state.enemySpeedIncreaseRate
                
                gameDelegate.state.difficultyIncreaseCount += 1
            }
        }
        
        // maybe spawn a new life for the player
        if abs(statisticsTime.truncatingRemainder(dividingBy: gameDelegate.state.lifeSpawnRate)) == 0 {
            if arc4random_uniform(1000) % 3 == 0 {
                spawnLife()
            }
        }
    }
    
    func key(event: GameModels.KeyEvent) {
        switch event {
        case .down(let key):
            switch key {
            case .arrowDown:
                playerDirection.dy = -1
            case .arrowUp:
                playerDirection.dy = 1
            case .arrowLeft:
                playerDirection.dx = -1
            case .arrowRight:
                playerDirection.dx = 1
            case .space:
                isShooting = true
            }
        case .up(let key):
            switch key {
            case .arrowDown, .arrowUp:
                playerDirection.dy = 0
            case .arrowLeft, .arrowRight:
                playerDirection.dx = 0
            case .space:
                isShooting = false
            }
        }
    }
    
    private func newEnemy() -> SKSpriteNode {
        let enemy = enemyPrototype.copy() as! SKSpriteNode
        enemy.name = "enemy-" + UUID().uuidString
        
        enemy.physicsBody = SKPhysicsBody(rectangleOf: enemy.size)
        enemy.physicsBody?.isDynamic = true
        enemy.physicsBody?.categoryBitMask = GameModels.PhysicsCategory.enemy
        enemy.physicsBody?.contactTestBitMask = GameModels.PhysicsCategory.shot
        enemy.physicsBody?.collisionBitMask = GameModels.PhysicsCategory.none
        
        return enemy
    }
    
    private func spawnEnemy() {
        let enemy = newEnemy()
        
        let y = CGFloat.random(min: 0, max: size.height - enemy.size.height)
        enemy.position = CGPoint(x: size.width, y: y)
        
        addChild(enemy)
        
        let duration = CGFloat.random(min: 1.0, max: gameDelegate.state.maxEnemySpeed)
        
        let moveAction = SKAction.move(to: CGPoint(x: -enemy.size.width, y: y), duration: TimeInterval(duration))
        let moveActionCompute = SKAction.run { [weak self] in
            self?.gameDelegate.state.score.escapedEnemies += 1
        }
        let moveActionCompletion = SKAction.removeFromParent()
        enemy.run(SKAction.sequence([moveAction, moveActionCompute, moveActionCompletion]))
    }
    
    private func newShot() -> SKSpriteNode {
        let shot = shotPrototype.copy() as! SKSpriteNode
        shot.name = "shot-" + UUID().uuidString
        
        shot.physicsBody = SKPhysicsBody(rectangleOf: shot.size)
        shot.physicsBody?.isDynamic = true
        shot.physicsBody?.categoryBitMask = GameModels.PhysicsCategory.shot
        shot.physicsBody?.contactTestBitMask = GameModels.PhysicsCategory.enemy
        shot.physicsBody?.collisionBitMask = GameModels.PhysicsCategory.none
        
        return shot
    }
    
    private func spawnShot() {
        if gameDelegate.state.lastShotTime != 0 {
            if gameTime - gameDelegate.state.lastShotTime < gameDelegate.state.maxShotRate {
                return
            } else {
                gameDelegate.state.lastShotTime = 0
            }
        }
        
        let shot = newShot()
        shot.position = CGPoint(x: player.position.x + player.size.width, y: player.position.y + player.size.height / 2)
        
        addChild(shot)
        
        let duration = CGFloat.random(min: 1.0, max: gameDelegate.state.maxShotSpeed)
        
        let moveAction = SKAction.move(to: CGPoint(x: size.width, y: shot.position.y), duration: TimeInterval(duration))
        let moveActionCompute = SKAction.run { [weak self] in
            self?.gameDelegate.state.score.wastedShots += 1
        }
        let moveActionCompletion = SKAction.removeFromParent()
        shot.run(SKAction.sequence([moveAction, moveActionCompute, moveActionCompletion]))
        
        gameDelegate.state.lastShotTime = gameTime
        
        run(SKAction.playSoundFileNamed(GameModels.Sound.shot.rawValue, waitForCompletion: false))
    }
    
    private func newLife() -> SKSpriteNode {
        let life = lifePrototype.copy() as! SKSpriteNode
        life.name = "life-" + UUID().uuidString
        
        life.physicsBody = SKPhysicsBody(rectangleOf: life.size)
        life.physicsBody?.isDynamic = true
        life.physicsBody?.categoryBitMask = GameModels.PhysicsCategory.life
        life.physicsBody?.contactTestBitMask = GameModels.PhysicsCategory.player
        life.physicsBody?.collisionBitMask = GameModels.PhysicsCategory.none
        
        return life
    }
    
    private func spawnLife() {
        let life = newLife()
        
        let y = CGFloat.random(min: 0, max: size.height - life.size.height)
        life.position = CGPoint(x: size.width, y: y)
        
        addChild(life)
        
        let duration = CGFloat.random(min: 1.0, max: gameDelegate.state.maxLifeSpeed)
        
        let moveAction = SKAction.move(to: CGPoint(x: -life.size.width, y: y), duration: TimeInterval(duration))
        let moveActionCompletion = SKAction.removeFromParent()
        life.run(SKAction.sequence([moveAction, moveActionCompletion]))
    }
    
    // MARK: - Collisions
    
    func didBegin(_ contact: SKPhysicsContact) {
        var firstBody: SKPhysicsBody
        var secondBody: SKPhysicsBody
        
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        } else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }

        // enemy hit by player shot
        if (secondBody.categoryBitMask & GameModels.PhysicsCategory.shot) != 0
            && (firstBody.categoryBitMask & GameModels.PhysicsCategory.enemy) != 0 {
            
            if let enemy = firstBody.node as? SKSpriteNode, let explosion = SKScene(fileNamed: "Explosion") {
                explosion.position = enemy.position
                explosion.size = enemy.size
                
                addChild(explosion)
                
                let wait = SKAction.wait(forDuration: 0.3)
                let remove = SKAction.removeFromParent()
                explosion.run(SKAction.sequence([wait, remove]))
            }
            
            firstBody.node?.removeFromParent()
            secondBody.node?.removeFromParent()
            gameDelegate.state.score.destroyedEnemies += 1

            run(SKAction.playSoundFileNamed(GameModels.Sound.enemykilled.rawValue, waitForCompletion: false))
        }
        
        // player hit by enemy
        if !gameDelegate.state.isHit {
            if (firstBody.categoryBitMask & GameModels.PhysicsCategory.enemy) != 0
                && (secondBody.categoryBitMask & GameModels.PhysicsCategory.player) != 0 {
                gameDelegate.state.isHit = true
                gameDelegate.state.hitTime = gameTime
                gameDelegate.state.score.lives -= 1
                gameDelegate.state.score.numberOfHits += 1
                run(SKAction.playSoundFileNamed(GameModels.Sound.playerhit.rawValue, waitForCompletion: false))
                
                if gameDelegate.state.score.lives <= 0 {
                    let overAction = SKAction.run {
                        NotificationCenter.default.post(name: .GameOver, object: nil)
                    }
                    let overSoundAction = SKAction.playSoundFileNamed(GameModels.Sound.gameover.rawValue, waitForCompletion: false)
                    
                    run(SKAction.sequence([overSoundAction, overAction]))
                }
            }
        }
        
        // player hit by life
        if (secondBody.categoryBitMask & GameModels.PhysicsCategory.life) != 0
            && (firstBody.categoryBitMask & GameModels.PhysicsCategory.player) != 0 {
            gameDelegate.state.score.lives += 1
            secondBody.node?.removeFromParent()
            run(SKAction.playSoundFileNamed(GameModels.Sound.life.rawValue, waitForCompletion: false))
        }
    }
    
}
