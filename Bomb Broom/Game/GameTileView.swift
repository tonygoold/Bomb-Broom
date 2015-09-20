//
//  GameTileView.swift
//  Bomb Broom
//
//  Created by R. Tony Goold on 2015-09-06.
//  Copyright (c) 2015 Tony. All rights reserved.
//

import UIKit

protocol GameTileViewDelegate {
    func tileAt(location: Location) -> Tile
    func bombsNear(location: Location) -> UInt

    func tilePressed(location: Location)
}

class GameTileView: UIView {

    static let tileSize: CGFloat = 44.0

    var location: Location
    var rows: Dimension
    var columns: Dimension

    var delegate: GameViewDelegate?
    var tileSet: TileSet?

    var pressingLocation: Location?
    var pressingInside = false

    init(location: Location, rows: Dimension, columns: Dimension) {
        precondition(rows > 0, "Rows must be non-zero")
        precondition(columns > 0, "Columns must be non-zero")
        self.location = location
        self.rows = rows
        self.columns = columns

        super.init(frame: CGRectMake(0.0, 0.0, CGFloat(columns) * GameTileView.tileSize, CGFloat(rows) * GameTileView.tileSize))

        self.userInteractionEnabled = true
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func locationForPoint(point: CGPoint) -> Location? {
        let viewSize = bounds.size
        let tileSize = GameTileView.tileSize
        switch (point.x, point.y) {
        case (0.0..<viewSize.width, 0.0..<viewSize.height):
            return Location(x: location.x + Dimension(floor(point.x / tileSize)),
                y: location.y + Dimension(floor(point.y / tileSize)))
        default:
            return nil
        }
    }

    func rectForLocation(location: Location) -> CGRect? {
        switch (location.x, location.y) {
        case (self.location.x..<self.location.x + columns, self.location.y..<self.location.y + rows):
            let tileSize = GameTileView.tileSize
            return CGRect(x: CGFloat(location.x) * tileSize,
                y: CGFloat(location.y) * tileSize,
                width: tileSize,
                height: tileSize)
        default:
            return nil
        }
    }

    func tileStatusChanged(tile: Tile, location: Location) {
        if let rect = rectForLocation(location) {
            if rect.intersects(self.bounds) {
                self.setNeedsDisplayInRect(rect)
            }
        }
    }

    override func drawRect(rect: CGRect) {
        let ctx = UIGraphicsGetCurrentContext()

        for y in 0..<rows {
            for x in 0..<columns {
                let location = Location(x: x, y: y)
                if let tileRect = rectForLocation(location) {
                    if tileRect.intersects(rect) {
                        drawTileAt(location, inRect: tileRect, inContext: ctx)
                    }
                }
            }
        }
    }

    func drawTileAt(location: Location, inRect rect: CGRect, inContext ctx: CGContext) {
        CGContextSaveGState(ctx)
        if let tile = delegate?.tileAt(location) {
            switch tile.status {
            case .Unknown:
                if location == pressingLocation && pressingInside {
                    tileSet?.drawPressedTile(rect, context: ctx)
                } else {
                    tileSet?.drawUnknownTile(rect, context: ctx)
                }
            case .Flagged:
                tileSet?.drawFlaggedTile(rect, context: ctx)
            case .Revealed:
                let count = delegate?.bombsNear(location) ?? 0
                tileSet?.drawRevealedTile(rect, context: ctx, count: count)
            case .Exploded:
                tileSet?.drawExplodedTile(rect, context: ctx)
            }
        } else {
            CGContextSetGrayFillColor(ctx, 0.75, 1.0)
            CGContextFillRect(ctx, rect)
            CGContextSetGrayFillColor(ctx, 0.5, 1.0)
            CGContextFillRect(ctx, CGRectInset(rect, 4.0, 4.0))
        }
        CGContextRestoreGState(ctx)
    }

    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        if let touch = touches.first as? UITouch {
            pressingLocation = locationForPoint(touch.locationInView(self))
            if let location = pressingLocation {
                pressingInside = true
                if let rect = rectForLocation(location) {
                    setNeedsDisplayInRect(rect)
                }
                return
            }
        }
        super.touchesBegan(touches, withEvent: event)
    }

    override func touchesMoved(touches: Set<NSObject>, withEvent event: UIEvent) {
        if let touch = touches.first as? UITouch {
            if let location = locationForPoint(touch.locationInView(self)) {
                let isInside = location == pressingLocation
                if isInside == pressingInside {
                    return
                }
                if let rect = rectForLocation(location) {
                    setNeedsDisplayInRect(rect)
                }
                pressingInside = isInside
                return
            }
        }
        super.touchesMoved(touches, withEvent: event)
    }

    override func touchesCancelled(touches: Set<NSObject>!, withEvent event: UIEvent!) {
        if let location = pressingLocation {
            if let rect = rectForLocation(location) {
                setNeedsDisplayInRect(rect)
            }
            pressingLocation = nil
            return
        }
        super.touchesCancelled(touches, withEvent: event)
    }

    override func touchesEnded(touches: Set<NSObject>, withEvent event: UIEvent) {
        if let location = pressingLocation {
            if let rect = rectForLocation(location) {
                setNeedsDisplayInRect(rect)
            }
            if pressingInside {
                delegate?.tilePressed(location)
            }
            pressingLocation = nil
            return
        }
        super.touchesEnded(touches, withEvent: event)
    }
}
