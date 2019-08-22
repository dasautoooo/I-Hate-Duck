//
//  GameScene.swift
//  I Hate Duck
//
//  Created by Leonard Chen on 8/12/19.
//  Copyright © 2019 Leonard Chan. All rights reserved.
//

import SpriteKit
import GameplayKit

class StageScene: SKScene {
    
    // Nodes
    var rifle: SKSpriteNode?
    var crosshair: SKSpriteNode?
    let fire = FireButton()
    var duckScoreNode: SKNode!
    var targetScoreNode: SKNode!
    
    // Score
    var totalScore = 0
    let targetScore = 10
    let duckScore = 10
    
    // Count
    var duckCount = 0
    var targetCount = 0
    
    // Touches
    var selectedNodes: [UITouch : SKSpriteNode] = [:]
    
    // Game state machine
    var gameStateMachine: GKStateMachine!
    
    var duckMoveDuration: TimeInterval!
    
    let targetXPosition: [Int] = [160, 240, 320, 400, 480, 560, 640]
    var usingTargetXPosition = Array<Int>()
    
    // The amount of ammunition
    var ammunitionQuantity = 5
    
    var magazine: Magazine!
    
    var zPositionDecimal = 0.001 {
        didSet {
            if zPositionDecimal == 1 {
                zPositionDecimal = 0.001
            }
        }
    }
    
    // Store the different value of x and y between touch point and crosshair when touchesBegan
    var touchDifferent: (CGFloat, CGFloat)?

    override func didMove(to view: SKView) {
        loadUI()
        
        Audio.sharedInstance.playSound(soundFileName: Sound.musicLoop.fileName)
        Audio.sharedInstance.player(with: Sound.musicLoop.fileName)?.volume = 0.3
        Audio.sharedInstance.player(with: Sound.musicLoop.fileName)?.numberOfLoops = -1
        
        gameStateMachine = GKStateMachine(states: [
            ShootingState(fire: fire, magazine: magazine),
            ReloadingState(fire: fire, magazine: magazine),
            ReadyState(fire: fire, magazine: magazine)])

        gameStateMachine.enter(ReadyState.self)
        
        
        activeDucks()
        activeTargets()
    }

}

// MARK: - GameLoop
extension StageScene {
    override func update(_ currentTime: TimeInterval) {
        syncRiflePosition()
        setBoundry()
    }
}

// MARK: - Touches
extension StageScene {
    
    // Touch Began
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let crosshair = crosshair else { return }
        
        for touch in touches {
            let location = touch.location(in: self)
            if let node = self.atPoint(location) as? SKSpriteNode {
                if !selectedNodes.values.contains(crosshair) && !(node is FireButton) {
                    selectedNodes[touch] = crosshair
                    let xDifference = touch.location(in: self).x - crosshair.position.x
                    let yDifference = touch.location(in: self).y - crosshair.position.y
                    touchDifferent = (xDifference, yDifference)
                }
                
                // Actual shooting
                if node is FireButton {
                    selectedNodes[touch] = fire
                    
                    // Check if is reloading
                    if !fire.isReloading {
                        fire.isPressed = true
                        magazine.shoot()
                        
                        // Play sound
                        Audio.sharedInstance.playSound(soundFileName: Sound.hit.fileName)
                        
                        // Need to reload, enter ReloadingState
                        if magazine.needToReload() {
                            gameStateMachine.enter(ReloadingState.self)
                        }
                        
                        var shootNode = SKSpriteNode()
                        var biggestZPosition: CGFloat = 0.0
                        
                        // Find the node which crosshair is landed
                        self.physicsWorld.enumerateBodies(at: crosshair.position) { (body, pointer) in
                            guard let node = body.node as? SKSpriteNode else { return }
                            
                            if node.name == "duck" || node.name == "duck_target" || node.name == "target" {
                                if let parentNode = node.parent {
                                    if parentNode.zPosition > biggestZPosition {
                                        biggestZPosition = parentNode.zPosition
                                        shootNode = node
                                    }
                                }
                            }
                        }
                        
                        var scoreText = ""
                        var shotImageName = ""
                        
                        switch shootNode.name {
                        case "duck":
                            scoreText = "+\(duckScore)"
                            totalScore += duckScore
                            duckCount += 1
                            shotImageName = "shot_blue"
                        case "duck_target":
                            scoreText = "+\(duckScore + targetScore)"
                            totalScore += duckScore + targetScore
                            duckCount += 1
                            targetCount += 1
                            shotImageName = "shot_blue"
                        case "target":
                            scoreText = "+\(targetScore)"
                            totalScore += targetScore
                            targetCount += 1
                            shotImageName = "shot_brown"
                        default:
                            return
                        }

                        // Add shot image
                        let shotPosition = self.convert(crosshair.position, to: shootNode)
                        let shot = SKSpriteNode(imageNamed: shotImageName)
                        shot.position = shotPosition
                        shootNode.addChild(shot)
                        shot.run(.sequence([
                            .wait(forDuration: 2),
                            .fadeAlpha(to: 0.0, duration: 0.3),
                            .removeFromParent()]))

                        // Add score text
                        let scorePosition = CGPoint(x: crosshair.position.x + 10, y: crosshair.position.y + 30)
                        let scoreNode = generateTextNode(from: scoreText)
                        scoreNode.position = scorePosition
                        scoreNode.zPosition = 9
                        scoreNode.xScale = 0.5
                        scoreNode.yScale = 0.5
                        addChild(scoreNode)
                        scoreNode.run(.sequence([
                            .wait(forDuration: 0.5),
                            .fadeOut(withDuration: 0.2),
                            .removeFromParent()]))
                        
                        // Play score sound
                        Audio.sharedInstance.playSound(soundFileName: Sound.score.fileName)
//                        Audio.sharedInstance.player(with: Sound.reload.fileName)?.volume = 0.5
                        
                        // Update score node
                        update(score: String(duckCount * duckScore), node: &duckScoreNode)
                        update(score: String(targetCount * targetScore), node: &targetScoreNode)

                        // Animate shoot node
                        shootNode.physicsBody = nil
                        
                        if let node = shootNode.parent {
                            node.run(.sequence([
                                .wait(forDuration: 0.2),
                                .scaleY(to: 0.0, duration: 0.2)]))
                        }

                    }
                }
            }
        }
    }
    
    // Touch Moved
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let crosshair = crosshair else { return }
        guard let touchDifferent = touchDifferent else { return }
        
        for touch in touches {
            let location = touch.location(in: self)
            if let node = selectedNodes[touch] {
                if node.name == "fire" {
                    
                } else {
                    let newCrosshairPosition = CGPoint(x: location.x - touchDifferent.0 , y: location.y - touchDifferent.1)
                    crosshair.position = newCrosshairPosition
                }
            }
        }
    }
    
    // Touch Ended
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            if selectedNodes[touch] != nil {
                if let fire = selectedNodes[touch] as? FireButton {
                    fire.isPressed = false
                }
                selectedNodes[touch] = nil
            }
        }
    }
}

// MARK: - Action
extension StageScene {
    func loadUI() {
        // Rifle and Crosshair
        if let scene = scene {
            rifle = childNode(withName: "rifle") as? SKSpriteNode
            crosshair = childNode(withName: "crosshair") as? SKSpriteNode
            crosshair?.position = CGPoint(x: scene.frame.midX, y: scene.frame.midY)
        }
        
        
        // Add fire button
        fire.position = CGPoint(x: 720, y: 80)
        fire.xScale = 1.7
        fire.yScale = 1.7
        fire.zPosition = 11
        
        addChild(fire)
        
        // Add icons
        let duckIcon = SKSpriteNode(imageNamed: Texture.duckIcon.imageName)
        duckIcon.position = CGPoint(x: 36, y: 365)
        duckIcon.zPosition = 11
        addChild(duckIcon)
        
        let targetIcon = SKSpriteNode(imageNamed: Texture.targetIcon.imageName)
        targetIcon.position = CGPoint(x: 36, y: 325)
        targetIcon.zPosition = 11
        addChild(targetIcon)
        
        // Add score nodes
        duckScoreNode = generateTextNode(from: "0")
        duckScoreNode.position = CGPoint(x: 60, y: 365)
        duckScoreNode.zPosition = 11
        duckScoreNode.xScale = 0.5
        duckScoreNode.yScale = 0.5
        addChild(duckScoreNode)
        
        targetScoreNode = generateTextNode(from: "0")
        targetScoreNode.position = CGPoint(x: 60, y: 325)
        targetScoreNode.zPosition = 11
        targetScoreNode.xScale = 0.5
        targetScoreNode.yScale = 0.5
        addChild(targetScoreNode)

        // Add empty magazine
        let magazineNode = SKNode()
        magazineNode.position = CGPoint(x: 760, y: 20)
        magazineNode.zPosition = 11
        
        var bullets = Array<Bullet>()
        
        for i in 0...ammunitionQuantity - 1 {
            let bullet = Bullet()
            bullet.position = CGPoint(x: -30 * i, y: 0)
            magazineNode.addChild(bullet)
            bullets.append(bullet)
        }
        
        magazine = Magazine(bullets: bullets)
        addChild(magazineNode)
    }
    
    func generateDuck(hasTarget: Bool = false) -> Duck {
        var duck: SKSpriteNode
        var stick: SKSpriteNode
        var duckImageName: String
        var duckNodeName: String
        var node = Duck()
        var texture = SKTexture()
        
        if hasTarget {
            duckImageName = "duck_target/\(Int.random(in: 1...3))"
            texture = SKTexture(imageNamed: duckImageName)
            duckNodeName = "duck_target"
            node = Duck(hasTarget: true)
        } else {
            duckImageName = "duck/\(Int.random(in: 1...3))"
            texture = SKTexture(imageNamed: duckImageName)
            duckNodeName = "duck"
            node = Duck()
        }
        
        duck = SKSpriteNode(texture: texture)
        duck.name = duckNodeName
        duck.position = CGPoint(x: 0, y: 140)
        
        let physicsBody = SKPhysicsBody(texture: texture, alphaThreshold: 0.5, size: texture.size())
        physicsBody.affectedByGravity = false
        physicsBody.isDynamic = false
        duck.physicsBody = physicsBody
        
        stick = SKSpriteNode(imageNamed: "stick/\(Int.random(in: 1...2))")
        stick.anchorPoint = CGPoint(x: 0.5, y: 0)
        stick.position = CGPoint(x: 0, y: 0)
        
        duck.xScale = 0.8
        duck.yScale = 0.8
        stick.xScale = 0.8
        stick.yScale = 0.8
    
        node.addChild(stick)
        node.addChild(duck)
        
        
        return node
    }
    
    func generateTarget() -> Target {
        var target: SKSpriteNode
        var stick: SKSpriteNode
        let node = Target()
        let texture = SKTexture(imageNamed: "target/\(Int.random(in: 1...3))")
        
        target = SKSpriteNode(texture: texture)
        
        stick = SKSpriteNode(imageNamed: "stick_metal")
        
        target.xScale = 0.5
        target.yScale = 0.5
        target.position = CGPoint(x: 0, y: 95)
        target.name = "target"
        stick.xScale = 0.5
        stick.yScale = 0.5
        stick.anchorPoint = CGPoint(x: 0.5, y: 0)
        stick.position = CGPoint(x: 0, y: 0)

        node.addChild(stick)
        node.addChild(target)
        

        
        return node
    }
    
    func activeDucks() {
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { (timer) in
            let duck = self.generateDuck(hasTarget: Bool.random())
            duck.position = CGPoint(x: -10, y: Int.random(in: 60...90))
            duck.zPosition = Int.random(in: 0...1) == 0 ? 4 : 6
            duck.zPosition = duck.zPosition + CGFloat(self.zPositionDecimal)
            self.zPositionDecimal += 0.001
            
            self.addChild(duck)
            
            if duck.hasTarget {
                self.duckMoveDuration = TimeInterval(Int.random(in: 2...4))
            } else {
                self.duckMoveDuration = TimeInterval(Int.random(in: 5...7))
            }
            
            duck.run(.sequence([
                .moveTo(x: 850, duration: self.duckMoveDuration),
                .removeFromParent()]))
        }
    }
    
    func activeTargets() {
        Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { (timer) in
            let target = self.generateTarget()
            var xPosition = self.targetXPosition.randomElement()!
            
            while self.usingTargetXPosition.contains(xPosition) {
                xPosition = self.targetXPosition.randomElement()!
            }
            
            self.usingTargetXPosition.append(xPosition)
            target.position = CGPoint(x: xPosition, y: Int.random(in: 120...145))
            target.zPosition = 1
            target.yScale = 0
            self.addChild(target)
            
            let physicsBody = SKPhysicsBody(circleOfRadius: 71/2)
            physicsBody.affectedByGravity = false
            physicsBody.isDynamic = false
            physicsBody.allowsRotation = false
            
            target.run(.sequence([
                .scaleY(to: 1, duration: 0.2),
                .run {
                    if let node = target.childNode(withName: "target") {
                        node.physicsBody = physicsBody
                    }
                },
                .wait(forDuration: TimeInterval(Int.random(in: 3...6))),
                .scaleY(to: 0, duration: 0.2),
                .removeFromParent(),
                .run {
                    self.usingTargetXPosition.remove(at: self.usingTargetXPosition.firstIndex(of: xPosition)!)
                }]))
            
        }
    }
    
    func syncRiflePosition() {
        guard let rifle = rifle else { return }
        guard let crosshair = crosshair else { return }
        
        rifle.position.x = crosshair.position.x + 100
    }
    
    func setBoundry() {
        guard let crosshair = crosshair else { return }
        guard let scene = scene else { return }
        
        if crosshair.position.x < scene.frame.minX {
            crosshair.position.x = 0
        }
        
        if crosshair.position.x > scene.frame.maxX {
            crosshair.position.x = scene.frame.maxX
        }
        
        if crosshair.position.y < scene.frame.minY {
            crosshair.position.y = 0
        }
        
        if crosshair.position.y > scene.frame.maxY {
            crosshair.position.y = scene.frame.maxY
        }
    }
    
    func generateTextNode(from text: String) -> SKNode {
        let node = SKNode()
        var width: CGFloat = 0.0
        
        for character in text {
            var characterNode = SKSpriteNode()
            
            if character == "0" {
                characterNode = SKSpriteNode(imageNamed: ScoreNumber.zero.textureName)
            } else if character == "1" {
                characterNode = SKSpriteNode(imageNamed: ScoreNumber.one.textureName)
            } else if character == "2" {
                characterNode = SKSpriteNode(imageNamed: ScoreNumber.two.textureName)
            } else if character == "3" {
                characterNode = SKSpriteNode(imageNamed: ScoreNumber.three.textureName)
            } else if character == "4" {
                characterNode = SKSpriteNode(imageNamed: ScoreNumber.four.textureName)
            } else if character == "5" {
                characterNode = SKSpriteNode(imageNamed: ScoreNumber.five.textureName)
            } else if character == "6" {
                characterNode = SKSpriteNode(imageNamed: ScoreNumber.six.textureName)
            } else if character == "7" {
                characterNode = SKSpriteNode(imageNamed: ScoreNumber.seven.textureName)
            } else if character == "8" {
                characterNode = SKSpriteNode(imageNamed: ScoreNumber.eight.textureName)
            } else if character == "9" {
                characterNode = SKSpriteNode(imageNamed: ScoreNumber.nine.textureName)
            } else if character == "+" {
                characterNode = SKSpriteNode(imageNamed: ScoreNumber.plus.textureName)
            } else if character == "*" {
                characterNode = SKSpriteNode(imageNamed: ScoreNumber.multiplication.textureName)
            } else {
                continue
            }
            
            node.addChild(characterNode)
            
            characterNode.anchorPoint = CGPoint(x: 0, y: 0.5)
            characterNode.position = CGPoint(x: width, y: 0.0)
            
            width += characterNode.size.width
        }
        
        return node
    }
    
    func update(score: String, node: inout SKNode) {
        let position = node.position
        let zPositon = node.zPosition
        let xScale = node.xScale
        let yScale = node.yScale
        
        node.removeFromParent()
        
        node = generateTextNode(from: score)
        node.position = position
        node.zPosition = zPositon
        node.xScale = xScale
        node.yScale = yScale
        
        addChild(node)
    }
}

