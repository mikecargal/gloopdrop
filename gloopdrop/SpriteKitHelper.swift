//
//  SpriteKitHelper.swift
//  gloopdrop
//
//  Created by Mike Cargal on 1/3/21.
//

import Foundation
import SpriteKit

// MARK: - SPRITEKIT HELPERS

enum PhysicsCategory {
    static let none:        UInt32 = 0
    static let player:      UInt32 = 0b1
    static let collectible: UInt32 = 0b10
    static let foreground:  UInt32 = 0b100
}

enum Layer: CGFloat {
    case background
    case foreground
    case player
    case collectible
    case ui
}

enum GloopActionKeys: String {
    case gloop
    case drop
}

// MARK: - SPRITEKIT EXTENSIONS

extension SKSpriteNode {
    func loadTextures(atlas: String, prefix: String,
                      startsAt: Int, stopsAt: Int) -> [SKTexture]
    {
        var textureArray = [SKTexture]()
        let texttureAtlas = SKTextureAtlas(named: atlas)
        for i in startsAt ... stopsAt {
            let textureName = "\(prefix)\(i)"
            let temp = texttureAtlas.textureNamed(textureName)
            textureArray.append(temp)
        }
        return textureArray
    }

    // Start the animation using a name and a count (0 = repeat forever)
    func startAnimation(textures: [SKTexture], speed: Double, name: String,
                        count: Int, resize: Bool, restore: Bool)
    {
        if action(forKey: name) == nil {
            let animation = SKAction.animate(with: textures, timePerFrame: speed,
                                             resize: resize, restore: restore)

            if count == 0 {
                // run animation until stopped
                let repeatAction = SKAction.repeatForever(animation)
                run(repeatAction, withKey: name)
            } else if count == 1 {
                run(animation, withKey: name)
            } else {
                let repeatAction = SKAction.repeat(animation, count: count)
                run(repeatAction, withKey: name)
            }
        }
    }
    
    // Used to create an endless scrolling background
    func endlessScroll(speed: TimeInterval) {
        let moveAction = SKAction.moveBy(x: -self.size.width,y: 0, duration: speed)
        let resetAction = SKAction.moveBy(x: self.size.width, y: 0, duration: 0.0)
        
        self.run(SKAction.repeatForever(SKAction.sequence([moveAction,resetAction])))
    }
}

extension SKScene {
    func viewTop() -> CGFloat {
        return convertPoint(fromView: CGPoint(x: 0.0, y: 0.0)).y
    }

    func viewBottom() -> CGFloat {
        guard let view = view else { return 0.0 }
        return convertPoint(fromView: CGPoint(x: 0.0, y: view.bounds.size.height)).y
    }
}

extension SKNode {
    func setupScollingView(imageNamed name: String, layer: Layer,blocks:Int,speed:TimeInterval) {
        for i in 0..<blocks {
            let spriteNode = SKSpriteNode(imageNamed: name)
            spriteNode.anchorPoint = CGPoint.zero
            spriteNode.position = CGPoint(x: CGFloat(i) * spriteNode.size.width, y: 0)
            spriteNode.zPosition = layer.rawValue
            spriteNode.name = name
            
            spriteNode.endlessScroll(speed: speed)
            addChild(spriteNode)
        }
    }
}
