//
//  ImageInfo.swift
//  test_draw
//
//  Created by Fung Wing on 21/5/2025.
//

import UIKit

class ImageInfo: NSObject, NSSecureCoding {
    static var supportsSecureCoding: Bool { true }

    let name: String
    let type: Int
    let url: String
    let size: CGSize
    let position: CGPoint
    let rotationAngle: CGFloat
    let deleted: Bool
    init(layer: ImageLayer) {
        self.name = layer.name ?? "defaultName"
        self.type = layer.type.rawValue
        self.url = layer.url!
        self.size = layer.bounds.size
        self.position = layer.position
        self.rotationAngle = layer.rotationAngle
        self.deleted = layer.deleted
    }

    // Required `NSSecureCoding` initializer for decoding
    required init?(coder: NSCoder) {
        self.name = coder.decodeObject(of: NSString.self, forKey: "name") as? String ?? "defaultName"
        self.type = coder.decodeInteger(forKey: "type")
        self.url = coder.decodeObject(of: NSString.self, forKey: "url") as? String ?? ""
        self.size = coder.decodeCGSize(forKey: "size")
        self.position = coder.decodeCGPoint(forKey: "position")
        self.rotationAngle = coder.containsValue(forKey: "rotationAngle") ? CGFloat(coder.decodeDouble(forKey: "rotationAngle")) : 0.0
        self.deleted = coder.decodeBool(forKey: "deleted")
    }

    // Required `NSSecureCoding` method for encoding
    func encode(with coder: NSCoder) {
        coder.encode(self.name, forKey: "name")
        coder.encode(self.type, forKey: "type")
        coder.encode(self.url, forKey: "url")
        coder.encode(self.size, forKey: "size")
        coder.encode(self.position, forKey: "position")
        coder.encode(Double(self.rotationAngle), forKey: "rotationAngle")
        coder.encode(self.deleted, forKey: "deleted")
    }

    func buildLayer() -> ImageLayer {
        return ImageLayer(name: self.name, type: NoteObjectType(rawValue: self.type) ?? NoteObjectType.image, url: self.url, position: self.position, size: self.size, rotationAngle: self.rotationAngle, deleted: self.deleted)
    }
}
