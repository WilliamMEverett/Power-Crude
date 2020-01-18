//
//  AssetSelectionViewController.swift
//  Power Crude
//
//  Created by William Everett on 1/18/20.
//  Copyright © 2020 William Everett. All rights reserved.
//

import Cocoa

protocol AssetSelectionViewControllerDelegate : AnyObject {
    func assetSelectionViewControllerDidSelectAsset(sender: AssetSelectionViewController, asset: Asset?)
}

class AssetSelectionViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource {

    @IBOutlet weak var tableView : NSTableView!
    @IBOutlet weak var titleTextField : NSTextField!
    @IBOutlet weak var acceptButton : NSButton!
    @IBOutlet weak var cancelButton : NSButton!
    
    var assets : [Asset]?
    weak var delegate : AssetSelectionViewControllerDelegate?
    
    convenience init( titleString : String, assetsIn : [Asset] ) {
        self.init()
        self.title = titleString
        self.assets = assetsIn
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        titleTextField.stringValue = title ?? ""
        tableView.reloadData()
        updateUI()
    }
    
    func updateUI() {
        acceptButton.isEnabled = tableView.selectedRow >= 0
    }
    
    // MARK: - Actions -
    
    @IBAction func cancelButtonPressed(sender : NSButton) {
        delegate?.assetSelectionViewControllerDidSelectAsset(sender: self, asset: nil)
    }
    
    @IBAction func accceptButtonPressed(sender : NSButton) {
        delegate?.assetSelectionViewControllerDidSelectAsset(sender: self, asset: assets?[tableView.selectedRow])
    }
    
    // MARK: - TableView Delegate -
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return assets?.count ?? 0
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        guard row >= 0 && row < (assets?.count ?? 0) else {
            return nil
        }
        return assets?[row].description
    }

    
    func tableViewSelectionDidChange(_ notification: Notification) {
        updateUI()
    }
}
