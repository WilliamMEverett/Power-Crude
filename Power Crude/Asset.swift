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
    
    init(_ dataIn : [String:Any]) throws {
        guard let outType = dataIn["type"] as? String else {
            throw NSError()
        }
        
        guard let outputTypeEnum = Commodity.allCases.first(where: {$0.rawValue.lowercased() == outType.lowercased()}) else {
            throw NSError()
        }
        type = outputTypeEnum
        
        guard let outputQty = dataIn["qty"] as? Int else {
            throw NSError()
        }
        qty = outputQty
    }
    
    init(type: Commodity, qty: Int) {
        self.type = type
        self.qty = qty
    }
}

struct AssetInputType : CustomStringConvertible, Equatable {
    var inp : CommodityQty;
    var choices : [CommodityQty];
    
    var description: String {
        if inp.qty > 0 {
            return String(describing: inp);
        }
        else if (choices.count > 0) {
            return "{\(choices.map({String(describing: $0)}).joined(separator: ", "))}"
        }
        else {
            return ""
        }
    }

    init(_ dataIn : Any) throws {
        choices = []
        do {
            if let dict = dataIn as? [String:Any] {
                inp = try CommodityQty(dict)
                if inp.qty <= 0 {
                    throw AssetInitializationError.invalidInputs
                }
            }
            else if let ar = dataIn as? [Any] {
                inp = CommodityQty(type: .timber, qty: 0)
                try ar.forEach {
                    if let d = $0 as? [String:Any] {
                        let c = try CommodityQty(d)
                        choices.append(c)
                    }
                    else {
                        throw AssetInitializationError.invalidInputs
                    }
                }
            }
            else {
                throw AssetInitializationError.invalidInputs
            }
        } catch {
            throw AssetInitializationError.invalidInputs
        }
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
        return inputs.map({String(describing: $0)}).joined(separator: " + ")
    }
    
    var value : Int = 0
    var initialOrdering : Int = -1
    var type : AssetType = .production
    var output : CommodityQty = CommodityQty(type: .timber, qty: 0)
    var inputs : [AssetInputType] = []
    
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
        guard let parsedOt = try? CommodityQty(ot), parsedOt.qty > 0 else {
            throw AssetInitializationError.invalidOutput
        }
        output = parsedOt
        
        if let inputArray = dataIn["inputs"] as? [Any], inputArray.count > 0 {
            inputs = []
            try inputArray.forEach({
                let inp = try AssetInputType($0)
                inputs.append(inp)
            })
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
        let success = inputs.reduce(true) { (res, assetInput) -> Bool in
            if (!res) {
                return false
            }
            
            if assetInput.inp.qty > 0 {
                if assetInput.inp.type == .energy {
                    energyRequired += assetInput.inp.qty
                    return true
                }
                else {
                    return (stockpile[assetInput.inp.type] ?? 0) >= assetInput.inp.qty
                }
                
            }
            else if assetInput.choices.count > 0 {
                return assetInput.choices.reduce(false) { (optRes, optInp) -> Bool in
                    if optRes {
                        return true
                    }
                    return (stockpile[optInp.type] ?? 0) >= optInp.qty
                }
            }
            else {
                powerCrudeHandleError(description: nil)
                return false
            }
        }
        
        return (success: success, energy : energyRequired)
    }
    
    func requiresCommodity(com : Commodity) -> Bool {
        let count = inputs.filter({$0.inp.type == com}).count
        return count > 0
    }
    
}
