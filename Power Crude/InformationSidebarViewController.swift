//
//  InformationSidebarViewController.swift
//  Power Crude
//
//  Created by William Everett on 1/10/20.
//  Copyright © 2020 William Everett. All rights reserved.
//

import Cocoa

class InformationSidebarViewController: NSViewController {

    @IBOutlet weak var playerTextView : NSTextView!
    var notificationObject : NSObjectProtocol? = nil
    
    var gameState : GameState? = nil {
        didSet {
            refreshPlayerInformation()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        refreshPlayerInformation()
        
        weak var weakSelf = self
        self.notificationObject = NotificationCenter.default.addObserver(forName: GameState.kGameStateChangedNotification, object: gameState, queue: nil, using: {_ in
            if weakSelf?.gameState != nil {
                weakSelf?.refreshPlayerInformation()
            }
        })
    }
    
    deinit {
        if notificationObject != nil {
            NotificationCenter.default.removeObserver(notificationObject!)
        }
    }
    
    func refreshPlayerInformation() {
        guard let nonNilGameState = gameState else {
            playerTextView.string = ""
            return
        }
        
        let displayString = NSMutableAttributedString()
        
        nonNilGameState.playerOrder.forEach( {
            let player = nonNilGameState.players[$0]!
            
            displayString.append(NSAttributedString(string: "Player \(player.playerNumber)\n", attributes: [.font:NSFont.boldSystemFont(ofSize: 20)]))
            displayString.append(NSAttributedString(string: "[\(player.totalAssetValue)]   $\(player.money)\n", attributes: [.font: NSFont.boldSystemFont(ofSize: 14)]))
            player.assets.forEach( {
                displayString.append(NSAttributedString(string: "\($0.description)\n", attributes: [:]))
            })
            
            displayString.append(NSAttributedString(string: "\(player.commoditiesDescription)\n\n\n", attributes: [:]))
            
        })
        playerTextView.textStorage?.setAttributedString(displayString)
    }
    
}
