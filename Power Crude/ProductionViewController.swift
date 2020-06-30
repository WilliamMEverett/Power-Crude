//
//  ProductionViewController.swift
//  Power Crude
//
//  Created by William Everett on 1/11/20.
//  Copyright © 2020 William Everett. All rights reserved.
//

import Cocoa

class ProductionViewController: PhaseViewController, NSCollectionViewDelegate, NSCollectionViewDataSource {
    
    static let productionCollectionViewIdentifier = NSUserInterfaceItemIdentifier("productionCollectionViewIdentifier")
    
    @IBOutlet weak var collectionView : NSCollectionView!
    @IBOutlet weak var playerLabel : NSTextField!
    @IBOutlet weak var resultsLabel : NSTextField!
    @IBOutlet weak var confirmButton : NSButton!
    @IBOutlet weak var selectAllButton : NSButton!
    
    var currentPlayer : Int = 0
    var selectableIndices = Set<IndexPath>()

    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.register(AssetCollectionViewItem.self, forItemWithIdentifier: ProductionViewController.productionCollectionViewIdentifier)
        (collectionView.collectionViewLayout as! NSCollectionViewGridLayout).maximumNumberOfColumns = 3
        nextPlayer()
    }
    
    func nextPlayer() {
        if gameState == nil {
            return
        }
        
        if currentPlayer == 0 {
            currentPlayer = gameState!.playerOrder.first!
        }
        else {
            if let index = gameState!.playerOrder.firstIndex(of: currentPlayer) {
                if index + 1 >= gameState!.playerOrder.count {
                    delegate?.phaseCompleted(viewController: self)
                    return
                }
                currentPlayer = gameState!.playerOrder[index + 1]
            }
            else {
                powerCrudeHandleError(description: "Failed to find next player in production phase")
            }
        }
        
        playerLabel.stringValue = "Player \(currentPlayer) \(gameState!.players[currentPlayer]!.playerName), select which assets will produce."
        collectionView.reloadData()
        
        selectableIndices = Set(gameState!.players[currentPlayer]!.assetsThatCanProduce(energyPrice: gameState!.currentRetailPriceEnergy).map({
            IndexPath(item: $0, section: 0)
        }))
        
        collectionView.selectionIndexPaths = self.filteredSelectedIndices(selectedIn: selectableIndices, limit: 4)
        
        updatePreview()
    }
    
    func updatePreview() {
        var resultString = "Results: "
        
        let selectedAssets = collectionView.selectionIndexPaths.map({ gameState!.players[currentPlayer]!.assets[$0.item] })
        
        let results = gameState!.players[currentPlayer]!.getResultFromProducingAssets(assets: selectedAssets, energyBuy: gameState!.currentRetailPriceEnergy, energySell: gameState!.currentWholesalePriceEnergy)
        
        for c in Commodity.allCases {
            if c.isVirtualCommodity() {
                continue
            }
            let valBefore = gameState!.players[currentPlayer]!.commodities[c] ?? 0
            let valAfter = results.stockpile[c] ?? 0
            
            if (valBefore != valAfter) {
                resultString += "  \(c.rawValue) "
                if valAfter > valBefore {
                    resultString += "+"
                }
                resultString += "\(valAfter - valBefore)"
            }
        }
        if gameState!.players[currentPlayer]!.money != results.money {
            resultString += "\n"
            if gameState!.players[currentPlayer]!.money > results.money {
                resultString += "-"
            }
            else {
                resultString += "+"
            }
            resultString += "$\(abs(gameState!.players[currentPlayer]!.money - results.money))"
        }
        
        resultsLabel.stringValue = resultString
    }
    
    func filteredSelectedIndices( selectedIn : Set<IndexPath>, limit : Int) -> Set<IndexPath> {
        var selected = selectedIn.intersection(selectableIndices);
        while selected.count > 4 {
            selected.removeFirst()
        }
        return selected
    }
    
    // MARK: - Actions -
    
    @IBAction func confirmButtonPressed(sender : NSButton) {
        let selectedAssets = collectionView.selectionIndexPaths.map({ gameState!.players[currentPlayer]!.assets[$0.item] })
        
        gameState?.produceAssets(player: currentPlayer, assets: selectedAssets)
        
        nextPlayer()
    }
    
    @IBAction func selectAllButtonPressed(sender : NSButton) {
        collectionView.selectionIndexPaths = self.filteredSelectedIndices(selectedIn: selectableIndices, limit: 4)
        updatePreview()
    }
    
    // MARK: - CollectionView delegate -
    
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return (gameState?.players[currentPlayer]?.assets.count ?? 0)
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let cell = collectionView.makeItem(withIdentifier: ProductionViewController.productionCollectionViewIdentifier, for: indexPath) as! AssetCollectionViewItem

        if (indexPath.item <= (gameState?.players[currentPlayer]?.assets.count ?? 0)) {
            cell.asset = gameState!.players[currentPlayer]!.assets[indexPath.item]
        }
        else {
            cell.asset = nil
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        if collectionView.selectionIndexPaths.count > 4 {
            var selected = collectionView.selectionIndexPaths
            while selected.count > 4 {
                selected.removeFirst()
            }
            collectionView.selectionIndexPaths = selected
        }
        updatePreview()
    }
    
    func collectionView(_ collectionView: NSCollectionView, didDeselectItemsAt indexPaths: Set<IndexPath>) {
        updatePreview()
    }
    
    func collectionView(_ collectionView: NSCollectionView, shouldSelectItemsAt indexPaths: Set<IndexPath>) -> Set<IndexPath> {
        return filteredSelectedIndices(selectedIn: indexPaths, limit: 4)
    }
    

}
