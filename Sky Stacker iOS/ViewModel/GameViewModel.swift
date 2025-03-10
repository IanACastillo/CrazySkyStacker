import SpriteKit

class GameViewModel {
    
    private var model = GameModel()
    
    // Configuration for game difficulty and experience
    var blockMoveSpeed: CGFloat = 200.0     // Initial horizontal speed for moving block
    var blockDropSpeed: CGFloat = 400.0     // Not used in this simple example but can affect physics
    var initialBlockSize: CGSize = CGSize(width: 200, height: 40)
    
    // Callbacks to update the view (e.g., score, new blocks, dropped pieces, fails, and game over)
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
        // Place the initial static block at the bottom of the screen
        let baseBlock = Block(size: initialBlockSize,
                              position: CGPoint(x: UIScreen.main.bounds.midX, y: 100),
                              node: nil)
        model.blocks.append(baseBlock)
        // Create the first moving block
        model.currentBlock = createMovingBlock()
        
        // Reset speed on game start
        blockMoveSpeed = 200.0
    }
    
    // Create a new moving block positioned above the current stack
    func createMovingBlock() -> Block {
        let lastBlockY = model.blocks.last?.position.y ?? 100
        let newY = lastBlockY + initialBlockSize.height + 20
        // Start from the left edge (will move horizontally)
        return Block(size: initialBlockSize,
                     position: CGPoint(x: initialBlockSize.width/2, y: newY),
                     node: nil)
    }
    
    // Update the moving block's position; to be called every frame
    func updateCurrentBlock(deltaTime: TimeInterval) {
        guard var currentBlock = model.currentBlock else { return }
        // Move block horizontally based on time elapsed
        let movement = CGFloat(deltaTime) * blockMoveSpeed
        currentBlock.position.x += movement
        // Wrap around when reaching the right edge
        let screenWidth = UIScreen.main.bounds.width
        if currentBlock.position.x - currentBlock.size.width/2 > screenWidth {
            currentBlock.position.x = -currentBlock.size.width/2
        }
        model.currentBlock = currentBlock
    }
    
    // Called when the player taps to drop the block
    func dropCurrentBlock() {
        guard var currentBlock = model.currentBlock,
              let previousBlock = model.blocks.last else { return }
        
        // Calculate overlap between current block and previous block
        let currentMinX = currentBlock.position.x - currentBlock.size.width / 2
        let currentMaxX = currentBlock.position.x + currentBlock.size.width / 2
        let previousMinX = previousBlock.position.x - previousBlock.size.width / 2
        let previousMaxX = previousBlock.position.x + previousBlock.size.width / 2
        
        let overlapMinX = max(currentMinX, previousMinX)
        let overlapMaxX = min(currentMaxX, previousMaxX)
        let overlapWidth = max(0, overlapMaxX - overlapMinX)
        
        // Define a threshold for a "perfect" drop
        let perfectAlignmentThreshold: CGFloat = 10.0
        let isPerfect = abs(currentBlock.position.x - previousBlock.position.x) < perfectAlignmentThreshold
        
        // Save the original width to calculate any extra (dropped) piece
        let originalWidth = currentBlock.size.width
        
        if isPerfect {
            // Perfect drop: reward extra points and reset fail counter
            model.score += 10
            model.failCount = 0
        } else if overlapWidth > 0 {
            // Partial drop: update score and count as a failure attempt
            model.score += 1
            model.failCount += 1
            
            // Calculate dropped piece dimensions if any extra part exists
            let droppedPieceWidth = originalWidth - overlapWidth
            if droppedPieceWidth > 0 {
                let droppedPieceSize = CGSize(width: droppedPieceWidth, height: currentBlock.size.height)
                var droppedPiecePosition = currentBlock.position
                // Determine which side is overhanging
                if currentBlock.position.x < previousBlock.position.x {
                    // Overhang on left side
                    droppedPiecePosition.x = currentBlock.position.x - droppedPieceWidth/2
                } else {
                    // Overhang on right side
                    droppedPiecePosition.x = currentBlock.position.x + droppedPieceWidth/2
                }
                let droppedPiece = Block(size: droppedPieceSize,
                                         position: droppedPiecePosition,
                                         node: nil)
                // Trigger callback to animate the falling extra piece
                onDroppedPiece?(droppedPiece)
            }
            
            // Trim the current block to the overlapping width
            currentBlock.size.width = overlapWidth
            
            // Check if the player has reached 3 fails
            if model.failCount >= 3 {
                onFailUpdate?(model.failCount)
                onScoreUpdate?(model.score)
                onGameOver?(model.score)
                return  // Do not create a new block if game is over
            }
        } else {
            // No overlap: immediate game over
            onGameOver?(model.score)
            return
        }
        
        // Save the dropped (or trimmed) block and update callbacks
        model.blocks.append(currentBlock)
        onScoreUpdate?(model.score)
        onFailUpdate?(model.failCount)
        onBlockDropped?(currentBlock)
        
        // Update dynamic difficulty based on score
        updateDifficulty()
        
        // Prepare the next moving block only if game isn't over
        model.currentBlock = createMovingBlock()
    }
    
    // Increase the block movement speed once a certain score threshold is reached
    private func updateDifficulty() {
        // If the score reaches 250, increase the movement speed
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
