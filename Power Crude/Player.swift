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
    
    func assetsThatCanProduce(energyPrice: Int) -> Set<Int> {
        var resultSet = Set<Int>( assets.enumerated().filter( { $0.element.inputs.count == 0}).map( { $0.offset }) )
        
        var stockpile = commodities
        
        resultSet.forEach( {
            let com = assets[$0].output.type
            stockpile[com] = (stockpile[com] ?? 0) + assets[$0].output.qty
        })
        
        assets.enumerated().filter( { $0.element.inputs.count > 0 && $0.element.type == .refining}).forEach( {
            let check = $0.element.canProduceWithInputs(stockpile: stockpile)
            if check.success {
                resultSet.insert($0.offset)
                let com = $0.element.output.type
                stockpile[com] = (stockpile[com] ?? 0) + $0.element.output.qty
            }
        })
        
        assets.enumerated().filter( { $0.element.inputs.count > 0 && $0.element.type == .manufacturing }).forEach( {
            let check = $0.element.canProduceWithInputs(stockpile: stockpile)
            if check.success {
                let requiredEnergy = check.energy - (stockpile[.energy] ?? 0)
                if (requiredEnergy*energyPrice <= self.money) {
                    resultSet.insert($0.offset)
                    let com = $0.element.output.type
                    stockpile[com] = (stockpile[com] ?? 0) + $0.element.output.qty
                }
            }
        })
        
        return resultSet
    }
    
    func getResultFromProducingAssets(assets:[Asset], energyBuy: Int, energySell: Int, startingCommodities:[Commodity:Int]? = nil, startingMoney: Int? = nil) -> (stockpile:[Commodity:Int], money:Int) {
        var remainingMoney = startingMoney != nil ? startingMoney! : money
        
        var finalCommodities = startingCommodities != nil ? startingCommodities! : commodities
        
        assets.filter({$0.inputs.count == 0}).forEach( {
            finalCommodities[$0.output.type] = (finalCommodities[$0.output.type] ?? 0) + $0.output.qty
        })
        
        let types : [AssetType] = [.refining, .manufacturing]
        types.forEach { (t) in
            assets.filter({$0.inputs.count > 0 && $0.type == t}).forEach( {
                let check = $0.canProduceWithInputs(stockpile: finalCommodities)
                if !check.success {
                    return
                }
                let energyRequired = check.energy
                let purchaseEnergy = energyRequired - (finalCommodities[.energy] ?? 0)
                if purchaseEnergy > 0 && purchaseEnergy*energyBuy > remainingMoney {
                    return
                }
                
                if purchaseEnergy > 0 {
                    remainingMoney -= purchaseEnergy*energyBuy
                    finalCommodities.removeValue(forKey: .energy)
                }
                else if energyRequired > 0 {
                    finalCommodities[.energy] = finalCommodities[.energy]! - energyRequired
                }
                
                $0.inputs.forEach { (inpAny) in
                    if inpAny.inp.qty > 0 {
                        if inpAny.inp.type == .energy {
                            return
                        }
                        let newQty = (finalCommodities[inpAny.inp.type] ?? 0) - inpAny.inp.qty
                        if newQty < 0 {
                            powerCrudeHandleError(description: nil)
                        }
                        else if newQty == 0 {
                            finalCommodities.removeValue(forKey: inpAny.inp.type)
                        }
                        else {
                            finalCommodities[inpAny.inp.type] = newQty
                        }
                    }
                    else if inpAny.choices.count > 0 {
                        var requirementSatisfied = false
                        inpAny.choices.reversed().forEach { (optCom) in
                            
                            if !requirementSatisfied && (finalCommodities[optCom.type] ?? 0) >= optCom.qty {
                                requirementSatisfied = true
                                finalCommodities[optCom.type] = (finalCommodities[optCom.type] ?? 0) - optCom.qty
                            }
                        }
                        if (!requirementSatisfied) {
                            powerCrudeHandleError(description: nil)
                        }
                    }
                }
                
                finalCommodities[$0.output.type] = (finalCommodities[$0.output.type] ?? 0) + $0.output.qty
                
            })
        }
        
        if ((finalCommodities[.energy] ?? 0) > 0) {
            remainingMoney += finalCommodities[.energy]! * energySell
        }
        finalCommodities.removeValue(forKey: .energy)
        
        return (stockpile:finalCommodities, money: remainingMoney)
    }
    
    func findRequiredCommoditiesToProduce() -> [Commodity:Int] {
        var res = [Commodity:Int]()
        
        var stockpile = [Commodity:Int]()
        
        assets.filter( { $0.inputs.count == 0}).forEach( {
            let com = $0.output.type
            stockpile[com] = (stockpile[com] ?? 0) + $0.output.qty
        })
        
        assets.filter( { $0.inputs.count > 0 }).sorted(by: { (first, second) -> Bool in
            return first.type < second.type
            
        }).forEach( { refAsset in
            
            refAsset.inputs.forEach { (assetInp) in
                if assetInp.inp.qty > 0 {
                    if assetInp.inp.type.isVirtualCommodity() {
                        return
                    }
                    let existingAmount = stockpile[assetInp.inp.type] ?? 0
                    if existingAmount >= assetInp.inp.qty {
                        stockpile[assetInp.inp.type] = existingAmount - assetInp.inp.qty
                    } else {
                        stockpile[assetInp.inp.type] = 0
                        res[assetInp.inp.type] = (res[assetInp.inp.type] ?? 0) + assetInp.inp.qty - existingAmount
                    }
                }
                else if assetInp.choices.count > 0 {
                    var fulfilledRequirement = false
                    for chooseComInp in assetInp.choices {
                        let existingAmount = stockpile[chooseComInp.type] ?? 0
                        if existingAmount >= chooseComInp.qty {
                            stockpile[chooseComInp.type] = existingAmount - chooseComInp.qty
                            fulfilledRequirement = true
                            break;
                        }
                    }
                    if !fulfilledRequirement {
                        let req = assetInp.choices.last!
                        let existingAmount = stockpile[req.type] ?? 0
                        if existingAmount >= req.qty {
                            stockpile[req.type] = existingAmount - req.qty
                        } else {
                            stockpile[req.type] = 0
                            res[req.type] = (res[req.type] ?? 0) + req.qty - existingAmount
                        }
                    }
                }
            }
            
        })
        
        return res
    }
}
