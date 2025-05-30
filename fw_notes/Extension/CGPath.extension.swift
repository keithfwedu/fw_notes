//
//  CGPath.extension.swift
//  test_draw
//
//  Created by Fung Wing on 12/5/2025.
//
import UIKit

extension CGPath {
    func getPathPoints() -> [CGPoint] {
        var points: [CGPoint] = []
        self.applyWithBlock { element in
            let point = element.pointee.points.pointee
            points.append(point)
        }
        return points
    }
}
