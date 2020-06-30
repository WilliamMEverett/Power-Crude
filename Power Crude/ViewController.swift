//
//  ViewController.swift
//  Power Crude
//
//  Created by William Everett on 1/5/20.
//  Copyright © 2020 William Everett. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, PhaseViewControllerDelegate, GameStartConfigureViewControllerDelegate {
    
    @IBOutlet weak var containerView : NSView!
    @IBOutlet weak var sidebarContainerView : NSView!
    @IBOutlet weak var bottomContainerView : NSView!
    
    var informationViewController : InformationSidebarViewController!
    var bottomInformationViewController : InformationBottomViewController!
    
    var currentPhaseViewController : PhaseViewController?
    var gameState : GameState?
    var playerNames : [String] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        informationViewController = InformationSidebarViewController()
        self.addChild(informationViewController)
        informationViewController.view.frame = sidebarContainerView.bounds
        sidebarContainerView.addSubview(informationViewController.view)
        
        bottomInformationViewController = InformationBottomViewController()
        self.addChild(bottomInformationViewController)
        bottomInformationViewController.view.frame = bottomContainerView.bounds
        bottomContainerView.addSubview(bottomInformationViewController.view)

        displayGameStartConfiguration()
        
        
    }
    
    func displayGameStartConfiguration() {
        
        let configure = GameStartConfigureViewController()
        configure.delegate = self
        let window = NSWindow(contentViewController: configure)
        if NSApplication.shared.runModal(for: window) == .OK {
            createNewGameWithPlayers(playerNames)
            window.close()
        }
    }
    
    func setPlayerNames(_ viewController: GameStartConfigureViewController, players: [String]) {
        playerNames = players
    }
    
    func createNewGameWithPlayers(_ playerNames : [String]) {
        do {
            gameState = try GameState(numberOfPlayers: playerNames.count, playerNames: playerNames)
        }
        catch {
            powerCrudeHandleError(description: "Failed to initialize game state: \(error.localizedDescription)")
        }
        gameState!.prepareForPhase()
        informationViewController.gameState = gameState
        bottomInformationViewController.gameState = gameState
        installNewPhaseController(phaseController: AuctionViewController())
        self.view.window?.orderFront(nil)
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
        
        let startsStage1 = gameState!.stage == 1
        
        gameState!.finishPhase()
        
        if startsStage1 && (gameState!.stage == 2) {
            let alert = NSAlert()
            alert.informativeText = "Stage 2 has begun"
            alert.alertStyle = .informational
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
        
        gameState!.prepareForPhase()
        
        switch gameState!.phase {
        case .Auction:
            
            if gameState!.lastTurn {
                let alert = NSAlert()
                alert.informativeText = "This is the last turn"
                alert.alertStyle = .informational
                alert.addButton(withTitle: "OK")
                alert.runModal()
            }
            
            installNewPhaseController(phaseController: AuctionViewController())
        case .Production:
            
            if !gameState!.lastTurn && gameState!.endGameTriggered() {
                let alert = NSAlert()
                alert.informativeText = "End Game Triggered. This is the second to last turn"
                alert.alertStyle = .informational
                alert.addButton(withTitle: "OK")
                alert.runModal()
            }
            
            installNewPhaseController(phaseController: ProductionViewController())
        case .Market:
            installNewPhaseController(phaseController: MarketViewController())
        case .Events:
            installNewPhaseController(phaseController: EventViewController())
        case .Finish:
            installNewPhaseController(phaseController: FinishViewController())
        }
    }
}

