//
//  StoreDataWrapper.swift
//  test_draw
//
//  Created by Fung Wing on 29/5/2025.
//

import UIKit

class StoreDataWrapper: NSObject, NSSecureCoding {
    static var supportsSecureCoding: Bool { true }


    let type: LayerType

    var pathData: PathInfo?
    var imageData: ImageInfo?

    init?(layer: CALayer) {
        if let pathLayer = layer as? PathLayer {
            self.type = .path
            self.pathData = pathLayer.data()
            self.imageData = nil
        } else if let imageLayer = layer as? ImageLayer {
            self.type = .image
            self.imageData = imageLayer.data()
            self.pathData = nil
        } else {
            return nil  // Avoid using `fatalError`
        }
    }

    required init?(coder: NSCoder) {
        guard
            let rawType = coder.decodeObject(of: NSString.self, forKey: "type")
                as? String,
            let type = LayerType(rawValue: rawType)
        else { return nil }

        self.type = type
        self.pathData = coder.decodeObject(
            of: PathInfo.self,
            forKey: "pathData"
        )
        self.imageData = coder.decodeObject(
            of: ImageInfo.self,
            forKey: "imageData"
        )
    }

    func encode(with coder: NSCoder) {
        coder.encode(type.rawValue, forKey: "type")
        coder.encode(pathData, forKey: "pathData")
        coder.encode(imageData, forKey: "imageData")
    }

    func buildLayer() -> CALayer? {
        switch type {
        case .path:
            return self.pathData?.buildLayer()
        case .image:
            return self.imageData?.buildLayer()
        }
    }
}
