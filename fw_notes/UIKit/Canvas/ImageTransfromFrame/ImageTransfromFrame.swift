//
//  ImageTransfromFrame.swift
//  test_draw
//
//  Created by Fung Wing on 21/5/2025.
//

import CoreGraphics
import UIKit

class ImageTransfromFrame: UIView {
    private let edgeLineTop: UIView = UIView()
    private let edgeLineBottom: UIView = UIView()
    private var closeButton: CloseButton = CloseButton()
    private var rotateControl: RotationControlView = RotationControlView()
    private var controlPoints: [ControlPointType: ControlPoint] = [
        .top: ControlPoint(ControlPointType.top),
        .bottom: ControlPoint(ControlPointType.bottom),
        .left: ControlPoint(ControlPointType.left),
        .right: ControlPoint(ControlPointType.right),
        .topLeft: ControlPoint(ControlPointType.topLeft),
        .topRight: ControlPoint(ControlPointType.topRight),
        .bottomLeft: ControlPoint(ControlPointType.bottomLeft),
        .bottomRight: ControlPoint(ControlPointType.bottomRight),
    ]

    private let frameColor: UIColor
    private let controlSize: CGFloat = 20
    private let padding: CGFloat = 15
    private let minimalWidth: CGFloat = 100.0
    private let minimalHeight: CGFloat = 100.0

    var layerRef: ImageLayer
    private var rotationAngle: CGFloat = 0.0
    private var initialTouchOffset: CGPoint = .zero
    private var previousFrameSize: CGSize = .zero
    
    private var originalLayerRef: ImageLayer?
    private var changedLayerRef: ImageLayer?
    var onClose: ((ImageLayer) -> Void)?
    var onChanged: ((ImageLayer?, ImageLayer?) -> Void)?

    init(_ layer: ImageLayer, color: UIColor = UIColor.blue) {
       
        self.layerRef = layer

        //let padding = controlSize / 2
        self.rotationAngle = atan2(
            layerRef.transform.m12,
            layerRef.transform.m11
        )
        self.layerRef.setAffineTransform(CGAffineTransform(rotationAngle: 0))
        self.frameColor = color
        let viewFrame = CGRect(
            x: layerRef.frame.minX - padding,
            y: layerRef.frame.minY - padding,
            width: layerRef.frame.width + (padding * 2),
            height: layerRef.frame.height + (padding * 2)
        )
        super.init(frame: viewFrame)

        setupFrame()
        addEdgeLineTop()
        addEdgeLineBottom()
        addCloseButton()
        addRotationControl()
        addControlPoints()
        self.layoutIfNeeded()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupFrame() {
        self.layer.borderWidth = 2.0
        self.layer.borderColor = frameColor.cgColor
        layerRef.setAffineTransform(
            CGAffineTransform(rotationAngle: rotationAngle)
        )

        self.transform = CGAffineTransform(rotationAngle: rotationAngle)
        let panGesture = UIPanGestureRecognizer(
            target: self,
            action: #selector(handleMove(_:))
        )
        panGesture
            .maximumNumberOfTouches = 1
        self.addGestureRecognizer(panGesture)
    }

    private func addEdgeLineTop() {
        edgeLineTop.backgroundColor = frameColor
        edgeLineTop.translatesAutoresizingMaskIntoConstraints = false  // Enable Auto Layout
        addSubview(edgeLineTop)

        // Define constraints
        NSLayoutConstraint.activate([
            edgeLineTop.widthAnchor.constraint(equalToConstant: 2),
            edgeLineTop.heightAnchor.constraint(equalToConstant: 30),
            edgeLineTop.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            edgeLineTop.topAnchor.constraint(
                equalTo: self.topAnchor,
                constant: -30
            ),  // Directly aligned at the top
        ])
    }

    private func addEdgeLineBottom() {
        edgeLineBottom.backgroundColor = frameColor
        edgeLineBottom.translatesAutoresizingMaskIntoConstraints = false  // Enable Auto Layout
        addSubview(edgeLineBottom)

        // Define constraints
        NSLayoutConstraint.activate([
            edgeLineBottom.widthAnchor.constraint(equalToConstant: 2),
            edgeLineBottom.heightAnchor.constraint(equalToConstant: 30),
            edgeLineBottom.centerXAnchor.constraint(
                equalTo: self.centerXAnchor
            ),
            edgeLineBottom.bottomAnchor.constraint(
                equalTo: self.bottomAnchor,
                constant: 30
            ),
        ])
    }

    private func addCloseButton() {
        closeButton.translatesAutoresizingMaskIntoConstraints = false  // Enable Auto Layout
        addSubview(closeButton)
        // Define constraints
        NSLayoutConstraint.activate([
            closeButton.widthAnchor.constraint(equalToConstant: 40),
            closeButton.heightAnchor.constraint(equalToConstant: 40),
            closeButton.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            closeButton.topAnchor.constraint(
                equalTo: self.topAnchor,
                constant: -70
            ),  // Directly aligned at the top
        ])

        closeButton.addTarget(
            self,
            action: #selector(handleCloseTap),
            for: .touchUpInside
        )
    }

    private func addRotationControl() {
        rotateControl.color = frameColor
        rotateControl.translatesAutoresizingMaskIntoConstraints = false  // Enable Auto Layout
        addSubview(rotateControl)
        // Define constraints
        NSLayoutConstraint.activate([
            rotateControl.widthAnchor.constraint(equalToConstant: 40),
            rotateControl.heightAnchor.constraint(equalToConstant: 40),
            rotateControl.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            rotateControl.bottomAnchor.constraint(
                equalTo: self.bottomAnchor,
                constant: 70
            ),
        ])

        // Attach rotation gesture
        let rotateGesture = UIPanGestureRecognizer(
            target: self,
            action: #selector(handleRotation(_:))
        )
        rotateGesture
            .maximumNumberOfTouches = 1
        rotateControl.addGestureRecognizer(rotateGesture)
    }

    private func addControlPoints() {
        for subview in self.subviews {
            if subview is ControlPoint {
                subview.removeFromSuperview()
            }
        }

        for (type, controlPoint) in controlPoints {
            self.addSubview(controlPoint)
            let anchors = controlPoint.anchors(in: self)

            switch type {
            case ControlPointType.topLeft, ControlPointType.topRight,
                ControlPointType.bottomLeft, ControlPointType.bottomRight:

                let cornerPanGesture = UIPanGestureRecognizer(
                    target: self,
                    action: #selector(handleCornerResize(_:))
                )
                cornerPanGesture
                    .maximumNumberOfTouches = 1
                controlPoint.addGestureRecognizer(cornerPanGesture)
                break
            case ControlPointType.top, ControlPointType.bottom,
                ControlPointType.left, ControlPointType.right:
                let sidePanGesture = UIPanGestureRecognizer(
                    target: self,
                    action: #selector(handleSideResize(_:))
                )
                sidePanGesture
                    .maximumNumberOfTouches = 1
                controlPoint.addGestureRecognizer(sidePanGesture)
                break
            }

            // Center the controls at each corner
            NSLayoutConstraint.activate([
                controlPoint.widthAnchor.constraint(
                    equalToConstant: controlSize
                ),
                controlPoint.heightAnchor.constraint(
                    equalToConstant: controlSize
                ),
                controlPoint.centerXAnchor.constraint(equalTo: anchors.0),
                controlPoint.centerYAnchor.constraint(equalTo: anchors.1),
            ])
        }
    }
    
  

    @objc func handleCloseTap(_ gesture: UITapGestureRecognizer) {
        print("handleCloseTap")
        self.onClose?(self.layerRef)
        self.removeFromSuperview()  // Optional: Remove the view
    }

    @objc func handleMove(_ gesture: UIPanGestureRecognizer) {
        let touchLocation = gesture.location(in: self.superview)
       
        switch gesture.state {
        case .began:
            let offset = CGPoint(
                x: touchLocation.x - self.center.x,
                y: touchLocation.y - self.center.y
            )
            initialTouchOffset = offset
            originalLayerRef = self.layerRef.clone() as? ImageLayer
            print("Began1")
           
        case .changed:
            let newPosition = CGPoint(
                x: touchLocation.x - initialTouchOffset.x,
                y: touchLocation.y - initialTouchOffset.y
            )
          
            CATransaction.begin()
            CATransaction.setDisableActions(true)  // Prevent implicit animations
            self.center = newPosition
            self.layerRef.position = self.center
         
          
           
            CATransaction.commit()
        case .ended, .cancelled:
            print("Began1c")
            changedLayerRef = self.layerRef.clone() as? ImageLayer
            self.onChanged?(originalLayerRef, changedLayerRef)
            break
        default:
            break
        }

    }

    @objc func handleCornerResize(_ gesture: UIPanGestureRecognizer) {
        guard let controlPoint = gesture.view as? ControlPoint else { return }
        let worldControlPointLocation = gesture.location(in: self.superview)

      
        switch gesture.state {
        case .began:
            originalLayerRef = self.layerRef.clone() as? ImageLayer
        case .changed:
            CATransaction.begin()
            CATransaction.setDisableActions(true)  // Prevent implicit animations
            let oppositeType = controlPoint.oppositeType()
            let oppositeControlPoint = controlPoints[oppositeType]
            let localControlPointLocation = gesture.location(
                in: controlPoint.superview
            )

            guard let oppositeControlPoint = oppositeControlPoint else {
                return
            }
            let newWidth = max(
                minimalWidth + controlSize,
                abs(
                    localControlPointLocation.x
                        - oppositeControlPoint.location().x
                )
            )
            let newHeight = max(
                minimalHeight + controlSize,
                abs(
                    localControlPointLocation.y
                        - oppositeControlPoint.location().y
                )
            )

            let newSize = CGSize(width: newWidth, height: newHeight)
            if newSize != previousFrameSize {
                let oppositeWorldControlPoint = oppositeControlPoint.location(
                    in: self.superview
                )
                let newCenter = findMidpoint(
                    pt1: worldControlPointLocation,
                    pt2: oppositeWorldControlPoint
                )
                self.transform = CGAffineTransform(rotationAngle: 0)
                layerRef.setAffineTransform(CGAffineTransform(rotationAngle: 0))
                self.frame.size = newSize
                previousFrameSize = newSize
                self.center = newCenter

                //let padding = controlSize / 2
                layerRef.frame.size = CGSize(
                    width: newWidth - padding * 2,
                    height: newHeight - padding * 2
                )

                self.transform = CGAffineTransform(rotationAngle: rotationAngle)
                layerRef.setAffineTransform(
                    CGAffineTransform(rotationAngle: rotationAngle)
                )

                layerRef.position = self.center

            }
            CATransaction.commit()
        case .ended, .cancelled:

            changedLayerRef = self.layerRef.clone() as? ImageLayer
            self.onChanged?(originalLayerRef, changedLayerRef)
            break
        default:
            break
        }

    }

    @objc func handleSideResize(_ gesture: UIPanGestureRecognizer) {
        guard let controlPoint = gesture.view as? ControlPoint else { return }
        let worldControlPointLocation = gesture.location(in: self.superview)

       
        switch gesture.state {
        case .began:
            originalLayerRef = self.layerRef.clone() as? ImageLayer
        case .changed:
            CATransaction.begin()
            CATransaction.setDisableActions(true)  // Prevent implicit animations
            let oppositeType = controlPoint.oppositeType()
            let oppositeControlPoint = controlPoints[oppositeType]

            guard let oppositeControlPoint = oppositeControlPoint else {
                return
            }

            let oppositeWorldControlPoint = oppositeControlPoint.location(
                in: self.superview
            )

            let newLength = findLength(
                pt1: worldControlPointLocation,
                pt2: oppositeWorldControlPoint
            )
            let oldCenter = CGPoint(x: self.center.x, y: self.center.y)

            self.transform = CGAffineTransform(rotationAngle: 0)
            layerRef.setAffineTransform(CGAffineTransform(rotationAngle: 0))
            var newWidth = self.frame.size.width
            var newHeight = self.frame.size.height
            print(controlPoint.type)
            if [ControlPointType.left, ControlPointType.right].contains(
                controlPoint.type
            ) {

                newWidth = max(
                    minimalWidth + controlSize,
                    newLength
                )
            } else {

                newHeight = max(
                    minimalHeight + controlSize,
                    newLength
                )
            }
            let newSize = CGSize(width: newWidth, height: newHeight)
            self.frame.size = newSize
            //let padding = controlSize / 2
            layerRef.frame.size = CGSize(
                width: newWidth - padding * 2,
                height: newHeight - padding * 2
            )
            layerRef.position = oldCenter
            self.center = oldCenter

            self.transform = CGAffineTransform(rotationAngle: rotationAngle)
            layerRef.setAffineTransform(
                CGAffineTransform(rotationAngle: rotationAngle)
            )
        case .ended, .cancelled:

            changedLayerRef = self.layerRef.clone() as? ImageLayer
            self.onChanged?(originalLayerRef, changedLayerRef)
            break
        default:
            break
        }
        CATransaction.commit()
    }

    // Handle rotation
    @objc func handleRotation(_ gesture: UIPanGestureRecognizer) {
        guard let rotateView = gesture.view, let mainView = rotateView.superview
        else { return }

        CATransaction.begin()
        CATransaction.setDisableActions(true)  // Prevent implicit animations
        let centerPoint = mainView.center
        let touchPoint = gesture.location(in: mainView.superview)  // Touch in superview

        // Compute angle correctly by adjusting for any offset
        let dx = touchPoint.x - centerPoint.x
        let dy = touchPoint.y - centerPoint.y
        let angle = atan2(dy, dx) - (.pi / 2)  // Subtract 90 degrees to align correctly

      
        switch gesture.state {
        case .began:
            originalLayerRef = self.layerRef.clone() as? ImageLayer

        case .changed:
            // Rotate MainView based on corrected touch angle
            mainView.transform = CGAffineTransform(rotationAngle: angle)
            layerRef.setAffineTransform(CGAffineTransform(rotationAngle: angle))

        case .ended, .cancelled:
            // Final adjustments if necessary
            rotationAngle = angle
            layerRef.rotationAngle = angle
            changedLayerRef = self.layerRef.clone() as? ImageLayer
            self.onChanged?(originalLayerRef, changedLayerRef)
            break
        default:
            break
        }
        CATransaction.commit()
    }

    func inBounds(location: CGPoint, in view: UIView) -> Bool {
        let expandedBounds = self.bounds
        let convertedLocation = self.convert(location, from: view)

        // Check if touch is inside ImageTransfromFrame or any of its subviews
        if expandedBounds.contains(convertedLocation)
            || self.frame.contains(location)
            || self.subviews.contains(where: { subview in
                let subviewBounds = subview.bounds
                let convertedSubviewLocation = subview.convert(
                    location,
                    from: view
                )
                return subviewBounds.contains(convertedSubviewLocation)
                    || subview.frame.contains(location)
            })
        {
            print("Touch inside ImageTransfromFrame or its subviews, ignoring.")
            return true
        }

        return false
    }

    func findMidpoint(pt1: CGPoint, pt2: CGPoint) -> CGPoint {
        return CGPoint(
            x: (pt1.x + pt2.x) / 2,
            y: (pt1.y + pt2.y) / 2
        )
    }

    func findLength(pt1: CGPoint, pt2: CGPoint) -> CGFloat {
        let dx = pt2.x - pt1.x
        let dy = pt2.y - pt1.y
        return sqrt(dx * dx + dy * dy)
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let touchedView = super.hitTest(point, with: event)

        // If the touch is outside, explicitly check all control points and rotateView
        if touchedView == nil {
            // First, check rotateView

            let closeButtonConvertedPoint = closeButton.convert(
                point,
                from: self
            )
            if closeButton.point(inside: closeButtonConvertedPoint, with: event)
            {
                return closeButton
            }

            let rotateControlConvertedPoint = rotateControl.convert(
                point,
                from: self
            )
            if rotateControl.point(
                inside: rotateControlConvertedPoint,
                with: event
            ) {
                return rotateControl
            }

            // Then, check all control points
            for controlPoint in controlPoints.values {
                let convertedPoint = controlPoint.convert(point, from: self)
                if controlPoint.point(inside: convertedPoint, with: event) {
                    return controlPoint
                }
            }
        }

        return touchedView
    }

}
