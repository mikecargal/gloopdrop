//
//  GameScene.swift
//  gloopdrop
//
//  Created by Mike Cargal on 1/3/21.
//

import AVFoundation
import GameplayKit
import SpriteKit

class GameScene: SKScene {
    let player = Player()
    let playerSpeed: CGFloat = 1.5
    
    let labelFont = "Nosifer"
    
    // player movement
    var movingPlayer = false
    var lastPosition: CGPoint?
    var prevDropLocation: CGFloat = 0.0
    
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
    
    // Audio Nodes
    let musicAudioNode = SKAudioNode(fileNamed: "music.mp3")
    let bubblesAudioNode = SKAudioNode(fileNamed: "bubbles.mp3")

    override func didMove(to view: SKView) {
        // set up the physics world contact delegate
        physicsWorld.contactDelegate = self
        
        // set up the background music audio node
        musicAudioNode.autoplayLooped = true
        musicAudioNode.isPositional = false
        // decrease the audio engine's volume
        audioEngine.mainMixerNode.outputVolume = 0.0
        addChild(musicAudioNode)
        musicAudioNode.run(SKAction.changeVolume(to: 0.0, duration: 0.0))
        run(SKAction.wait(forDuration: 1.0), completion: { [unowned self] in
            self.audioEngine.mainMixerNode.outputVolume = 1.0
            self.musicAudioNode.run(SKAction.changeVolume(to: 0.75, duration: 2.0))
        })
        
        // run a delayed action to add bubble audio to the scene
        run(SKAction.wait(forDuration: 1.5), completion: {
            [unowned self] in
            self.bubblesAudioNode.autoplayLooped = true
            self.bubblesAudioNode.run(SKAction.changeVolume(to: 0.3, duration: 0.0))
            self.addChild(self.bubblesAudioNode)
        })
        
        let background = SKSpriteNode(imageNamed: "background_1")
        background.name = "background"
        background.anchorPoint = CGPoint(x: 0, y: 0)
        background.position = CGPoint(x: 0, y: 0)
        background.zPosition = Layer.background.rawValue
        addChild(background)
        
        // set up foreground
        let foreground = SKSpriteNode(imageNamed: "foreground_1")
        foreground.name = "foreground"
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

        // set up the banner
        let banner = SKSpriteNode(imageNamed: "banner")
        banner.zPosition = Layer.banner.rawValue + 1
        banner.position = CGPoint(x: frame.midX, y: viewTop() - 20)
        banner.anchorPoint = CGPoint(x: 0.5, y: 1.0)
        addChild(banner)
        
        setupLabels()

        // Set up a plyer
        player.position = CGPoint(x: size.width / 2, y: foreground.frame.maxY)
        player.setupConstraints(floor: foreground.frame.maxY)
        prevDropLocation = CGFloat.random(in: marginRange())
        addChild(player)
        setupGloopFlow()
        setupStars()
        randomSpaceShip()
        
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
                                      green: 155.0 / 255,
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
        
        let touchedNodes = nodes(at: pos)
        for touchedNode in touchedNodes {
            if touchedNode.name == "player" {
                movingPlayer = true
            }
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
        for t in touches { touchDown(atPoint: t.location(in: self)) }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { touchMoved(toPoint: t.location(in: self)) }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { touchUp(atPoint: t.location(in: self)) }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { touchUp(atPoint: t.location(in: self)) }
    }

    // MARK: - GAME FUNCTIONS

    func spawnMultipleGloops() {
        hideMessage()

        player.mumble()
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
    
    func marginRange() -> ClosedRange<CGFloat> {
        let margin = Collectible(collectibleType: CollectibleType.gloop).size.width * 2
        let minX = frame.minX + margin
        let maxX = frame.maxX - margin
        return minX ... maxX
    }
    
    func spawnGloop() {
        let collectible = Collectible(collectibleType: CollectibleType.gloop)
        let margins = marginRange()

        let randomX = CGFloat.random(in: margins)
        
        let distance = min(CGFloat.random(in: 50 + CGFloat(level) ... 60 + CGFloat(level)), 400)
        
        let newDropLocation = prevDropLocation < randomX ?
            max(margins.lowerBound, prevDropLocation + distance) :
            min(margins.upperBound, prevDropLocation - distance)
        
        // add the number tag to the collectiondrop
        let xLabel = SKLabelNode()
        xLabel.name = "dropNumber"
        xLabel.fontName = "AvenirNext-DemiBold"
        xLabel.fontColor = UIColor.yellow
        xLabel.fontSize = 22.0
        xLabel.text = "\(numberOfDrops)"
        xLabel.position = CGPoint(x: 0, y: 2)
        collectible.addChild(xLabel)
        numberOfDrops -= 1
        
        collectible.position = CGPoint(x: newDropLocation, y: player.position.y * 2.5)
        prevDropLocation = newDropLocation
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

    func randomSpaceShip() {
        let spaceship = SKSpriteNode(imageNamed: "robot")
        spaceship.zPosition = Layer.foreground.rawValue
        let rightToLeft = Bool.random()
        let duration = TimeInterval(CGFloat.random(in: 5.0 ... 10.0))
        let offLeft = CGFloat(-spaceship.size.width)
        let offRight = CGFloat(frame.width + spaceship.size.width)
        
        let (start, stop) = rightToLeft ?
            (offLeft, offRight) :
            (offRight, offLeft)
        spaceship.position = CGPoint(x: start, y: frame.midY + spaceship.size.height)
        
        let audioNode = SKAudioNode(fileNamed: "robot.wav")
        audioNode.autoplayLooped = true
        audioNode.run(SKAction.changeVolume(to: 1.0, duration: 0.0))
        spaceship.addChild(audioNode)
        
        addChild(spaceship)
        let wobbleAngle = CGFloat.random(in: 0.0 ... 0.8)
        let wobbleDuration = TimeInterval(CGFloat.random(in: 0.5 ... 1.0))
        spaceship.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.rotate(byAngle: wobbleAngle, duration: wobbleDuration / 2),
            SKAction.rotate(byAngle: -wobbleAngle * 2, duration: wobbleDuration),
            SKAction.rotate(byAngle: wobbleAngle, duration: wobbleDuration / 2)
        ])))

        let vertChange = CGFloat.random(in: 10.0 ... 20.0)
        let vertDuration = TimeInterval(CGFloat.random(in: 0.25 ... 1.0))
        spaceship.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.moveBy(x: 0.0, y: vertChange, duration: vertDuration),
            SKAction.moveBy(x: 0.0, y: -vertChange, duration: vertDuration)
        ])))
        spaceship.run(SKAction.sequence([
            SKAction.moveTo(x: stop, duration: duration),
            SKAction.removeFromParent()
        ]), completion: {
            self.run(SKAction.sequence([
                SKAction.wait(forDuration: 30, withRange: 60),
                SKAction.run {
                    self.randomSpaceShip()
                }
            ]))
        })
    }
}

// MARK: - COLLISION DETECTION

extension GameScene: SKPhysicsContactDelegate {
    func didBegin(_ contact: SKPhysicsContact) {
        // check collision bodies
        let collision = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        
        // did the [PLAYER] collide with the [COLLECTIBLE]?
        if collision == PhysicsCategory.player | PhysicsCategory.collectible {
            let body = contact.bodyA.categoryBitMask == PhysicsCategory.collectible ?
                contact.bodyA.node :
                contact.bodyB.node
            
            if let sprite = body as? Collectible {
                sprite.collected()
                dropsCollected += 1
                score += level
                checkForRemainingDrops()
                
                // add the 'chomp' text at the player's position
                let chomp = SKLabelNode(fontNamed: "Nosifer")
                chomp.name = "chomp"
                chomp.alpha = 0.0
                chomp.fontSize = 22.0
                chomp.text = "gloop"
                chomp.horizontalAlignmentMode = .center
                chomp.verticalAlignmentMode = .bottom
                chomp.position = CGPoint(x: player.position.x, y: player.frame.maxY + 25)
                chomp.zRotation = CGFloat.random(in: -0.15 ... 0.15)
                addChild(chomp)
                
                // add actions to fade in, rise up, and fade out
                let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: 0.05)
                let moveAndFadeOut = SKAction.group([
                    SKAction.fadeAlpha(to: 0.0, duration: 0.45),
                    SKAction.moveBy(x: 0.0, y: 45, duration: 0.45)
                ])
                chomp.run(SKAction.sequence([fadeIn, moveAndFadeOut, SKAction.removeFromParent()]))
            }
        }
        
        if collision == PhysicsCategory.foreground | PhysicsCategory.collectible {
            let body = contact.bodyA.categoryBitMask == PhysicsCategory.collectible ?
                contact.bodyA.node :
                contact.bodyB.node
            if let sprite = body as? Collectible {
                sprite.missed()
                gameOver()
            }
        }
    }

    // MARK: - Gloop Flow & particle effects

    func setupGloopFlow() {
        let gloopFlow = SKNode()
        gloopFlow.name = "gloopFlow"
        gloopFlow.zPosition = Layer.foreground.rawValue
        gloopFlow.position = CGPoint(x: 0.0, y: -60)
        gloopFlow.setupScollingView(imageNamed: "flow_1",
                                    layer: Layer.foreground,
                                    emitterNamed: "GloopFlow.sks",
                                    blocks: 3,
                                    speed: 30.0)
        addChild(gloopFlow)
    }
    
    func setupStars() {
        if let stars = SKEmitterNode(fileNamed: "Stars.sks") {
            stars.name = "stars"
            stars.zPosition = Layer.foreground.rawValue
            stars.position = CGPoint(x: frame.midX, y: frame.midY)
            addChild(stars)
        }
    }
}
