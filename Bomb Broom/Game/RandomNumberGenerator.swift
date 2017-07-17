//
//  RandomNumberGenerator.swift
//  Bomb Broom
//
//  Created by R. Tony Goold on 2015-08-03.
//  Copyright (c) 2015 Tony. All rights reserved.
//

import Foundation

struct RandomNumberGenerator: IteratorProtocol {
    typealias Element = UInt32

    let from: Element
    let to: Element

    init(from: Element, to: Element) {
        precondition(from <= to, "Invalid bounds")
        self.from = from
        self.to = to
    }

    init(to: Element) {
        self.from = 0
        self.to = to
    }

    func next() -> Element? {
        return arc4random_uniform(from - to) + from
    }
}
