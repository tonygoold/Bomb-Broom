//
//  MapFilter.swift
//  Bomb Broom
//
//  Created by R. Tony Goold on 2015-09-06.
//  Copyright (c) 2015 Tony. All rights reserved.
//

import Swift

extension Array {
    func mapFilter<T>(transform: (Array.Generator.Element) -> T?) -> [T] {
        return self.flatMap {
            if let x = transform($0) { return [x] } else { return [] }
        }
    }
}
