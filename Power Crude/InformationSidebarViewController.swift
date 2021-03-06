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
    @IBOutlet weak var economyLevelTextField : NSTextField!
    @IBOutlet weak var energyPriceTextField : NSTextField!
    @IBOutlet weak var economyChangeTextField : NSTextField!
    
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
        self.notificationObject = NotificationCenter.default.addObserver(forName: GameState.kGameStateChangedNotification, object: nil, queue: nil, using: {notification in
            if weakSelf?.gameState == notification.object as? GameState {
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
            economyChangeTextField.stringValue = ""
            economyLevelTextField.stringValue = ""
            energyPriceTextField.stringValue = ""
            return
        }
        
        let displayString = NSMutableAttributedString()
        
        nonNilGameState.players.keys.sorted().forEach( {
            let player = nonNilGameState.players[$0]!
            
            let titleFont = NSFont(name: "Times New Roman", size: 20)
            
            displayString.append(NSAttributedString(string: "Player \(player.playerNumber) \(player.playerName)\n", attributes: [.font:titleFont!]))
            displayString.append(NSAttributedString(string: "[\(player.totalAssetValue)]   $\(player.money)\n\n", attributes: [.font: NSFont.systemFont(ofSize: 16)]))
            player.assets.forEach( {
                displayString.append(NSAttributedString(string: "\($0.description)\n", attributes:  [.font: NSFont(name: "Helvetica", size: 12)!]))
            })
            
            displayString.append(NSAttributedString(string: "\n\(player.commoditiesDescription)\n______________\n", attributes: [.font: NSFont(name: "Helvetica", size: 12)!]))
            
            
        })
        playerTextView.textStorage?.setAttributedString(displayString)
        
        economyLevelTextField.stringValue = "\(nonNilGameState.economyLevel)"
        energyPriceTextField.stringValue = "\(nonNilGameState.currentRetailPriceEnergy)"
        
        economyChangeTextField.stringValue = nonNilGameState.economies[nonNilGameState.economyLevel]!.changeDescriptionString
    }
    
}
