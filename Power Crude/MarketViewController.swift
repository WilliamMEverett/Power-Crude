//
//  MarketViewController.swift
//  Power Crude
//
//  Created by William Everett on 1/12/20.
//  Copyright © 2020 William Everett. All rights reserved.
//

import Cocoa

class MarketViewController: PhaseViewController, NSCollectionViewDelegate, NSCollectionViewDataSource, CommodityMarketViewItemDelegate {
    
    static let MarketCollectionViewIdentifier = NSUserInterfaceItemIdentifier("MarketCollectionViewIdentifier")
    
    @IBOutlet var commodityCollectionView : NSCollectionView!
    @IBOutlet var playerLabel : NSTextField!
    @IBOutlet var confirmButton : NSButton!
    @IBOutlet var sellAllButton : NSButton!
    @IBOutlet var autoButton : NSButton!
    
    @IBOutlet var moneyChangeLabel : NSTextField!
    @IBOutlet var resultingMoneyLabel : NSTextField!
    @IBOutlet var commodityResultLabel : NSTextField!
    
    fileprivate var commodityArray : [Commodity]!
    fileprivate var remainingMoney = 0
    fileprivate var playerList : [Int]?
    fileprivate var currentPlayer = 0
    
    fileprivate var adjustedMarkets : [Commodity:Market] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()
        commodityCollectionView.register(CommodityMarketViewItem.self, forItemWithIdentifier: MarketViewController.MarketCollectionViewIdentifier)
        (commodityCollectionView.collectionViewLayout as! NSCollectionViewGridLayout).maximumNumberOfColumns = 4
        
        commodityArray = Commodity.allCases.filter({ !$0.isVirtualCommodity()}).sorted(by: {
            let firstType = $0.isRawCommodity() ? 0 : ($0.isFinishedCommodity() ? 2 : 1)
            let secondType = $1.isRawCommodity() ? 0 : ($1.isFinishedCommodity() ? 2 : 1)
            return firstType < secondType
        })
        
        playerList = gameState?.playerOrder.reversed()
        
        configureForCurrentPlayer()
    }
    
    func configureForCurrentPlayer() {
        currentPlayer = (playerList?.first ?? 0)
        
        if (currentPlayer == 0) {
            delegate?.phaseCompleted(viewController: self)
            return
        }
        
        remainingMoney = gameState!.players[currentPlayer]!.money
        adjustedMarkets = [:]
        
        playerLabel.stringValue = "Player \(currentPlayer) \(gameState!.players[currentPlayer]!.playerName)"
        
        configureAuto()
    }
    
    fileprivate func recalculateCommodityCost() {
        remainingMoney = (gameState?.players[currentPlayer]!.money ?? 0)
        for c in commodityArray {
            
            let dif = calculateAmountPurchased(c)
            if dif == 0 {
                continue
            }
            guard let cost = gameState?.commodityMarket[c]?.totalPriceForBuying(qtyBought: dif) else {
                print("Error calculating cost for \(c)")
                continue
            }
            remainingMoney -= cost
        }
        let moneyDif = remainingMoney - (gameState?.players[currentPlayer]!.money ?? 0)
        if moneyDif < 0 {
            moneyChangeLabel.stringValue = "-$\(abs(moneyDif))"
        }
        else {
            moneyChangeLabel.stringValue = "+$\(moneyDif)"
        }
        resultingMoneyLabel.stringValue = "$\(remainingMoney)"
        
        var comString = ""
        for c in commodityArray {
            
            
            let totalQ = (gameState?.players[currentPlayer]?.commodities[c] ?? 0) + calculateAmountPurchased(c)
            if totalQ == 0 {
                continue
            }
            if totalQ < 0 {
                print("This should not happen")
            }
            else {
                comString += "   \(c.rawValue):\(totalQ)"
            }
        }
        commodityResultLabel.stringValue = comString
        
        commodityCollectionView.visibleItems().forEach {
            ($0 as? CommodityMarketViewItem)?.remainingPlayerMoney = remainingMoney
        }
    }
    
    fileprivate func calculateAmountPurchased(_ com : Commodity) -> Int {
        guard let adjMarket = adjustedMarkets[com] else {
            return 0
        }
        return (gameState?.commodityMarket[com]?.qty ?? 0) - adjMarket.qty
    }
    
    fileprivate func sellAll() {
        guard let currentCom = gameState?.players[currentPlayer]?.commodities else {
            return
        }
        adjustedMarkets = [:]
        
        currentCom.forEach { (key: Commodity, value: Int) in
            if key == gameState?.unavailableCommodity {
                return
            }
            var m = gameState!.commodityMarket[key]!
            let amountSold = min(m.prices.count - m.qty, value)
            m.qty += amountSold
            adjustedMarkets[key] = m
        }
        commodityCollectionView.reloadData()
        recalculateCommodityCost()
    }
    
    fileprivate func configureAuto() {
        guard let required = gameState?.players[currentPlayer]?.findRequiredCommoditiesToProduce() else {
            return
        }
        adjustedMarkets = [:]
        var adjustments = required
        gameState!.players[currentPlayer]!.commodities.forEach { (entry) in
            if entry.key == gameState!.unavailableCommodity {
                return
            }
            let existing = entry.value
            let newValue = (adjustments[entry.key] ?? 0) - existing
            adjustments[entry.key] = newValue
        }
        var startingMoney = gameState!.players[currentPlayer]!.money
        
        adjustments.filter({ $0.value < 0 }).forEach({ (entry) in
            if entry.key == gameState!.unavailableCommodity {
                return
            }
            var m = gameState!.commodityMarket[entry.key]!
            let amountSold = min(m.prices.count - m.qty, -1*entry.value)
            startingMoney -= m.totalPriceForBuying(qtyBought: -1*amountSold)!
            m.qty += amountSold
            adjustedMarkets[entry.key] = m
        })
        
        adjustments.filter({ $0.value > 0 }).forEach({ (entry) in
            if entry.key == gameState!.unavailableCommodity {
                return
            }
            var m = gameState!.commodityMarket[entry.key]!
            if let p = m.totalPriceForBuying(qtyBought: entry.value), p <= startingMoney {
                startingMoney -= p
                m.qty -= entry.value
                adjustedMarkets[entry.key] = m
            }
        })
        commodityCollectionView.reloadData()
        recalculateCommodityCost()
    }
    
    // MARK: - Actions -
    
    @IBAction func confirmButtonPressed(sender : NSButton) {
        
        var purchaseDict : [Commodity:Int] = [:]
        for c in commodityArray {
            let total = calculateAmountPurchased(c)
            if total != 0 {
                purchaseDict[c] = total
            }
        }
        gameState?.buyCommodities(player: currentPlayer, commodities: purchaseDict)
        playerList?.remove(at: 0)
        configureForCurrentPlayer()
    }
    
    @IBAction func sellAllButtonPressed(sender : NSButton) {
        sellAll()
    }
    
    @IBAction func autoButtonPressed(sender : NSButton) {
        configureAuto()
    }
    
    // MARK: - CommodityMarketViewItemDelegate -
    func commodityMarketViewItemChanged(_ item: CommodityMarketViewItem) {
        adjustedMarkets[item.market!.type] = item.market!
        recalculateCommodityCost()
    }
    
    // MARK: - CollectionViewDelegate -
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        commodityArray.count
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let cell = collectionView.makeItem(withIdentifier: MarketViewController.MarketCollectionViewIdentifier, for: indexPath) as! CommodityMarketViewItem

        if (indexPath.item < commodityArray.count) {
            let com = commodityArray[indexPath.item]
            cell.enabled = gameState?.unavailableCommodity != com
            cell.market = (adjustedMarkets[com] ?? gameState?.commodityMarket[com])
            cell.currentPlayerQty = (gameState?.players[currentPlayer]?.commodities[com] ?? 0)
            cell.currentMarketQty = (gameState?.commodityMarket[com]?.qty ?? 0)
            cell.remainingPlayerMoney = remainingMoney
            cell.delegate = self
        }
        else {
            cell.market = nil
        }
        
        return cell
    }
    

    
}
