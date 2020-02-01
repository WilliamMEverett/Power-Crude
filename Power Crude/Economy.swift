//
//  Economy.swift
//  Power Crude
//
//  Created by William Everett on 1/30/20.
//  Copyright © 2020 William Everett. All rights reserved.
//

import Foundation

struct EconomyChangeDescription : Equatable {
    var raw : Int
    var refined : Int
    var goods : Int
}

struct Economy : Equatable {
    
    var level : Int = 0
    var energyPrice : Int = 8
    var changeEffect : EconomyChangeDescription = EconomyChangeDescription(raw:0,refined:0,goods:0)
    var steadyEffect : EconomyChangeDescription = EconomyChangeDescription(raw:0,refined:0,goods:0)
    
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
            self.changeEffect = EconomyChangeDescription(raw:r,refined:rf,goods:g)
        }
        if let change = dataIn["steady"] as? [String:Any] {
            let r = (change["raw"] as? Int) ?? 0
            let rf = (change["refined"] as? Int) ?? 0
            let g = (change["goods"] as? Int) ?? 0
            self.steadyEffect = EconomyChangeDescription(raw:r,refined:rf,goods:g)
        }
    }
    
    var changeDescriptionString : String {
        var tempString = ""
        
        if (changeEffect.goods != 0 || changeEffect.raw != 0 || changeEffect.refined != 0) {
            tempString += "On start:"
        }
        if (changeEffect.goods != 0) {
            tempString += " Goods "
            tempString += (changeEffect.goods > 0 ? "+" : "-")
            tempString += "$"
            tempString += "\(abs(changeEffect.goods))"
        }
        if (changeEffect.refined != 0) {
            tempString += " Refined "
            tempString += (changeEffect.refined > 0 ? "+" : "-")
            tempString += "\(abs(changeEffect.refined))"
        }
        if (changeEffect.raw != 0) {
            tempString += " Raw "
            tempString += (changeEffect.raw > 0 ? "+" : "-")
            tempString += "\(abs(changeEffect.raw))"
        }
        
        if (steadyEffect.goods != 0 || steadyEffect.raw != 0 || steadyEffect.refined != 0) {
            if !tempString.isEmpty {
                tempString += "\n"
            }
            tempString += "Following turns:"
        }
        if (steadyEffect.goods != 0) {
            tempString += " Goods "
            tempString += (steadyEffect.goods > 0 ? "+" : "-")
            tempString += "$"
            tempString += "\(abs(steadyEffect.goods))"
        }
        if (steadyEffect.refined != 0) {
            tempString += " Refined "
            tempString += (steadyEffect.refined > 0 ? "+" : "-")
            tempString += "\(abs(steadyEffect.refined))"
        }
        if (steadyEffect.raw != 0) {
            tempString += " Raw "
            tempString += (steadyEffect.raw > 0 ? "+" : "-")
            tempString += "\(abs(steadyEffect.raw))"
        }

        
        return tempString
    }
}
