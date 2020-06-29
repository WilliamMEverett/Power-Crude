//
//  Event.swift
//  Power Crude
//
//  Created by William Everett on 1/28/20.
//  Copyright © 2020 William Everett. All rights reserved.
//

import Foundation

struct TaxEvent : CustomStringConvertible, Equatable {
    
    var type : String
    var assetType : AssetType?
    var outputType : Commodity?
    var amount : Int
    
    init(_ dataIn : [String:Any]) throws {
        if let typeString = dataIn["type"] as? String {
            type = typeString.lowercased()
        }
        else {
            throw NSError(domain: "Tax event missing type", code: 1, userInfo: nil)
        }
        assetType = nil
        outputType = nil
        if type == "commodity" {
        }
        else if type == "assettype" {
            if let typeString = dataIn["category"] as? String {
                assetType = AssetType.allCases.first(where: {String(describing:$0).lowercased() == typeString.lowercased()})
            }
            if assetType == nil {
                throw NSError(domain: "Tax event does not have valid asset type", code: 1, userInfo: nil)
            }
        }
        else if type == "outputtype" {
            if let typeString = dataIn["category"] as? String {
                outputType = Commodity.allCases.first(where: {$0.rawValue.lowercased() == typeString.lowercased()})
            }
            if outputType == nil {
                throw NSError(domain: "Tax event does not have valid output type", code: 1, userInfo: nil)
            }
        }
        else {
            throw NSError(domain: "Tax event does not have valid type", code: 1, userInfo: nil)
        }
        
        if let amountInt = dataIn["amount"] as? Int {
            amount = amountInt
        }
        else {
            throw NSError(domain: "Tax event does not have amount", code: 1, userInfo: nil)
        }
    }
    
    var description: String {
        let signString = amount < 0 ? "-" : ""
        let dollarString = "\(signString)$\(abs(amount))"
        if type == "commodity" {
            return "\(dollarString) for each commodity stored"
        }
        else if assetType != nil {
            return "\(dollarString) for each \(assetType!) asset"
        }
        else if outputType != nil {
            return "\(dollarString) for each \(outputType!) producing asset"
        }
        else {
            return ""
        }
    }
}

struct Event : CustomStringConvertible, Equatable {

    var economyChange : Int
    var marketChange : CommodityQty
    var marketUnavailable : Commodity?
    var changeEffect : EconomyChangeDescription?
    var taxEvent : TaxEvent?
    
    var description: String {
        let eD = self.economyDescription
        if eD.isEmpty {
            return self.mainEventDescription
        }
        else {
            return "\(self.mainEventDescription), \(eD)"
        }
    }
    
    var economyDescription: String {
        if (economyChange == 0) {
            return ""
        }
        else if economyChange > 0 {
            return "Economy +\(economyChange)"
        }
        else {
            return "Economy \(economyChange)"
        }
    }
    
    var mainEventDescription: String {
        if (marketChange.qty != 0) {
            let qtyDesc = marketChange.qty > 0 ? "+\(marketChange.qty)" : "\(marketChange.qty)"
            return "\(marketChange.type.rawValue) \(qtyDesc)"
        }
        else if marketUnavailable != nil {
            return "\(marketUnavailable!.rawValue) market unavailable next turn."
        }
        else if changeEffect != nil {
            return "\(changeEffect!.description)"
        }
        else if taxEvent != nil {
            return taxEvent!.description
        }
        else {
            return ""
        }
    }
    
    init(_ dataIn : [String:Any]) throws {
        
        economyChange = (dataIn["economy"] as? Int) ?? 0
        
        if let mChange = dataIn["market"] as? [String:Any] {
            marketChange = try CommodityQty(mChange)
        }
        else {
            marketChange = CommodityQty(type: .timber, qty: 0)
        }
        
        if let unavailableString = dataIn["unavailable"] as? String {
            marketUnavailable = Commodity.allCases.first(where: {$0.rawValue.lowercased() == unavailableString.lowercased()})
        }
        else {
            marketUnavailable = nil
        }
        
        if let changeDes = dataIn["change"] as? [String:Any] {
            changeEffect = try EconomyChangeDescription(dataIn: changeDes)
        }
        else {
            changeEffect = nil
        }
        
        if let taxDict = dataIn["taxevent"] as? [String:Any] {
            taxEvent = try TaxEvent(taxDict)
        }
        else {
            taxEvent = nil
        }
    
    }
        
}
