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
            if let game = game {
                contentSize = CGSize(width: tileSize * CGFloat(game.width),
                    height: tileSize * CGFloat(game.height))
            } else {
                contentSize = bounds.size
            }
            for view in tileViews {
                view.removeFromSuperview()
            }
            tileViews.removeAll(keepingCapacity: true)
            setNeedsLayout()
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
        contentSize = bounds.size
        clipsToBounds = true
        bounces = false
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        contentSize = bounds.size
        clipsToBounds = true
        bounces = false
    }

    override func layoutSubviews() {
        guard let game = game else {
            return
        }

        // Only need to perform layout when the tiles have not been created yet
        if tileViews.count > 0 {
            return
        }

        // One big tile!
        let tile = GameTileView(location: Location(x: 0, y: 0), rows: game.height, columns: game.width)
        tile.delegate = self
        tile.tileSet = tileSet
        tile.setNeedsDisplay()
        tileViews.append(tile)
        addSubview(tile)
    }

    func tileViewForLocation(_ location: Location) -> GameTileView? {
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

    func tileAt(_ location: Location) -> Tile {
        return gameViewDelegate?.tileAt(location) ?? Tile(content: .empty)
    }

    func bombsNear(_ location: Location) -> UInt {
        return gameViewDelegate?.bombsNear(location) ?? 0
    }

    func tilePressed(_ location: Location) {
        gameViewDelegate?.tilePressed(location)
    }

    // GameObserver methods

    func tileStatusChanged(_ game: Game, tile: Tile, location: Location) {
        if let tileView = tileViewForLocation(location) {
            tileView.tileStatusChanged(tile, location: location)
        }
    }

    func gameWon(_ game: Game) {
        // Unfinished
        print("Won!")
    }

    func gameLost(_ game: Game) {
        // Unfinished
        print("Lost...")
    }
}
