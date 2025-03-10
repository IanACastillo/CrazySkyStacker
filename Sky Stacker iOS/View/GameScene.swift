//
//  GameScene.swift
//  Sky Stacker iOS
//
//  Created by Ian Castillo on 3/6/25.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {
    
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
    
    // Restart UI containers (3D style)
    var gameOverContainer: SKNode?
    var restartContainer: SKNode?
    
    // Flag to track game over state
    var isGameOver = false
    
    // Define tangerine orange color (attractive color)
    let tangerine = SKColor(red: 1.0, green: 0.6, blue: 0.0, alpha: 1.0)
    
    override func didMove(to view: SKView) {
        // Set a blue background
        backgroundColor = .blue
        physicsWorld.gravity = CGVector(dx: 0, dy: -9.8)
        
        // Setup camera and attach it to the scene
        camera = cameraNode
        cameraNode.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(cameraNode)
        
        // Setup dynamic clouds attached to camera
        setupParallaxBackground()
        
        // Setup 3D Score Label container (hidden initially)
        setupScoreContainer()
        // Setup 3D Fail Label container (hidden initially)
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
    
    // MARK: - 3D Label Helper Function
    /// Creates a container node with a main label and a shadow label offset to the left.
    func create3DLabel(withText text: String, fontSize: CGFloat) -> SKNode {
        let container = SKNode()
        let shadowLabel = SKLabelNode(fontNamed: "Arial")
        shadowLabel.fontSize = fontSize
        shadowLabel.fontColor = .black
        shadowLabel.horizontalAlignmentMode = .center
        shadowLabel.text = text
        // Offset to the left (projected to the left)
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
        // Create container using the helper function
        let container = create3DLabel(withText: "Score: 0", fontSize: 36)
        container.position = CGPoint(x: 0, y: -(size.height/2) + 80)
        container.isHidden = true
        scoreContainer = container
        
        // Retrieve references to main and shadow labels for updating later
        // (Assumes first child is shadow and second is main)
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
    
    // Helper functions to update label texts
    func updateScoreLabel(_ text: String) {
        scoreMainLabel.text = text
        scoreShadowLabel.text = text
    }
    
    func updateFailLabel(_ text: String) {
        failMainLabel.text = text
        failShadowLabel.text = text
    }
    
    // MARK: - Dynamic Clouds Attached to Camera with Thunder Effect
    func setupParallaxBackground() {
        let margin: CGFloat = 20.0
        
        // Cloud 1: Attach one instance to the top-left of the camera view.
        let cloud1 = SKSpriteNode(imageNamed: "cloud1")
        cloud1.setScale(4.0)  // Scale 4 times bigger
        cloud1.alpha = 0.8
        cloud1.zPosition = 1000  // Ensure it appears on top
        // Calculate effective size after scaling
        let effectiveWidth1 = cloud1.size.width * cloud1.xScale
        let effectiveHeight1 = cloud1.size.height * cloud1.yScale
        // Position it at the top-left corner (relative to the camera's coordinate system)
        cloud1.position = CGPoint(
            x: -size.width / 2 + effectiveWidth1 / 2 + margin,
            y: size.height / 2 - effectiveHeight1 / 2 - margin
        )
        cameraNode.addChild(cloud1)
        
        // Add an oscillating animation for a subtle side-to-side movement
        let cloud1Oscillate = SKAction.sequence([
            SKAction.moveBy(x: 30, y: 0, duration: 5),
            SKAction.moveBy(x: -30, y: 0, duration: 5)
        ])
        cloud1.run(SKAction.repeatForever(cloud1Oscillate))
    }
    
    
    // MARK: - Orientation & UI Updates
    override func didChangeSize(_ oldSize: CGSize) {
        cameraNode.position = CGPoint(x: size.width/2, y: size.height/2)
        scoreContainer?.position = CGPoint(x: 0, y: -(size.height/2) + 80)
        failContainer?.position = CGPoint(x: 0, y: -(size.height/2) + 40)
        gameOverContainer?.position = CGPoint(x: 0, y: 20)
        restartContainer?.position = CGPoint(x: 0, y: -20)
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
    
    func createGameOverContainer(finalScore: Int, fontSize: CGFloat) -> SKNode {
        let container = SKNode()
        
        // Create the "Game Over!" 3D label container using your existing helper.
        let gameOverLabelContainer = create3DLabel(withText: "Game Over!", fontSize: fontSize)
        // Create the score 3D label container.
        let scoreLabelContainer = create3DLabel(withText: "Score: \(finalScore)", fontSize: fontSize)
        
        // Position the labels vertically (adjust spacing as needed)
        // For example, place "Game Over!" above and "Score: ..." below.
        gameOverLabelContainer.position = CGPoint(x: 0, y: fontSize / 2 + 10)
        scoreLabelContainer.position = CGPoint(x: 0, y: -fontSize / 2 - 10)
        
        container.addChild(gameOverLabelContainer)
        container.addChild(scoreLabelContainer)
        return container
    }

    func gameOver(finalScore: Int) {
        isGameOver = true
        currentBlockNode?.removeFromParent()
        
        // Create a container with two lines: "Game Over!" and "Score: <finalScore>"
        let gameOverContainer = createGameOverContainer(finalScore: finalScore, fontSize: 36)
        // Center the container in the camera view (adjust Y as needed)
        gameOverContainer.position = CGPoint(x: 0, y: 20)
        cameraNode.addChild(gameOverContainer)
        self.gameOverContainer = gameOverContainer
        
        // Create the restart button using your helper function.
        let restartBtn = createRestartButton()
        restartBtn.position = CGPoint(x: 0, y: -50)
        cameraNode.addChild(restartBtn)
        self.restartContainer = restartBtn
    }

    func restartGame() {
        isGameOver = false
        
        // Remove all nodes except the camera
        for child in children {
            if child != cameraNode {
                child.removeFromParent()
            }
        }
        
        // Remove game over and restart containers if they exist
        gameOverContainer?.removeFromParent()
        restartContainer?.removeFromParent()
        gameOverContainer = nil
        restartContainer = nil
        
        viewModel.startGame()
        updateScoreLabel("Score: 0")
        updateFailLabel("Fails: 0")
        
        // Re-add dynamic clouds attached to camera
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
        
        // If game is over, check if restart was tapped
        if isGameOver {
            let locationInCamera = touch.location(in: cameraNode)
            if let restartContainer = restartContainer,
               restartContainer.contains(locationInCamera) {
                restartGame()
            }
            return
        }
        
        // On first tap, unhide the 3D labels (score and fail)
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
    
    /// Creates a restart button with a rounded rectangle border (tangerine color) and white background, with “Restart” text in tangerine.
    /// A drop shadow is added for a 3D effect.
    func createRestartButton() -> SKNode {
        // Define the button size
        let buttonSize = CGSize(width: 200, height: 60)
        let rect = CGRect(origin: CGPoint(x: -buttonSize.width / 2, y: -buttonSize.height / 2), size: buttonSize)
        
        // Create the button shape with a rounded rectangle
        let buttonShape = SKShapeNode(rect: rect, cornerRadius: 10)
        buttonShape.fillColor = .white
        buttonShape.strokeColor = tangerine
        buttonShape.lineWidth = 4
        buttonShape.zPosition = 1
        
        // Create the restart label
        let label = SKLabelNode(fontNamed: "Arial")
        label.text = "Restart"
        label.fontSize = 36
        label.fontColor = tangerine
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.zPosition = 2
        buttonShape.addChild(label)
        
        // Create a container node and add a drop shadow for 3D effect
        let container = SKNode()
        
        // Create a shadow copy of the button shape
        if let shadow = buttonShape.copy() as? SKShapeNode {
            shadow.fillColor = .black
            shadow.strokeColor = .black
            shadow.alpha = 0.3
            // Offset the shadow to the bottom-left
            shadow.position = CGPoint(x: -3, y: -3)
            shadow.zPosition = buttonShape.zPosition - 1
            container.addChild(shadow)
        }
        
        container.addChild(buttonShape)
        return container
    }
    
}
