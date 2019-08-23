//
//  StartScene.swift
//  I Hate Duck
//
//  Created by Leonard Chen on 8/23/19.
//  Copyright © 2019 Leonard Chan. All rights reserved.
//

import SpriteKit

class StartScene: SKScene {
    // Node
    var startButton: SKSpriteNode!
    var textNode: SKNode!
    
    // Touches
    var selectedNodes: [UITouch : SKSpriteNode] = [:]
    
    override func didMove(to view: SKView) {
        startButton = childNode(withName: "start") as? SKSpriteNode
        textNode = childNode(withName: "textNode")
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let location = touch.location(in: self)
            
            if let node = self.atPoint(location) as? SKSpriteNode, node.name == "start" {
                selectedNodes[touch] = node
                node.texture = SKTexture(imageNamed: Texture.startButtonPressed.imageName)
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            if selectedNodes[touch] != nil {
                if let node = selectedNodes[touch], node.name == "start" {
                    node.texture = SKTexture(imageNamed: Texture.startButton.imageName)
                    
                    // Start Animation
                    node.removeFromParent()
                    
                    let readyNode = SKSpriteNode(imageNamed: "ready")
                    readyNode.setScale(0.0)
                    textNode.addChild(readyNode)
                    readyNode.run(.sequence([
                        .scale(to: 1.0, duration: 0.1),
                        .wait(forDuration: 1),
                        .fadeAlpha(to: 0.0, duration: 0.2),
                        .setTexture(SKTexture(imageNamed: "go")),
                        .fadeAlpha(to: 1.0, duration: 0.1),
                        .scale(to: 1.0, duration: 0.1),
                        .wait(forDuration: 0.3),
                        .run {
                            // Start Game
                            let stageScene = StageScene(fileNamed: "StageScene")
                            stageScene?.scaleMode = .aspectFit
                            self.view?.presentScene(stageScene)
                        }]))
                    
                    
                }
                selectedNodes[touch] = nil
            }
        }
    }
}
