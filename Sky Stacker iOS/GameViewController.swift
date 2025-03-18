//
//  GameViewController.swift
//  Sky Stacker iOS
//
//  Created by Ian Castillo on 3/6/25.
//

import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Safely cast the view to SKView
        if let skView = self.view as? SKView {
            let scene = GameScene.newGameScene()
            skView.presentScene(scene)
            
            skView.ignoresSiblingOrder = true
            skView.showsFPS = true
            skView.showsNodeCount = true
        }
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused while the application was inactive.
        GameCenterManager.shared.authenticateLocalPlayer()
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
}
