//
//  ImageLayer.swift
//  test_draw
//
//  Created by Fung Wing on 21/5/2025.
//
import UIKit

class ImageLayer: CALayer, NSCopying {
    var type: NoteObjectType = NoteObjectType.image
    var url: String?
    var rotationAngle: CGFloat = 0.0

    
    override init(layer: Any) {
        super.init(layer: layer)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    

    init(
        name: String = UUID().uuidString,
        type: NoteObjectType = NoteObjectType.image,
        url: String,
        position: CGPoint,
        size: CGSize = CGSize(width: 100, height: 100),
        rotationAngle: CGFloat = 0.0,
        deleted: Bool = false
    ) {
        self.url = url
        self.type = type
        self.rotationAngle = rotationAngle
      
        super.init()
        self.name = name
        self.contentsGravity = .resize
        self.deleted = deleted
        self.bounds = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        self.frame = CGRect(x: position.x, y: position.y, width: size.width, height: size.height)
        self.position = position
        print(url);
        self.setAffineTransform(CGAffineTransform(rotationAngle: rotationAngle))
        if let image = UIImage(named: url)?.cgImage {
            self.contents = image
        } else {
            print("Error: Image '\(url)' not found in resources.")
        }
    }


    func copy(with zone: NSZone? = nil) -> Any {
        let copy = ImageLayer(
            type: self.type,
            url: self.url!,
            position: self.position,  // Instead of frame.origin
            size: self.bounds.size,   // Instead of frame.size
            rotationAngle: self.rotationAngle,
            deleted: self.deleted
        )
      
        return copy
    }
    
    func clone() -> Any {
        let copy = ImageLayer(
            name: self.name!,
            type: self.type,
            url: self.url!,
            position: self.position,  // Instead of frame.origin
            size: self.bounds.size,   // Instead of frame.size
            rotationAngle: self.rotationAngle,
            deleted: self.deleted
        )
      
        return copy
    }
   
    func data() -> ImageInfo {
        return ImageInfo(layer: self)
    }

}
