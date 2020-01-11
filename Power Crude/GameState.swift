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
