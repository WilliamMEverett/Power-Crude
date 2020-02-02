//
//  EventViewController.swift
//  Power Crude
//
//  Created by William Everett on 1/28/20.
//  Copyright © 2020 William Everett. All rights reserved.
//

import Cocoa

class EventViewController: PhaseViewController {
    
    @IBOutlet var nextButton : NSButton!
    @IBOutlet var mainEventTextField : NSTextField!
    @IBOutlet var economyTextField : NSTextField!
    @IBOutlet var economyEffectTextField : NSTextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let ev = gameState?.nextEvent else {
            NSLog("No Next Event!")
            return
        }
        
        mainEventTextField.stringValue = (ev.mainEventDescription)
        economyTextField.stringValue = (ev.economyDescription)
        
        let nextEconomyLevel = gameState!.nextEconomyLevelWithChange(ev.economyChange)
        let nextEconomy = gameState!.economies[nextEconomyLevel]!
        
        if nextEconomyLevel == gameState!.economyLevel {
            economyEffectTextField.stringValue = nextEconomy.steadyEffect.description
        }
        else {
            economyEffectTextField.stringValue = nextEconomy.changeEffect.description
        }
    }
    
    @IBAction func nextButtonPressed(_ sender: NSButton) {
        delegate?.phaseCompleted(viewController: self)
    }
    
}
