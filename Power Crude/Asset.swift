//
//  Asset.swift
//  Power Crude
//
//  Created by William Everett on 1/2/20.
//  Copyright © 2020 William Everett. All rights reserved.
//

import Foundation


enum AssetType : Comparable {
    static func < (lhs: AssetType, rhs: AssetType) -> Bool {
        if lhs != rhs {
            if lhs == production {
                return true
            }
            else if lhs == refining && rhs == manufacturing {
                return true
            }
        }
        return false
    }
    
    case production
    case refining
    case manufacturing
}

enum AssetInitializationError : Error {
    case invalidValue
    case invalidOutput
    case invalidInputs
}

struct CommodityQty : CustomStringConvertible, Equatable {
    var type : Commodity;
    var qty : Int;
    
    var description: String {
        return "\(type.rawValue)(\(qty))"
    }
}

struct Asset : CustomStringConvertible, Equatable {
    
    var description: String {
        var res = "[\(value)] "
        if (inputs.count > 0) {
            res += self.inputDescription
            res += " => "
        }
        res += String(describing: output)
        return res
    }
    
    var inputDescription: String {
        var res = ""
        if (inputs.count > 0) {
            for (index,item) in inputs.enumerated() {
                if index > 0 {
                    res += " + "
                }
                if let itemComm = item as? CommodityQty {
                    res += String(describing: itemComm)
                }
                else if let itemArr = item as? [Any] {
                    res += "{"
                    for (index,item) in itemArr.enumerated() {
                        if index > 0 {
                            res += " or "
                        }
                        res += String(describing: item)
                    }
                    
                    res += "}"
                }
            }
        }
        return res
    }
    
    var value : Int = 0
    var initialOrdering : Int = -1
    var type : AssetType = .production
    var output : CommodityQty = CommodityQty(type: .timber, qty: 0)
    var inputs : [Any] = []
    
    init( dataIn : [String:Any]) throws {
        guard let v = dataIn["value"] as? Int else {
            throw AssetInitializationError.invalidValue
        }
        value = v
        
        if let iO = dataIn["initial"] as? Int {
            initialOrdering = iO
        }
        
        guard let ot = dataIn["output"] as? [String:Any] else {
            throw AssetInitializationError.invalidOutput
        }
        guard let parsedOt = parseCommodityTypeQuantityPair(pair: ot) else {
            throw AssetInitializationError.invalidOutput
        }
        output = parsedOt
        
        if let inputArray = dataIn["inputs"] as? [Any], inputArray.count > 0 {
            if let newInp = parseArrayOfNestedCommodityTypePairs(ar: inputArray) {
                inputs = newInp
            }
            else {
                throw AssetInitializationError.invalidInputs
            }
        }
        
        if output.type.isRawCommodity() {
            type = .production
        }
        else if output.type.isRefinedCommodity() {
            type = .refining
        }
        else if output.type.isFinishedCommodity() {
            type = .manufacturing
        }
        else {
            throw AssetInitializationError.invalidOutput
        }
    }
    
    func canProduceWithInputs(stockpile : [Commodity:Int]) -> (success: Bool, energy: Int) {
        
        var energyRequired = 0
        
        if (inputs.count == 0) {
            return (success: true, energy : energyRequired)
        }
        let success = inputs.reduce(true) { (res, inp) -> Bool in
            if (!res) {
                return false
            }
            
            if let comInp = inp as? CommodityQty {
                if comInp.type == .energy {
                    energyRequired += comInp.qty
                    return true
                }
                else {
                    return (stockpile[comInp.type] ?? 0) >= comInp.qty
                }
                
            }
            else if let arrayInp = inp as? [Any] {
                return arrayInp.reduce(false) { (optRes, optInp) -> Bool in
                    if optRes {
                        return true
                    }
                    if let comOptIn = optInp as? CommodityQty {
                        return (stockpile[comOptIn.type] ?? 0) >= comOptIn.qty
                    }
                    else {
                        exit(-1)
                    }
                }
            }
            else {
                exit(-1)
            }
        }
        
        return (success: success, energy : energyRequired)
    }
    
    static func == (lhs: Asset, rhs: Asset) -> Bool {
        return lhs.value == rhs.value && lhs.initialOrdering == rhs.initialOrdering && lhs.description == rhs.description
    }
    
    private func parseArrayOfNestedCommodityTypePairs(ar : [Any]) -> [Any]? {
        return try? ar.map({ (o) -> Any in

            if let v = o as? [String:Any] {
                let p = parseCommodityTypeQuantityPair(pair: v)
                if p != nil {
                    return p!
                }
                else {
                    throw AssetInitializationError.invalidInputs
                }
            }
            else if let a = o as? [Any] {
                let p = parseArrayOfNestedCommodityTypePairs(ar: a)
                if p != nil {
                    return p!
                }
                else {
                    throw AssetInitializationError.invalidInputs
                }
            }
            else {
                throw AssetInitializationError.invalidInputs
            }
        })
    }
    
    private func parseCommodityTypeQuantityPair(pair : [String:Any]) -> CommodityQty? {
        guard let outType = pair["type"] as? String else {
            return nil
        }
        
        guard let outputTypeEnum = Commodity.allCases.first(where: {$0.rawValue.lowercased() == outType.lowercased()}) else {
            return nil
        }
        guard let outputQty = pair["qty"] as? Int, outputQty > 0 else {
            return nil
        }
        return CommodityQty(type:outputTypeEnum, qty:outputQty)
    }
    
}
