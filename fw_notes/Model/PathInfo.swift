//
//  PathInfo.swift
//  test_draw
//
//  Created by Fung Wing on 21/5/2025.
//

import UIKit

class PathInfo: NSObject, NSSecureCoding {
    static var supportsSecureCoding: Bool { true }

    let name: String
    let pathData: Data?
    let colorHex: String?
    let opacity: Float
    let position: CGPoint
    let deleted: Bool
   

    init(layer: PathLayer) {
        self.name = layer.name ?? "defaultName"
        self.position = layer.position

        self.opacity = layer.opacity

        self.pathData = try? NSKeyedArchiver.archivedData(
            withRootObject: UIBezierPath(
                cgPath: layer.path ?? CGPath(rect: .zero, transform: nil)
            ),
            requiringSecureCoding: false
        )
        self.colorHex = UIColor(cgColor: layer.pathColor).hexString
        self.deleted = layer.deleted
    }

    required init?(coder: NSCoder) {
        self.name =
            coder.decodeObject(of: NSString.self, forKey: "name") as? String
            ?? "defaultName"
        self.position = coder.decodeCGPoint(forKey: "position")
        self.opacity = coder.decodeFloat(forKey: "opacity")
        self.pathData =
            coder.decodeObject(of: NSData.self, forKey: "pathData") as? Data
        self.colorHex =
            coder.decodeObject(of: NSString.self, forKey: "colorHex") as? String
        self.deleted = coder.decodeBool(forKey: "deleted")
    }

    func encode(with coder: NSCoder) {
        coder.encode(name, forKey: "name")
        coder.encode(position, forKey: "position")
        coder.encode(opacity, forKey: "opacity")
        coder.encode(pathData, forKey: "pathData")
        coder.encode(colorHex, forKey: "colorHex")
        coder.encode(deleted, forKey: "deleted")
    }

    func buildLayer() -> PathLayer {
        guard let pathData = self.pathData else {
            fatalError("Invalid path data")
        }

        guard
            let path = try? NSKeyedUnarchiver.unarchivedObject(
                ofClass: UIBezierPath.self,
                from: pathData
            )
        else {
            fatalError("Invalid path data")
        }

        let color = UIColor(hex: self.colorHex ?? "#000000") ?? UIColor.black
        return PathLayer(
            name: self.name,
            path: path.cgPath,
            color: color.cgColor,
            opacity: self.opacity,
            position: self.position,
            deleted: self.deleted
        )
    }
}
