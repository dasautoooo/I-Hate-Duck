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
    
    // Touches
    var selectedNodes: [UITouch : SKSpriteNode] = [:]
    
    var duckMoveDuration: TimeInterval!
    
    let targetXPosition: [Int] = [160, 240, 320, 400, 480, 560, 640]
    var usingTargetXPosition = Array<Int>()
    
    // Store the different value of x and y between touch point and crosshair when touchesBegan
    var touchDifferent: (CGFloat, CGFloat)?

    override func didMove(to view: SKView) {
        rifle = childNode(withName: "rifle") as? SKSpriteNode
        crosshair = childNode(withName: "crosshair") as? SKSpriteNode
        
        crosshair?.position = CGPoint(x: view.frame.midX, y: view.frame.midY)
        
        activeDucks()
        activeTargets()
    }

}

// MARK: - GameLoop
extension StageScene {
    override func update(_ currentTime: TimeInterval) {
        syncRiflePosition()
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
                if !selectedNodes.values.contains(crosshair) && node.name != "fire" {
                    selectedNodes[touch] = crosshair
                    let xDifference = touch.location(in: self).x - crosshair.position.x
                    let yDifference = touch.location(in: self).y - crosshair.position.y
                    touchDifferent = (xDifference, yDifference)
                }
                
                if node.name == "fire" {
                    selectedNodes[touch] = node
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
                selectedNodes[touch] = nil
            }
        }
    }
}

// MARK: - Action
extension StageScene {
    func generateDuck(hasTarget: Bool = false) -> Duck {
        var duck: SKSpriteNode
        var stick: SKSpriteNode
        var duckImageName: String
        var node = Duck()
        
        if hasTarget {
            duckImageName = "duck_target/\(Int.random(in: 1...3))"
            node = Duck(hasTarget: true)
        } else {
            duckImageName = "duck/\(Int.random(in: 1...3))"
            node = Duck()
        }
        
        duck = SKSpriteNode(imageNamed: duckImageName)
        duck.position = CGPoint(x: 0, y: 140)
        duck.xScale = 0.8
        duck.yScale = 0.8
        stick = SKSpriteNode(imageNamed: "stick/\(Int.random(in: 1...2))")
        stick.anchorPoint = CGPoint(x: 0.5, y: 0)
        stick.position = CGPoint(x: 0, y: 0)
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
        
        target = SKSpriteNode(imageNamed: "target/\(Int.random(in: 1...3))")
        target.xScale = 0.5
        target.yScale = 0.5
        target.position = CGPoint(x: 0, y: 95)
        
        stick = SKSpriteNode(imageNamed: "stick_metal")
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
            
            target.run(.sequence([
                .scaleY(to: 1, duration: 0.2),
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
}

