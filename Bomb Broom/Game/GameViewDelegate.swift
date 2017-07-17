//
//  GameViewDelegate.swift
//  Bomb Broom
//
//  Created by R. Tony Goold on 2015-09-07.
//  Copyright (c) 2015 Tony. All rights reserved.
//

import Foundation

protocol GameViewDelegate {
    func tileAt(_ location: Location) -> Tile
    func bombsNear(_ location: Location) -> UInt

    func tilePressed(_ location: Location)
}
