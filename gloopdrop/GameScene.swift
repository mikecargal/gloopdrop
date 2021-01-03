//
//  GameScene.swift
//  gloopdrop
//
//  Created by Mike Cargal on 1/3/21.
//

import GameplayKit
import SpriteKit

class GameScene: SKScene {
    let player = Player()
    let playerSpeed: CGFloat = 1.5;
    
    override func didMove(to view: SKView) {
        let background = SKSpriteNode(imageNamed: "background_1")
        background.anchorPoint = CGPoint(x: 0, y: 0)
        background.position = CGPoint(x: 0, y: 0)
        background.zPosition = Layer.background.rawValue
        addChild(background)
        
        // set up foreground
        let foreground = SKSpriteNode(imageNamed: "foreground_1")
        foreground.anchorPoint = CGPoint(x: 0, y: 0)
        foreground.position = CGPoint(x: 0, y: 0)
        foreground.zPosition = Layer.foreground.rawValue
        addChild(foreground)
        
        // Set up a plyer
        player.position = CGPoint(x: size.width / 2, y: foreground.frame.maxY)
        player.setupConstraints(floor: foreground.frame.maxY)
        addChild(player)
        
        player.walk()
        // set up game
        spawnGloop()
    }
    
    // MARK: - TOUCH HANDLING
    
    func touchDown(atPoint pos: CGPoint) {
        let direction = pos.x < player.position.x ? PlayerMovementDirection.left : PlayerMovementDirection.right
        // let distance = hypot(pos.x-player.position.x,pos.y-player.position.y)
        let distance = abs(pos.x-player.position.x)
        let calculatedSpeed = TimeInterval(distance/playerSpeed)/255
        player.moveToPosition(pos: pos, direction: direction, speed: calculatedSpeed)
    }
     
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { touchDown(atPoint: t.location(in: self)) }
    }
    
    // MARK: - GAME FUNCTIONS
    
    func spawnGloop() {
        let collectible = Collectible(collectibleType: CollectibleType.gloop)
        collectible.position = CGPoint(x: player.position.x, y: player.position.y * 2.5)
        addChild(collectible)
    }
}
