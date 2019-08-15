//
//  FireButton.swift
//  I Hate Duck
//
//  Created by Leonard Chen on 8/15/19.
//  Copyright © 2019 Leonard Chan. All rights reserved.
//

import Foundation
import SpriteKit

class FireButton: SKSpriteNode {
    
    var isReloading = false {
        didSet {
            if isReloading {
                texture = SKTexture(imageNamed: "fire_reloading")
                run(.repeatForever(.rotate(byAngle: 180, duration: 30)), withKey: ActionKey.reloadingRotation.key)
            } else {
                texture = SKTexture(imageNamed: "fire_normal")
                removeAction(forKey: ActionKey.reloadingRotation.key)
            }
        }
    }
    
    init() {
        let texture = SKTexture(imageNamed: "fire_normal")
        super.init(texture: texture, color: .clear, size: texture.size())
        
        isUserInteractionEnabled = true
        name = "fire"
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Touch Events
extension FireButton {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !isReloading {
            texture = SKTexture(imageNamed: "fire_pressed")
        }
        
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !isReloading {
            texture = SKTexture(imageNamed: "fire_normal")
        }
        
    }
}
