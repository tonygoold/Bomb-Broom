//
//  ViewController.swift
//  Bomb Broom
//
//  Created by R. Tony Goold on 2015-08-03.
//  Copyright (c) 2015 Tony. All rights reserved.
//

import UIKit

private enum FlagMode: Int {
    case disabled = 0
    case enabled = 1
}

class ViewController: UIViewController, GameViewDelegate, GameObserver {

    @IBOutlet var gameView: GameView!
    @IBOutlet var bombsLeftLabel: UILabel!
    @IBOutlet var flagModeSelector: UISegmentedControl!

    var game: Game? {
        didSet {
            updateBombsLeftLabel()
        }
    }

    private func updateBombsLeftLabel() {
        guard let game = game else {
            bombsLeftLabel.text = ""
            return
        }

        switch game.state {
        case .initialized: fallthrough
        case .running:
            bombsLeftLabel.text = "\(game.bombs - game.flagCount)"
        default:
            bombsLeftLabel.text = ""
        }
    }

    fileprivate func startNewGame() {
        game = Game(width: 16, height: 16, bombs: 40)
        game?.addObserver(self)
        gameView.game = game
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        gameView.tileSet = DefaultTileSet()
        gameView.gameViewDelegate = self

        startNewGame()
    }

    @IBAction func newGamePressed(_ sender: AnyObject?) {
        startNewGame()
    }

    @IBAction func flagModeChanged(_ sender: AnyObject?) {
        if flagModeSelector.selectedSegmentIndex == FlagMode.enabled.rawValue {
            gameView.flagMode = true
        } else {
            gameView.flagMode = false
        }
    }

    // GameViewDelegate methods

    func tileAt(_ location: Location) -> Tile {
        return game?.tileAt(location) ?? Tile(content: .empty)
    }

    func bombsNear(_ location: Location) -> UInt {
        return game?.bombsNear(location) ?? 0
    }

    func tilePressed(_ location: Location) {
        guard let game = game else {
            return
        }

        // Tapping on a revealed tile will reveal its unflagged neighbours,
        // so long as all the neighbouring bombs have been flagged.
        let tile = game.tileAt(location)
        if tile.status == .revealed && tile.content == .empty {
            game.revealSafeNeighbours(location)
        } else if gameView.flagMode {
            game.toggleFlag(location)
        } else {
            game.reveal(location)
        }
    }

    // GameObserver methods

    func tileStatusChanged(_ game: Game, tile: Tile, location: Location) {
        gameView.tileStatusChanged(game, tile: tile, location: location)
        updateBombsLeftLabel()
    }

    func gameLost(_ game: Game) {
        gameView.gameLost(game)
    }

    func gameWon(_ game: Game) {
        gameView.gameWon(game)
    }
}
