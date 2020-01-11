//
//  Commodities.swift
//  Power Crude
//
//  Created by William Everett on 1/2/20.
//  Copyright © 2020 William Everett. All rights reserved.
//

import Foundation

enum Commodity : String, CaseIterable {
    case timber = "Timber", ironOre = "Iron Ore", bauxite = "Bauxite", oil = "Oil", lumber = "Lumber", steel = "Steel", aluminum = "Aluminum", plastic = "Plastic", goods = "Goods", energy = "Energy"
    
    func isRawCommodity() -> Bool {
        switch self {
        case .timber, .ironOre, .bauxite, .oil:
            return true
        default:
            return false
        }
    }
    
    func isRefinedCommodity() -> Bool {
        switch self {
        case .lumber, .steel, .aluminum, .plastic, .energy:
            return true
        default:
            return false
        }
    }
    
    func isFinishedCommodity() -> Bool {
        switch self {
        case .goods:
            return true
        default:
            return false
        }
    }
    
    func isVirtualCommodity() -> Bool {
        switch self {
        case .energy:
            return true
        default:
            return false
        }
    }
    
}
