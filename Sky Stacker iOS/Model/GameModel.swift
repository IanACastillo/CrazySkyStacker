//
//  GameModel.swift
//  Sky Stacker iOS
//
//  Created by Ian Castillo on 3/6/25.
//

import Foundation

class GameModel {
    var blocks: [Block] = []
    var currentBlock: Block?
    var score: Int = 0
    var failCount: Int = 0
}
