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
    
    let viewModel = GameViewModel()
    var currentBlockNode: SKSpriteNode?
    
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
        // Authenticate the local Game Center player
        GameCenterManager.shared.authenticateLocalPlayer()
        
        // Add background music to the camera so it persists across restarts
        let backgroundMusic = SKAudioNode(fileNamed: "background.mp3")
        backgroundMusic.autoplayLooped = true
        cameraNode.addChild(backgroundMusic)
        
        // Set a blue background
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

    // MARK: - GKGameCenterControllerDelegate
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true) { [weak self] in
            print("Leaderboard dismissed – resuming game scene")
            DispatchQueue.main.async {
                self?.view?.isPaused = false
            }
        }
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
    func createBlockNode(for block: Block) -> SKSpriteNode {
        let node = SKSpriteNode(color: tangerine, size: block.size)
        node.position = block.position
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
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let _ = view else { return }
        let locationInCamera = touch.location(in: cameraNode)
        
        if isGameOver {
            // Check if the restart button was tapped.
            if let restartContainer = restartContainer, restartContainer.contains(locationInCamera) {
                restartGame()
                return
            }
            // Check if the leaderboard button was tapped.
            if let leaderboardContainer = leaderboardContainer, leaderboardContainer.contains(locationInCamera) {
                if let viewController = self.view?.window?.rootViewController {
                    self.view?.isPaused = true  // Pause the scene before presenting the leaderboard
                    GameCenterManager.shared.showLeaderboard(from: viewController, delegate: self)
                }
                return
            }
            return
        }
        
        // On first tap, unhide the 3D labels.
        if scoreContainer.isHidden {
            scoreContainer.isHidden = false
            failContainer.isHidden = false
        }
        
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
