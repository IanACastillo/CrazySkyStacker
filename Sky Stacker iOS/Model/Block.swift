//
//  Block.swift
//  Sky Stacker iOS
//
//  Created by Ian Castillo on 3/6/25.
//

import SpriteKit

struct Block {
    var size: CGSize
    var position: CGPoint
    // We hold a reference to the node if needed, but here it’s optional
    var node: SKSpriteNode?
}
