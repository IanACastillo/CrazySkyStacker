//
//  GameScene.swift
//  Sky Stacker iOS
//
//  Created by Ian Castillo on 3/6/25.
//

import SpriteKit
import GameplayKit
import GameKit  // Needed for GKGameCenterControllerDelegate

class GameScene: SKScene, GKGameCenterControllerDelegate {
    
    // Declare new instance properties at the top of your GameScene class.
    var instructionsLabel: SKLabelNode?
    var gameStarted = false
    
    var blocksDroppedCount = 0
    
    var coinThreshold: Int = 50
    
    let viewModel = GameViewModel()
    var currentBlockNode: SKShapeNode?
    
    var lastCoinEffectScore: Int = 0
    
    // Camera node
    let cameraNode = SKCameraNode()
    
    // 3D Label containers for score and fails
    var scoreContainer: SKNode!
    var scoreMainLabel: SKLabelNode!
    var scoreShadowLabel: SKLabelNode!
    
    var failContainer: SKNode!
    var failMainLabel: SKLabelNode!
    var failShadowLabel: SKLabelNode!
    
    // Restart and Leaderboard UI containers
    var gameOverContainer: SKNode?
    var restartContainer: SKNode?
    var leaderboardContainer: SKNode?
    
    // Flag to track game over state
    var isGameOver = false
    
    // Define tangerine orange color (attractive color)
    let tangerine = SKColor(red: 1.0, green: 0.6, blue: 0.0, alpha: 1.0)
    
    override func didMove(to view: SKView) {
        // Show the title screen.
        showTitleScreen()
        
        // Show scrolling instructions.
        showInstructions()
        
        // Authenticate the local Game Center player
        GameCenterManager.shared.authenticateLocalPlayer()
        
        // Add background music to the camera so it persists across restarts
        let backgroundMusic = SKAudioNode(fileNamed: "background.mp3")
        backgroundMusic.autoplayLooped = true
        cameraNode.addChild(backgroundMusic)
        
        // Set a blue background and physics gravity
        backgroundColor = .blue
        physicsWorld.gravity = CGVector(dx: 0, dy: -9.8)
        
        // Setup camera and attach it to the scene
        camera = cameraNode
        cameraNode.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(cameraNode)
        
        // Setup dynamic clouds attached to camera
        setupParallaxBackground()
        
        // Setup 3D Score and Fail Label containers (hidden initially)
        setupScoreContainer()
        setupFailContainer()
        
        // Setup callbacks from the ViewModel
        viewModel.onScoreUpdate = { [weak self] score in
            self?.updateScoreLabel("Score: \(score)")
        }
        viewModel.onFailUpdate = { [weak self] fails in
            self?.updateFailLabel("Fails: \(fails)")
        }
        viewModel.onBlockDropped = { [weak self] block in
            self?.addBlockToScene(block: block)
            self?.updateCameraToFollowTop()
        }
        viewModel.onDroppedPiece = { [weak self] droppedBlock in
            if let droppedNode = self?.createBlockNode(for: droppedBlock) {
                droppedNode.physicsBody?.affectedByGravity = true
                self?.addChild(droppedNode)
            }
        }
        viewModel.onGameOver = { [weak self] finalScore in
            self?.gameOver(finalScore: finalScore)
        }
        
        // **Set up coin effect callback here:**
        viewModel.onCoinEffect = { [weak self] in
            guard let self = self else { return }
            let coinOrigin = self.currentBlockNode?.position ?? CGPoint(x: self.size.width / 2, y: self.size.height / 2)
            self.spawnCoinEffect(at: coinOrigin)
        }
        
        // Start game state
        viewModel.startGame()
        
        // Add the initial base block(s)
        for block in viewModel.getBlocks() {
            let node = createBlockNode(for: block)
            addChild(node)
        }
        
        // Add the moving block
        if let movingBlock = viewModel.getCurrentBlock() {
            currentBlockNode = createBlockNode(for: movingBlock)
            if let node = currentBlockNode {
                addChild(node)
            }
        }
    }
    
    func showTitleScreen() {
        // Create a container node for the title.
        let titleContainer = SKNode()
        titleContainer.position = CGPoint(x: size.width / 2, y: size.height / 2)
        titleContainer.zPosition = 10000  // Ensure it appears above all other nodes.
        addChild(titleContainer)
        
        // Use your custom Star Wars–style font.
        // Make sure you've added the font file (e.g., "Starjedi.ttf") to your project,
        // and that you've updated Info.plist with its name under "Fonts provided by application".
        let customFontName = "Starjedi"  // Replace with the exact name of your custom font.
        let fontSize: CGFloat = 80       // Adjust for the desired size.
        let textColor = SKColor.white    // Main text color.
        let shadowColor = SKColor.gray.withAlphaComponent(0.7)  // For a cool 3D effect.
        let shadowOffset = CGPoint(x: 4, y: -4)  // Adjust offset for your desired look.
        
        // Helper function to create a 3D-styled label using the custom font.
        func create3DTitleLabel(text: String) -> SKNode {
            let container = SKNode()
            
            // Shadow label for the 3D effect.
            let shadowLabel = SKLabelNode(fontNamed: customFontName)
            shadowLabel.text = text
            shadowLabel.fontSize = fontSize
            shadowLabel.fontColor = shadowColor
            shadowLabel.position = shadowOffset
            shadowLabel.zPosition = 0
            
            // Main label.
            let mainLabel = SKLabelNode(fontNamed: customFontName)
            mainLabel.text = text
            mainLabel.fontSize = fontSize
            mainLabel.fontColor = textColor
            mainLabel.position = CGPoint.zero
            mainLabel.zPosition = 1
            
            container.addChild(shadowLabel)
            container.addChild(mainLabel)
            return container
        }
        
        // Create three lines for the title.
        let line1 = create3DTitleLabel(text: "Crazy")
        let line2 = create3DTitleLabel(text: "Sky")
        let line3 = create3DTitleLabel(text: "Stacker")
        
        // Arrange the lines vertically with space between them.
        line1.position = CGPoint(x: 0, y: fontSize)
        line2.position = CGPoint(x: 0, y: 0)
        line3.position = CGPoint(x: 0, y: -fontSize)
        
        titleContainer.addChild(line1)
        titleContainer.addChild(line2)
        titleContainer.addChild(line3)
        
        // Animate the title: fade in, hold, then fade out and remove.
        titleContainer.alpha = 0
        let fadeIn = SKAction.fadeIn(withDuration: 1.0)
        let wait = SKAction.wait(forDuration: 2.0)
        let fadeOut = SKAction.fadeOut(withDuration: 1.0)
        let remove = SKAction.removeFromParent()
        let sequence = SKAction.sequence([fadeIn, wait, fadeOut, remove])
        titleContainer.run(sequence)
    }
    
    // MARK: - GKGameCenterControllerDelegate
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true) { [weak self] in
            print("Leaderboard dismissed – resuming game scene")
            DispatchQueue.main.async {
                self?.view?.isPaused = false
            }
        }
    }
    
    func showInstructions() {
        // Create an instruction label using your custom Star Wars–style font.
        let instructions = SKLabelNode(fontNamed: "Starjedi")  // Ensure this matches your custom font's name.
        instructions.text = "Start scrolling to begin"
        instructions.fontSize = 40
        instructions.fontColor = .white
        // Position it below the title screen (adjust as needed).
        instructions.position = CGPoint(x: size.width / 2, y: size.height / 2 - 150)
        instructions.zPosition = 10000  // Make sure it’s above all other nodes.
        addChild(instructions)
        instructionsLabel = instructions
        
        // Add a blinking effect to attract attention.
        let fadeOut = SKAction.fadeAlpha(to: 0.3, duration: 0.8)
        let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: 0.8)
        let blink = SKAction.sequence([fadeOut, fadeIn])
        instructions.run(SKAction.repeatForever(blink))
    }
    
    // MARK: - 3D Label Helper Function
    func create3DLabel(withText text: String, fontSize: CGFloat) -> SKNode {
        let container = SKNode()
        let shadowLabel = SKLabelNode(fontNamed: "Arial")
        shadowLabel.fontSize = fontSize
        shadowLabel.fontColor = .black
        shadowLabel.horizontalAlignmentMode = .center
        shadowLabel.text = text
        shadowLabel.position = CGPoint(x: -3, y: 0)
        
        let mainLabel = SKLabelNode(fontNamed: "Arial")
        mainLabel.fontSize = fontSize
        mainLabel.fontColor = tangerine
        mainLabel.horizontalAlignmentMode = .center
        mainLabel.text = text
        mainLabel.position = .zero
        
        container.addChild(shadowLabel)
        container.addChild(mainLabel)
        return container
    }
    
    // MARK: - Setup Score and Fail Containers
    func setupScoreContainer() {
        let container = create3DLabel(withText: "Score: 0", fontSize: 36)
        container.position = CGPoint(x: 0, y: -(size.height/2) + 80)
        container.isHidden = true
        scoreContainer = container
        
        if let shadow = container.children.first as? SKLabelNode,
           container.children.count >= 2,
           let main = container.children[1] as? SKLabelNode {
            scoreShadowLabel = shadow
            scoreMainLabel = main
        }
        cameraNode.addChild(scoreContainer)
    }
    
    func setupFailContainer() {
        let container = create3DLabel(withText: "Fails: 0", fontSize: 36)
        container.position = CGPoint(x: 0, y: -(size.height/2) + 40)
        container.isHidden = true
        failContainer = container
        
        if let shadow = container.children.first as? SKLabelNode,
           container.children.count >= 2,
           let main = container.children[1] as? SKLabelNode {
            failShadowLabel = shadow
            failMainLabel = main
        }
        cameraNode.addChild(failContainer)
    }
    
    func updateScoreLabel(_ text: String) {
        scoreMainLabel.text = text
        scoreShadowLabel.text = text
    }
    
    func updateFailLabel(_ text: String) {
        failMainLabel.text = text
        failShadowLabel.text = text
    }
    
    // MARK: - Dynamic Clouds Attached to Camera
    func setupParallaxBackground() {
        let margin: CGFloat = 20.0
        
        let cloud1 = SKSpriteNode(imageNamed: "cloud1")
        cloud1.setScale(4.0)
        cloud1.alpha = 0.8
        cloud1.zPosition = 1000
        let effectiveWidth1 = cloud1.size.width * cloud1.xScale
        let effectiveHeight1 = cloud1.size.height * cloud1.yScale
        cloud1.position = CGPoint(
            x: -size.width / 2 + effectiveWidth1 / 2 + margin,
            y: size.height / 2 - effectiveHeight1 / 2 - margin
        )
        cameraNode.addChild(cloud1)
        
        let cloud1Oscillate = SKAction.sequence([
            SKAction.moveBy(x: 30, y: 0, duration: 5),
            SKAction.moveBy(x: -30, y: 0, duration: 5)
        ])
        cloud1.run(SKAction.repeatForever(cloud1Oscillate))
    }
    
    // MARK: - Block Node Management
    func createBlockNode(for block: Block) -> SKShapeNode {
        // Calculate a corner radius (adjust the multiplier for desired rounding)
        let cornerRadius = min(block.size.width, block.size.height) * 0.3
        let node = SKShapeNode(rectOf: block.size, cornerRadius: cornerRadius)
        
        // Set fill color to your tangerine and add a white stroke for the rounded corners
        node.fillColor = tangerine
        node.strokeColor = .white
        node.lineWidth = 4  // Adjust as needed for a thicker or thinner white outline
        
        node.position = block.position
        
        // Set up the physics body similar to before
        node.physicsBody = SKPhysicsBody(rectangleOf: block.size)
        node.physicsBody?.affectedByGravity = false
        return node
    }
    
    func addBlockToScene(block: Block) {
        let node = createBlockNode(for: block)
        addChild(node)
    }
    
    // MARK: - Camera & Game Over Handling
    func updateCameraToFollowTop() {
        if let topBlock = viewModel.getBlocks().last {
            let newCameraY = topBlock.position.y + 100
            let moveAction = SKAction.moveTo(y: newCameraY, duration: 0.3)
            cameraNode.run(moveAction)
        }
    }
    
    /// Creates a container with "Game Over!" and "Score: <finalScore>" labels.
    func createGameOverContainer(finalScore: Int, fontSize: CGFloat) -> SKNode {
        let container = SKNode()
        let gameOverLabelContainer = create3DLabel(withText: "Game Over!", fontSize: fontSize)
        let scoreLabelContainer = create3DLabel(withText: "Score: \(finalScore)", fontSize: fontSize)
        
        gameOverLabelContainer.position = CGPoint(x: 0, y: fontSize / 2 + 10)
        scoreLabelContainer.position = CGPoint(x: 0, y: -fontSize / 2 - 10)
        
        container.addChild(gameOverLabelContainer)
        container.addChild(scoreLabelContainer)
        return container
    }
    
    /// Called when the game ends.
    func gameOver(finalScore: Int) {
        isGameOver = true
        currentBlockNode?.removeFromParent()
        
        // Report the final score to Game Center.
        GameCenterManager.shared.reportScore(score: finalScore)
        // Optionally, report an achievement if the score meets a threshold.
        if finalScore >= 1000 {
            GameCenterManager.shared.reportAchievement()
        }
        
        // Create and add the Game Over container.
        let gameOverContainer = createGameOverContainer(finalScore: finalScore, fontSize: 36)
        gameOverContainer.position = CGPoint(x: 0, y: 20)
        cameraNode.addChild(gameOverContainer)
        self.gameOverContainer = gameOverContainer
        
        // Create and add the Restart button.
        let restartBtn = createRestartButton()
        restartBtn.position = CGPoint(x: 0, y: -50)
        cameraNode.addChild(restartBtn)
        self.restartContainer = restartBtn
        
        // Create and add the Leaderboard button.
        let leaderboardBtn = createLeaderboardButton()
        leaderboardBtn.position = CGPoint(x: 0, y: -120)
        cameraNode.addChild(leaderboardBtn)
        self.leaderboardContainer = leaderboardBtn
    }
    
    /// Creates a restart button.
    func createRestartButton() -> SKNode {
        let buttonSize = CGSize(width: 200, height: 60)
        let rect = CGRect(origin: CGPoint(x: -buttonSize.width / 2, y: -buttonSize.height / 2), size: buttonSize)
        
        let buttonShape = SKShapeNode(rect: rect, cornerRadius: 10)
        buttonShape.fillColor = .white
        buttonShape.strokeColor = tangerine
        buttonShape.lineWidth = 4
        buttonShape.zPosition = 1
        
        let label = SKLabelNode(fontNamed: "Arial")
        label.text = "Restart"
        label.fontSize = 36
        label.fontColor = tangerine
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.zPosition = 2
        buttonShape.addChild(label)
        
        let container = SKNode()
        if let shadow = buttonShape.copy() as? SKShapeNode {
            shadow.fillColor = .black
            shadow.strokeColor = .black
            shadow.alpha = 0.3
            shadow.position = CGPoint(x: -3, y: -3)
            shadow.zPosition = buttonShape.zPosition - 1
            container.addChild(shadow)
        }
        container.addChild(buttonShape)
        return container
    }
    
    /// Creates a leaderboard button.
    func createLeaderboardButton() -> SKNode {
        let buttonSize = CGSize(width: 300, height: 60)
        let rect = CGRect(origin: CGPoint(x: -buttonSize.width / 2, y: -buttonSize.height / 2), size: buttonSize)
        
        let buttonShape = SKShapeNode(rect: rect, cornerRadius: 10)
        buttonShape.fillColor = .white
        buttonShape.strokeColor = tangerine
        buttonShape.lineWidth = 4
        buttonShape.zPosition = 1
        
        let label = SKLabelNode(fontNamed: "Arial")
        label.text = "LeaderBoard"
        label.fontSize = 24
        label.fontColor = tangerine
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.zPosition = 2
        buttonShape.addChild(label)
        
        let container = SKNode()
        if let shadow = buttonShape.copy() as? SKShapeNode {
            shadow.fillColor = .black
            shadow.strokeColor = .black
            shadow.alpha = 0.3
            shadow.position = CGPoint(x: -3, y: -3)
            shadow.zPosition = buttonShape.zPosition - 1
            container.addChild(shadow)
        }
        container.addChild(buttonShape)
        return container
    }
    
    // MARK: - Orientation & UI Updates
    override func didChangeSize(_ oldSize: CGSize) {
        cameraNode.position = CGPoint(x: size.width/2, y: size.height/2)
        scoreContainer?.position = CGPoint(x: 0, y: -(size.height/2) + 80)
        failContainer?.position = CGPoint(x: 0, y: -(size.height/2) + 40)
        gameOverContainer?.position = CGPoint(x: 0, y: 20)
        restartContainer?.position = CGPoint(x: -100, y: -50)
        leaderboardContainer?.position = CGPoint(x: 100, y: -50)
    }
    
    
    
    func restartGame() {
        isGameOver = false
        
        // Remove all nodes except the camera
        for child in children {
            if child != cameraNode {
                child.removeFromParent()
            }
        }
        
        // Remove game over, restart, and leaderboard containers
        gameOverContainer?.removeFromParent()
        restartContainer?.removeFromParent()
        leaderboardContainer?.removeFromParent()
        gameOverContainer = nil
        restartContainer = nil
        leaderboardContainer = nil
        
        viewModel.startGame()
        updateScoreLabel("Score: 0")
        updateFailLabel("Fails: 0")
        
        setupParallaxBackground()
        
        for block in viewModel.getBlocks() {
            let node = createBlockNode(for: block)
            addChild(node)
        }
        
        if let movingBlock = viewModel.getCurrentBlock() {
            currentBlockNode = createBlockNode(for: movingBlock)
            addChild(currentBlockNode!)
        }
    }
    
    // MARK: - Update Loop & Touch Handling
    override func update(_ currentTime: TimeInterval) {
        let deltaTime = 1.0/60.0
        viewModel.updateCurrentBlock(deltaTime: deltaTime)
        if let movingBlock = viewModel.getCurrentBlock(), let node = currentBlockNode, !isGameOver {
            node.position = movingBlock.position
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        // When the player scrolls for the first time, remove the instructions.
        if !gameStarted {
            gameStarted = true
            instructionsLabel?.removeFromParent()
            // Optionally, reveal the score and fail labels here.
            scoreContainer.isHidden = false
            failContainer.isHidden = false
        }
        // You could also use scrolling to control other aspects of your game here.
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // If the game hasn't started yet, ignore tap input.
        if !gameStarted { return }
        
        guard let touch = touches.first, let _ = view else { return }
        let locationInCamera = touch.location(in: cameraNode)
        
        if isGameOver {
            // Handle restart and leaderboard taps.
            if let restartContainer = restartContainer, restartContainer.contains(locationInCamera) {
                restartGame()
                return
            }
            if let leaderboardContainer = leaderboardContainer, leaderboardContainer.contains(locationInCamera) {
                if let viewController = self.view?.window?.rootViewController {
                    self.view?.isPaused = true  // Pause the scene before presenting the leaderboard.
                    GameCenterManager.shared.showLeaderboard(from: viewController, delegate: self)
                }
                return
            }
            return
        }
        
        // The game is now running, so perform the block drop.
        viewModel.dropCurrentBlock()
        
        currentBlockNode?.removeFromParent()
        if let newBlock = viewModel.getCurrentBlock(), !isGameOver {
            currentBlockNode = createBlockNode(for: newBlock)
            addChild(currentBlockNode!)
        }
    }
    
    // MARK: - Scene Factory
    static func newGameScene() -> GameScene {
        let scene = GameScene(size: UIScreen.main.bounds.size)
        scene.scaleMode = .resizeFill
        return scene
    }
}


private extension GameScene {
    func spawnCoinEffect(at position: CGPoint) {
        // Play coin sound effect.
        run(SKAction.playSoundFileNamed("coinSound.mp3", waitForCompletion: false))
        
        // Spawn multiple coins for the explosion effect.
        for _ in 1...10 {
            let coin = SKSpriteNode(imageNamed: "coin")
            coin.position = position
            coin.zPosition = 5000  // Ensure coins appear above other game elements.
            coin.setScale(0.5)    // Adjust the scale as needed.
            addChild(coin)
            
            // Determine a random direction and distance.
            let angle = CGFloat.random(in: 0...2 * .pi)
            let distance = CGFloat.random(in: 100...200)
            let dx = cos(angle) * distance
            let dy = sin(angle) * distance
            
            // Animate the coin: move outward and fade out.
            let moveAction = SKAction.moveBy(x: dx, y: dy, duration: 0.8)
            let fadeOut = SKAction.fadeOut(withDuration: 0.8)
            let group = SKAction.group([moveAction, fadeOut])
            let remove = SKAction.removeFromParent()
            coin.run(SKAction.sequence([group, remove]))
        }
    }
    
}
