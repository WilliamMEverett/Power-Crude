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
    
    var isEmpty : Bool {
        raw == 0 && refined == 0 && goods == 0
    }
    
    var description : String {
        
        var strArry : [String] = []
        
        if (goods != 0) {
            var tempString : String = "Goods "
            tempString += (goods > 0 ? "+" : "-")
            tempString += "$"
            tempString += "\(abs(goods))"
            strArry.append(tempString)
        }
        if (refined != 0) {
            var tempString : String = "Refined "
            tempString += (refined > 0 ? "+" : "-")
            tempString += "\(abs(refined))"
            strArry.append(tempString)
        }
        if (raw != 0) {
            var tempString : String = "Raw "
            tempString += (raw > 0 ? "+" : "-")
            tempString += "\(abs(raw))"
            strArry.append(tempString)
        }
        
        return strArry.joined(separator: ", ")
    }
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
        
        if (!changeEffect.isEmpty) {
            tempString += "On start: "
            tempString += changeEffect.description
        }
        
        if (!steadyEffect.isEmpty) {
            if !tempString.isEmpty {
                tempString += "\n"
            }
            tempString += "Following turns: "
            tempString += steadyEffect.description
        }

        return tempString
    }
    
}
