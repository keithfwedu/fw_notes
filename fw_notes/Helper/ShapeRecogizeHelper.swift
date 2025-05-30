//
//  ShapeRecogizeHelper.swift
//  test_draw
//
//  Created by Fung Wing on 12/5/2025.
//

import CoreGraphics
import UIKit

class ShapeRecognizeHelper {
    static func getRecognizedShape(from points: [CGPoint]) -> CGPath? {
        // Step 1: Recognize the shape type
        let recognizedShape = recognizeShape(from: points)
        print("Recognized shape: \(recognizedShape)")

        // Step 2: Simplify the points using Douglas-Peucker
        let simplifiedCGPoints = douglasPeucker(
            points: points,
            epsilon: 15.0
        )

        // Step 3: Generate the correct CGPath based on the recognized shape
        switch recognizedShape {
        case .line:
            return ShapeRefineHelper.createLine(from: simplifiedCGPoints)
        case .curve:
            return ShapeRefineHelper.createCurvePath(
                from: simplifiedCGPoints,
                maxDistance: 7.0
            )
        case .oval, .circle:
            return ShapeRefineHelper.createOvalPath(from: simplifiedCGPoints)
        case .undefined:
            return ShapeRefineHelper.createPath(from: simplifiedCGPoints)
        default:
            let closedCGPoints = ShapeRefineHelper.mergeClosePoints(
                from: simplifiedCGPoints
            )
            return ShapeRefineHelper.createPath(from: closedCGPoints)
        }
    }

    static func recognizeShape(from points: [CGPoint]) -> RecognizeShape {
        guard points.count > 3 else { return .undefined }

        let simplifiedCGPoints = self.douglasPeucker(
            points: points,
            epsilon: 15.0
        )

        let edges = countEdges(simplifiedCGPoints)
        let totalCurvature = measureCurvature(simplifiedCGPoints)
        print(
            "edges: \(edges) - totalCurvature: \(totalCurvature) - points: \(simplifiedCGPoints)"
        )

        if edges <= 2, totalCurvature <= 60 { return .line }

        // FIX: If curvature is high, even with 4 edges, classify as curve
        if edges == 4 && totalCurvature > 60 { return .curve }

        if edges == 3 { return .triangle }
        if edges == 4 { return .rectangle }

        let shapeType = detectOvalOrCircle(simplifiedCGPoints)

        if shapeType == .circle || shapeType == .oval || shapeType == .curve {
            return shapeType
        }

        return .undefined
    }

    // Douglas-Peucker Simplification
    static func douglasPeucker(points: [CGPoint], epsilon: CGFloat) -> [CGPoint]
    {
        guard points.count > 2 else {
            return points
        }

        var maxDistance: CGFloat = 0
        var index = 0

        for i in 1..<points.count - 1 {
            let distance = perpendicularDistance(
                points[i],
                points[0],
                points[points.count - 1]
            )
            if distance > maxDistance {
                maxDistance = distance
                index = i
            }
        }

        if maxDistance > epsilon {
            let left = douglasPeucker(
                points: Array(points[0...index]),
                epsilon: epsilon
            )
            let right = douglasPeucker(
                points: Array(points[index...]),
                epsilon: epsilon
            )

            return Array(left.dropLast()) + right
        } else {
            return [points.first!, points.last!]
        }
    }

    //-----------------------------------------------------------------------------------------------------

    static func detectOvalOrCircle(_ points: [CGPoint]) -> RecognizeShape {
        guard points.count > 2, let center = calculateCenter(points) else {
            return .undefined
        }

        // Compute Bounding Box & Aspect Ratio
        guard let minX = points.map({ $0.x }).min(),
            let maxX = points.map({ $0.x }).max(),
            let minY = points.map({ $0.y }).min(),
            let maxY = points.map({ $0.y }).max()
        else { return .undefined }

        let width = maxX - minX
        let height = maxY - minY
        let sizeFactor = (width + height) / 2
        let boundingBoxDiagonal = hypot(width, height)

        // Compute Path Length vs Bounding Box Ratio
        let pathLength = calculatePathLength(points)
        let pathRatio = pathLength / boundingBoxDiagonal

        // Compute True Ellipse Axes Using PCA
        let (majorAxis, minorAxis) = computeEllipseAxes(points)
        let ellipseAspectRatio = majorAxis / minorAxis

        // Check Radial Distance Consistency with Smoothed Points
        let smoothedPoints = points.map {
            CGPoint(x: ($0.x + center.x) / 2, y: ($0.y + center.y) / 2)
        }
        let distances = smoothedPoints.map {
            hypot($0.x - center.x, $0.y - center.y)
        }
        let avgDistance = distances.reduce(0, +) / CGFloat(distances.count)

        let filteredDistances = distances.filter {
            abs($0 - avgDistance) < avgDistance * 0.2
        }  // Reduce noise
        let radialVarianceFiltered =
            filteredDistances.map { pow($0 - avgDistance, 2) }
            .reduce(0, +) / CGFloat(filteredDistances.count)
        let stdDevDistance = sqrt(radialVarianceFiltered)

        // Normalize thresholds dynamically based on shape size
        let normalizationFactor = max(
            sizeFactor,
            boundingBoxDiagonal,
            pathLength * 0.2
        )
        let adjustedRadialVariance =
            radialVarianceFiltered / normalizationFactor
        let adjustedStdDevDistance = stdDevDistance / normalizationFactor

        // Measure Start-End Gap
        let startEndGap = hypot(
            points.first!.x - points.last!.x,
            points.first!.y - points.last!.y
        )
        let adjustedStartEndGap = startEndGap / normalizationFactor

        print(
            "adjustedStartEndGap: \(adjustedStartEndGap)\n adjustedRadialVariance: \(adjustedRadialVariance)\n adjustedStdDevDistance: \(adjustedStdDevDistance)\n ellipseAspectRatio: \(ellipseAspectRatio)\n pathRatio: \(pathRatio)"
        )

        // **Refined Shape Classification**
        if adjustedStartEndGap < 1 && adjustedStdDevDistance < 10
            && ellipseAspectRatio < 1.1 && pathRatio > 2.0
        {
            return .circle
        }

        if adjustedStartEndGap < 1 && adjustedStdDevDistance < 20
            && ellipseAspectRatio > 1.1 && ellipseAspectRatio < 3.5  // Increased limit
            && adjustedRadialVariance < 5.5 && pathRatio > 1.8
        {  // More flexible path ratio
            return .oval
        }

        // **Detect Irregular Shapes More Accurately**
        if adjustedStartEndGap > 2.0 || adjustedStdDevDistance > 30
            || ellipseAspectRatio > 2.0 || pathRatio > 3.5
            || adjustedRadialVariance > 5.5
        {
            return .undefined
        }

        if adjustedStartEndGap > 1 || adjustedStdDevDistance > 30
            || pathRatio < 2.0
        {
            return .curve
        }

        return .undefined
    }

    static func computeEllipseAxes(_ points: [CGPoint]) -> (
        majorAxis: CGFloat, minorAxis: CGFloat
    ) {
        guard points.count > 2 else { return (0, 0) }

        let meanX = points.map({ $0.x }).reduce(0, +) / CGFloat(points.count)
        let meanY = points.map({ $0.y }).reduce(0, +) / CGFloat(points.count)

        let covXX =
            points.map { pow($0.x - meanX, 2) }.reduce(0, +)
            / CGFloat(points.count)
        let covYY =
            points.map { pow($0.y - meanY, 2) }.reduce(0, +)
            / CGFloat(points.count)
        let covXY =
            points.map { ($0.x - meanX) * ($0.y - meanY) }.reduce(0, +)
            / CGFloat(points.count)

        // Eigenvalue calculation to determine axes
        let trace = covXX + covYY
        let determinant = covXX * covYY - covXY * covXY
        let eigenValue1 = (trace + sqrt(pow(trace, 2) - 4 * determinant)) / 2
        let eigenValue2 = (trace - sqrt(pow(trace, 2) - 4 * determinant)) / 2

        let majorAxis = sqrt(eigenValue1) * 2  // Scaling factor
        let minorAxis = sqrt(eigenValue2) * 2

        return (majorAxis, minorAxis)
    }

    static func calculatePathLength(_ points: [CGPoint]) -> CGFloat {
        guard points.count > 1 else { return 0 }
        var length: CGFloat = 0
        for i in 1..<points.count {
            length += hypot(
                points[i].x - points[i - 1].x,
                points[i].y - points[i - 1].y
            )
        }
        return length
    }

    static func simplifyPath(
        _ points: [NotePoint],
        epsilon: CGFloat = 12.0
    ) -> [CGPoint] {
        guard points.count > 2 else { return points.map { $0.location } }

        let first = points.first!.location
        let last = points.last!.location

        var maxDistance: CGFloat = 0
        var index = 0

        for i in 1..<points.count - 1 {
            let dist = perpendicularDistance(points[i].location, first, last)
            if dist > maxDistance {
                index = i
                maxDistance = dist
            }
        }

        if maxDistance > epsilon {
            let left = simplifyPath(Array(points[0...index]), epsilon: epsilon)
            let right = simplifyPath(Array(points[index...]), epsilon: epsilon)

            guard !left.isEmpty, !right.isEmpty else { return [first, last] }

            var uniquePoints: [String: CGPoint] = [:]
            for point in left + right {
                let key = "\(point.x),\(point.y)"
                uniquePoints[key] = point
            }

            // 🔥 Ensure original start & end points remain unchanged
            var finalPoints = Array(uniquePoints.values).sorted { $0.x < $1.x }
            finalPoints.insert(first, at: 0)
            finalPoints.append(last)

            return finalPoints
        } else {
            return [first, last]
        }
    }

    static func countEdges(_ points: [CGPoint]) -> Int {
        var edgeCount = 1  // Start with 1 to account for the first turning point

        for i in 1..<points.count - 1 {
            let angle = angleBetween(points[i - 1], points[i], points[i + 1])

            if abs(angle) < 150 {  // Only count major shifts as edges
                edgeCount += 1
            }
        }

        return edgeCount
    }

    static func measureCurvature(_ points: [CGPoint]) -> CGFloat {
        var totalCurvature: CGFloat = 0

        for i in 1..<points.count - 1 {
            let angle = angleBetween(points[i - 1], points[i], points[i + 1])
            totalCurvature += abs(angle - 180)  // Deviation from straight path
        }

        return totalCurvature / CGFloat(points.count)
    }

    static func calculateCenter(_ points: [CGPoint]) -> CGPoint? {
        guard !points.isEmpty else { return nil }
        let xSum = points.map { $0.x }.reduce(0, +) / CGFloat(points.count)
        let ySum = points.map { $0.y }.reduce(0, +) / CGFloat(points.count)
        return CGPoint(x: xSum, y: ySum)
    }

    static func angleBetween(_ a: CGPoint, _ b: CGPoint, _ c: CGPoint)
        -> CGFloat
    {
        let ab = CGVector(dx: b.x - a.x, dy: b.y - a.y)
        let bc = CGVector(dx: c.x - b.x, dy: c.y - b.y)

        let dotProduct = (ab.dx * bc.dx + ab.dy * bc.dy)
        let magnitudeAB = hypot(ab.dx, ab.dy)
        let magnitudeBC = hypot(bc.dx, bc.dy)

        return acos(dotProduct / (magnitudeAB * magnitudeBC)) * (180.0 / .pi)
    }

    static func perpendicularDistance(
        _ point: CGPoint,
        _ lineStart: CGPoint,
        _ lineEnd: CGPoint
    ) -> CGFloat {
        let numerator = abs(
            (lineEnd.x - lineStart.x) * (lineStart.y - point.y)
                - (lineStart.x - point.x) * (lineEnd.y - lineStart.y)
        )
        let denominator = hypot(
            lineEnd.x - lineStart.x,
            lineEnd.y - lineStart.y
        )

        return denominator > 0 ? numerator / denominator : 0
    }

    // Euclidean Distance Function
    static func distance(_ p1: NotePoint, _ p2: NotePoint) -> CGFloat {
        return sqrt(
            pow(p1.location.x - p2.location.x, 2)
                + pow(p1.location.y - p2.location.y, 2)
        )
    }

}
