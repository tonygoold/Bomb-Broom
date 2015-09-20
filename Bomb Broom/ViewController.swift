//
//  ViewController.swift
//  Bomb Broom
//
//  Created by R. Tony Goold on 2015-08-03.
//  Copyright (c) 2015 Tony. All rights reserved.
//

import UIKit

private enum FlagMode: Int {
    case Disabled = 0
    case Enabled = 1
}

class ViewController: UIViewController, GameViewDelegate, GameObserver {

    var game: Game?
    @IBOutlet var gameView: GameView!
    @IBOutlet var flagModeSelector: UISegmentedControl!

    override func viewDidLoad() {
        super.viewDidLoad()

        game = Game(width: 24, height: 24, bombs: 99)
        game?.addObserver(self)
        gameView.tileSet = DefaultTileSet()
        gameView.gameViewDelegate = self
        gameView.game = game
    }

    @IBAction func flagModeChanged(sender: AnyObject?) {
        if flagModeSelector.selectedSegmentIndex == FlagMode.Enabled.rawValue {
            gameView.flagMode = true
        } else {
            gameView.flagMode = false
        }
    }

    // GameViewDelegate methods

    func tileAt(location: Location) -> Tile {
        if let game = self.game {
            return game.tileAt(location)
        } else {
            return Tile(type: .Empty)
        }
    }

    func bombsNear(location: Location) -> UInt {
        return game?.bombsNear(location) ?? 0
    }

    func tilePressed(location: Location) {
        if let tile = game?.tileAt(location) {
            if tile.status == .Revealed && tile.type == .Empty {
                game?.revealSafe(location)
                return
            }
        }
        if gameView.flagMode {
            game?.toggleFlag(location)
        } else {
            game?.reveal(location)
        }
    }

    // GameObserver methods

    func tileStatusChanged(tile: Tile, location: Location) {
        gameView.tileStatusChanged(tile, location: location)
    }

    func gameLost() {
        gameView.gameLost()
    }

    func gameWon() {
        gameView.gameWon()
    }
}

