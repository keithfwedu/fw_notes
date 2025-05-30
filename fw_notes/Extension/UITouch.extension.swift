//
//  UITouch.extension.swift
//  test_draw
//
//  Created by Fung Wing on 20/5/2025.
//
import UIKit

extension UITouch {
    /// Returns the normalized force value (0 to 1) based on maximum possible force.
    var forceRatio: CGFloat {
        guard maximumPossibleForce > 0 else { return 0 }  // Avoid division by zero
        return force / maximumPossibleForce
    }

    /// Calculates movement distance between current and previous touch location.
    func movementDistance(in view: UIView) -> CGFloat {
        let previousLocation = self.previousLocation(in: view)
        let currentLocation = self.location(in: view)

        return hypot(
            currentLocation.x - previousLocation.x,
            currentLocation.y - previousLocation.y
        )
    }

    func rect(in view: UIView, size: CGFloat = 0) -> CGRect {
        let currentLocation = self.location(in: view)
        let halfSize = size == 0 ? 0 : size / 2
        return CGRect(
            x: currentLocation.x - halfSize,
            y: currentLocation.y - halfSize,
            width: size,
            height: size
        )
    }

    func speed(in view: UIView, comparedTo previousTouchTime: TimeInterval?) -> CGFloat {
        
        guard let previousTouchTime = previousTouchTime else { return 0 }  // Avoid division by zero
       
        let currentTime = self.timestamp
        let previousTime = previousTouchTime
      
        let timeDiff = currentTime - previousTime
        let movementDistance = self.movementDistance(in: view)
      
        if timeDiff > 0 {
         
            return movementDistance / CGFloat(timeDiff)
        }

        return 0
    }

    func toNotePoint(
        in view: UIView,
        baseWidth: CGFloat = 1.0,
        previousTouchTime: TimeInterval?
    ) -> NotePoint {
        let location = self.location(in: view)
        let forceRatio = self.forceRatio
        let speed = self.speed(in: view, comparedTo: previousTouchTime)

        return NotePoint(
            location: location,
            baseWidth: baseWidth,
            forceRatio: forceRatio,
            speed: speed
        )
    }
}
