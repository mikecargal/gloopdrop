//
//  SpriteKitHelper.swift
//  gloopdrop
//
//  Created by Mike Cargal on 1/3/21.
//

import Foundation
import SpriteKit

// MARK: - SPRITEKIT HELPERS

enum Layer: CGFloat {
    case background
    case foreground
    case player
    case collectible
    case ui
}

enum PhysicsCategory {
    static let none:        UInt32 = 0
    static let player:      UInt32 = 0b1
    static let collectible: UInt32 = 0b10
    static let foreground:  UInt32 = 0b100
}

// MARK: - SPRITEKIT EXTENSIONS

extension SKSpriteNode {
    func loadTexttures(atlas: String, prefix: String, startsAt: Int, stopsAt: Int) -> [SKTexture] {
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
    func startAnimation(textures: [SKTexture], speed: Double, name: String, count: Int, resize: Bool, restore: Bool) {
        let animation = SKAction.animate(withNormalTextures: textures, timePerFrame: speed, resize: resize, restore: restore)

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

extension SKScene {
    func viewTop() -> CGFloat {
        return convertPoint(fromView: CGPoint(x: 0.0, y: 0.0)).y
    }
    
    func viewBottom() -> CGFloat {
        guard let view = view else {return 0.0}
        return convertPoint(fromView: CGPoint(x: 0.0, y: view.bounds.size.height)).y
    }
}
