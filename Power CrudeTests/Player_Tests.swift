//
//  Player_Tests.swift
//  Power CrudeTests
//
//  Created by William Everett on 1/23/20.
//  Copyright © 2020 William Everett. All rights reserved.
//

import XCTest
@testable import Power_Crude

class Player_Tests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testProduceAssetWithInputChoice() {
        let player = Player(number: 1)
        
        guard let asset = try? Asset(dataIn: ["value" : 51,
        "output" : ["type" : "goods", "qty" : 2],
        "inputs" : [[["type" : "aluminum", "qty" : 1],["type" : "plastic", "qty" : 1],["type" : "steel", "qty" : 1],["type" : "lumber", "qty" : 1]],["type" : "energy", "qty" : 1]]]) else {
            XCTAssert(false, "Failed to initalize Asset")
            return
        }
        
        let stockpile : [Commodity:Int] = [Commodity.lumber:1]
        let startMoney = 50
        let energyBuyPrice = 8
        let energySellPrice = 4
        
        let result = player.getResultFromProducingAssets(assets: [asset], energyBuy: energyBuyPrice, energySell: energySellPrice, startingCommodities: stockpile, startingMoney: startMoney)
        
        let goodQty = result.stockpile[.goods] ?? 0
        let lumberQty = result.stockpile[.lumber] ?? 0
        XCTAssertEqual(goodQty, 2)
        XCTAssertEqual(lumberQty, 0)
        XCTAssertEqual(result.money, startMoney - energyBuyPrice)
        
        let stockpile2 : [Commodity:Int] = [.aluminum:1, .plastic:1, .steel:1]

        let result2 = player.getResultFromProducingAssets(assets: [asset], energyBuy: energyBuyPrice, energySell: energySellPrice, startingCommodities: stockpile2, startingMoney: startMoney)
        
        let goodQty2 = result2.stockpile[.goods] ?? 0
        let aluminumQty2 = result2.stockpile[.aluminum] ?? 0
        let plasticQty2 = result2.stockpile[.plastic] ?? 0
        let steelQty2 = result2.stockpile[.steel] ?? 0
        XCTAssertEqual(goodQty2, 2)
        XCTAssertEqual(aluminumQty2, 1)
        XCTAssertEqual(plasticQty2, 1)
        XCTAssertEqual(steelQty2, 0)
        XCTAssertEqual(result2.money, startMoney - energyBuyPrice)
    }


}
