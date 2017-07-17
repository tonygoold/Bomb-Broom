//
//  Game.swift
//  Bomb Broom
//
//  Created by R. Tony Goold on 2015-08-03.
//  Copyright (c) 2015 Tony. All rights reserved.
//

import Foundation

/// The type used for expressing width, height, and position.
typealias Dimension = UInt32

/**
 *  Represents a single tile in the game.
 */
struct Tile {
    enum Content {
        case empty
        case bomb
    }

    enum Status {
        case unknown
        case flagged
        case revealed
        case exploded
    }

    let content: Content
    var status = Status.unknown

    init(content: Content) {
        self.content = content
    }
}

/**
 *  Represents the location of a tile.
 */
struct Location: Equatable, CustomStringConvertible {
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

/// Observes changes to a Game
protocol GameObserver: class {
    /**
     Called whenever a tile changes status.

     - parameter game:     The game to which the tile belongs.
     - parameter tile:     The tile that changed.
     - parameter location: The tile's location.
     */
    func tileStatusChanged(_ game: Game, tile: Tile, location: Location)

    /**
     Called when the game has been won. This happens when all the non-bomb tiles
     have been revealed.
     
     - parameter game: The game that was won.
     */
    func gameWon(_ game: Game)

    /**
     Called when the game has been lost. This happens when a bomb tile is
     revealed.

     - parameter game: The game that was lost.
     */
    func gameLost(_ game: Game)
}

/// Represents the game state.
class Game {
    enum State {
        case initialized
        case running
        case won
        case lost
    }

    let width: Dimension
    let height: Dimension
    let bombs: UInt
    var state: State = .initialized

    private var tiles = Array<Tile>();
    private var observers = Array<GameObserver>()

    /**
     Creates a new Game.

     - parameter width:  The width in number of tiles.
     - parameter height: The height in number of tiles.
     - parameter bombs:  The number of bombs. Must be less than total number of tiles.

     - returns: A new Game instance.
     */
    init?(width: Dimension, height: Dimension, bombs: UInt) {
        self.width = width
        self.height = height
        self.bombs = bombs

        if width <= 0 || height <= 0 || bombs >= UInt(width * height) {
            return nil
        }
    }

    /// The number of tiles that have been flagged.
    var flagCount: UInt {
        return UInt(tiles.filter { $0.status == .flagged }.count)
    }

    /// The number of tiles that have been revealed.
    var revealedCount: UInt {
        return UInt(tiles.filter { $0.status == .revealed && $0.content == .empty }.count)
    }

    /**
     Returns true if the game winning condition has been met.

     - returns: True if the game has been won.
     */
    private func meetsWinCondition() -> Bool {
        return self.revealedCount + bombs == UInt(width * height)
    }

    /**
     Adds a game observer.

     - parameter observer: An observer.
     */
    func addObserver(_ observer: GameObserver) {
        if !observers.contains(where: { $0 === observer }) {
            observers.append(observer)
        }
    }

    /**
     Removes a game observer.

     - parameter observer: An observer.
     */
    func removeObserver(_ observer: GameObserver) {
        if let index = observers.index(where: { $0 === observer }) {
            observers.remove(at: index)
        }
    }

    /**
     Returns the tile for a given location.

     - parameter location: A location.

     - returns: A tile.
     */
    func tileAt(_ location: Location) -> Tile {
        precondition(location.x >= 0 && location.x < width, "Location x coordinate out of bounds")
        precondition(location.y >= 0 && location.y < height, "Location y coordinate out of bounds")
        return tiles.count == 0 ? Tile(content: .empty) : tiles[toIndex(location: location)]
    }

    /**
     Toggles the bomb flag for a location.

     - parameter location: A location.
     */
    func toggleFlag(_ location: Location) {
        if state == .won || state == .lost {
            return
        }

        generateIfNecessary(excluding: nil)

        if state == .initialized {
            state = .running
        }

        let index = toIndex(location: location)
        var tile = tiles[index]
        tile.status = tile.status == .flagged ? .unknown : .flagged
        tiles[index] = tile
        for observer in observers {
            observer.tileStatusChanged(self, tile: tile, location: location)
        }
    }

    /**
     Reveals the tile at a given location. The first time this is called, if the
     tile arrangement has not been generated, it will generate a random one that
     ensures the given location does not contain a bomb.

     - parameter location: A location.
     */
    func reveal(_ location: Location) {
        if state == .won || state == .lost {
            return
        }

        generateIfNecessary(excluding: location)

        if state == .initialized {
            state = .running
        }

        let index = toIndex(location: location)
        var tile = tiles[index]

        // Don't process already revealed tiles
        if tile.status == .revealed {
            return
        }

        tile.status = tile.content == .bomb ? .exploded : .revealed
        tiles[index] = tile

        for observer in observers {
            observer.tileStatusChanged(self, tile: tile, location: location)
        }

        if tile.content == .bomb {
            state = .lost
            for observer in observers {
                observer.gameLost(self)
            }
        } else if meetsWinCondition() {
            state = .won
            for observer in observers {
                observer.gameWon(self)
            }
        } else {
            let neighbours = neighbourhood(location: location)
            if neighbours.filter({ self.tiles[self.toIndex(location: $0)].content == .bomb }).count == 0 {
                for neighbour in neighbours {
                    reveal(neighbour)
                }
            }
        }
    }

    /**
     Reveal all the uncovered, unflagged tiles around a location as long as the
     correct number of tiles have been flagged as bombs.

     - parameter location: A location.
     */
    func revealSafeNeighbours(_ location: Location) {
        if state == .won || state == .lost {
            return
        }

        generateIfNecessary(excluding: location)

        if state == .initialized {
            state = .running
        }

        let neighbours = neighbourhood(location: location)
        let flagged = neighbours.filter {
            self.tiles[self.toIndex(location: $0)].status == .flagged
        }.count
        let bombs = neighbours.filter {
            self.tiles[self.toIndex(location: $0)].content == .bomb
        }.count
        if flagged != bombs { return }
        let safeNeighbours = neighbourhood(location: location).filter {
            self.tiles[self.toIndex(location: $0)].status == .unknown
        }
        for neighbour in safeNeighbours {
            reveal(neighbour)
        }
    }

    /**
     Returns the locations that border a given location, including diagonals.

     - parameter location: A location.
     - parameter radius:   Distance that determines neighbourhood.

     - returns: All neighbours within the given distance.
     */
    private func neighbourhood(location: Location, radius: UInt = 1) -> Array<Location> {
        let r = Dimension(radius)
        let left = location.x >= r ? location.x - r : 0
        let right = min(location.x + r, width - 1)
        let top = location.y >= r ? location.y - r : 0
        let bottom = min(location.y + r, height - 1)

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

    /**
     Returns the number of bombs in a location's immediate neighbourhood.

     - parameter location: A location.

     - returns: The number of bombs (from 0 to 8 inclusive).
     */
    func bombsNear(_ location: Location) -> UInt {
        guard tiles.count > 0 else {
            return 0
        }

        return UInt(neighbourhood(location: location).filter {
            return self.tiles[self.toIndex(location: $0)].content == .bomb
        }.count)
    }

    /**
     Converts a location to an index in the tile array.

     - parameter location: A location.

     - returns: The corresponding array index.
     */
    private func toIndex(location: Location) -> Int {
        precondition(tiles.count > 0)
        return Int(location.x + width * location.y)
    }

    private func generateIfNecessary(excluding excluded: Location?, radius: UInt = 1) {
        if tiles.count == 0 {
            generate(excluding: excluded, radius: radius)
        }
    }

    /**
     Places bombs on random tiles. A safe location can be specified, in which
     case that location is guaranteed not to have a bomb.

     - parameter excluding: An optional location to exclude.
     - parameter radius:    How many neighbouring locations should also be
                            excluded
     */
    func generate(excluding excluded: Location?, radius: UInt = 1) {
        // Generate a random map by placing all the bombs first, filling the
        // remaining positions with empty tiles, and shuffling randomly.

        // Place all the bombs at the start.
        let size = width * height
        tiles = (0..<size).map {
            return Tile(content: UInt($0) < self.bombs ? .bomb : .empty)
        }

        // Since the last tile is guaranteed to be empty, it can be excluded
        // from the shuffle and then swapped with a given location to ensure
        // that location is empty after the shuffle. We can extend this to the
        // other neighbours, so long as there are sufficient empty tiles.
        var safeLocations = Array<Location>()
        if let location = excluded {
            safeLocations.append(location)
            safeLocations.append(contentsOf: neighbourhood(location: location, radius: radius))
        }

        let end = size - Dimension(safeLocations.count);
        for i in 0..<end {
            // Fisher-Yates shuffle algorithm
            let j = arc4random_uniform(end - i) + i
            if i != j {
                swap(&tiles[Int(i)], &tiles[Int(j)])
            }
        }

        var index = Int(size - 1)
        for location in safeLocations {
            swap(&tiles[toIndex(location: location)], &tiles[index])
            index -= 1
        }
    }
}
