//
//  GameStartConfigureViewController.swift
//  Power Crude
//
//  Created by William Everett on 6/29/20.
//  Copyright © 2020 William Everett. All rights reserved.
//

import Cocoa

protocol GameStartConfigureViewControllerDelegate: AnyObject {
    func setPlayerNames(_ viewController : GameStartConfigureViewController, players : [String])
}

class GameStartConfigureViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    
    @IBOutlet var playerNumberSelectPopup : NSPopUpButton!
    @IBOutlet var playerConfigureTableView : NSTableView!
    
    weak var delegate : GameStartConfigureViewControllerDelegate? = nil
    
    var numberOfPlayers = 4
    
    var playerNames : [String] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
    }
    
    func configureView() {
        playerNumberSelectPopup.selectItem(withTitle: "\(numberOfPlayers)")
        playerConfigureTableView.reloadData()
    }
    
    @IBAction func selectPlayersChanged(_ sender : NSPopUpButton)  {
        if let title = sender.selectedItem?.title {
            if let number = Int(title) {
                numberOfPlayers = number
                configureView()
            }
            else {
                print("Invalid number selection...")
            }
        }
    }
    
    @IBAction func startButtonPressed(_ sender : NSButton) {
        
        while playerNames.count < numberOfPlayers {
            playerNames.append("")
        }
        
        delegate?.setPlayerNames(self, players: Array(playerNames[0..<numberOfPlayers]))
        NSApplication.shared.stopModal(withCode: .OK)
    }
    
    // MARK: - TableView delegate -
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return numberOfPlayers
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        if tableColumn == nil {
            print("No table column...")
            return ""
        }
        guard let columnIndex = tableView.tableColumns.lastIndex(of: tableColumn!) else {
            print("No table column...")
            return ""
        }
        if columnIndex == 0 {
            return "Player \(row + 1)"
        }
        else {
            if playerNames.count > row {
                return playerNames[row]
            }
            else {
                return ""
            }
        }
    }
    
    func controlTextDidEndEditing(_ obj: Notification) {
        let editedRow = playerConfigureTableView.editedRow
        if (editedRow < 0) {
            print("Invalid row...")
            return
        }
        while playerNames.count <= editedRow {
            playerNames.append("")
        }
        if let textView = obj.userInfo?["NSFieldEditor"] as? NSTextView {
            playerNames[editedRow] = textView.string.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        }
        
        configureView()
    }
    
}
