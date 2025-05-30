//
//  ControlPoint.swift
//  test_draw
//
//  Created by Fung Wing on 22/5/2025.
//

import UIKit

class ControlPoint: UIView {
    let type: ControlPointType
    let size = 20.0
    let expandInsets = UIEdgeInsets(
        top: -20,
        left: -20,
        bottom: -20,
        right: -20
    )

    init(_ type: ControlPointType) {
        let frame = CGRect(
            x: 0,
            y: 0,
            width: size,
            height: size
        )
        self.type = type
        super.init(frame: frame)

        self.backgroundColor = UIColor.blue
        self.layer.cornerRadius = size / 2
        self.translatesAutoresizingMaskIntoConstraints = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func location(in view: UIView? = nil) -> CGPoint {
        guard let view = view, let superview = self.superview else { return self.center }
        return superview.convert(self.center, to: view)
    }

    func anchors(in view: UIView) -> (NSLayoutXAxisAnchor, NSLayoutYAxisAnchor)
    {
        switch type {
        case ControlPointType.top:
            return (view.centerXAnchor, view.topAnchor)
        case ControlPointType.bottom:
            return (view.centerXAnchor, view.bottomAnchor)
        case ControlPointType.left:
            return (view.leadingAnchor, view.centerYAnchor)
        case ControlPointType.right:
            return (view.trailingAnchor, view.centerYAnchor)
        case ControlPointType.topLeft:
            return (view.leadingAnchor, view.topAnchor)
        case ControlPointType.topRight:
            return (view.trailingAnchor, view.topAnchor)
        case ControlPointType.bottomLeft:
            return (view.leadingAnchor, view.bottomAnchor)
        case ControlPointType.bottomRight:
            return (view.trailingAnchor, view.bottomAnchor)
        }
    }

    func oppositeType() -> ControlPointType {
        switch type {
        case ControlPointType.top:
            return ControlPointType.bottom
        case ControlPointType.bottom:
            return ControlPointType.top
        case ControlPointType.left:
            return ControlPointType.right
        case ControlPointType.right:
            return ControlPointType.left
        case ControlPointType.topLeft:
            return ControlPointType.bottomRight
        case ControlPointType.topRight:
            return ControlPointType.bottomLeft
        case ControlPointType.bottomLeft:
            return ControlPointType.topRight
        case ControlPointType.bottomRight:
            return ControlPointType.topLeft
        }
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let expandedBounds = bounds.inset(by: expandInsets)
        return expandedBounds.contains(point)
    }
}
