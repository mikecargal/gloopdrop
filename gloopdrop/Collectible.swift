//
//  Collectibles.swift
//  gloopdrop
//
//  Created by Mike Cargal on 1/3/21.
//

import Foundation
import SpriteKit

enum CollectibleType: String {
    case none
    case gloop
}

class Collectible:SKSpriteNode {
    // MARK: - PROPERTIES
    private var collectibleType: CollectibleType = .none
    
    // MARK: - INIT
    init(collectibleType:CollectibleType) {
        var texture: SKTexture!
        self.collectibleType = collectibleType
        
        switch self.collectibleType {
        case .gloop:
            texture = SKTexture(imageNamed: "gloop")
        case .none:
            break
        }
        
        super.init(texture: texture, color: .clear, size: texture.size())
        
        self.name = "co_\(collectibleType)"
        self.anchorPoint = CGPoint(x: 0.5, y: 1.0)
        self.zPosition = Layer.collectible.rawValue
        
        // add [hysics body
        self.physicsBody = SKPhysicsBody(rectangleOf: self.size, center: CGPoint(x: 0.0, y: -self.size.height/2))
        self.physicsBody?.affectedByGravity = false
        
        self.physicsBody?.categoryBitMask = PhysicsCategory.collectible
        self.physicsBody?.contactTestBitMask = PhysicsCategory.player | PhysicsCategory.foreground
        self.physicsBody?.collisionBitMask = PhysicsCategory.none
    }
    
    required init?(coder aDecoder:NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - FUNCTIONS
    func drop(dropSpeed: TimeInterval, floorLevel:CGFloat) {
        let pos = CGPoint(x: position.x, y: floorLevel)
        
        let scaleX = SKAction.scale(to: 1.0, duration: 1.0)
        let scaleY = SKAction.scale(to: 1.3, duration: 1.0)
        let scale = SKAction.group([scaleX,scaleY])
        
        let appear = SKAction.fadeAlpha(to: 1.0, duration: 0.25)
        let moveAction = SKAction.move(to: pos, duration: 0.25)
        let actionSequence = SKAction.sequence([appear,scale,moveAction])
        
        //Shrink first, then run fall action
        self.scale(to: CGSize(width: 0.25, height: 1.0))
        self.run(actionSequence,withKey: GloopActionKeys.drop.rawValue)
    }
    
    func collected() {
        self.run(SKAction.removeFromParent())
    }
    
    func missed() {
        self.run(SKAction.removeFromParent())
    }
}
