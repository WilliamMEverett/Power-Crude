//
//  Player.swift
//  Power Crude
//
//  Created by William Everett on 1/7/20.
//  Copyright © 2020 William Everett. All rights reserved.
//

import Cocoa

class Player: NSObject {

    var playerNumber : Int = 0
    var money : Int = 0
    var assets : [Asset] = []
    var commodities : [Commodity:Int] = [:]
    
    var totalAssetValue : Int {
        return assets.reduce(0, { $0 + $1.value})
    }
    
    var hasMaximumNumberOfAssets : Bool {
        return assets.count >= 6
    }
    
    init(number : Int) {
        super.init()
        
        playerNumber = number
        money = 50
        assets = []
        commodities = [:]
    }
    
    var commoditiesDescription : String {
        
        let comStringArray = Commodity.allCases.compactMap { (c) -> String? in
            guard let quant = commodities[c], quant != 0 else {
                return nil
            }
            return "\(c.rawValue):\(quant)"
        }
        
        return comStringArray.joined(separator: ", ")
    }
}
