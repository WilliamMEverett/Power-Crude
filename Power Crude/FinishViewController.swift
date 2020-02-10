//
//  FinishViewController.swift
//  Power Crude
//
//  Created by William Everett on 2/9/20.
//  Copyright © 2020 William Everett. All rights reserved.
//

import Cocoa

class FinishViewController: PhaseViewController {
    
    @IBOutlet weak var resultsLabel : NSTextField!;

    override func viewDidLoad() {
        super.viewDidLoad()

        if gameState == nil {
            print("Error, no gamestate")
            return
        }
        
        let sortedPlayers = gameState!.players.values.sorted { (p1, p2) -> Bool in
            if p1.lastGoodsProduced != p2.lastGoodsProduced {
                return p1.lastGoodsProduced > p2.lastGoodsProduced
            }
            else {
                return p1.totalAssetValue < p2.totalAssetValue
            }
        }
        
        let playerStringArray = sortedPlayers.map { (p) -> String in
            "Player \(p.playerNumber): Produced \(p.lastGoodsProduced) Goods, Total Asset Value \(p.totalAssetValue)"
        }
        resultsLabel.stringValue = playerStringArray.joined(separator: "\n\n")
    }
    
}
