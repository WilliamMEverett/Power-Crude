//
//  ViewController.swift
//  Power Crude
//
//  Created by William Everett on 1/5/20.
//  Copyright © 2020 William Everett. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    
    @IBOutlet weak var containerView : NSView!
    @IBOutlet weak var sidebarContainerView : NSView!
    var informationViewController : InformationSidebarViewController!
    
    var gameState : GameState?

    override func viewDidLoad() {
        super.viewDidLoad()

        gameState = try? GameState(numberOfPlayers: 4)
        if gameState == nil {
            NSLog("Failed to initialize game state")
            exit(-1)
        }
        gameState!.prepareForPhase()
        
        informationViewController = InformationSidebarViewController()
        self.addChild(informationViewController)
        informationViewController.view.frame = sidebarContainerView.bounds
        sidebarContainerView.addSubview(informationViewController.view)
        
        informationViewController.gameState = gameState
        
        let auctionViewController = AuctionViewController()
        auctionViewController.gameState = gameState
        self.addChild(auctionViewController)
        auctionViewController.view.frame = containerView.bounds
        containerView.addSubview(auctionViewController.view)
        
    }


}

