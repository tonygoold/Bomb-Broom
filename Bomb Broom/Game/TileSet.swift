//
//  TileSet.swift
//  Bomb Broom
//
//  Created by R. Tony Goold on 2015-09-06.
//  Copyright (c) 2015 Tony. All rights reserved.
//

import UIKit
import CoreText

protocol TileSet {
    func drawUnknownTile(rect: CGRect, context: CGContextRef)
    func drawFlaggedTile(rect: CGRect, context: CGContextRef)
    func drawPressedTile(rect: CGRect, context: CGContextRef)
    func drawRevealedTile(rect: CGRect, context: CGContextRef, count: UInt)
    func drawExplodedTile(rect: CGRect, context: CGContextRef)
    // When losing, shows other uncovered bombs
    func drawBombTile(rect: CGRect, context: CGContextRef)
}

class DefaultTileSet: TileSet {
    func drawUnknownTile(rect: CGRect, context: CGContextRef) {
        CGContextSetGrayFillColor(context, 0.75, 1.0)
        CGContextSetGrayStrokeColor(context, 0.5, 1.0)
        CGContextFillRect(context, rect)
        CGContextStrokeRectWithWidth(context, rect, 4.0)
    }

    func drawFlaggedTile(rect: CGRect, context: CGContextRef) {
        drawUnknownTile(rect, context: context)
        CGContextSetRGBFillColor(context, 1.0, 0.0, 0.0, 1.0)
        CGContextFillEllipseInRect(context, CGRectInset(rect, 8.0, 8.0))
    }

    func drawPressedTile(rect: CGRect, context: CGContextRef) {
        CGContextSetGrayFillColor(context, 0.5, 1.0)
        CGContextSetGrayStrokeColor(context, 0.75, 1.0)
        CGContextFillRect(context, rect)
        CGContextStrokeRectWithWidth(context, rect, 4.0)
    }

    func drawRevealedTile(rect: CGRect, context: CGContextRef, count: UInt) {
        CGContextSetGrayFillColor(context, 1.0, 1.0)
        CGContextFillRect(context, rect)
        if count == 0 {
            return
        }
        let string = NSAttributedString(string: "\(count)",
            attributes: [ NSFontAttributeName: UIFont.boldSystemFontOfSize(18.0),
                NSForegroundColorAttributeName: UIColor.blackColor() ])
        let line = CTLineCreateWithAttributedString(string)
        let imageRect = CTLineGetImageBounds(line, context)
        CGContextSetTextMatrix(context, CGAffineTransformMakeScale(1.0, -1.0))
        CGContextSetTextPosition(context,
            rect.origin.x + floor((rect.size.width - imageRect.size.width) / 2.0),
            rect.origin.y + floor((rect.size.height - imageRect.size.height) / 2.0))
        CTLineDraw(line, context)
        CGContextFlush(context)
    }

    func drawExplodedTile(rect: CGRect, context: CGContextRef) {
        drawUnknownTile(rect, context: context)
        CGContextSetRGBFillColor(context, 1.0, 0.0, 0.0, 1.0)
        CGContextFillRect(context, CGRectInset(rect, 4.0, 4.0))
    }

    func drawBombTile(rect: CGRect, context: CGContextRef) {
        drawUnknownTile(rect, context: context)
        CGContextSetGrayFillColor(context, 0.0, 1.0)
        CGContextFillRect(context, CGRectInset(rect, 4.0, 4.0))
    }
}