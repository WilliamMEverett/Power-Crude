//
//  Market.swift
//  Power Crude
//
//  Created by William Everett on 1/11/20.
//  Copyright © 2020 William Everett. All rights reserved.
//

import Foundation

enum MarketInitializationError : Error {
    case invalidType
    case invalidQuantity
    case invalidPrices
}

struct Market {
    var type : Commodity = .timber
    var qty : Int = 0
    var prices : [Int] = []
    
    init( dataIn : [String:Any], typeName : String) throws {
        
        guard let c = Commodity.allCases.first(where: {$0.rawValue.lowercased() == typeName.lowercased()}) else {
            throw MarketInitializationError.invalidType
        }
        type = c
        
        guard let q = dataIn["qty"] as? Int else {
            throw MarketInitializationError.invalidQuantity
        }
        qty = q
        
        guard let p = dataIn["market"] as? [Int] else {
            throw MarketInitializationError.invalidPrices
        }
        var lastVal = 0
        for pr in p {
            if pr < lastVal {
                throw MarketInitializationError.invalidPrices
            }
            lastVal = pr
        }
        
        prices = p
        
    }
    
    var currentBuyPrice : Int? {
        if type.isFinishedCommodity() {
            return nil
        }
        if (qty <= 0) {
            return nil
        }
        if (qty >= prices.count) {
            return prices[0]
        }
        else {
            return prices.reversed()[qty - 1]
        }
    }
    
    var currentSellPrice : Int? {
        if (qty >= prices.count) {
            return nil
        }
        else {
            return prices.reversed()[qty]
        }
    }
    
    func totalPriceForBuying(qtyBought: Int) -> Int? {
        if qtyBought == 0 {
            return 0
        }
        if qtyBought > qty {
            return nil
        }
        if qtyBought < 0 && qtyBought < qty - prices.count {
            return nil
        }
        if (qtyBought > 0 ) {
            if type.isFinishedCommodity() {
                return nil
            }
            
            let result = (0..<qtyBought).reduce(0) { (res, index) -> Int in
                res + prices.reversed()[qty - 1 - index]
            }
            return result
        }
        else {
            let negativeQtyBought = -1 * qtyBought
            let result = (0..<negativeQtyBought).reduce(0) { (res, index) -> Int in
                res - prices.reversed()[qty + index]
            }
            return result
        }
        
    }
}
