//
//  EraseLayer.swift
//  test_draw
//
//  Created by Fung Wing on 20/5/2025.
//

import UIKit

class EraseMaskLayer: CAShapeLayer {
    private var erasePathLayer: CAShapeLayer = CAShapeLayer()
    private var erasePath: UIBezierPath = UIBezierPath()

    override init() {
        super.init()
        configureLayer()
        configureErasePathLayer()
    }

    override init(layer: Any) {
        super.init(layer: layer)
        configureLayer()  // Ensures settings are applied to copied layers
        configureErasePathLayer()
    }

    required init?(coder: NSCoder) {
        super.init()
        configureLayer()
        configureErasePathLayer()
    }

    private func configureLayer() {
        self.lineCap = .round
        self.lineJoin = .round
        self.strokeColor = UIColor.clear.cgColor
        self.fillColor = UIColor.white.cgColor
        self.fillMode = .forwards

    }

    func configureErasePathLayer() {
        self.erasePathLayer.lineCap = .round
        self.erasePathLayer.lineJoin = .round
        self.erasePathLayer.strokeColor = UIColor.clear.cgColor
        self.erasePathLayer.fillColor = UIColor.clear.cgColor
     
        self.addSublayer(erasePathLayer)
    }

    func adjustBounds(by parentView: UIView) {
        let bounds = parentView.bounds
        self.frame = bounds
        self.erasePathLayer.frame = bounds
        let rect = UIBezierPath(rect: bounds)
        self.path = rect.cgPath
    }

    func drawErasePath(_ location: CGPoint, width: CGFloat = 1.0) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        if erasePath.cgPath.isEmpty {
            erasePath.move(to: location)
        } else {
            erasePath.addLine(to: location)
            print( self.bounds);
            let rect = UIBezierPath(rect: self.bounds)
            let stroke = erasePath.cgPath.copy(
                strokingWithWidth: width,
                lineCap: .round,
                lineJoin: .round,
                miterLimit: .pi
            )
            self.lineWidth = width
            let mask = rect.cgPath.subtracting(stroke)
            self.path = mask
            
        }
        CATransaction.commit()
    }

    func reset() {
        self.erasePath = UIBezierPath()
        let rect = UIBezierPath(rect: self.bounds)
        self.path = rect.cgPath
    }

    func realEraseStroke(from layers: [PathLayer] = [], width: CGFloat = 1.0,
                         onEnd: (([PathLayer], [PathLayer]) -> Void)? = nil) {

        let stroke = self.erasePath.cgPath.copy(
            strokingWithWidth: width,
            lineCap: .round,
            lineJoin: .round,
            miterLimit: .pi
        )

        var originalPathLayers: [PathLayer] = []
        var erasedPathLayers: [PathLayer] = []
        let globalStrokeBounds = self.erasePath.cgPath.boundingBoxOfPath
        DispatchQueue.global(qos: .userInteractive).async {

            for layer in layers {
                if let cgPath = layer.path {
                    let globalBounds = layer.frame

                    if globalStrokeBounds.intersects(globalBounds)
                        || cgPath.contains(globalStrokeBounds.origin)
                    {
                        print("Intersection detected, processing")
                    } else {
                        print("No intersection, skipping")
                        continue
                    }
                  
                  
             
                    originalPathLayers.append(layer)
               
                    
                    // Step 2: Apply transformation only if needed
                    let layerFrame = layer.frame.origin
                    var transform = CGAffineTransform(
                        translationX: -layerFrame.x,
                        y: -layerFrame.y
                    )

                    if let transformedStroke = stroke.copy(
                        using: &transform
                    ) {
                        let newCGPath = cgPath.subtracting(
                            transformedStroke,
                            using: .winding
                        )

                        DispatchQueue.main.async {
                            CATransaction.begin()
                            CATransaction.setDisableActions(true)
                            layer.path = newCGPath
                            erasedPathLayers.append(layer.clone() as! PathLayer)
                            CATransaction.commit()

                        }
                    }
                }
            }

            DispatchQueue.main.async {
                DispatchQueue.main.asyncAfter(
                    deadline: .now() + 0.5
                ) {
                    self.reset()
                    if let onEnd = onEnd {
                        onEnd(originalPathLayers, erasedPathLayers)
                    }
                }
            }
        }
    }

}
