//
//  GameView.swift
//  Bomb Broom
//
//  Created by R. Tony Goold on 2015-08-03.
//  Copyright (c) 2015 Tony. All rights reserved.
//

import UIKit

class GameView: UIScrollView, GameViewDelegate, GameObserver {

    static let gridSize: CGFloat = 44.0

    var flagMode = false
    var tileViews = Array<GameTileView>()
    var gameViewDelegate: GameViewDelegate?

    var game: Game? {
        didSet {
            let tileSize = GameTileView.tileSize
            if let game = self.game {
                self.contentSize = CGSize(width: tileSize * CGFloat(game.width),
                                          height: tileSize * CGFloat(game.height))
            } else {
                self.contentSize = self.bounds.size
            }
            for view in tileViews {
                view.removeFromSuperview()
            }
            tileViews.removeAll(keepCapacity: true)
            self.setNeedsLayout()
        }
    }

    var tileSet: TileSet? {
        didSet {
            for view in tileViews {
                view.tileSet = tileSet
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.contentSize = self.bounds.size
        self.clipsToBounds = true
        self.bounces = false
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.contentSize = self.bounds.size
        self.clipsToBounds = true
        self.bounces = false
    }

    override func layoutSubviews() {
        if let game = self.game {
            if tileViews.count == 0 {
                // One big tile!
                let tile = GameTileView(location: Location(x: 0, y: 0), rows: game.height, columns: game.width)
                tile.delegate = self
                tile.tileSet = tileSet
                tile.setNeedsDisplay()
                tileViews.append(tile)
                addSubview(tile)
            }
        }
    }

    func tileViewForLocation(location: Location) -> GameTileView? {
        for tileView in tileViews {
            let tileLocation = tileView.location
            switch (location.x, location.y) {
            case (tileLocation.x ..< tileLocation.x + tileView.columns,
                tileLocation.y ..< tileLocation.y + tileView.rows):
                return tileView
            default:
                break
            }
        }
        return nil
    }

    // GameTileViewDelegate methods

    func tileAt(location: Location) -> Tile {
        if let delegate = self.gameViewDelegate {
            return delegate.tileAt(location)
        } else {
            return Tile(type: .Empty)
        }
    }

    func bombsNear(location: Location) -> UInt {
        if let delegate = self.gameViewDelegate {
            return delegate.bombsNear(location)
        } else {
            return 0
        }
    }

    func tilePressed(location: Location) {
        gameViewDelegate?.tilePressed(location)
    }

    // GameObserver methods

    func tileStatusChanged(tile: Tile, location: Location) {
        if let tileView = tileViewForLocation(location) {
            tileView.tileStatusChanged(tile, location: location)
        }
    }

    func gameWon() {
        println("Won!")
    }

    func gameLost() {
        println("Lost...")
    }
}
