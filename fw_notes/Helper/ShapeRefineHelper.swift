import CoreGraphics
//
//  ShapeRefineHelper.swift
//  test_draw
//
//  Created by Fung Wing on 12/5/2025.
//
import UIKit

class ShapeRefineHelper {

    static func createPath(from points: [CGPoint]) -> CGPath {
        guard !points.isEmpty else {
            print("Error: Points array is empty")
            return CGPath(rect: .zero, transform: nil)
        }

        let path = UIBezierPath()
        path.move(to: points[0])

        for point in points.dropFirst() {
            path.addLine(to: point)
        }

        return path.cgPath
    }

    static func createLine(from points: [CGPoint]) -> CGPath {
        guard points.count > 1 else {
            print("Error: Not enough points for a path")
            return CGPath(rect: .zero, transform: nil)
        }

        let path = UIBezierPath()
        path.move(to: points[0])

        for i in 1..<points.count {
            let start = points[i - 1]
            var end = points[i]

            // Calculate angle in degrees
            let dx = end.x - start.x
            let dy = end.y - start.y
            let angle = atan2(dy, dx) * (180 / .pi)  // Convert to degrees

            // Snap to horizontal or vertical if within ±15 degrees
            if abs(angle) < 15 {  // Snap to horizontal
                end.y = start.y
            } else if abs(angle - 90) < 15 || abs(angle + 90) < 15 {  // Snap to vertical
                end.x = start.x
            }

            path.addLine(to: end)
        }

        return path.cgPath
    }

    // Helper functions:
    static func distanceBetween(_ p1: CGPoint, _ p2: CGPoint) -> CGFloat {
        let dx = p2.x - p1.x
        let dy = p2.y - p1.y
        return sqrt(dx * dx + dy * dy)
    }

    static func catmullRomInterpolate(
        _ p0: CGPoint,
        _ p1: CGPoint,
        _ p2: CGPoint,
        _ p3: CGPoint,
        _ t: CGFloat
    ) -> CGPoint {
        let t2 = t * t
        let t3 = t2 * t

        // Compute x-coordinates separately
        let c1x = (-p0.x + p2.x) * t
        let c2x =
            (2 * p0.x - 5 * p1.x + 4 * p2.x
                - p3.x) * t2
        let c3x =
            (-p0.x + 3 * p1.x - 3 * p2.x
                + p3.x) * t3
        let interpolatedX = 0.5 * (2 * p1.x + c1x + c2x + c3x)

        // Compute y-coordinates separately
        let c1y = (-p0.y + p2.y) * t
        let c2y =
            (2 * p0.y - 5 * p1.y + 4 * p2.y
                - p3.y) * t2
        let c3y =
            (-p0.y + 3 * p1.y - 3 * p2.y
                + p3.y) * t3
        let interpolatedY = 0.5 * (2 * p1.y + c1y + c2y + c3y)

        return CGPoint(x: interpolatedX, y: interpolatedY)
    }

    static func createOvalPath(from points: [CGPoint]) -> CGPath? {
        guard points.count >= 3 else {
            print("Not enough points to detect an oval")
            return nil
        }

        // Compute Minimum Bounding Rotated Rectangle
        let boundingBox = computeRotatedBoundingBox(points: points)
        let center = boundingBox.center
        let width = boundingBox.width
        let height = boundingBox.height
        let rotation = boundingBox.rotation

        return createOvalCGPath(
            center: center,
            width: width,
            height: height,
            rotation: rotation
        )
    }

    static func createOvalCGPath(
        center: CGPoint,
        width: CGFloat,
        height: CGFloat,
        rotation: CGFloat
    ) -> CGPath {
        // Create a bounding box for the ellipse
        let boundingBox = CGRect(
            x: center.x - width / 2,
            y: center.y - height / 2,
            width: width,
            height: height
        )

        // Create an elliptical path inside the bounding box
        let ovalPath = UIBezierPath(ovalIn: boundingBox).cgPath

        // Convert degrees to radians for rotation
        let radians = -rotation * (.pi / 180)

        // Step 1: Translate oval to the origin
        var transform = CGAffineTransform(translationX: -center.x, y: -center.y)

        // Step 2: Apply rotation
        transform = transform.concatenating(
            CGAffineTransform(rotationAngle: radians)
        )

        // Step 3: Translate oval back to its original position
        transform = transform.concatenating(
            CGAffineTransform(translationX: center.x, y: center.y)
        )

        return ovalPath.copy(using: &transform) ?? ovalPath
    }

    static func mergeClosePoints(from points: [CGPoint], epsilon: CGFloat = 50)
        -> [CGPoint]
    {
        guard points.count > 2 else { return points }

        let startPoint = points.first!
        let endPoint = points.last!

        let distance = hypot(
            endPoint.x - startPoint.x,
            endPoint.y - startPoint.y
        )

        var modifiedPoints = points
        print("distance: \(distance) - epsilon: \(epsilon)")

        // If start and end points are close, merge the last point into the start point
        if distance < epsilon {
            modifiedPoints[modifiedPoints.count - 1] = startPoint  // Merge into start point
        }

        return modifiedPoints
    }

    static func computeRotatedBoundingBox(points: [CGPoint]) -> (
        center: CGPoint, width: CGFloat, height: CGFloat, rotation: CGFloat
    ) {
        guard points.count > 1 else {
            return (center: .zero, width: 0, height: 0, rotation: 0)
        }

        // Compute centroid
        let centerX = points.map { $0.x }.reduce(0, +) / CGFloat(points.count)
        let centerY = points.map { $0.y }.reduce(0, +) / CGFloat(points.count)
        let center = CGPoint(x: centerX, y: centerY)

        // Compute covariance matrix
        let covXX =
            points.map { ($0.x - centerX) * ($0.x - centerX) }.reduce(0, +)
            / CGFloat(points.count)
        let covYY =
            points.map { ($0.y - centerY) * ($0.y - centerY) }.reduce(0, +)
            / CGFloat(points.count)
        let covXY =
            points.map { ($0.x - centerX) * ($0.y - centerY) }.reduce(0, +)
            / CGFloat(points.count)

        // Compute eigenvalues and eigenvectors
        let trace = covXX + covYY
        let det = covXX * covYY - covXY * covXY
        let lambda1 = trace / 2 + sqrt(trace * trace / 4 - det)
        let lambda2 = trace / 2 - sqrt(trace * trace / 4 - det)

        let eigenVector1X = covXY
        let eigenVector1Y = lambda1 - covXX
        let eigenVector2X = covXY
        let eigenVector2Y = lambda2 - covXX

        // Choose dominant eigenvector for orientation
        let (majorVectorX, majorVectorY) =
            abs(lambda1) > abs(lambda2)
            ? (eigenVector1X, eigenVector1Y)
            : (eigenVector2X, eigenVector2Y)

        let angleRadians = atan2(majorVectorY, majorVectorX)
        let angleDegrees = angleRadians * (180 / .pi)

        // Rotate points to align with principal axis
        let rotatedPoints = points.map { point -> CGPoint in
            let dx = point.x - centerX
            let dy = point.y - centerY
            return CGPoint(
                x: dx * cos(angleRadians) - dy * sin(angleRadians),
                y: dx * sin(angleRadians) + dy * cos(angleRadians)
            )
        }

        let minX = rotatedPoints.map { $0.x }.min() ?? 0
        let maxX = rotatedPoints.map { $0.x }.max() ?? 0
        let minY = rotatedPoints.map { $0.y }.min() ?? 0
        let maxY = rotatedPoints.map { $0.y }.max() ?? 0

        var width = maxX - minX
        var height = maxY - minY

        // Ensure the major axis is always correctly assigned
        var adjustedAngle = angleDegrees
        if height > width {
            swap(&width, &height)
            adjustedAngle += 90
        }

        return (
            center: center, width: width, height: height,
            rotation: adjustedAngle
        )
    }

    static func createSmoothCurvePath(
        from points: [CGPoint],
        tension: CGFloat = 0.3
    ) -> CGPath {
        guard points.count > 2 else {
            print("Not enough points for smooth interpolation")
            return CGPath(rect: .zero, transform: nil)
        }

        let path = UIBezierPath()
        path.move(to: points[0])

        for i in 1..<points.count - 1 {
            let current = points[i]
            let next = points[i + 1]

            let prev = points[i - 1]
            let nextNext = (i + 2 < points.count) ? points[i + 2] : next

            let distanceFactor =
                hypot(next.x - prev.x, next.y - prev.y) * tension

            let controlPoint1 = CGPoint(
                x: current.x - (distanceFactor * (next.x - prev.x) / 2),
                y: current.y - (distanceFactor * (next.y - prev.y) / 2)
            )

            let controlPoint2 = CGPoint(
                x: next.x + (distanceFactor * (nextNext.x - current.x) / 2),
                y: next.y + (distanceFactor * (nextNext.y - current.y) / 2)
            )

            path.addCurve(
                to: next,
                controlPoint1: controlPoint1,
                controlPoint2: controlPoint2
            )
        }

        return path.cgPath
    }

    static func createCurvePath(from points: [CGPoint], maxDistance: CGFloat)
        -> CGPath
    {
        guard points.count > 2 else {
            print("Not enough points for interpolation")
            return CGPath(rect: .zero, transform: nil)
        }

        let path = UIBezierPath()
        path.move(to: points.first!)  // Start at first point

        var newPoints: [CGPoint] = []

        for i in 0..<points.count - 1 {
            let p0 = i > 0 ? points[i - 1] : points[i]
            let p1 = points[i]
            let p2 = points[i + 1]
            let p3 = i + 2 < points.count ? points[i + 2] : points[i + 1]

            let segments = Int(ceil(distanceBetween(p1, p2) / maxDistance))

            for j in 0..<segments {
                let t = CGFloat(j) / CGFloat(segments)
                let interpolatedPoint = catmullRomInterpolate(p0, p1, p2, p3, t)

                newPoints.append(interpolatedPoint)
                path.addLine(to: interpolatedPoint)  // Add interpolated point to path
            }
        }

        return path.cgPath
    }

}
