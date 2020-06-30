//
//  GameState.swift
//  Power Crude
//
//  Created by William Everett on 1/5/20.
//  Copyright © 2020 William Everett. All rights reserved.
//

import Cocoa

enum GameStatePhase {
    case Auction, Production, Market, Events, Finish
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
    var unavailableCommodity : Commodity?
    var eventDeck : [Event]!
    var discardedEventDeck : [Event]!
    
    var stage : Int = 1
    var movingToStage2 : Bool = false
    var lastTurn : Bool = false
    var playerOrder = [Int]()
    var players : [Int:Player] = [:]
    
    var economies : [Int:Economy]!
    var economyLevel : Int = 0
    
    var lowestAssetInMarket : Asset? = nil
    
    init(numberOfPlayers : Int, playerNames : [String]?) throws {
        super.init()
        
        var assets = try loadAssets()
        commodityMarket = try loadMarkets()
        unavailableCommodity = nil
        eventDeck = try loadEvents()
        eventDeck.shuffle()
        discardedEventDeck = []
        
        if numberOfPlayers <= 3 {
            assets = assets.filter({ $0.output.type != .bauxite && $0.output.type != .aluminum && !$0.requiresCommodity(com: .bauxite) && !$0.requiresCommodity(com: .aluminum) })
        }
        
        manufacturingAssetDeck = assets.filter() { $0.type == .manufacturing}.shuffled()
        
        let nonManufacturing = assets.filter() { $0.type != .manufacturing}
        regularAssetDeck = nonManufacturing.filter({$0.initialOrdering > 0}).sorted(by: { $0.initialOrdering < $1.initialOrdering})
        regularAssetDeck.append(contentsOf: nonManufacturing.filter({$0.initialOrdering <= 0}).shuffled())
        
        reshuffleRegularAssetDeck = []
        discardDeck = []
        auctionMarket = []
        mfgAuctionMarket = []
        playerOrder = (1...numberOfPlayers).map({$0})
        
        let startingCommodityTypes = Commodity.allCases.filter {
            $0.isRawCommodity() && !$0.isVirtualCommodity() && (numberOfPlayers > 3 || $0 != .bauxite)
        }
        let startingCommodities = startingCommodityTypes.reduce(into: [Commodity:Int](), {
            $0[$1] = 1
        })
        
        players = playerOrder.reduce(into: [Int:Player](), {
            var name = ""
            if playerNames != nil && playerNames!.count >= $1 {
                name = playerNames![$1 - 1]
            }
            $0[$1] = Player(number:$1, startingCommodities: startingCommodities, name: name)
        })
        
        playerOrder.shuffle()
        
        economies = try loadEconomies()
        economyLevel = 0
        
        var deckEmpty = false
        while auctionMarket.count < 6 && !deckEmpty {
            deckEmpty = drawAssetForMarket(regularMarket: true)
        }
        
    }
    
    var currentRetailPriceEnergy : Int {
        return economies[economyLevel]!.energyPrice
    }
    
    var currentWholesalePriceEnergy : Int {
        return (economies[economyLevel]!.energyPrice)/2
    }
    
    var nextEvent : Event {
        if eventDeck.count > 0 {
            return eventDeck.last!
        }
        else if discardedEventDeck.count > 0 {
            eventDeck = discardedEventDeck.shuffled()
            discardedEventDeck = []
            return eventDeck.last!
        }
        else {
            powerCrudeHandleError(description: "No Events!")
            exit(-1)
        }
    }
    
    func prepareForPhase() {
        if (phase == .Auction) {
            if endGameTriggered() {
                lastTurn = true
            }
            
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
                
                while manufacturingAssetDeck.count > 0 && mfgAuctionMarket.count < 4 {
                    _ = drawAssetForMarket(regularMarket: false)
                }
            }

            playerOrder.sort(by: {players[$0]!.totalAssetValue > players[$1]!.totalAssetValue})
            phase = .Production
        }
        else if phase == .Production {
            if lastTurn {
                phase = .Finish
            }
            else {
                phase = .Market
            }
        }
        else if phase == .Market {
            unavailableCommodity = nil
            phase = .Events
        }
        else if phase == .Events {
            let ev = eventDeck.popLast()!
            applyEvent(ev)
            discardedEventDeck.append(ev)
            phase = .Auction
        }
        
        NotificationCenter.default.post(name: GameState.kGameStateChangedNotification, object: self)
    }
    
    func endGameTriggered() -> Bool {
        
        let numPlayers3Mfg = players.values.filter({$0.numberOfManufacturingAssets >= 3}).count
        if numPlayers3Mfg >= 1 {
            return true
        }
        let numPlayers2Mfg = players.values.filter({$0.numberOfManufacturingAssets >= 2}).count
        if numPlayers2Mfg >= 2 {
            return true
        }
        return false
    }
    
    fileprivate func applyEvent(_ ev : Event) {
        
        if ev.marketChange.qty != 0 {
            var mk = commodityMarket[ev.marketChange.type]!
            let newQty = max(min(mk.qty + ev.marketChange.qty, mk.prices.count),0)
            mk.qty = newQty
            commodityMarket[ev.marketChange.type] = mk
        }
        
        if ev.marketUnavailable != nil {
            unavailableCommodity = ev.marketUnavailable
        }
        
        if ev.changeEffect != nil {
            applyChangeEffect(ev.changeEffect!)
        }
        
        if ev.taxEvent != nil {
            applyTaxEvent(ev.taxEvent!)
        }
        
        let oldLevel = economyLevel
        economyLevel = nextEconomyLevelWithChange(ev.economyChange)
        if oldLevel != economyLevel {
            applyChangeEffect(economies[economyLevel]!.changeEffect)
            
        }
        else {
            applyChangeEffect(economies[economyLevel]!.steadyEffect)
        }
    }
    
    fileprivate func applyChangeEffect(_ changeEffect : EconomyChangeDescription) {
        if stage == 2 && changeEffect.goods != 0 {
            let newPrice = ((commodityMarket[.goods]?.currentSellPrice) ?? 0) + changeEffect.goods
            
            if newPrice > (commodityMarket[.goods]?.currentSellPrice ?? 0) {
                while newPrice > (commodityMarket[.goods]?.currentSellPrice ?? 0) && commodityMarket[.goods]!.qty > 0 {
                    commodityMarket[.goods]!.qty -= 1
                }
            }
            else if newPrice < (commodityMarket[.goods]?.currentSellPrice ?? 0) {
                while newPrice < (commodityMarket[.goods]?.currentSellPrice ?? 0) && commodityMarket[.goods]!.remainingSpaces > 0 {
                    commodityMarket[.goods]!.qty += 1
                }
            }
        }
        if changeEffect.raw != 0 {
            let rawKeys = commodityMarket.keys.filter({$0.isRawCommodity()})
            
            rawKeys.forEach { (c) in
                let newQ = min(max(commodityMarket[c]!.qty + changeEffect.raw, 0), commodityMarket[c]!.prices.count)
                commodityMarket[c]!.qty = newQ
            }
        }
        if changeEffect.refined != 0 {
            let refinedKeys = commodityMarket.keys.filter({$0.isRefinedCommodity()})
            
            refinedKeys.forEach { (c) in
                let newQ = min(max(commodityMarket[c]!.qty + changeEffect.refined, 0), commodityMarket[c]!.prices.count)
                commodityMarket[c]!.qty = newQ
            }
        }
    }
    
    fileprivate func applyTaxEvent(_ ev : TaxEvent) {
        players.values.forEach { (player) in
            player.applyTaxEvent(ev)
        }
    }
    
    func nextEconomyLevelWithChange(_ change : Int) -> Int {
        let maxEconomy = economies.keys.max()!
        let minEconomy = economies.keys.min()!
        
        return min(max(minEconomy, (economyLevel + change)), maxEconomy)
    }
    
    func buyCommodities(player: Int, commodities:[Commodity:Int]) {
        var totalPriceChange = 0
        commodities.keys.forEach {
            guard let price = commodityMarket[$0]?.totalPriceForBuying(qtyBought: commodities[$0]!) else {
                powerCrudeHandleError(description: nil)
                exit(-1)
            }
            totalPriceChange -= price
            let newQ = (players[player]?.commodities[$0] ?? 0) + commodities[$0]!
            if (newQ < 0) {
                powerCrudeHandleError(description: nil)
            }
            else if (newQ == 0) {
                players[player]?.commodities.removeValue(forKey: $0)
            }
            else {
                players[player]?.commodities[$0] = newQ
            }
            let newMarketQ = (commodityMarket[$0]?.qty ?? 0) - commodities[$0]!
            if (newMarketQ < 0) {
                powerCrudeHandleError(description: nil)
            }
            commodityMarket[$0]?.qty = newMarketQ
        }
        
        let newMoney = (players[player]?.money ?? 0) + totalPriceChange
        if (newMoney < 0) {
            powerCrudeHandleError(description: nil)
        }
        players[player]?.money = newMoney
        
        NotificationCenter.default.post(name: GameState.kGameStateChangedNotification, object: self)
    }
    
    func produceAssets(player: Int, assets:[Asset]) {
        let result = players[player]!.getResultFromProducingAssets(assets: assets, energyBuy: currentRetailPriceEnergy, energySell: currentWholesalePriceEnergy)
        
        players[player]!.lastGoodsProduced = 0
        let lastGoodsStockpile = players[player]!.commodities[.goods] ?? 0
        
        players[player]!.money = result.money
        players[player]!.commodities = result.stockpile
        
        let currentGoodsStockpile = players[player]!.commodities[.goods] ?? 0
        if (currentGoodsStockpile < lastGoodsStockpile) {
            print("This shouldn't happen. Goods stockpile went down after production for player \(player)")
        }
        else {
            players[player]!.lastGoodsProduced = currentGoodsStockpile - lastGoodsStockpile
        }
        
        NotificationCenter.default.post(name: GameState.kGameStateChangedNotification, object: self)
    }
    
    func sellAssetForPlayer(asset : Asset, player : Int) -> Bool {
        guard let index = players[player]?.assets.firstIndex(of: asset) else {
            return false
        }
        
        let a = players[player]!.assets.remove(at: index)
        players[player]!.money += a.value
        discardDeck.append(a)
        
        NotificationCenter.default.post(name: GameState.kGameStateChangedNotification, object: self)
        
        return true
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
    
    fileprivate func loadEvents() throws -> [Event]  {
        
        guard let filepath = Bundle.main.path(forResource: "events", ofType: "json") else {
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
        
        let mark : [Event] = try jsonArray.map { (anyIn) -> Event in
            guard let dict = anyIn as? [String:Any] else {
                throw NSError(domain: "JSON was not dictionary", code: 1, userInfo: nil)
            }
            return try Event(dict)
        }
        
        return mark
    }
    
    fileprivate func loadEconomies() throws -> [Int:Economy] {
        guard let filepath = Bundle.main.path(forResource: "economies", ofType: "json") else {
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
            throw NSError(domain: "JSON was not dict", code: 1, userInfo: nil)
        }
        
        var res : [Int:Economy] = [:]
        
        try jsonDict.forEach { (key: String, value: Any) in
            guard let lev = Int(key) else {
                throw NSError(domain: "Invalid Key for Economy Level: \(key)", code: 1, userInfo: nil)
            }
            if res.keys.contains(lev) {
                throw NSError(domain: "Duplicate key for Economy: \(lev)", code: 1, userInfo: nil)
            }
            guard let v = value as? [String:Any] else {
                throw NSError(domain: "Invalid value for Economy Level: \(lev)", code: 1, userInfo: nil)
            }
            let econ = try Economy(dataIn: v, level: lev)
            res[lev] = econ
        }
        
        return res
    }

}
