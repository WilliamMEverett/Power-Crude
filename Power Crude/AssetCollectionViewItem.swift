//
//  AssetCollectionViewItem.swift
//  Power Crude
//
//  Created by William Everett on 1/6/20.
//  Copyright © 2020 William Everett. All rights reserved.
//

import Cocoa

class AssetCollectionViewItem: NSCollectionViewItem {
    
    @IBOutlet weak var valueLabel : NSTextField!
    @IBOutlet weak var typeLabel : NSTextField!
    @IBOutlet weak var inputLabel : NSTextField!
    @IBOutlet weak var outputLabel : NSTextField!
    @IBOutlet weak var displayBox : NSBox!

    var asset : Asset? {
        didSet {
            if (asset == nil) {
                self.view.isHidden = true
            }
            else {
                self.view.isHidden = false
                valueLabel.stringValue = "\(asset!.value)"
                typeLabel.stringValue = String(describing:asset!.type).capitalized
                inputLabel.stringValue = asset!.inputDescription
                outputLabel.stringValue = String(describing: asset!.output)
            }
        }
    }
    
    override var isSelected: Bool {
        didSet {
            if isSelected {
                displayBox.fillColor = NSColor.yellow
            }
            else {
                displayBox.fillColor = NSColor.clear
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    
}
