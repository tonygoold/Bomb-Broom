//
//  Game.swift
//  Bomb Broom
//
//  Created by R. Tony Goold on 2015-08-03.
//  Copyright (c) 2015 Tony. All rights reserved.
//

import Foundation

typealias Dimension = UInt32

enum TileType {
    case Empty
    case Bomb
}

enum TileStatus {
    case Unknown
    case Flagged
    case Revealed
    case Exploded
}

struct Tile {
    let type: TileType
    var status: TileStatus = .Unknown

    init(type: TileType) {
        self.type = type
    }
}

struct Location: Equatable, Printable {
    let x: Dimension
    let y: Dimension

    init(x: Dimension, y: Dimension) {
        self.x = x
        self.y = y
    }

    var description: String {
        return "(\(x), \(y))"
    }
}

func ==(lhs: Location, rhs: Location) -> Bool {
    return lhs.x == rhs.x && lhs.y == rhs.y
}

enum GameState {
    case Initialized
    case Running
    case Won
    case Lost
}

protocol GameObserver: class {
    func tileStatusChanged(tile: Tile, location: Location)

    func gameWon()
    func gameLost()
}

class Game {
    private var tiles = Array<Tile>();
    private var observers = Array<GameObserver>()

    let width: Dimension
    let height: Dimension
    let bombs: UInt
    var state: GameState = .Initialized

    init(width: Dimension, height: Dimension, bombs: UInt) {
        precondition(width > 0, "Width must be greater than zero")
        precondition(height > 0, "Height must be greater than zero")
        precondition(bombs < UInt(width * height), "Too many bombs")
        self.width = width
        self.height = height
        self.bombs = bombs
    }

    var flagCount: UInt {
        return UInt(tiles.filter { $0.status == .Flagged }.count)
    }

    var revealedCount: UInt {
        return UInt(tiles.filter { $0.status == .Revealed && $0.type == .Empty }.count)
    }

    func meetsWinCondition() -> Bool {
        return self.revealedCount + bombs == UInt(width * height)
    }

    func observerIndex(observer: GameObserver) -> Int? {
        for i in 0..<observers.count {
            if observer === observers[i] {
                return i
            }
        }
        return nil
    }

    func addObserver(observer: GameObserver) {
        let index = observerIndex(observer)
        if index == nil {
            observers.append(observer)
        }
    }

    func removeObserver(observer: GameObserver) {
        if let index = observerIndex(observer) {
            observers.removeAtIndex(index)
        }
    }

    func tileAt(location: Location) -> Tile {
        precondition(location.x >= 0 && location.x < width, "Location x coordinate out of bounds")
        precondition(location.y >= 0 && location.y < height, "Location y coordinate out of bounds")
        return tiles.count == 0 ? Tile(type: .Empty) : tiles[toIndex(location)]
    }

    func toggleFlag(location: Location) {
        let index = toIndex(location)
        var tile = tiles[index]
        tile.status = tile.status == .Flagged ? .Unknown : .Flagged
        tiles[index] = tile
        for observer in observers {
            observer.tileStatusChanged(tile, location: location)
        }
    }

    func reveal(location: Location) {
        println("Reveal: \(location)")
        if tiles.count == 0 {
            generate(location)
        }

        let index = toIndex(location)
        var tile = tiles[index]

        // Don't process already revealed tiles
        if tile.status == .Revealed {
            return
        }

        tile.status = tile.type == .Bomb ? .Exploded : .Revealed
        tiles[index] = tile

        for observer in observers {
            observer.tileStatusChanged(tile, location: location)
        }

        if tile.type == .Bomb {
            state = .Lost
            for observer in observers {
                observer.gameLost()
            }
        } else if meetsWinCondition() {
            state = .Won
            for observer in observers {
                observer.gameWon()
            }
        } else {
            let neighbours = neighbourhood(location)
            if neighbours.filter({ self.tiles[self.toIndex($0)].type == .Bomb }).count == 0 {
                for neighbour in neighbours {
                    reveal(neighbour)
                }
            }
        }
    }

    func revealSafe(location: Location) {
        println("Reveal (safe): \(location)")
        let neighbours = neighbourhood(location)
        let flagged = neighbours.filter {
            self.tiles[self.toIndex($0)].status == .Flagged
        }.count
        let bombs = neighbours.filter {
            self.tiles[self.toIndex($0)].type == .Bomb
        }.count
        if flagged != bombs { return }
        let safeNeighbours = neighbourhood(location).filter {
            self.tiles[self.toIndex($0)].status == .Unknown
        }
        for neighbour in safeNeighbours {
            reveal(neighbour)
        }
    }

    func neighbourhood(location: Location) -> Array<Location> {
        var left = location.x > 0 ? location.x - 1 : location.x
        var right = location.x + 1 < width ? location.x + 1 : location.x
        var top = location.y > 0 ? location.y - 1 : location.y
        var bottom = location.y + 1 < height ? location.y + 1 : location.y

        var neighbourhood = Array<Location>()
        neighbourhood.reserveCapacity(8)
        for y in top...bottom {
            for x in left...right {
                let neighbour = Location(x: x, y: y)
                if neighbour != location {
                    neighbourhood.append(neighbour)
                }
            }
        }
        return neighbourhood
    }

    func bombsNear(location: Location) -> UInt {
        return UInt(neighbourhood(location).filter {
            return self.tiles[self.toIndex($0)].type == .Bomb
        }.count)
    }

    private func toIndex(location: Location) -> Int {
        return Int(location.x + width * location.y)
    }

    private func generate(excluding: Location?) {
        // Generate a random map by placing all the bombs first, filling the
        // remaining positions with empty tiles, and shuffling randomly.
        let size = width * height
        tiles = (0..<size).map {
            return Tile(type: UInt($0) < self.bombs ? .Bomb : .Empty)
        }

        // Since the last tile is guaranteed to be empty, it can be excluded
        // from the shuffle and then swapped with a given location to ensure
        // that location is empty after the shuffle.
        let end = excluding != nil ? size - 1 : size;
        for i in 0..<end {
            // Fisher-Yates shuffle algorithm
            let j = arc4random_uniform(end - i) + i
            swap(&tiles[Int(i)], &tiles[Int(j)])
        }
        if let location = excluding {
            swap(&tiles[toIndex(location)], &tiles[Int(size) - 1])
        }
    }
}