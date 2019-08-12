//
//  GameScene.swift
//  I Hate Duck
//
//  Created by Leonard Chen on 8/12/19.
//  Copyright © 2019 Leonard Chan. All rights reserved.
//

import SpriteKit
import GameplayKit

class Target: SKNode { }

class StageScene: SKScene {

    override func didMove(to view: SKView) {
        let duck = generateDuck(hasTarget: true)
        duck.position = CGPoint(x: 200, y: 80)
        duck.zPosition = 6
        addChild(duck)
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
        stick = SKSpriteNode(imageNamed: "stick/\(Int.random(in: 1...2))")
        stick.anchorPoint = CGPoint(x: 0.5, y: 0)
        duck.position = CGPoint(x: 0, y: 170)
        node.xScale = 0.8
        node.yScale = 0.8
        node.addChild(stick)
        node.addChild(duck)
        
        
        return node
    }
}

