//
//  CommodityMarketViewItem.swift
//  Power Crude
//
//  Created by William Everett on 1/12/20.
//  Copyright © 2020 William Everett. All rights reserved.
//

import Cocoa

protocol CommodityMarketViewItemDelegate : AnyObject {
    func commodityMarketViewItemChanged(_ item : CommodityMarketViewItem)
}

class CommodityMarketViewItem: NSCollectionViewItem {
    
    @IBOutlet var commodityLabelTextField : NSTextField!
    @IBOutlet var commodityQuantityTextField : NSTextField!
    @IBOutlet var sellPriceTextField : NSTextField!
    @IBOutlet var buyPriceTextField : NSTextField!
    @IBOutlet var qtyChangeTextField : NSTextField!
    @IBOutlet var buyButton : NSButton!
    @IBOutlet var sellButton : NSButton!
    
    weak var delegate : CommodityMarketViewItemDelegate? = nil
    
    var market : Market? = nil {
        didSet {
            commodityLabelTextField.stringValue = market?.type.rawValue ?? ""
        }
    }
    
    var currentMarketQty : Int = 0
    var currentPlayerQty : Int = 0
    
    var remainingPlayerMoney : Int = 0 {
        didSet {
            updateUI()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    func updateUI() {
        if market == nil {
            buyButton.isEnabled = false
            sellButton.isEnabled = false
        }
        
//        buyPriceTextField.isHidden = market!.type.isFinishedCommodity()
//        buyButton.isHidden = market!.type.isFinishedCommodity()
        
        let qtyBought = currentMarketQty - market!.qty
        
        if (qtyBought >= 0) {
            qtyChangeTextField.stringValue = "+\(qtyBought)"
        }
        else {
            qtyChangeTextField.stringValue = "\(qtyBought)"
        }
        
        if let buyPrice = market!.currentBuyPrice, !market!.type.isFinishedCommodity() || qtyBought < 0 {
            buyPriceTextField.stringValue = "\(buyPrice)"
            buyButton.isEnabled = buyPrice <= remainingPlayerMoney
        }
        else {
            buyPriceTextField.stringValue = "-"
            buyButton.isEnabled = false
        }
        
        if let sellPrice = market!.currentSellPrice {
            sellPriceTextField.stringValue = "\(sellPrice)"
            sellButton.isEnabled = currentPlayerQty + qtyBought > 0
        }
        else {
            sellPriceTextField.stringValue = "-"
            sellButton.isEnabled = false
        }
        commodityQuantityTextField.stringValue = "\(market!.qty)"
    }
    
    @IBAction func buyButtonPressed(sender : NSButton) {
        if let price = market?.currentBuyPrice {
            market?.qty -= 1
            remainingPlayerMoney -= price
            updateUI()
            delegate?.commodityMarketViewItemChanged(self)
        }
    }
    
    @IBAction func sellButtonPressed(sender : NSButton) {
        if let price = market?.currentSellPrice {
            market?.qty += 1
            remainingPlayerMoney += price
            updateUI()
            delegate?.commodityMarketViewItemChanged(self)
         }
    }


    
}
