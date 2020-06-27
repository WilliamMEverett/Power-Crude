//
//  Event_Tests.swift
//  Power CrudeTests
//
//  Created by William Everett on 6/26/20.
//  Copyright © 2020 William Everett. All rights reserved.
//

import XCTest
@testable import Power_Crude

class Event_Tests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testMarketUnavailable() throws {
        
        let commod = Commodity(rawValue: "Steel")!
        
        let unavailableEvent = try Event(["unavailable":commod.rawValue])
        
        let gameState = try GameState(numberOfPlayers: 4)
        
        gameState.eventDeck.append(unavailableEvent)
        gameState.phase = .Events
        gameState.finishPhase()
        
        XCTAssertNotNil(gameState.unavailableCommodity)
        if gameState.unavailableCommodity == nil {
            return
        }
        XCTAssertEqual(gameState.unavailableCommodity!, commod)
        
        gameState.phase = .Market
        gameState.finishPhase()
        XCTAssertNil(gameState.unavailableCommodity)
        
    }

}
