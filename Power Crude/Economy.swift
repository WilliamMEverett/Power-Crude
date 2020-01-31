//
//  Economy.swift
//  Power Crude
//
//  Created by William Everett on 1/30/20.
//  Copyright © 2020 William Everett. All rights reserved.
//

import Foundation


struct Economy : Equatable {
    
    var level : Int = 0
    var energyPrice : Int = 8
    var changeEffect : (raw: Int, refined: Int, goods: Int) = (0,0,0)
    var steadyEffect : (raw: Int, refined: Int, goods: Int) = (0,0,0)

    static func == (lhs: Economy, rhs: Economy) -> Bool {
        return lhs.level == rhs.level && lhs.energyPrice == rhs.energyPrice && lhs.changeEffect == rhs.changeEffect && lhs.steadyEffect == rhs.steadyEffect
    }
    
    init(dataIn: [String:Any], level : Int) throws {
        self.level = level
        guard let ene = dataIn["energy"] as? Int else {
            throw NSError(domain: "Economy missing energy param", code: 1, userInfo: nil)
        }
        self.energyPrice = ene
        
        if let change = dataIn["change"] as? [String:Any] {
            let r = (change["raw"] as? Int) ?? 0
            let rf = (change["refined"] as? Int) ?? 0
            let g = (change["goods"] as? Int) ?? 0
            self.changeEffect = (raw:r,refined:rf,goods:g)
        }
        if let change = dataIn["steady"] as? [String:Any] {
            let r = (change["raw"] as? Int) ?? 0
            let rf = (change["refined"] as? Int) ?? 0
            let g = (change["goods"] as? Int) ?? 0
            self.steadyEffect = (raw:r,refined:rf,goods:g)
        }
    }
}
