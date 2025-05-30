//
//  NoteStroke.swift
//  test_draw
//
//  Created by Fung Wing on 21/5/2025.
//
import UIKit

/*class PathLayerOld: CAShapeLayer, NSCopying {
    let type: NoteObjectType = NoteObjectType.path
    var pathColor: CGColor
    
    init(
        name: String = UUID().uuidString,
        path: CGPath,
        color: CGColor = UIColor.black.cgColor,
        opacity: Float = 1.0,
        position: CGPoint? = nil,
        deleted: Bool = false
    ) {
        self.pathColor = color
        super.init()
        self.name = name
        self.strokeColor = UIColor.black.cgColor
        self.fillColor = color
        self.opacity = opacity
        self.path = path
        self.lineCap = .round
        self.lineJoin = .round
        self.fillRule = .nonZero
       
        self.deleted = deleted
        
        // Unwrap position safely
        if let safePosition = position {
            self.adjustFrameByPath()
            self.position = safePosition
        } else {
            self.adjustFrameByPath()
            self.adjestPathPosition()
        }

    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func adjestPathPosition() {
        guard let cgPath = self.path else { return }
        let bounds = cgPath.boundingBox
        var transform = CGAffineTransform(
            translationX: -bounds.origin.x,
            y: -bounds.origin.y
        )

        self.path = cgPath.copy(using: &transform)
    }

    func adjustFrameByPath() {
        guard let cgPath = self.path else { return }
        let bounds = cgPath.boundingBox
        self.frame = bounds
    }
    
    func copy(with zone: NSZone? = nil) -> Any {
        if let path = self.path?.copy() {
            return PathLayer(
                path: path,
                color: self.fillColor ?? UIColor.black.cgColor,
                opacity: self.opacity,
                position: self.position
            )
        } else {
            print("Warning: `path` is nil, returning default PathLayer")
            return PathLayer(name: self.name!,path: CGPath(rect: .zero, transform: nil), color: UIColor.black.cgColor, opacity: 1.0, position: .zero)
        }
    }
    
    func clone() -> Any {
        if let path = self.path?.copy() {
            return PathLayer(
                name: self.name!,
                path: path,
                color: self.fillColor ?? UIColor.black.cgColor,
                opacity: self.opacity,
                position: self.position
            )
        } else {
            print("Warning: `path` is nil, returning default PathLayer")
            return PathLayer(name: self.name!,path: CGPath(rect: .zero, transform: nil), color: UIColor.black.cgColor, opacity: 1.0, position: .zero)
        }
    }

    
  func data() -> PathInfo {
        return PathInfo(layer: self)
    }


}
*/
