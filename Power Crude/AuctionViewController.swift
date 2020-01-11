//
//  AuctionViewController.swift
//  Power Crude
//
//  Created by William Everett on 1/6/20.
//  Copyright © 2020 William Everett. All rights reserved.
//

import Cocoa

class AuctionViewController: NSViewController, NSCollectionViewDataSource, NSCollectionViewDelegate {

    static let assetCollectionViewIdentifier = NSUserInterfaceItemIdentifier("assetCollectionViewIdentifier")
    
    weak var gameState : GameState?
    
    @IBOutlet weak var collectionView : NSCollectionView!
    @IBOutlet weak var messageTextField : NSTextField!
    @IBOutlet weak var passButton : NSButton!
    @IBOutlet weak var sellButton : NSButton!
    @IBOutlet weak var minusButton : NSButton!
    @IBOutlet weak var plusButton : NSButton!
    @IBOutlet weak var priceTextField : NSTextField!
    
    @IBOutlet weak var remainingPlayersTextField : NSTextField!
    @IBOutlet weak var remainingBiddingTextField : NSTextField!
    
    var biddingPlayerIndex : Int = 0
    var biddingPlayerBid : Int = 0
    var passedPlayersOnBidding = Set<Int>()
    var playersWhoHaveFinished = Set<Int>()
    var selectedAssetIndexPath : IndexPath? = nil
    var highestCurrentBid : (player: Int, bid: Int)? = nil
    var currentPlayerIndex : Int = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.register(AssetCollectionViewItem.self, forItemWithIdentifier: AuctionViewController.assetCollectionViewIdentifier)
        
        if (gameState?.stage == 2) {
            (collectionView.collectionViewLayout as! NSCollectionViewGridLayout).maximumNumberOfColumns = 4
        }
        else {
            (collectionView.collectionViewLayout as! NSCollectionViewGridLayout).maximumNumberOfColumns = 3
        }
        collectionView.reloadData()
        findCurrentPlayer()
    }
    
    fileprivate func findCurrentPlayer() {
        currentPlayerIndex = gameState!.playerOrder.first(where: {!playersWhoHaveFinished.contains($0)}) ?? 0
        
        if (currentPlayerIndex == 0) {
// TODO: Auction phase over
        }
        configureUIForCurrentState()
    }
    
    fileprivate func findNextBidder() {
        guard let nonNilHighestCurrentBid = highestCurrentBid else {
            print("This shouldn't happen")
            exit(-1)
        }
        
        biddingPlayerIndex += 1
        while (biddingPlayerIndex > gameState?.players.count ?? 1 || playersWhoHaveFinished.contains(biddingPlayerIndex) || passedPlayersOnBidding.contains(biddingPlayerIndex) || gameState?.players[biddingPlayerIndex]?.money ?? 0 <= nonNilHighestCurrentBid.bid || gameState?.players[biddingPlayerIndex]?.hasMaximumNumberOfAssets ?? false ) {
            if (biddingPlayerIndex == nonNilHighestCurrentBid.player) {
                break;
            }
            if (gameState?.players.keys.contains(biddingPlayerIndex) ?? false && (gameState!.players[biddingPlayerIndex]!.money <= nonNilHighestCurrentBid.bid || gameState!.players[biddingPlayerIndex]!.hasMaximumNumberOfAssets)) {
                passedPlayersOnBidding.insert(biddingPlayerIndex)
            }
            
            if (biddingPlayerIndex > gameState?.players.count ?? 1) {
                biddingPlayerIndex = 1
            }
            else {
                biddingPlayerIndex += 1
            }
        }
        
        //player has won bidding
        if (biddingPlayerIndex == nonNilHighestCurrentBid.player) {
            playersWhoHaveFinished.insert(nonNilHighestCurrentBid.player)
            if gameState?.purchaseAssetIndexFromMarketForPlayer(regularMarket: selectedAssetIndexPath!.section != 1, index: selectedAssetIndexPath!.item, price: nonNilHighestCurrentBid.bid, player: nonNilHighestCurrentBid.player) ?? false {
                //stage 2 has begun
            }
            
            selectedAssetIndexPath = nil
            collectionView.deselectAll(nil)
            
            passedPlayersOnBidding = Set()
            highestCurrentBid = nil
            biddingPlayerIndex = 0
            biddingPlayerBid = 0
            
            collectionView.reloadData()
            
            findCurrentPlayer()
            
        }
        else {
            biddingPlayerBid = nonNilHighestCurrentBid.bid + 1
            configureUIForCurrentState()
        }
        
    }
    
    fileprivate func configureUIForCurrentState() {
        if gameState == nil {
            return
        }
        if (selectedAssetIndexPath == nil) {
            priceTextField.isHidden = true
            minusButton.isHidden = true
            plusButton.isHidden = true
            sellButton.title = "Sell"
            passButton.title = "Pass"
            
            
            let currentPlayer = gameState!.players[currentPlayerIndex]!
            
            sellButton.isEnabled = currentPlayer.assets.count > 0
            
            messageTextField.stringValue = "Player \(currentPlayerIndex), select an asset to buy, pass, or sell an asset."
            remainingBiddingTextField.isHidden = true
            
        }
        else {
            priceTextField.isHidden = false
            priceTextField.stringValue = "\(biddingPlayerBid)"
            sellButton.title = "Bid"
            minusButton.isHidden = false
            plusButton.isHidden = false
            remainingBiddingTextField.isHidden = false
            
            let remainingPlayers = gameState?.players.keys.filter({!passedPlayersOnBidding.contains($0) && !playersWhoHaveFinished.contains($0)}).sorted().map({"\($0)"}) ?? []
            var remainBidString = "Players in bidding: \(remainingPlayers.joined(separator:", "))"
            
            plusButton.isEnabled = gameState!.players[biddingPlayerIndex]!.money > biddingPlayerBid
            if (highestCurrentBid != nil) {
                minusButton.isEnabled = biddingPlayerBid > highestCurrentBid!.bid + 1
                passButton.title = "Pass"
                remainBidString += "  Current high bid: Player \(highestCurrentBid!.player)"
            }
            else {
                minusButton.isEnabled = biddingPlayerBid > assetForIndexPath(path: selectedAssetIndexPath!)!.value
                passButton.title = "Cancel"
            }
            
            remainingBiddingTextField.stringValue = remainBidString
            
            sellButton.isEnabled = gameState!.players[biddingPlayerIndex]!.money >= biddingPlayerBid
            
            passButton.isEnabled = true
            
            if highestCurrentBid == nil {
                messageTextField.stringValue = "Player \(biddingPlayerIndex), bid or cancel."
            }
            else {
                messageTextField.stringValue = "Player \(biddingPlayerIndex), bid or pass."
            }
            
        }
        
        let remainingMovePlayers = gameState?.playerOrder.filter({!playersWhoHaveFinished.contains($0)}).map({"\($0)"}) ?? []
        remainingPlayersTextField.stringValue = "Players remaining: \(remainingMovePlayers.joined(separator: ", "))"
    }
    
    fileprivate func assetForIndexPath(path : IndexPath) -> Asset? {
        let market : [Asset]? = path.section == 1 ? gameState?.mfgAuctionMarket : gameState?.auctionMarket
        let selectedAsset = market?[path.item]
        return selectedAsset
    }

// MARK: - Actions

    @IBAction func passButtonPressed(sender : NSButton) {
        if (selectedAssetIndexPath == nil) {
            playersWhoHaveFinished.insert(currentPlayerIndex)
            findCurrentPlayer()
        }
        else if (highestCurrentBid == nil) {
            selectedAssetIndexPath = nil
            collectionView.deselectAll(nil)
            configureUIForCurrentState()
        }
        else {
            passedPlayersOnBidding.insert(biddingPlayerIndex)
            findNextBidder()
        }
    }
    
    @IBAction func sellBidButtonPressed(sender : NSButton) {
        if (selectedAssetIndexPath == nil) {
            
        }
        else if (biddingPlayerBid > highestCurrentBid?.bid ?? 0 && biddingPlayerBid >= assetForIndexPath(path: selectedAssetIndexPath!)?.value ?? 1000 && biddingPlayerBid <= gameState?.players[biddingPlayerIndex]?.money ?? 0 ) {
            highestCurrentBid = (player:biddingPlayerIndex,bid:biddingPlayerBid)
            findNextBidder()
        }
    }
    
    @IBAction func plusButtonPressed(sender : NSButton) {
        biddingPlayerBid += 1
        configureUIForCurrentState()
    }
    
    @IBAction func minusButtonPressed(sender : NSButton) {
        biddingPlayerBid -= 1
        configureUIForCurrentState()
    }
    
// MARK: - CollectionView delegate -
    func numberOfSections(in collectionView: NSCollectionView) -> Int {
        if (gameState?.stage ?? 1 == 1) {
            return 1
        }
        else {
            return 2
        }
    }
    
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        if (section == 0) {
            let auctionSize = (gameState?.stage ?? 1 == 1) ? 6 : 4
            
            return min(auctionSize, gameState?.auctionMarket.count ?? 0)
        }
        else {
            return min(4,gameState?.mfgAuctionMarket.count ?? 0)
        }
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let cell = collectionView.makeItem(withIdentifier: AuctionViewController.assetCollectionViewIdentifier, for: indexPath) as! AssetCollectionViewItem
        let market = indexPath.section == 0 ? gameState?.auctionMarket : gameState?.mfgAuctionMarket
        if (indexPath.item <= market?.count ?? 0) {
            cell.asset = market![indexPath.item]
        }
        else {
            cell.asset = nil
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        if (highestCurrentBid == nil) {
            selectedAssetIndexPath = indexPaths.first
            biddingPlayerBid = 0
            biddingPlayerIndex = currentPlayerIndex
            passedPlayersOnBidding = Set()
            if selectedAssetIndexPath != nil, let selectedAsset = assetForIndexPath(path: selectedAssetIndexPath!) {
                biddingPlayerBid = selectedAsset.value
            }
            configureUIForCurrentState()
        }
    }
    
    func collectionView(_ collectionView: NSCollectionView, didDeselectItemsAt indexPaths: Set<IndexPath>) {
        if (highestCurrentBid == nil) {
            selectedAssetIndexPath = nil
            configureUIForCurrentState()
        }
    }
    
    func collectionView(_ collectionView: NSCollectionView, shouldSelectItemsAt indexPaths: Set<IndexPath>) -> Set<IndexPath> {
        if highestCurrentBid != nil && selectedAssetIndexPath != nil {
            return Set<IndexPath>([selectedAssetIndexPath!])
        }
        else {
            if let indexPath = indexPaths.first, let asset = assetForIndexPath(path: indexPath), currentPlayerIndex > 0 {
                if gameState!.players[currentPlayerIndex]!.money >= asset.value && !gameState!.players[currentPlayerIndex]!.hasMaximumNumberOfAssets {
                    return indexPaths
                }
            }
            return Set<IndexPath>()
        }
    }
    
    func collectionView(_ collectionView: NSCollectionView, shouldDeselectItemsAt indexPaths: Set<IndexPath>) -> Set<IndexPath> {
        if highestCurrentBid != nil && selectedAssetIndexPath != nil {
             return Set<IndexPath>()
         }
         else {
             return indexPaths
         }
    }
}
