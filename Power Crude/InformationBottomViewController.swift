//
//  InformationBottomViewController.swift
//  Power Crude
//
//  Created by William Everett on 1/18/20.
//  Copyright © 2020 William Everett. All rights reserved.
//

import Cocoa

class InformationBottomViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource {
    
    @IBOutlet weak var rawGoodsLabel : NSTextField!
    @IBOutlet weak var refinedGoodsLabel : NSTextField!
    @IBOutlet weak var finishedGoodsLabel : NSTextField!
    @IBOutlet weak var unavailableMarketLabel : NSTextField!
    @IBOutlet weak var playerTableView : NSTableView!
    @IBOutlet weak var assetMarketTableView : NSTableView!
    
    var notificationObject : NSObjectProtocol? = nil
    
    var gameState : GameState? = nil {
        didSet {
            refreshGameInformation()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        refreshGameInformation()
        
        weak var weakSelf = self
        self.notificationObject = NotificationCenter.default.addObserver(forName: GameState.kGameStateChangedNotification, object: nil, queue: nil, using: {notification in
            if weakSelf?.gameState == notification.object as? GameState {
                weakSelf?.refreshGameInformation()
            }
        })
    }
    
    deinit {
        if notificationObject != nil {
            NotificationCenter.default.removeObserver(notificationObject!)
        }
    }
    
    func refreshGameInformation() {
        playerTableView.reloadData()
        assetMarketTableView.reloadData()
        
        guard let nonNilGameState = gameState else {
            rawGoodsLabel.stringValue = ""
            refinedGoodsLabel.stringValue = ""
            finishedGoodsLabel.stringValue = ""
            unavailableMarketLabel.stringValue = ""
            return
        }
        
        let rawCommodityArray = Commodity.allCases.filter({!$0.isVirtualCommodity() && $0.isRawCommodity()})
        let refinedCommodityArray = Commodity.allCases.filter({!$0.isVirtualCommodity() && $0.isRefinedCommodity()})
        let finishedCommodityArray = Commodity.allCases.filter({!$0.isVirtualCommodity() && $0.isFinishedCommodity()})
        
        let rawCommodityString = rawCommodityArray.reduce("") { (res, c) -> String in
            let sellPrice = nonNilGameState.commodityMarket[c]?.currentSellPrice
            let sellPriceString = sellPrice != nil ? "\(sellPrice!)" : "-"
            let buyPrice = nonNilGameState.commodityMarket[c]?.currentBuyPrice
            let buyPriceString = buyPrice != nil ? "\(buyPrice!)" : "-"
            let q = nonNilGameState.commodityMarket[c]?.qty ?? 0
            
            return res + c.rawValue  + " " + sellPriceString + "/" + buyPriceString + " (\(q))  "
        }
        rawGoodsLabel.stringValue = rawCommodityString
        
        let refinedCommodityString = refinedCommodityArray.reduce("") { (res, c) -> String in
            let sellPrice = nonNilGameState.commodityMarket[c]?.currentSellPrice
            let sellPriceString = sellPrice != nil ? "\(sellPrice!)" : "-"
            let buyPrice = nonNilGameState.commodityMarket[c]?.currentBuyPrice
            let buyPriceString = buyPrice != nil ? "\(buyPrice!)" : "-"
            let q = nonNilGameState.commodityMarket[c]?.qty ?? 0
            
            return res + c.rawValue  + " " + sellPriceString + "/" + buyPriceString + " (\(q))  "
        }
        refinedGoodsLabel.stringValue = refinedCommodityString
        
        let finishedCommodityString = finishedCommodityArray.reduce("") { (res, c) -> String in
            let sellPrice = nonNilGameState.commodityMarket[c]?.currentSellPrice
            let sellPriceString = sellPrice != nil ? "\(sellPrice!)" : "-"
            
            return res + c.rawValue  + " " + sellPriceString + "   "
        }
        finishedGoodsLabel.stringValue = finishedCommodityString
        
        if let comm = nonNilGameState.unavailableCommodity {
            unavailableMarketLabel.stringValue = "\(comm.rawValue) market unavailable"
        }
        else {
            unavailableMarketLabel.stringValue = ""
        }
    }
    
    //MARK: - TableView Delegate -
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        if tableView == playerTableView {
            return gameState?.playerOrder.count ?? 0
        }
        else if tableView == assetMarketTableView {
            return (gameState?.auctionMarket.count ?? 0) + (gameState?.mfgAuctionMarket.count ?? 0)
        }
        else {
            return 0
        }
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        if tableView == playerTableView {
            if row < 0 || row >= (gameState?.playerOrder.count ?? 0) {
                return nil
            }
            let p = gameState!.players[gameState!.playerOrder[row]]!
            return "\(p.playerNumber) - [\(p.totalAssetValue)] $\(p.money)"
        }
        else if tableView == assetMarketTableView {
            if row < 0 || row >= ((gameState?.auctionMarket.count ?? 0) + (gameState?.mfgAuctionMarket.count ?? 0)) {
                return nil
            }
            if row < gameState!.mfgAuctionMarket.count {
                return gameState!.mfgAuctionMarket[row].description
            }
            else {
                return gameState!.auctionMarket[row - gameState!.mfgAuctionMarket.count].description
            }
            
        }
        else {
            return nil
        }
    }
    
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        return false
    }
}
