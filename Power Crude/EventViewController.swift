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

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let ev = gameState?.nextEvent
        
        mainEventTextField.stringValue = (ev?.mainEventDescription) ?? ""
        economyTextField.stringValue = (ev?.economyDescription) ?? ""
    }
    
    @IBAction func nextButtonPressed(_ sender: NSButton) {
        delegate?.phaseCompleted(viewController: self)
    }
    
}
