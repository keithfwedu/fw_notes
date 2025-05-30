//
//  LassoLayer.swift
//  test_draw
//
//  Created by Fung Wing on 20/5/2025.
//

import UIKit

class LassoLayer: CAShapeLayer {
    var isSelecting: Bool = false
    var bezierPath: UIBezierPath = UIBezierPath()
    var selected: [CALayer] = []

    //History
    private var originalSelected: [CALayer] = []
    private var changedSelected: [CALayer] = []
    
    private var selectionTouchOffset: CGPoint = CGPoint(x: 0, y: 0)
    private var selectionLayerOffsets: [CALayer: CGPoint] = [:]  // Store distance between touch and path

    override init() {
        super.init()
        configureLayer()
    }

    override init(layer: Any) {
        super.init(layer: layer)
        configureLayer()  // Ensures settings are applied to copied layers
    }

    required init?(coder: NSCoder) {
        super.init()
        configureLayer()
    }

    private func configureLayer() {
        self.lineWidth = 2
        self.strokeColor = UIColor.blue.cgColor
        self.fillColor = UIColor.clear.cgColor
        self.lineDashPattern = [4, 2]
    }

    func adjustBounds(by parentView: UIView) {
        print("parentView.bounds: \(parentView.bounds)")
        self.frame = parentView.bounds
    }

    func drawLassoPath(_ location: CGPoint, in parentView: UIView) {
        if bezierPath.cgPath.isEmpty {
            self.reset()

            bezierPath.move(to: location)
        } else {
            bezierPath.addLine(to: location)
        }
        self.path = bezierPath.cgPath
    }

    func endLassoPath() {
        bezierPath.close()
        self.path = bezierPath.cgPath
        isSelecting = true
    }

    func setLassoBounds(to bounds: CGRect) {
        self.path = UIBezierPath(rect: bounds).cgPath
    }

    func reset() {
        print("rest");
        bezierPath = UIBezierPath()
        self.path = nil
        self.isSelecting = false
        self.selected = []
    }

    func isSelectingBounds(by location: CGPoint) -> Bool {
        guard let lassoBounds = self.path?.boundingBoxOfPath else {
            return false
        }
        return lassoBounds.contains(location)
    }

    func computeOffsetForSelectedObjects(from location: CGPoint) {
        guard let currentPath = self.path else {
            print("Error: Path is nil!")
            return
        }

        let boundingBox = currentPath.boundingBox

        selectionTouchOffset = CGPoint(
            x: location.x - boundingBox.origin.x,
            y: location.y - boundingBox.origin.y
        )

        // Correct offset for each selected object
        for layer in selected {
            selectionLayerOffsets[layer] = CGPoint(
                x: location.x - layer.position.x,
                y: location.y - layer.position.y
            )
        }
    }

    func selectObject(from layers: [CALayer] = []) {
        selected.removeAll()
        originalSelected.removeAll()
        changedSelected.removeAll()
        var selectedBounds: CGRect = .null  // Start with an empty bounding box

        // Filter out deleted layers first
        let activeLayers = layers.filter { layer in
            return !(layer.deleted)
        }

        for case let layer in activeLayers {
            if let shapeLayer = layer as? CAShapeLayer, let cgPath = shapeLayer.path {
                // If the layer has a path, use path-based containment
                let pathPoints = cgPath.getPathPoints()
                var transformedPoints: [CGPoint] = []

                for point in pathPoints {
                    let convertedPoint = shapeLayer.convert(point, to: nil) // Convert to global space
                    transformedPoints.append(convertedPoint)
                }

                for point in transformedPoints {
                    if self.bezierPath.contains(point) {
                        if !selected.contains(shapeLayer) {
                            selected.append(shapeLayer)
                            selectedBounds = selectedBounds.union(shapeLayer.frame)
                        }
                        break
                    }
                }
            } else {
                // If it's a regular CALayer, use frame containment
                if self.bezierPath.contains(layer.frame.origin) {
                    selected.append(layer)
                    selectedBounds = selectedBounds.union(layer.frame)
                }
            }
        }

        originalSelected = self.cloneLayers()

        DispatchQueue.main.async {
            if !selectedBounds.isNull {
                self.setLassoBounds(to: selectedBounds)
            } else {
                self.reset()
            }
        }
    }


    func moveSelectedObject(to location: CGPoint) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
       
        // Move Lasso Path
        if let currentPath = self.path {

            // Get the current bounding box's top-left position
            let boundingBox = currentPath.boundingBox

            // Compute the new target position (where the top-left of bounding box should be)
            let targetLocationX = location.x - selectionTouchOffset.x
            let targetLocationY = location.y - selectionTouchOffset.y

            // Compute translation to align the path's top-left with target position
            var translation = CGAffineTransform(
                translationX: targetLocationX - boundingBox.origin.x,
                y: targetLocationY - boundingBox.origin.y
            )

            // Apply the transformation
            self.path = currentPath.copy(using: &translation)
        }
      
        // Move each selected object while preserving the initial offsets
        for layer in selected {
            if let offset = selectionLayerOffsets[layer] {
                layer.position = CGPoint(
                    x: location.x - offset.x,
                    y: location.y - offset.y
                )
            }
        }
        changedSelected = self.cloneLayers()
        CATransaction.commit()
    }
    
    func getAfterChangeSelected() -> ([CALayer], [CALayer]) {
        return (originalSelected,changedSelected)
    }
    
    func cloneLayers() -> [CALayer] {
        var clonedLayers: [CALayer] = []

        for layer in selected {
            if let pathLayer = layer as? PathLayer {
                let newLayer = pathLayer.clone() as? PathLayer
                clonedLayers.append(newLayer!)

            } else if let imageLayer = layer as? ImageLayer {
                let newLayer = imageLayer.clone() as? ImageLayer
                clonedLayers.append(newLayer!)
            }
        }

        return clonedLayers
    }


}
