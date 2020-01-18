//
//  GameState.swift
//  Power Crude
//
//  Created by William Everett on 1/5/20.
//  Copyright © 2020 William Everett. All rights reserved.
//

import Cocoa

enum GameStatePhase {
    case Auction, Production, Market, Events
}


class GameState: NSObject {
    
    static let kGameStateChangedNotification = NSNotification.Name(rawValue: "kGameStateChangedNotification")
    
    var manufacturingAssetDeck : [Asset]!
    var regularAssetDeck : [Asset]!
    var reshuffleRegularAssetDeck : [Asset]!
    var discardDeck : [Asset]!
    var auctionMarket : [Asset]!
    var mfgAuctionMarket : [Asset]!
    var phase : GameStatePhase = .Auction
    
    var commodityMarket : [Commodity:Market]!
    
    var stage : Int = 1
    var movingToStage2 : Bool = false
    var playerOrder = [Int]()
    var players : [Int:Player] = [:]
    
    var lowestAssetInMarket : Asset? = nil
    
    init(numberOfPlayers : Int) throws {
        super.init()
        
        let assets = try loadAssets()
        commodityMarket = try loadMarkets()
        
        manufacturingAssetDeck = assets.filter() { $0.type == .manufacturing}.shuffled()
        
        let nonManufacturing = assets.filter() { $0.type != .manufacturing}
        regularAssetDeck = nonManufacturing.filter({$0.initialOrdering > 0}).sorted(by: { $0.initialOrdering < $1.initialOrdering})
        regularAssetDeck.append(contentsOf: nonManufacturing.filter({$0.initialOrdering <= 0}).shuffled())
        
        reshuffleRegularAssetDeck = []
        discardDeck = []
        auctionMarket = []
        mfgAuctionMarket = []
        playerOrder = (1...numberOfPlayers).map({$0})
        players = playerOrder.reduce(into: [Int:Player](), {
            $0[$1] = Player(number:$1)
        })
        
        var deckEmpty = false
        while auctionMarket.count < 6 && !deckEmpty {
            deckEmpty = drawAssetForMarket(regularMarket: true)
        }
        
    }
    
    var currentRetailPriceEnergy : Int {
        return 8
    }
    
    var currentWholesalePriceEnergy : Int {
        return 4
    }
    
    func prepareForPhase() {
        if (phase == .Auction) {
            if stage == 2 {
                lowestAssetInMarket = auctionMarket.first
            }
            else {
                lowestAssetInMarket = nil
            }
        }
    }
    
    func finishPhase() {
        if (phase == .Auction) {
            
            if stage == 1 && auctionMarket.count >= 6 && !movingToStage2 {
                reshuffleRegularAssetDeck.append(auctionMarket.popLast()!)
                
                _ = drawAssetForMarket(regularMarket: true)
            }
            if stage == 2 {
                if mfgAuctionMarket.count >= 4 {
                    manufacturingAssetDeck.append( mfgAuctionMarket.popLast()!)
                    
                    _ = drawAssetForMarket(regularMarket: false)
                }
                
                if lowestAssetInMarket != nil && auctionMarket.count > 0 && auctionMarket.first == lowestAssetInMarket {
                    discardDeck.append(auctionMarket.remove(at: 0))
                    _ = drawAssetForMarket(regularMarket: true)
                }
                lowestAssetInMarket = nil
            }
            
            if movingToStage2 && stage == 1 {
                stage = 2
                movingToStage2 = false
                regularAssetDeck.append(contentsOf: reshuffleRegularAssetDeck.shuffled())
                reshuffleRegularAssetDeck.removeAll()
                
                while let indexToRemove = regularAssetDeck.firstIndex(where: { ($0.type == .production || $0.type == .refining) && $0.output.qty == 1 }) {
                    discardDeck.append(regularAssetDeck.remove(at: indexToRemove) )
                }
                while let indexToRemove = auctionMarket.firstIndex(where: { ($0.type == .production || $0.type == .refining) && $0.output.qty == 1 }) {
                    discardDeck.append(auctionMarket.remove(at: indexToRemove) )
                }
                
                while regularAssetDeck.count > 0 && auctionMarket.count < 4 {
                    _ = drawAssetForMarket(regularMarket: true)
                }
                while stage == 2 && auctionMarket.count > 4 {
                    discardDeck.append(auctionMarket.remove(at: 0))
                }
            }

            playerOrder.sort(by: {players[$0]!.totalAssetValue > players[$1]!.totalAssetValue})
            phase = .Production
        }
        else if phase == .Production {
            phase = .Market
        }
        else if phase == .Market {
            phase = .Auction // TODO: hook up to events phase
        }
        else if phase == .Events {
            phase = .Auction
        }
        
        NotificationCenter.default.post(name: GameState.kGameStateChangedNotification, object: self)
    }
    
    func buyCommodities(player: Int, commodities:[Commodity:Int]) {
        var totalPriceChange = 0
        commodities.keys.forEach {
            guard let price = commodityMarket[$0]?.totalPriceForBuying(qtyBought: commodities[$0]!) else {
                exit(-1)
            }
            totalPriceChange -= price
            let newQ = (players[player]?.commodities[$0] ?? 0) + commodities[$0]!
            if (newQ < 0) {
                exit(-1)
            }
            else if (newQ == 0) {
                players[player]?.commodities.removeValue(forKey: $0)
            }
            else {
                players[player]?.commodities[$0] = newQ
            }
            let newMarketQ = (commodityMarket[$0]?.qty ?? 0) - commodities[$0]!
            if (newMarketQ < 0) {
                exit(-1)
            }
            commodityMarket[$0]?.qty = newMarketQ
        }
        
        let newMoney = (players[player]?.money ?? 0) + totalPriceChange
        if (newMoney < 0) {
            exit(-1)
        }
        players[player]?.money = newMoney
        
        NotificationCenter.default.post(name: GameState.kGameStateChangedNotification, object: self)
    }
    
    func produceAssets(player: Int, assets:[Asset]) {
        let result = players[player]!.getResultFromProducingAssets(assets: assets, energyBuy: currentRetailPriceEnergy, energySell: currentWholesalePriceEnergy)
        
        players[player]!.money = result.money
        players[player]!.commodities = result.stockpile
        
        NotificationCenter.default.post(name: GameState.kGameStateChangedNotification, object: self)
    }
    
    func purchaseAssetIndexFromMarketForPlayer(regularMarket : Bool, index : Int, price : Int, player : Int) -> Bool {
        if regularMarket {
            players[player]?.assets.append(auctionMarket.remove(at: index))
        }
        else {
            players[player]?.assets.append(mfgAuctionMarket.remove(at: index))
        }
        
        players[player]?.assets.sort(by: { $0.value > $1.value })
        
        players[player]?.money -= price
        
        let result = drawAssetForMarket(regularMarket: regularMarket)
        
        NotificationCenter.default.post(name: GameState.kGameStateChangedNotification, object: self)
        
        return result
    }
    
    fileprivate func drawAssetForMarket(regularMarket : Bool) -> Bool {
        if regularMarket {
            if regularAssetDeck.count > 0 {
                auctionMarket.append(regularAssetDeck.remove(at: 0))
                auctionMarket.sort(by: { $0.value < $1.value })
            }
            else {
                movingToStage2 = true
                return true
            }
        }
        else {
            if manufacturingAssetDeck.count > 0 {
                mfgAuctionMarket.append(manufacturingAssetDeck.remove(at: 0))
                mfgAuctionMarket.sort(by: { $0.value < $1.value })
            }
            else {
                return true
            }
        }
        
        return false
    }
    
    fileprivate func loadAssets() throws -> [Asset]  {
        
        guard let filepath = Bundle.main.path(forResource: "Assets", ofType: "json") else {
            throw NSError(domain: "Error loading file", code: 1, userInfo: nil)
        }
        guard let contents = try? String(contentsOfFile: filepath) else {
            throw NSError(domain: "Error loading file", code: 1, userInfo: nil)
        }

        var json : Any? = nil
        do {
            json = try JSONSerialization.jsonObject(with: contents.data(using: .utf8)!, options: [])
        } catch {
            NSLog("JSON Error: \(error)");
        }
        guard let jsonArray = json as? [Any] else {
            throw NSError(domain: "JSON was not array", code: 1, userInfo: nil)
        }
        
        let assetArray = jsonArray.compactMap { (obj) -> Asset? in
            guard let dictObj = obj as? [String:Any] else {
                NSLog("Json Item was not dictionary : \(obj)")
                return nil
            }
            do {
                let asset =  try Asset(dataIn:dictObj)
                return asset
            } catch {
                NSLog("Failed to initialize Asset : \(dictObj) - \(error)")
            }
            return nil
        }
        return assetArray
    }
    
    fileprivate func loadMarkets() throws -> [Commodity:Market]  {
        
        guard let filepath = Bundle.main.path(forResource: "markets", ofType: "json") else {
            throw NSError(domain: "Error loading file", code: 1, userInfo: nil)
        }
        guard let contents = try? String(contentsOfFile: filepath) else {
            throw NSError(domain: "Error loading file", code: 1, userInfo: nil)
        }

        var json : Any? = nil
        do {
            json = try JSONSerialization.jsonObject(with: contents.data(using: .utf8)!, options: [])
        } catch {
            NSLog("JSON Error: \(error)");
        }
        guard let jsonDict = json as? [String:Any] else {
            throw NSError(domain: "JSON was not dictionary", code: 1, userInfo: nil)
        }
        
        var mark : [Commodity:Market] = [:]
        
        try jsonDict.keys.forEach {
            guard let dict = jsonDict[$0] as? [String:Any] else {
                throw NSError(domain: "JSON was not dictionary", code: 1, userInfo: nil)
            }
            let m = try Market(dataIn: dict, typeName: $0)
            mark[m.type] = m
        }
        
        return mark
    }

}
