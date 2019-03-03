import SpriteKit

enum SequenceType: CaseIterable {
    case one //, chain, fastChain
}

var compostList: [Int] = [2, 3, 7, 13, 16, 28]
var trashList: [Int] = [15,18,20,21,22,24,25,26,27,29,31]
var recycleList: [Int] = [0,1,5,6,8,9,10,14,17,23,28,32]
var electricList: [Int] = [4, 11, 12, 19, 30]

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    let gravity: CGFloat = -4.8
    let physicsSpeed: CGFloat = 0.90
    let topItemNumber = 27
    let outerBoundary: CGFloat = 400.0
    
    var touchpoint: CGPoint = CGPoint()
    var touching: Bool = false
    var movingItem = SKSpriteNode()
    
    var scoreLabel: SKLabelNode!
    var score = 0 {
        didSet {
            scoreLabel.text = "Score: \(score)"
        }
    }
    
    var livesImages = [SKSpriteNode]()
    var lives = 3
    
    var menuLabel: SKLabelNode!
    var menuUp: Bool = false {
        didSet {
            if menuUp {
                menuLabel.text = "Done"
            } else {
                menuLabel.text = "Menu"
            }
        }
    }
    
    var activeItems = [SKSpriteNode]()
    var popupTime = 3.0
    var sequence: [SequenceType]!
    var sequencePosition = 0
    var chainDelay = 4.0
    var fastChainSpeedUp = 1.5
    var nextSequenceQueued = true
    
    var gameEnded = false
    
    
    
    override func didMove(to view: SKView) {
        //createBackground()
        let backgroundSound = SKAudioNode(fileNamed: "mainmusic.mp3")
        self.addChild(backgroundSound)
        setupPhysics()
        createScore()
        createLives()
        createMenuButton()
        setUpSceneNodes()
        //makeBouncer(at: CGPoint(x: size.width/2, y: size.height/2))
        
        sequence = [.one, .one, .one]
        for _ in 0 ... 1000 {
            let nextSequence = SequenceType.allCases.randomElement()!
            sequence.append(nextSequence)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [unowned self] in
            self.tossItems()
        }
    }
    func drawPhysicsLine(touchpoint: CGPoint, endOfTouch: CGPoint, name: String) {
        let length = sqrt(pow(endOfTouch.x - touchpoint.x, 2) + pow(endOfTouch.y - touchpoint.y, 2))
        let height: CGFloat = 30
        let size = CGSize(width: length, height: height)
        let box = SKSpriteNode(color: UIColor(red: CGFloat.random(in: 0...1), green: CGFloat.random(in: 0...1), blue: CGFloat.random(in: 0...1), alpha: 1), size: size)
        box.zRotation = atan((endOfTouch.y - touchpoint.y)/(endOfTouch.x - touchpoint.x))
        box.position.x = (endOfTouch.x + touchpoint.x)/2
        box.position.y = (endOfTouch.y + touchpoint.y)/2
        
        box.physicsBody = SKPhysicsBody(rectangleOf: box.size)
        box.physicsBody?.isDynamic = false
        box.name = name
        
        addChild(box)
    }
    
    func setUpSceneNodes() {
        //    private var trashBottom : SKSpriteNode?
        //    private var trashCanTop : SKSpriteNode?
        //    private var trashBoundary : SKSpriteNode?
        //    private var trashDestroy : SKSpriteNode?
        //    private var compostBottom : SKSpriteNode?
        //    private var compostTop : SKSpriteNode?
        //    private var compostBoundary : SKSpriteNode?
        //    private var compostDestroy : SKSpriteNode?
        //    private var recycleBottom : SKSpriteNode?
        //    private var recycleTop : SKSpriteNode?
        //    private var recycleBoundary : SKSpriteNode?
        //    private var recycleDestroy : SKSpriteNode?
        //    private var electricBottom : SKSpriteNode?
        //    private var electricTop : SKSpriteNode?
        //    private var electricBoundary : SKSpriteNode?
        //    private var electricDestroy : SKSpriteNode?
        
        drawPhysicsLine(touchpoint: CGPoint(x: 21, y: 1007), endOfTouch: CGPoint(x: -203, y: 818), name: "trashBoundary")
        drawPhysicsLine(touchpoint: CGPoint(x: -203, y: 818), endOfTouch: CGPoint(x: -55, y: 617), name: "trashDestroy")
        drawPhysicsLine(touchpoint: CGPoint(x: -55, y: 617), endOfTouch: CGPoint(x: 194, y: 771), name: "trashBoundary")
        
        drawPhysicsLine(touchpoint: CGPoint(x: 45, y: 361), endOfTouch: CGPoint(x: -204, y: 154), name: "compostBoundary")
        drawPhysicsLine(touchpoint: CGPoint(x: -204, y: 154), endOfTouch: CGPoint(x: -48, y: -49), name: "compostDestroy")
        drawPhysicsLine(touchpoint: CGPoint(x: -48, y: -49), endOfTouch: CGPoint(x: 229, y: 109), name: "compostBoundary")

        drawPhysicsLine(touchpoint: CGPoint(x: 818, y: 1022), endOfTouch: CGPoint(x: 1046, y: 817), name: "recycleBoundary")
        drawPhysicsLine(touchpoint: CGPoint(x: 1046, y: 817), endOfTouch: CGPoint(x: 901, y: 620), name: "recycleDestroy")
        drawPhysicsLine(touchpoint: CGPoint(x: 901, y: 620), endOfTouch: CGPoint(x: 634, y: 781), name: "recycleBoundary")

        drawPhysicsLine(touchpoint: CGPoint(x: 800, y: 348), endOfTouch: CGPoint(x: 1022, y: 144), name: "electricBoundary")
        drawPhysicsLine(touchpoint: CGPoint(x: 1022, y: 144), endOfTouch: CGPoint(x: 874, y: -45), name: "electricDestroy")
        drawPhysicsLine(touchpoint: CGPoint(x: 874, y: -45), endOfTouch: CGPoint(x: 625, y: 108), name: "electricBoundary")

        
        
    }
    func makeBouncer(at position: CGPoint) {
        let bouncer = SKSpriteNode(imageNamed: "bouncer")
        bouncer.position = position
        bouncer.physicsBody = SKPhysicsBody(circleOfRadius: bouncer.size.width / 2.0)
        bouncer.physicsBody?.isDynamic = false
        addChild(bouncer)
    }
    
    func makeSlot(at position: CGPoint, isGood: Bool) {
        var slotBase: SKSpriteNode
        var slotGlow: SKSpriteNode
        
        if isGood {
            slotBase = SKSpriteNode(imageNamed: "slotBaseGood")
            slotGlow = SKSpriteNode(imageNamed: "slotGlowGood")
            slotBase.name = "good"
        } else {
            slotBase = SKSpriteNode(imageNamed: "slotBaseBad")
            slotGlow = SKSpriteNode(imageNamed: "slotGlowBad")
            slotBase.name = "bad"
        }
        
        slotBase.position = position
        slotGlow.position = position
        slotGlow.zPosition = -0.9
        
        slotBase.physicsBody = SKPhysicsBody(rectangleOf: slotBase.size)
        slotBase.physicsBody?.isDynamic = false
        
        addChild(slotBase)
        addChild(slotGlow)
        
        let spin = SKAction.rotate(byAngle: .pi, duration: 10)
        let spinForever = SKAction.repeatForever(spin)
        slotGlow.run(spinForever)
    }
    
    func createBackground() {
        let background = SKSpriteNode(imageNamed: "background@2x.jpg")
        background.position = CGPoint(x: size.width/2, y: size.height/2)
        background.blendMode = .replace
        background.scale(to: CGSize(width: size.width, height: size.height))
        background.zPosition = -1
        addChild(background)
    }
    
    func setupPhysics() {
        physicsWorld.contactDelegate = self
        physicsWorld.gravity = CGVector(dx: 0, dy: gravity)
        physicsWorld.speed = physicsSpeed
    }
    
    func createScore() {
        scoreLabel = SKLabelNode(fontNamed: "Impact")
        scoreLabel.text = "Score: 0"
        scoreLabel.horizontalAlignmentMode = .left
        scoreLabel.fontSize = 48
        
        addChild(scoreLabel)
        
        scoreLabel.position = CGPoint(x: 70, y: size.height-100)
    }
    
    func createLives() {
        for i in 0 ..< 3 {
            let spriteNode = SKSpriteNode(imageNamed: "sliceLife")
            spriteNode.position = CGPoint(x: size.width - CGFloat(50 + (i * 70)), y: size.height - 100)
            addChild(spriteNode)
            
            livesImages.append(spriteNode)
        }
    }
    
    func subtractLife() {
        lives -= 1
        
        //run(SKAction.playSoundFileNamed("wrong.caf", waitForCompletion: false))
        
        var life: SKSpriteNode
        
        if lives == 2 {
            life = livesImages[0]
        } else if lives == 1 {
            life = livesImages[1]
        } else {
            life = livesImages[2]
            endGame()
        }
        
        life.texture = SKTexture(imageNamed: "sliceLifeGone")
        
        life.xScale = 1.3
        life.yScale = 1.3
        life.run(SKAction.scale(to: 1, duration:0.1))
    }
    
    func endGame() {
        if gameEnded {
            return
        }
        
        gameEnded = true
        physicsWorld.speed = 0
        isUserInteractionEnabled = false
        
        //        if bombSoundEffect != nil {
        //            bombSoundEffect.stop()
        //            bombSoundEffect = nil
        //        }
        //
        //        if triggeredByBomb {
        //            livesImages[0].texture = SKTexture(imageNamed: "sliceLifeGone")
        //            livesImages[1].texture = SKTexture(imageNamed: "sliceLifeGone")
        //            livesImages[2].texture = SKTexture(imageNamed: "sliceLifeGone")
        //        }
    }
    
    func createMenuButton() {
        menuLabel = SKLabelNode(fontNamed: "Impact")
        menuLabel.text = "Menu"
        menuLabel.position = CGPoint(x: 50, y: size.height-150)
        addChild(menuLabel)
    }
    
    func tossItems() {
        if gameEnded {
            return
        }
        popupTime *= 0.991
        chainDelay *= 0.999
        physicsWorld.speed *= 1.001
        
        let sequenceType = sequence![sequencePosition]
        
        switch sequenceType {
        case .one:
            createEnemy()
            
//        case .chain:
//            createEnemy()
//            
//            DispatchQueue.main.asyncAfter(deadline: .now() + (chainDelay)) { [unowned self] in self.createEnemy() }
//            DispatchQueue.main.asyncAfter(deadline: .now() + (chainDelay * 2.0)) { [unowned self] in self.createEnemy() }
//            DispatchQueue.main.asyncAfter(deadline: .now() + (chainDelay * 3.0)) { [unowned self] in self.createEnemy() }
//            DispatchQueue.main.asyncAfter(deadline: .now() + (chainDelay * 4.0)) { [unowned self] in self.createEnemy() }
//            
//        case .fastChain:
//            createEnemy()
//            
//            DispatchQueue.main.asyncAfter(deadline: .now() + (chainDelay/fastChainSpeedUp)) { [unowned self] in self.createEnemy() }
//            DispatchQueue.main.asyncAfter(deadline: .now() + (chainDelay/fastChainSpeedUp * 2.0)) { [unowned self] in self.createEnemy() }
//            DispatchQueue.main.asyncAfter(deadline: .now() + (chainDelay/fastChainSpeedUp * 3.0)) { [unowned self] in self.createEnemy() }
//            DispatchQueue.main.asyncAfter(deadline: .now() + (chainDelay/fastChainSpeedUp * 4.0)) { [unowned self] in self.createEnemy() }
        }
        
        sequencePosition += 1
        nextSequenceQueued = false
    }
    
    func createEnemy() {
        let itemType = Int.random(in: 0..<topItemNumber)
        let imageName = "item\(itemType)"
        let item: SKSpriteNode = SKSpriteNode(imageNamed: imageName)
        item.scale(to: CGSize(width: 200, height: 200*item.size.height/item.size.width))
        if(item.size.height > 280) {
            item.scale(to: CGSize(width: 125, height: 125*item.size.height/item.size.width))
        }
        if(item.size.height < 180 && item.size.width < 180) {
            item.scale(to: CGSize(width: item.size.width*1.5, height: item.size.width*1.5))
        }
        
        //run(SKAction.playSoundFileNamed("launch.caf", waitForCompletion: false))
        
        // 1
        let randomPosition = CGPoint(x: CGFloat.random(in: size.width/10...9*size.width/10), y: size.height+10)
        item.position = randomPosition
        
        // 2
        let randomAngularVelocity = CGFloat.random(in: -6...6) / 2.0
        var randomXVelocity = 0
        
        // 3
        if randomPosition.x < size.width/4 {
            randomXVelocity = Int.random(in: 8...15)
        } else if randomPosition.x < 2*size.width/4 {
            randomXVelocity = Int.random(in: 3...5)
        } else if randomPosition.x < 3*size.width/4 {
            randomXVelocity = -Int.random(in: 3...5)
        } else {
            randomXVelocity = -Int.random(in: 8...15)
        }
        
        // 4
        let randomYVelocity = 0
        
        // 5
        item.physicsBody = SKPhysicsBody(texture: SKTexture(imageNamed: "penguin"), size: item.size)
        item.physicsBody?.velocity = CGVector(dx: randomXVelocity * 40, dy: randomYVelocity * 40)
        item.physicsBody?.angularVelocity = randomAngularVelocity
        //item.physicsBody?.collisionBitMask = 0x01
        item.physicsBody!.contactTestBitMask = item.physicsBody!.collisionBitMask
        item.physicsBody?.restitution = 0.4
        if(compostList.contains(itemType)) {
          item.name = "compost"
        } else if(trashList.contains(itemType)) {
            item.name = "trash"
        } else if(recycleList.contains(itemType)) {
            item.name = "recycle"
        } else if(electricList.contains(itemType)) {
            item.name = "electric"
        }
        
        addChild(item)
        activeItems.append(item)
    }
    
    func collisionBetween(item: SKNode, object: SKNode) {
        var match = false
        switch object.name {
        case "trashDestroy":
            if item.name == "trash" {
                score += 1
                match = true
            }
            else {
                subtractLife()
            }
        case "compostDestroy":
            if item.name == "compost" {
                score += 1
                match = true
            }
            else {
                subtractLife()
            }
        case "recycleDestroy":
            if item.name == "recycle" {
                score += 1
                match = true
            }
            else {
                subtractLife()
            }
        case "electricDestroy":
            if item.name == "electric" {
                score += 1
                match = true
            }
            else {
                subtractLife()
            }
        default:
            return
        }
        
        destroy(item: item, successfully: match)
        
    }
    
    func destroy(item: SKNode, successfully: Bool) {
        if let fireParticles = SKEmitterNode(fileNamed: "FireParticles") {
            fireParticles.position = item.position
            addChild(fireParticles)
        }
        item.removeFromParent()
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        guard let nodeA = contact.bodyA.node else {return}
        guard let nodeB = contact.bodyB.node else {return}

        if let name = contact.bodyA.node?.name {
            if name.count < 10 {
                collisionBetween(item: nodeA, object: nodeB)
                return
            } else {
            }
        }
        if let name = contact.bodyB.node?.name {
            if name.count < 10 {
                collisionBetween(item: nodeB, object: nodeA)
            } else {
                return
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        touching = false
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let location = touch.location(in: self)
            for item in activeItems {
                if item.frame.contains(location) {
                    touching = true
                    touchpoint = location
                    movingItem = item
                }
            }
            
            let objects = nodes(at: location)
            if objects.contains(menuLabel) {
                menuUp = !menuUp
            } else {
                if !menuUp {
                    //                    let ball = SKSpriteNode(imageNamed: "ballRed")
                    //                    ball.physicsBody = SKPhysicsBody(circleOfRadius: ball.size.width / 2.0)
                    //                    ball.physicsBody!.contactTestBitMask = ball.physicsBody!.collisionBitMask
                    //                    ball.physicsBody?.restitution = 0.4
                    //                    ball.position = location
                    //                    ball.name = "ball"
                    //                    addChild(ball)
                }
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        touchpoint = location
    }
    
    override func update(_ currentTime: TimeInterval) {
        if touching {
            let dt:CGFloat = 1.0/60.0
            let distance = CGVector(dx: touchpoint.x-movingItem.position.x, dy: touchpoint.y-movingItem.position.y)
            let velocity = CGVector(dx: distance.dx/dt*3/4, dy: distance.dy/dt*3/4)
            movingItem.physicsBody!.velocity=velocity
        }
        
        for node in activeItems {
            if node.position.y < -outerBoundary || node.position.x < -outerBoundary || node.position.x > size.width + outerBoundary {
                
                node.removeAllActions()
                node.name = ""
                subtractLife()
                
                node.removeFromParent()
                
                if let index = activeItems.index(of: node) {
                    activeItems.remove(at: index)
                }
            }
        }
        
        if !nextSequenceQueued {
            DispatchQueue.main.asyncAfter(deadline: .now() + popupTime) { [unowned self] in
                self.tossItems()
            }
            nextSequenceQueued = true
        }
        
    }
}
