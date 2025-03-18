//
//  GameCenterManager.swift
//  Sky Stacker
//
//  Created by Ian Castillo on 3/17/25.
//

import UIKit
import GameKit

class GameCenterManager: NSObject {
    static let shared = GameCenterManager()
    
    // MARK: - Authentication
    
    func authenticateLocalPlayer() {
        let localPlayer = GKLocalPlayer.local
        
        localPlayer.authenticateHandler = { viewController, error in
            if let vc = viewController {
                // Present the Game Center authentication view controller using the active window scene
                if let windowScene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
                   let rootVC = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController {
                    rootVC.present(vc, animated: true, completion: nil)
                } else {
                    print("No active window scene available")
                }
            } else if localPlayer.isAuthenticated {
                print("Game Center: Player authenticated")
            } else {
                print("Game Center: Authentication failed, error: \(error?.localizedDescription ?? "unknown error")")
            }
        }
    }
    
    // MARK: - Leaderboards Integration
    
    /// Report a score to your leaderboard with ID "challengesoonskystacker"
    func reportScore(score: Int) {
        let leaderboardID = "challengesoonskystacker"
        
        // Load the leaderboard for the given identifier.
        GKLeaderboard.loadLeaderboards(IDs: [leaderboardID]) { leaderboards, error in
            if let error = error {
                print("Error loading leaderboard: \(error.localizedDescription)")
                return
            }
            
            guard let leaderboard = leaderboards?.first else {
                print("Leaderboard not found")
                return
            }
            
            // Submit the score using the new instance method.
            // Note: The method signature is: submitScore(_ score: Int, context: UInt64, player: GKPlayer, completionHandler: @escaping (Error?) -> Void)
            leaderboard.submitScore(Int(score), context: 0, player: GKLocalPlayer.local, completionHandler: { error in
                if let error = error {
                    print("Error submitting score: \(error.localizedDescription)")
                } else {
                    print("Score submitted successfully!")
                }
            })
        }
    }
    
    /// Present the Game Center leaderboard view controller
    func showLeaderboard(from viewController: UIViewController, delegate: GKGameCenterControllerDelegate) {
        let gcViewController = GKGameCenterViewController(leaderboardID: "challengesoonskystacker",
                                                          playerScope: .global,
                                                          timeScope: .allTime)
        gcViewController.gameCenterDelegate = delegate
        viewController.present(gcViewController, animated: true, completion: nil)
    }
    
    // MARK: - Achievements Integration
    
    /// Report the achievement with ID "1000pts" as complete.
    func reportAchievement() {
        let achievementID = "1000pts"
        let achievement = GKAchievement(identifier: achievementID)
        achievement.percentComplete = 100.0  // Mark achievement as complete
        achievement.showsCompletionBanner = true
        
        GKAchievement.report([achievement]) { error in
            if let error = error {
                print("Error reporting achievement: \(error.localizedDescription)")
            } else {
                print("Achievement reported successfully!")
            }
        }
    }
}
