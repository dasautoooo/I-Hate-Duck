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
                    if !fire.isReloading {
                        fire.isPressed = true
                        magazine.shoot()
                        
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

                        let shotPosition = self.convert(crosshair.position, to: shootNode)
                        let shot = SKSpriteNode(imageNamed: "shot_blue")
                        shot.position = shotPosition
                        shootNode.addChild(shot)
                        shot.run(.sequence([
                            .wait(forDuration: 2),
                            .fadeAlpha(to: 0.0, duration: 0.3),
                            .removeFromParent()]))

                        

                        

                        // Check the node type, in order to add right shot color on it
                        
                        // Add shot image
                        
                        // TODO Score system
                        
                        //
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
        fire.xScale = 1.3
        fire.yScale = 1.3
        fire.zPosition = 11
        
        addChild(fire)
        
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
}
