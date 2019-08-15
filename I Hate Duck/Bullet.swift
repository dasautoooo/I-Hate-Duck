//
//  Bullet.swift
//  I Hate Duck
//
//  Created by Leonard Chen on 8/15/19.
//  Copyright © 2019 Leonard Chan. All rights reserved.
//

import Foundation
import SpriteKit

class Bullet: SKSpriteNode {
    var isEmpty: Bool! {
        didSet {
            if isEmpty {
                texture = SKTexture(imageNamed: "icon_bullet_empty")
            } else {
                texture = SKTexture(imageNamed: "icon_bullet")
            }
        }
    }
    
    init(isEmpty: Bool) {
        self.isEmpty = isEmpty
        
        var texture = SKTexture()
        
        if isEmpty {
            texture = SKTexture(imageNamed: "icon_bullet_empty")
        } else {
            texture = SKTexture(imageNamed: "icon_bullet")
        }
        
        super.init(texture: texture, color: .clear, size: texture.size())
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
}
