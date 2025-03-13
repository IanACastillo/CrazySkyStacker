//
//  GameViewModel.swift
//  Sky Stacker iOS
//
//  Created by Ian Castillo on 3/6/25.
//

import SpriteKit

class GameViewModel {
    
    private var model = GameModel()
    
    // Configuration for game difficulty and experience
    var blockMoveSpeed: CGFloat = 200.0     // Initial horizontal speed for moving block
    var blockDropSpeed: CGFloat = 400.0     // (Not used in this simple example)
    var initialBlockSize: CGSize = CGSize(width: 200, height: 40)
    
    // New properties to alternate block direction:
    var isNextBlockFromLeft: Bool = true
    var currentBlockDirection: CGFloat = 1.0  // 1.0 means moving right, -1.0 moving left
    
    // Callbacks for UI updates
    var onScoreUpdate: ((Int) -> Void)?
    var onFailUpdate: ((Int) -> Void)?
    var onBlockDropped: ((Block) -> Void)?
    var onDroppedPiece: ((Block) -> Void)?
    var onGameOver: ((Int) -> Void)?
    
    // Start or restart the game
    func startGame() {
        model.score = 0
        model.failCount = 0
        model.blocks = []
        
        // Reset alternating flag at game start
        isNextBlockFromLeft = true
        
        // Place the initial static block at the bottom
        let baseBlock = Block(size: initialBlockSize,
                              position: CGPoint(x: UIScreen.main.bounds.midX, y: 100),
                              node: nil)
        model.blocks.append(baseBlock)
        
        // Create the first moving block
        model.currentBlock = createMovingBlock()
        
        // Reset movement speed
        blockMoveSpeed = 200.0
    }
    
    // Create a new moving block positioned above the current stack
    func createMovingBlock() -> Block {
        let lastBlockY = model.blocks.last?.position.y ?? 100
        let newY = lastBlockY + initialBlockSize.height + 20
        let screenWidth = UIScreen.main.bounds.width
        var newBlock: Block
        
        if isNextBlockFromLeft {
            // Start at left side and move right
            newBlock = Block(size: initialBlockSize,
                             position: CGPoint(x: initialBlockSize.width / 2, y: newY),
                             node: nil)
            currentBlockDirection = 1.0
        } else {
            // Start at right side and move left
            newBlock = Block(size: initialBlockSize,
                             position: CGPoint(x: screenWidth - initialBlockSize.width / 2, y: newY),
                             node: nil)
            currentBlockDirection = -1.0
        }
        
        return newBlock
    }
    
    // Update the moving block's position each frame
    func updateCurrentBlock(deltaTime: TimeInterval) {
        guard var currentBlock = model.currentBlock else { return }
        
        // Multiply movement by the current direction
        let movement = CGFloat(deltaTime) * blockMoveSpeed * currentBlockDirection
        currentBlock.position.x += movement
        
        let screenWidth = UIScreen.main.bounds.width
        if currentBlockDirection > 0 {
            // When moving right: wrap around if it goes off the right edge
            if currentBlock.position.x - currentBlock.size.width / 2 > screenWidth {
                currentBlock.position.x = -currentBlock.size.width / 2
            }
        } else {
            // When moving left: wrap around if it goes off the left edge
            if currentBlock.position.x + currentBlock.size.width / 2 < 0 {
                currentBlock.position.x = screenWidth + currentBlock.size.width / 2
            }
        }
        
        model.currentBlock = currentBlock
    }
    
    // Called when the player taps to drop the block
    func dropCurrentBlock() {
        guard var currentBlock = model.currentBlock,
              let previousBlock = model.blocks.last else { return }
        
        // Calculate overlap between the current and previous block
        let currentMinX = currentBlock.position.x - currentBlock.size.width / 2
        let currentMaxX = currentBlock.position.x + currentBlock.size.width / 2
        let previousMinX = previousBlock.position.x - previousBlock.size.width / 2
        let previousMaxX = previousBlock.position.x + previousBlock.size.width / 2
        
        let overlapMinX = max(currentMinX, previousMinX)
        let overlapMaxX = min(currentMaxX, previousMaxX)
        let overlapWidth = max(0, overlapMaxX - overlapMinX)
        
        let perfectAlignmentThreshold: CGFloat = 10.0
        let isPerfect = abs(currentBlock.position.x - previousBlock.position.x) < perfectAlignmentThreshold
        
        let originalWidth = currentBlock.size.width
        
        if isPerfect {
            model.score += 10
            model.failCount = 0
        } else if overlapWidth > 0 {
            model.score += 1
            model.failCount += 1
            
            let droppedPieceWidth = originalWidth - overlapWidth
            if droppedPieceWidth > 0 {
                let droppedPieceSize = CGSize(width: droppedPieceWidth, height: currentBlock.size.height)
                var droppedPiecePosition = currentBlock.position
                if currentBlock.position.x < previousBlock.position.x {
                    // Overhang on left side
                    droppedPiecePosition.x = currentBlock.position.x - droppedPieceWidth / 2
                } else {
                    // Overhang on right side
                    droppedPiecePosition.x = currentBlock.position.x + droppedPieceWidth / 2
                }
                let droppedPiece = Block(size: droppedPieceSize,
                                         position: droppedPiecePosition,
                                         node: nil)
                onDroppedPiece?(droppedPiece)
            }
            
            // Trim the current block to the overlapping width
            currentBlock.size.width = overlapWidth
            
            if model.failCount >= 3 {
                onFailUpdate?(model.failCount)
                onScoreUpdate?(model.score)
                onGameOver?(model.score)
                return
            }
        } else {
            // No overlap, so the game is over
            onGameOver?(model.score)
            return
        }
        
        // Save the dropped (or trimmed) block
        model.blocks.append(currentBlock)
        onScoreUpdate?(model.score)
        onFailUpdate?(model.failCount)
        onBlockDropped?(currentBlock)
        
        updateDifficulty()
        
        // Toggle the starting side for the next block
        isNextBlockFromLeft.toggle()
        model.currentBlock = createMovingBlock()
    }
    
    // Increase the block movement speed based on score thresholds
    private func updateDifficulty() {
        if model.score >= 150 {
            blockMoveSpeed = 400.0
        }
        if model.score >= 500 {
            blockMoveSpeed = 800.0
        }
    }
    
    // Expose the current block for the view to render
    func getCurrentBlock() -> Block? {
        return model.currentBlock
    }
    
    // Expose all placed blocks for the view to render
    func getBlocks() -> [Block] {
        return model.blocks
    }
}

