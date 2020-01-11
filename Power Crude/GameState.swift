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
    
    var stage : Int = 1
    var movingToStage2 : Bool = false
    var playerOrder = [Int]()
    var players : [Int:Player] = [:]
    
    var lowestAssetInMarket : Asset? = nil
    
    init(numberOfPlayers : Int) throws {
        super.init()
        
        let assets = try loadAssets()
        
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
        
        NotificationCenter.default.post(name: GameState.kGameStateChangedNotification, object: self)
    }
    
    func purchaseAssetIndexFromMarketForPlayer(regularMarket : Bool, index : Int, price : Int, player : Int) -> Bool {
        if regularMarket {
            players[player]?.assets.append(auctionMarket.remove(at: index))
        }
        else {
            players[player]?.assets.append(mfgAuctionMarket.remove(at: index))
        }
        
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

}
