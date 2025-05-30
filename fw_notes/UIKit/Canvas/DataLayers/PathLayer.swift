import UIKit

class PathLayer: CATiledLayer, NSCopying {
    let type: NoteObjectType = NoteObjectType.path
    var path: CGPath? {
        didSet {

            self.contents = renderPathToImage(path: path)
        }
    }
    var pathColor: CGColor
    private var padding: CGFloat = 10.0

    override class func fadeDuration() -> CFTimeInterval {
        return 0  // Disable fade effect
    }

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
        self.levelsOfDetailBias = 2
        self.name = name
        self.opacity = opacity
        self.magnificationFilter = .nearest

        self.contentsScale = UIScreen.main.scale
        //self.rasterizationScale = UIScreen.main.scale
        self.path = path
        self.deleted = deleted

        self.bounds = CGRect(
            x: padding,
            y: padding,
            width: (path.boundingBox.size.width),
            height: (path.boundingBox.size.height)
        )

        self.position =
            (position != nil)
            ? CGPoint(x: position!.x, y: position!.y)
            : .zero
        let cgPath = self.adjustPathPosition()
        self.path = cgPath
        // Render path to image and set it as layer contents
        self.contents = renderPathToImage(path: cgPath)

    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func renderPathToImage(path: CGPath?) -> CGImage? {
        guard let cgPath = path else {
            print("Invalid CGPath")
            return nil
        }

        let size = self.bounds.size

        // Prevent zero-size rendering
        if size.width <= 0 || size.height <= 0 {
            print("Invalid image size: \(size)")
            return nil
        }

        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        guard let context = UIGraphicsGetCurrentContext() else {
            UIGraphicsEndImageContext()
            return nil
        }

        context.setFillColor(self.pathColor)
        context.setStrokeColor(self.pathColor)
        context.setLineWidth(1.0)
        context.addPath(cgPath)

        context.drawPath(using: .fillStroke)

        let image = UIGraphicsGetImageFromCurrentImageContext()?.cgImage
        UIGraphicsEndImageContext()

        return image
    }

    func adjustPathPosition() -> CGPath? {
        guard let cgPath = self.path else { return nil }
        let bounds = cgPath.boundingBox
        var transform = CGAffineTransform(
            translationX: -bounds.origin.x,
            y: -bounds.origin.y
        )

        return cgPath.copy(using: &transform)
    }

    // Consolidate Copy & Clone Methods
    func copy(with zone: NSZone? = nil) -> Any {
        return PathLayer(
            path: self.path?.copy() ?? CGPath(rect: .zero, transform: nil),
            color: self.pathColor,
            opacity: self.opacity,
            position: self.frame.origin,
            deleted: self.deleted
        )
    }

    func clone(with zone: NSZone? = nil) -> Any {
        return PathLayer(
            name: self.name!,
            path: self.path?.copy() ?? CGPath(rect: .zero, transform: nil),
            color: self.pathColor,
            opacity: self.opacity,
            position: self.position,
            deleted: self.deleted
        )
    }

    func data() -> PathInfo {
        return PathInfo(layer: self)
    }
}
