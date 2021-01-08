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
    let playerSpeed: CGFloat = 1.5
    
    let labelFont = "Nosifer"
    
    // player movement
    var movingPlayer = false
    var lastPosition: CGPoint?
    
    var level: Int = 1 {
        didSet {
            levelLabel.text = "Level:\(level)"
        }
    }
    
    var score: Int = 0 {
        didSet {
            scoreLabel.text = "Score: \(score)"
        }
    }
    
    var numberOfDrops: Int = 10
    var dropsExpected = 10
    var dropsCollected = 0

    var dropSpeed: CGFloat = 1.0
    var minDropSpeed: CGFloat = 0.12 // fastest drop
    var maxDropSpeed: CGFloat = 1.0 // slowest drop
    
    // game states
    var gameInProgress = false

    // Labels
    var scoreLabel = SKLabelNode()
    var levelLabel = SKLabelNode()

    override func didMove(to view: SKView) {
        // set up the physics world contact delegate
        physicsWorld.contactDelegate = self
        
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
                
        // add physics body
        foreground.physicsBody = SKPhysicsBody(edgeLoopFrom: foreground.frame)
        foreground.physicsBody?.affectedByGravity = false
        
        foreground.physicsBody?.categoryBitMask = PhysicsCategory.foreground
        foreground.physicsBody?.contactTestBitMask = PhysicsCategory.collectible
        foreground.physicsBody?.collisionBitMask = PhysicsCategory.none
        
        addChild(foreground)

        setupLabels()

        // Set up a plyer
        player.position = CGPoint(x: size.width / 2, y: foreground.frame.maxY)
        player.setupConstraints(floor: foreground.frame.maxY)
        addChild(player)

        showMessage("Tap to start game")
    }
    
    func setupLabels() {
        // SCORE LABEL
        commonLabelInit(label: scoreLabel,
                        hAlign: .right,
                        xPos: frame.maxX - 50,
                        text: "Score: 0")
        addChild(scoreLabel)
        
        // LEVEL LABEL
        commonLabelInit(label: levelLabel,
                        hAlign: .left,
                        xPos: frame.minX + 50,
                        text: "Level: \(level)")
        addChild(levelLabel)
    }
    
    func commonLabelInit(label: SKLabelNode, hAlign: SKLabelHorizontalAlignmentMode, xPos: CGFloat, text: String) {
        label.name = "score"
        label.fontName = labelFont
        label.fontColor = .yellow
        label.fontSize = 35.0
        label.horizontalAlignmentMode = hAlign
        label.verticalAlignmentMode = .center
        label.zPosition = Layer.ui.rawValue
        label.position = CGPoint(x: xPos, y: viewTop() - 100)
        label.text = text
    }
    
    func showMessage(_ message: String) {
        let messageLabel = SKLabelNode()
        messageLabel.name = "message"
        messageLabel.position = CGPoint(x: frame.midX, y: player.frame.maxY + 100)
        messageLabel.zPosition = Layer.ui.rawValue
        
        messageLabel.numberOfLines = 2
        
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: SKColor(red: 251.0 / 255.0,
                                      green: 155.0 / 255 / 0,
                                      blue: 24.0 / 255.0,
                                      alpha: 1.0),
            .backgroundColor: UIColor.clear,
            .font: UIFont(name: labelFont, size: 45.0)!,
            .paragraphStyle: paragraph
        ]
        
        messageLabel.attributedText = NSAttributedString(string: message,
                                                         attributes: attributes)
        
        // run a fade action and add the labelto the scene
        messageLabel.run(SKAction.fadeIn(withDuration: 0.25))
        addChild(messageLabel)
    }
    
    func hideMessage() {
        if let messageLabel = childNode(withName: "//message") as? SKLabelNode {
            messageLabel.run(SKAction.sequence([
                SKAction.fadeOut(withDuration: 0.25),
                SKAction.removeFromParent()
            ]))
        }
    }

    // MARK: - TOUCH HANDLING
    
    func touchDown(atPoint pos: CGPoint) {
        if !gameInProgress {
            spawnMultipleGloops()
            return
        }
        
        let touchedNode = atPoint(pos)
        if touchedNode.name == "player" {
            movingPlayer = true
        }
    }
    
    func touchMoved(toPoint pos: CGPoint) {
        if movingPlayer == true {
            // clamp position
            let newPos = CGPoint(x: pos.x, y: player.position.y)
            player.position = newPos
            
            // check last position; if empty set it
            let recordedPosition = lastPosition ?? player.position
            player.xScale = recordedPosition.x > newPos.x ? -abs(xScale) : abs(xScale)
            
            // save last known position
            lastPosition = newPos
        }
    }
    
    func touchUp(atPoint pos: CGPoint) {
        movingPlayer = false
    }
     
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchDown(atPoint: t.location(in: self)) }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchMoved(toPoint: t.location(in: self)) }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }

    // MARK: - GAME FUNCTIONS

    func spawnMultipleGloops() {
        hideMessage()

        player.walk()

        if !gameInProgress {
            score = 0
            level = 1
        }
        
        // set number of drops based on the level
        switch level {
        case 1 ... 5: numberOfDrops = level * 10
        case 6: numberOfDrops = 75
        case 7: numberOfDrops = 100
        case 8: numberOfDrops = 150
        default: numberOfDrops = 150
        }
        
        dropsCollected = 0
        dropsExpected = numberOfDrops
        
        // set up drop speed
        dropSpeed = 1.0 / (CGFloat(level) + CGFloat(level) / CGFloat(numberOfDrops))
        dropSpeed = max(dropSpeed, minDropSpeed)
        dropSpeed = min(dropSpeed, maxDropSpeed)
        
        // set up repeating action
        let sequence = SKAction.sequence([
            SKAction.wait(forDuration: TimeInterval(dropSpeed)),
            SKAction.run { [unowned self] in self.spawnGloop() }
        ])
        let repeatAction = SKAction.repeat(sequence, count: numberOfDrops)
        
        // run action
        run(repeatAction, withKey: GloopActionKeys.gloop.rawValue)
        gameInProgress = true
    }
    
    func spawnGloop() {
        let collectible = Collectible(collectibleType: CollectibleType.gloop)
        
        // set random position
        let margin = collectible.size.width * 2
        let dropRange = SKRange(lowerLimit: frame.minX + margin,
                                upperLimit: frame.maxX - margin)
        let randomX = CGFloat.random(in: dropRange.lowerLimit ... dropRange.upperLimit)
        
        collectible.position = CGPoint(x: randomX, y: player.position.y * 2.5)
        addChild(collectible)
        collectible.drop(dropSpeed: TimeInterval(1.0), floorLevel: player.frame.minY)
    }
    
    func checkForRemainingDrops() {
        if dropsCollected == dropsExpected {
            nextLevel()
        }
    }
    
    func nextLevel() {
        showMessage("Get Ready!")

        run(SKAction.wait(forDuration: 2.25),
            completion: {
                [unowned self] in self.level += 1
                self.spawnMultipleGloops()
            })
    }
    
    // Player FAILED level
    func gameOver() {
        showMessage("Game Over\nTap to try again")

        gameInProgress = false
        player.die()

        print("removeAction(forKey: \(GloopActionKeys.gloop.rawValue))")
        removeAction(forKey: GloopActionKeys.gloop.rawValue)

        enumerateChildNodes(withName: "//co_*") {
            node, _ in
            node.removeAction(forKey: GloopActionKeys.drop.rawValue)
            node.physicsBody = nil
        }
        
        resetPlayerPosition()
        popRemainingDrops()
    }
    
    func resetPlayerPosition() {
        let resetPoint = CGPoint(x: frame.midX, y: player.position.y)
        let distance = hypot(resetPoint.x - player.position.x, 0.0)
        
        player.moveToPosition(pos: resetPoint,
                              direction: player.position.x > frame.midX ? .left : .right,
                              speed: TimeInterval(distance / (playerSpeed * 2)) / 255)
    }
    
    func popRemainingDrops() {
        var i = 0
        enumerateChildNodes(withName: "//co_*") {
            node, _ in
            
            let initialWait = SKAction.wait(forDuration: 1.0)
            let wait = SKAction.wait(forDuration: TimeInterval(0.15 * CGFloat(i)))
            
            let removeFromParent = SKAction.removeFromParent()
            let actionSequence = SKAction.sequence([initialWait, wait, removeFromParent])

            node.run(actionSequence)
            
            i += 1
        }
    }
}

// MARK: - COLLISION DETECTION

extension GameScene: SKPhysicsContactDelegate {
    func didBegin(_ contact: SKPhysicsContact) {
        // check collision bodies
        let collision = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        
        // did the [PLAYER] collide with the [COLLECTIBLE]?
        if collision == PhysicsCategory.player | PhysicsCategory.collectible {
            print("player hit collectible")
            
            let body = contact.bodyA.categoryBitMask == PhysicsCategory.collectible ?
                contact.bodyA.node :
                contact.bodyB.node
            
            if let sprite = body as? Collectible {
                sprite.collected()
                dropsCollected += 1
                score += level
                checkForRemainingDrops()
            }
        }
        
        if collision == PhysicsCategory.foreground | PhysicsCategory.collectible {
            print("collectible hit foreground")
            
            let body = contact.bodyA.categoryBitMask == PhysicsCategory.collectible ?
                contact.bodyA.node :
                contact.bodyB.node
            if let sprite = body as? Collectible {
                sprite.missed()
                gameOver()
            }
        }
    }
}
