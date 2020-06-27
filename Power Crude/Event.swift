//
//  Event.swift
//  Power Crude
//
//  Created by William Everett on 1/28/20.
//  Copyright © 2020 William Everett. All rights reserved.
//

import Foundation


struct Event : CustomStringConvertible, Equatable {

    var economyChange : Int
    var marketChange : CommodityQty
    var marketUnavailable : Commodity?
    
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
    
    }
        
}
