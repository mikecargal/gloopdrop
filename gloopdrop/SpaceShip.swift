//
//  SpaceShip.swift.swift
//  gloopdrop
//
//  Created by Mike Cargal on 1/12/21.
//

import Foundation
import SpriteKit

class SpaceShip: SKSpriteNode {
    init() {
        let texture = SKTexture(imageNamed: "robot")
        super.init(texture: texture, color: .clear, size: texture.size())
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func randomSpaceShip(width: CGFloat) {
        let firstDelay = TimeInterval(CGFloat.random(in: 30.0...60.0))
        let rightToLeft = Bool.random()
        let duration = TimeInterval(CGFloat.random(in: 5.0...10.0))
        let offLeft = CGPoint(x: -size.width, y: 10.0)
        let offRight = CGPoint(x: width + size.width, y: 10.0)
        
        print("=====\ndelay: \(firstDelay)\nRtoL: \(rightToLeft)\nduration: \(duration)\n")

        let (start, stop) = rightToLeft ?
            (offLeft, offRight) :
            (offRight, offLeft)
        self.run(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.0, duration: 0.0),
            SKAction.wait(forDuration: firstDelay),
            SKAction.move(to: start, duration: 0.0),
            SKAction.fadeAlpha(to: 1.0, duration: 0.0),
            SKAction.move(to: stop, duration: duration)
        ])) {[unowned self] in
            print("AGAIN!")
            randomSpaceShip(width:width)
        }
    }
}
