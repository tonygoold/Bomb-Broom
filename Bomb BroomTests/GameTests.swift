//
//  GameTests.swift
//  Bomb Broom
//
//  Created by R. Tony Goold on 2016-02-19.
//  Copyright © 2016 Tony. All rights reserved.
//

import XCTest

@testable import Bomb_Broom

class GameTests: XCTestCase {

    func testBombsArePlaced() {
        let width: Bomb_Broom.Dimension = 10
        let height: Bomb_Broom.Dimension = 10
        let numBombs: UInt = 5
        guard let game = Game(width: width, height: height, bombs: numBombs) else {
            XCTFail("Failed to create Game")
            return
        }
        var countedBombs: UInt = 0
        for i in 0..<width {
            for j in 0..<height {
                if game.tileAt(Location(x: i, y: j)).content == .bomb {
                    countedBombs += 1
                }
            }
        }
        XCTAssertEqual(numBombs, countedBombs)
    }

    func testInvalidWidth() {
        XCTAssertNil(Game(width: 0, height: 10, bombs: 5))
    }

    func testInvalidHeight() {
        XCTAssertNil(Game(width: 10, height: 0, bombs: 5))
    }

    func testTooManyBombs() {
        XCTAssertNil(Game(width: 10, height: 10, bombs: 100))
    }

    func testZeroBombsPermitted() {
        XCTAssertNotNil(Game(width: 10, height: 10, bombs: 0))
    }
}
