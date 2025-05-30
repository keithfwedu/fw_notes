//
//  NotePoint.swift
//  test_draw
//
//  Created by Fung Wing on 19/5/2025.
//
import UIKit

class NotePoint {
    let id: UUID = UUID()
    var location: CGPoint
    var width: CGFloat

    init(
        location: CGPoint,
        baseWidth: CGFloat,
        forceRatio: CGFloat = 1,
        speed: CGFloat = 0
    ) {
        self.location = location
        self.width = NotePoint.getWidth(
            baseWidth: baseWidth,
            forceRatio: forceRatio,
            speed: speed
        )
        
    }

    func adjustedWidth(by previousPoint: NotePoint?) {
        guard let previousPoint = previousPoint else { return }
        self.width = previousPoint.width * 0.85 + self.width * 0.15
    }

    static func getWidth(
        baseWidth: CGFloat,
        forceRatio: CGFloat,
        speed: CGFloat
    )
        -> CGFloat
    {
        var ratio = 0.7
        if forceRatio > 0 {
            return baseWidth * (1.0 + forceRatio * 1.2)  // More gradual scaling by force
        }
        if speed < 200 {
            ratio = 3.0
        } else if speed < 600 {
            ratio = (1.5 - (speed - 200) / 400 * 0.5)
        }
        return baseWidth * ratio
    }
    
    func copy() -> NotePoint {
          let clonedPoint = NotePoint(
              location: self.location,
              baseWidth: self.width  // Use current width as base width
          )
          return clonedPoint
      }

}
