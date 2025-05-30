//
//  PathHelper.swift
//  test_draw
//
//  Created by Fung Wing on 12/5/2025.
//
import UIKit

class PathHelper {

    static func createPath(
        from points: [NotePoint],
        tension: CGFloat = 2.0
    ) -> UIBezierPath {

        let (leftPoints, rightPoints) = getEdgePoints(
            from: points
        )
        let rightpointsReversed = rightPoints.reversed().map({ $0 })
        let path = UIBezierPath()

        guard leftPoints.count + rightpointsReversed.count > 2 else {
            return path
        }

        path.move(to: rightpointsReversed.last!)  // Start at reversed right points

        addArcBetweenPoints(
            path,
            from: rightpointsReversed.last!,
            to: leftPoints.first!
        )

        var derivatives: [CGPoint] = computeDerivatives(from: leftPoints)

        for i in 1..<leftPoints.count {
            let endPoint = leftPoints[i]
            let cp1 = CGPoint(
                x: leftPoints[i - 1].x + derivatives[i - 1].x / tension,
                y: leftPoints[i - 1].y + derivatives[i - 1].y / tension
            )

            path.addQuadCurve(to: endPoint, controlPoint: cp1)
        }

        addArcBetweenPoints(
            path,
            from: leftPoints.last!,
            to: rightpointsReversed.first!
        )

        derivatives = computeDerivatives(from: rightpointsReversed)

        for i in 1..<rightpointsReversed.count {
            let endPoint = rightpointsReversed[i]
            let cp1 = CGPoint(
                x: rightpointsReversed[i - 1].x + derivatives[i - 1].x
                    / tension,
                y: rightpointsReversed[i - 1].y + derivatives[i - 1].y / tension
            )
            let cp2 = CGPoint(
                x: rightpointsReversed[i].x - derivatives[i].x / tension,
                y: rightpointsReversed[i].y - derivatives[i].y / tension
            )

            path.addCurve(to: endPoint, controlPoint1: cp1, controlPoint2: cp2)
        }

        return path
    }

    static func getEdgePoints(from points: [NotePoint]) -> (
        [CGPoint], [CGPoint]
    ) {
        var leftPoints: [CGPoint] = []
        var rightPoints: [CGPoint] = []

        guard points.count > 1 else { return ([], []) }

        for i in 0..<points.count {
            let current = points[i]
            let prev = i > 0 ? points[i - 1] : current
            let next = i < points.count - 1 ? points[i + 1] : current

            // Compute vectors
            let dx1 = current.location.x - prev.location.x
            let dy1 = current.location.y - prev.location.y
            let dx2 = next.location.x - current.location.x
            let dy2 = next.location.y - current.location.y

            let length1 = sqrt(dx1 * dx1 + dy1 * dy1)
            let length2 = sqrt(dx2 * dx2 + dy2 * dy2)

            guard length1 > 0, length2 > 0 else { continue }

            let normalizedDX1 = dx1 / length1
            let normalizedDY1 = dy1 / length1
            let normalizedDX2 = dx2 / length2
            let normalizedDY2 = dy2 / length2

            // Compute angle between vectors
            let dotProduct =
                (normalizedDX1 * normalizedDX2)
                + (normalizedDY1 * normalizedDY2)
            let angle = acos(dotProduct) * 180 / .pi

            // **Adjust path if angle is less than 30 degrees**
            let basePoint: CGPoint

            if angle < 30 || angle > 150 {

                basePoint = CGPoint(
                    x: (prev.location.x + next.location.x) / 2,
                    y: (prev.location.y + next.location.y) / 2
                )
            } else {
                basePoint = current.location
            }

            let halfWidth = current.width / 2

            // **Calculate perpendicular direction based on BASE POINT**
            let midDX = next.location.x - prev.location.x
            let midDY = next.location.y - prev.location.y
            let midLength = sqrt(midDX * midDX + midDY * midDY)
            guard midLength > 0 else { continue }

            let perpDX = -midDY / midLength
            let perpDY = midDX / midLength

            let leftPoint = CGPoint(
                x: basePoint.x + perpDX * halfWidth,
                y: basePoint.y + perpDY * halfWidth
            )
            let rightPoint = CGPoint(
                x: basePoint.x - perpDX * halfWidth,
                y: basePoint.y - perpDY * halfWidth
            )

            leftPoints.append(leftPoint)
            rightPoints.append(rightPoint)
        }

        return (leftPoints, rightPoints)
    }

    static func computeDerivatives(from points: [CGPoint]) -> [CGPoint] {
        var derivatives: [CGPoint] = []

        for i in 0..<points.count {
            let prev = points[max(i - 1, 0)]
            let next = points[min(i + 1, points.count - 1)]
            let derivative = CGPoint(
                x: (next.x - prev.x) * 0.5,
                y: (next.y - prev.y) * 0.5
            )
            derivatives.append(derivative)
        }

        return derivatives
    }

    static func addArcBetweenPoints(
        _ path: UIBezierPath,
        from startPoint: CGPoint,
        to endPoint: CGPoint
    ) {
        // Calculate center as the midpoint
        let center = CGPoint(
            x: (startPoint.x + endPoint.x) / 2,
            y: (startPoint.y + endPoint.y) / 2
        )

        // Calculate radius (distance from center to either point)
        let radius = sqrt(
            pow(endPoint.x - center.x, 2) + pow(endPoint.y - center.y, 2)
        )

        // Determine angles
        let startAngle = atan2(startPoint.y - center.y, startPoint.x - center.x)
        let endAngle = atan2(endPoint.y - center.y, endPoint.x - center.x)

        // Add arc to path
        path.addArc(
            withCenter: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )
    }

}
