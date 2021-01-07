//
//  Player.swift
//  gloopdrop
//
//  Created by Mike Cargal on 1/3/21.
//

import Foundation
import SpriteKit

// This enum lets you easily switch between animations
enum PlayerAnimationType: String {
    case walk
    case die
}

enum PlayerMovementDirection: String {
    case left
    case right
}

enum GloopBlobPrefixes : String {
    case blobWalk = "blob-walk_"
    case blobDie = "blob-die_"
}

class Player: SKSpriteNode {
    // MARK: - PROPERTIES

    // Textures (Animation)
    private var walkTextures: [SKTexture]?
    private var dieTextures: [SKTexture]?
    
    // MARK: - INIT

    init() {
        let texture = SKTexture(imageNamed: "\(GloopBlobPrefixes.blobWalk.rawValue)0")
        super.init(texture: texture, color: .clear, size: texture.size())
        
        self.walkTextures = self.loadTexttures(atlas: "blob",
                                               prefix: GloopBlobPrefixes.blobWalk.rawValue,
                                               startsAt: 0, stopsAt: 2)
        self.dieTextures = self.loadTexttures(atlas: "blob",
                                              prefix: GloopBlobPrefixes.blobDie.rawValue,
                                              startsAt: 0, stopsAt: 0)
        
        self.name = "player"
        self.setScale(1.0)
        self.anchorPoint = CGPoint(x: 0.5, y: 0.0)
        self.zPosition = Layer.player.rawValue
        
        // add physics body
        self.physicsBody = SKPhysicsBody(rectangleOf: self.size, center: CGPoint(x: 0.0, y: self.size.height / 2))
        self.physicsBody?.affectedByGravity = false
        
        self.physicsBody?.categoryBitMask = PhysicsCategory.player
        self.physicsBody?.contactTestBitMask = PhysicsCategory.collectible
        self.physicsBody?.collisionBitMask = PhysicsCategory.none
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - METHODS

    func setupConstraints(floor: CGFloat) {
        let range = SKRange(lowerLimit: floor, upperLimit: floor)
        let lockToPlatform = SKConstraint.positionY(range)
        
        constraints = [lockToPlatform]
    }
    
    func walk() {
        guard let walkTextures = walkTextures else {
            preconditionFailure("Could not find walk textures!")
        }
        removeAction(forKey: PlayerAnimationType.die.rawValue)
        startAnimation(textures: walkTextures, speed: 0.25,
                       name: PlayerAnimationType.walk.rawValue,
                       count: 0, resize: true, restore: true)
    }
    
    func die() {
        print("Player::die()")
        guard let dieTextures = dieTextures else {
            preconditionFailure("Could not find die textures!")
        }
        print("removeAction(forKey: \(PlayerAnimationType.walk.rawValue))")
        removeAction(forKey: PlayerAnimationType.walk.rawValue)
        print("dieTextures=>>\(dieTextures)<<")
        print("startAnimation(name:\(PlayerAnimationType.die.rawValue))")
        startAnimation(textures: dieTextures, speed: 0.25,
                       name: PlayerAnimationType.die.rawValue,
                       count: 0, resize: true, restore: true)
    }
    
    func moveToPosition(pos: CGPoint, direction: PlayerMovementDirection, speed: TimeInterval) {
        switch direction {
        case .left:
            xScale = -abs(xScale)
        case .right:
            xScale = abs(xScale)
        }
        let moveAction = SKAction.move(to: pos, duration: speed)
        run(moveAction)
    }
}
