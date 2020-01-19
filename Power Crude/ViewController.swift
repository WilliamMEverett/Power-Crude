//
//  ViewController.swift
//  Power Crude
//
//  Created by William Everett on 1/5/20.
//  Copyright © 2020 William Everett. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, PhaseViewControllerDelegate {
    
    @IBOutlet weak var containerView : NSView!
    @IBOutlet weak var sidebarContainerView : NSView!
    @IBOutlet weak var bottomContainerView : NSView!
    
    var informationViewController : InformationSidebarViewController!
    var bottomInformationViewController : InformationBottomViewController!
    
    var currentPhaseViewController : PhaseViewController?
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
        
        bottomInformationViewController = InformationBottomViewController()
        self.addChild(bottomInformationViewController)
        bottomInformationViewController.view.frame = bottomContainerView.bounds
        bottomContainerView.addSubview(bottomInformationViewController.view)

        bottomInformationViewController.gameState = gameState
        
        installNewPhaseController(phaseController: AuctionViewController())
    }
    
    func installNewPhaseController(phaseController : PhaseViewController?) {
        if (currentPhaseViewController != nil) {
            currentPhaseViewController!.delegate = nil
            currentPhaseViewController!.view.removeFromSuperview()
            currentPhaseViewController!.removeFromParent()
        }
        
        currentPhaseViewController = phaseController
        if (currentPhaseViewController != nil) {
            currentPhaseViewController?.gameState = gameState
            self.addChild(currentPhaseViewController!)
            currentPhaseViewController!.view.frame = containerView.bounds
            containerView.addSubview(currentPhaseViewController!.view)
            currentPhaseViewController!.delegate = self
        }
    }

//MARK: - PhaseViewControllerDelegate -
    func phaseCompleted(viewController: PhaseViewController) {
        if (gameState == nil) {
            return
        }
        
        gameState?.finishPhase()
        
        gameState!.prepareForPhase()
        
        switch gameState!.phase {
        case .Auction:
            installNewPhaseController(phaseController: AuctionViewController())
        case .Production:
            installNewPhaseController(phaseController: ProductionViewController())
        case .Market:
            installNewPhaseController(phaseController: MarketViewController())
        case .Events:
            print("\(String(describing: gameState!.phase)) not implemented")
            installNewPhaseController(phaseController: nil)
        }
    }
}

