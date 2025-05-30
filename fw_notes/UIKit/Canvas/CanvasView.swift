//
//  DrawingView.swift
//  test_draw
//
//  Created by Fung Wing on 8/5/2025.
//

import UIKit

class CanvasView: UIView, ToolBarDelegate {
    //Controller
    private let historyManager: HistoryManager = HistoryManager()
    private let storeManager: StoreManager = StoreManager()
    private let gifAnimationController: GifAnimationController =
        GifAnimationController()

    //UI
    private var toolBar: ToolBar = ToolBar()
    private let debugPanel: DebugPanel = DebugPanel()

    //Layers
    private var backgroundLayers: CALayer = CALayer()
    private var mainLayers: CALayer = CALayer()
    private var drawingLayer: DrawingLayer = DrawingLayer()
    private var lassoLayer: LassoLayer = LassoLayer()
    private var eraseMaskLayer: EraseMaskLayer = EraseMaskLayer()
    private var laserLayer: LaserLayer = LaserLayer()
    private var imageTransfromFrame: ImageTransfromFrame? {
        didSet {
            updateBackgroundLayer()
        }
    }

    //Helpers
    private var mode: DrawMode = DrawMode.pen
    private var baseWidth: CGFloat = 2.0
    private var eraseWidth: CGFloat = 16
    private var baseImage: UIImage?

    var pageId: UUID = UUID()
    private var layers: [CALayer] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.white
        initializeCanvas()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func initializeCanvas() {
        self.layer.backgroundColor = UIColor.clear.cgColor

        lassoLayer.adjustBounds(by: self)
        drawingLayer.adjustBounds(by: self)
        eraseMaskLayer.adjustBounds(by: self)
        mainLayers.frame = self.bounds
        mainLayers.mask = eraseMaskLayer
        self.isMultipleTouchEnabled = true
        self.layer.addSublayer(backgroundLayers)
        self.layer.addSublayer(mainLayers)
        self.layer.addSublayer(drawingLayer)
        self.layer.addSublayer(lassoLayer)
        self.layer.addSublayer(laserLayer)

        self.addSubview(toolBar)
        self.addSubview(debugPanel)
        debugPanel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            debugPanel.topAnchor.constraint(
                equalTo: self.safeAreaLayoutGuide.topAnchor,
                constant: 10
            ),  // 10px from top
            debugPanel.trailingAnchor.constraint(
                equalTo: self.safeAreaLayoutGuide.trailingAnchor,
                constant: -10
            ),  // 10px from right
            debugPanel.widthAnchor.constraint(equalToConstant: 100),  // Adjust width as needed
            debugPanel.heightAnchor.constraint(equalToConstant: 100),  // Adjust height as needed
        ])

        toolBar.delegate = self  // Set delegate
     
      
    }


    func toolDidChange(to mode: DrawMode) {
        print("Selected tool changed to: \(mode)")
        self.mode = mode
        updateBackgroundLayer()
        lassoLayer.reset()
    }

    func updateBackgroundLayer() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        backgroundLayers.sublayers?.forEach { $0.removeFromSuperlayer() }
        if mode == .eraser && imageTransfromFrame == nil {
            for layer in layers {
                if layer is ImageLayer {
                    if let clonedLayer = layer.copy() as? CALayer {

                        backgroundLayers.addSublayer(clonedLayer)
                    }
                }
            }
        }
        CATransaction.commit()
    }

    func updateDebugInfo() {
        let pathLayers = self.layers.compactMap { $0 as? PathLayer }
        debugPanel.updateDebugInfo(from: pathLayers)
    }

    func replaceLayers(from updateLayers: [CALayer]) {
        var updateLayersCopy = updateLayers  // Make a local copy since we can't modify the original directly
        var replacedCount = 0

        self.layers = layers.map { layer in
            if let index = updateLayersCopy.firstIndex(where: {
                $0.name == layer.name
            }) {
                print("find")
                let matchingLayer = updateLayersCopy.remove(at: index)  // Remove matched layer from local copy
                replacedCount += 1

                // Stop looping if all layers have been replaced
                if replacedCount >= updateLayersCopy.count {
                    print("find2 \(matchingLayer.deleted)")
                    return matchingLayer
                }

                print("find3")
                return matchingLayer
            } else {
                return layer  // Keep original if no match
            }
        }
    }

    func synchronizeLayers() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        var newLayers: [CALayer] = []

        // Maintain a dictionary of existing layers
        let existingLayers = Set(mainLayers.sublayers ?? [])

        // Filter out deleted layers
        let activeLayers = self.layers.filter { layer in
            if let pathLayer = layer as? PathLayer {
                return pathLayer.deleted != true  // Keep only non-deleted PathLayers
            } else if let imageLayer = layer as? ImageLayer {
                return imageLayer.deleted != true
            } else {
                return false  // Exclude other types
            }
        }

        for layer in activeLayers.reversed() {
            if !existingLayers.contains(layer) {
                self.mainLayers.addSublayer(layer)
                newLayers.append(layer)
            } else {
                break
            }

            if let imageLayer = layer as? ImageLayer,
                imageLayer.type == NoteObjectType.gif,
                let name = imageLayer.name,
                self.gifAnimationController.gifWrappers[name] == nil
            {
                self.gifAnimationController.startGIFAnimation(for: imageLayer)
            }
        }

        CATransaction.commit()
        updateDebugInfo()
    }

    func refreshLayers() {
        print("refreshLayers")
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        mainLayers.sublayers?.forEach { $0.removeFromSuperlayer() }
        let activeLayers = self.layers.filter { layer in
            if let pathLayer = layer as? PathLayer {
                return pathLayer.deleted != true  // Keep only non-deleted PathLayers
            } else if let imageLayer = layer as? ImageLayer {
                return imageLayer.deleted != true
            } else {
                return false  // Exclude other types
            }
        }

        for layer in activeLayers {
            self.mainLayers.addSublayer(layer)

            if let imageLayer = layer as? ImageLayer,
                imageLayer.type == NoteObjectType.gif,
                let name = imageLayer.name,
                self.gifAnimationController.gifWrappers[name] == nil
            {
                self.gifAnimationController.startGIFAnimation(for: imageLayer)
            }
        }
        print("refreshLayers-end")
        CATransaction.commit()

        updateDebugInfo()
    }

    func resetLayers() {
        mainLayers.sublayers?.forEach { $0.removeFromSuperlayer() }
        let pathLayers = layers.compactMap { $0 as? PathLayer }
        debugPanel.updateDebugInfo(from: pathLayers)
    }

    func removeImageTransfromFrame() {
        for subview in self.subviews.reversed() {
            if subview is ImageTransfromFrame {

                subview.removeFromSuperview()

                self.imageTransfromFrame?.removeFromSuperview()

                self.imageTransfromFrame = nil

                break
            }
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let isMultitouchDetected =
            touches.count > 1 || event?.allTouches?.count ?? 0 > 1

        if isMultitouchDetected {
            return
        }

        let location = touch.location(in: self)
        if let imageTransfromFrame = imageTransfromFrame {
            if imageTransfromFrame.inBounds(location: location, in: self) {
                return
            }
        }
        removeImageTransfromFrame()
        if let touchedImageLayer = getTouchedImage(touchLocation: location),
            mode != DrawMode.lasso
        {
            createImageFrame(touchedImageLayer)
        }

        switch mode {
        case DrawMode.pen:
            drawingLayer.drawPath(
                touch,
                in: self,
                baseWidth: baseWidth,
                color: UIColor.purple,
                opacity: 1.0,
                begin: true
            )
            break
        case DrawMode.laser:
            laserLayer.drawPath(
                touch,
                in: self,
                baseWidth: baseWidth,
                begin: true
            )
            break
        case DrawMode.eraser:
            backgroundLayers.isHidden = false
            gifAnimationController.pauseAllGIFAnimations()
            eraseMaskLayer.drawErasePath(location, width: eraseWidth)
            break
        case DrawMode.lasso:
            if lassoLayer.isSelectingBounds(by: location) {
                lassoLayer.computeOffsetForSelectedObjects(from: location)
            } else {
                lassoLayer.reset()
                lassoLayer.drawLassoPath(location, in: self)
            }
            break
        }

    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {

        guard let touch = touches.first else { return }
       
        let isMultitouchDetected =
            touches.count > 1 || event?.allTouches?.count ?? 0 > 1

        if isMultitouchDetected {
            return
        }


        let location = touch.location(in: self)

        let touchRect = touch.rect(in: self, size: 20)
        if imageTransfromFrame == nil {
            switch mode {
            case DrawMode.pen:
                drawingLayer.drawPath(
                    touch,
                    in: self,
                    baseWidth: baseWidth,
                    color: UIColor.purple,
                    opacity: 1.0,
                    begin: false
                )
                setNeedsDisplay(touchRect)
                break
            case DrawMode.laser:
                laserLayer.drawPath(
                    touch,
                    in: self,
                    baseWidth: baseWidth,
                    begin: false
                )
                setNeedsDisplay(touchRect)
                break
            case DrawMode.eraser:
                eraseMaskLayer.drawErasePath(location, width: eraseWidth)
                setNeedsDisplay(touchRect)
                break
            case DrawMode.lasso:
                if lassoLayer.isSelecting {
                    lassoLayer.moveSelectedObject(to: location)
                } else {
                    lassoLayer.drawLassoPath(location, in: self)
                }
                break
            }
        }

    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        print("touchesEnded")
        let isMultitouchDetected =
            touches.count > 1 || event?.allTouches?.count ?? 0 > 1

        if isMultitouchDetected {
            return
        }

        
        if imageTransfromFrame == nil {
            switch mode {
            case DrawMode.pen:
                let pathLayer = drawingLayer.endPath()
                self.layers.append(pathLayer)
                self.synchronizeLayers()
                historyManager.addInsertHistory(
                    pageId: pageId,
                    tag: ActionTag.normal,
                    layers: [pathLayer]
                )
                break
            case DrawMode.laser:
                laserLayer.endPath()
                break
            case DrawMode.eraser:
                let pathLayers = layers.compactMap { $0 as? PathLayer }

                eraseMaskLayer.realEraseStroke(
                    from: pathLayers,
                    width: eraseWidth,
                    onEnd: { [self] originalLayers, changedPathLayers in
                        historyManager.addUpdateHistory(
                            pageId: pageId,
                            tag: ActionTag.normal,
                            oldLayers: originalLayers,
                            newLayers: changedPathLayers
                        )

                        backgroundLayers.isHidden = true
                        gifAnimationController.resumeAllGIFAnimations()
                    }
                )
                break
            case DrawMode.lasso:
                if lassoLayer.isSelecting {
                    let (originalSelected, changedSelected) =
                        lassoLayer.getAfterChangeSelected()
                    historyManager.addUpdateHistory(
                        pageId: pageId,
                        tag: ActionTag.lasso,
                        oldLayers: originalSelected,
                        newLayers: changedSelected
                    )
                } else {
                    lassoLayer.endLassoPath()
                    lassoLayer.selectObject(from: layers)
                }
                break
            }

        }
    }

    func getTouchedImage(touchLocation: CGPoint) -> ImageLayer? {
        for layer in layers.compactMap({ $0 as? ImageLayer }).reversed() {
            if layer.frame.contains(touchLocation) {
                return layer
            }
        }
        return nil  // Return nil if no layer is found
    }

    func createImageFrame(_ touchedImageLayer: ImageLayer) {

        removeImageTransfromFrame()
        self.imageTransfromFrame = ImageTransfromFrame(touchedImageLayer)

        if let imageTransfromFrame = self.imageTransfromFrame {
            self.addSubview(imageTransfromFrame)
            imageTransfromFrame.onChanged = self.onChangedImageFrame
            imageTransfromFrame.onClose = self.onCloseImageFrame
        }

    }

    func onChangedImageFrame(
        imageLayer: ImageLayer?,
        changedImageLayer: ImageLayer?
    ) {

        guard let imageLayer = imageLayer else {
            print("Error: imageLayer is nil, cannot proceed.")
            return
        }

        historyManager.addUpdateHistory(
            pageId: pageId,
            tag: ActionTag.imageFrame,
            oldLayers: [imageLayer],
            newLayers: [changedImageLayer!]
        )

    }

    func onCloseImageFrame(imageLayer: ImageLayer) {
        historyManager.addDeleteHistory(
            pageId: pageId,
            tag: ActionTag.imageFrame,
            layers: [imageLayer],

        )

        self.layers = self.layers.map { layer in
            if layer.name == imageLayer.name {
                let updatedLayer = layer
                updatedLayer.deleted = true  // Mark it as deleted instead of filtering out
                return updatedLayer
            }
            return layer
        }

        self.refreshLayers()
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {

        guard let imageTransfromFrame = imageTransfromFrame else {
            return super.hitTest(point, with: event)
        }

        let convertedPoint = imageTransfromFrame.convert(point, from: self)
        let expandedBounds = imageTransfromFrame.bounds.insetBy(
            dx: -50,
            dy: -50
        )

        if expandedBounds.contains(convertedPoint) {
            let subviewHitTest = imageTransfromFrame.hitTest(
                convertedPoint,
                with: event
            )

            return subviewHitTest ?? imageTransfromFrame
        }

        let hitView = super.hitTest(point, with: event)
        return hitView == self ? self.superview : hitView

    }

    // Functions
    //---------------------------------------------------------------------------------

    func clone() {
        guard
            let firstPathLayer = layers.first(where: { $0 is PathLayer })
                as? PathLayer
        else {
            print("No PathLayer found in layers.")
            return
        }

        for _ in 1...10000 {

            let randomX = CGFloat.random(in: 0...500)  // Adjust range as needed
            let randomY = CGFloat.random(in: 0...800)
            let position = CGPoint(x: randomX, y: randomY)
            let clonedLayer = firstPathLayer.copy() as! PathLayer
            clonedLayer.position = position

            layers.append(clonedLayer)
        }

        refreshLayers()

        print("Cloned 1,000 PathLayers successfully with random positions.")
    }

    func saveDrawing() {
        saveLayers(to: "layers.data")
    }

    func loadDrawing() {
        loadLayers(
            from: "layers.data",
            completion: {
                print("completion")
            }
        )
        synchronizeLayers()
    }

    func clearDrawing() {
        self.layers = []
        self.resetLayers()
        setNeedsDisplay()
    }

    func addImage() {
        let imageLayer = ImageLayer(
            url: "sample.png",
            position: CGPoint(x: 150, y: 350)
        )
        historyManager.addInsertHistory(
            pageId: pageId,
            tag: ActionTag.normal,
            layers: [imageLayer]
        )
        self.layers.append(imageLayer)
        refreshLayers()

    }

    func addGif() {
        let imageLayer = ImageLayer(
            type: NoteObjectType.gif,
            url: "example2.gif",
            position: CGPoint(x: 150, y: 150)
        )
        historyManager.addInsertHistory(
            pageId: pageId,
            tag: ActionTag.normal,
            layers: [imageLayer]
        )
        self.layers.append(imageLayer)
        refreshLayers()

    }

    func undo() {
        print("undo")
        let layerHistory: LayerHistory? = historyManager.getUndoHistory()
        if let layerHistory = layerHistory {
            let oldLayers = layerHistory.oldLayers
            let tag = layerHistory.tag

            oldLayers.forEach({ print("deleted2: \($0.deleted)") })

            self.replaceLayers(from: oldLayers)
            refreshLayers()

            switch tag {
            case .lasso:
                lassoLayer.reset()
                break
            case .imageFrame:
                removeImageTransfromFrame()
                break

            default:
                break
            }
        }

    }

    func redo() {
        print("redo")
        let layerHistory: LayerHistory? = historyManager.getRedoHistory()
        if let layerHistory = layerHistory {

            let newLayers = layerHistory.newLayers

            let tag = layerHistory.tag
            self.replaceLayers(from: newLayers)
            refreshLayers()

            switch tag {
            case .lasso:
                lassoLayer.reset()
                break
            case .imageFrame:
                removeImageTransfromFrame()
                break
            default:
                break
            }
        }
    }

    func saveLayers(to filename: String) {
        let fileURL = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first!
            .appendingPathComponent(filename)
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        storeManager.saveLayers(with: self.layers, to: fileURL)
        CATransaction.commit()
        // Print file size in MB after saving
        DispatchQueue.global(qos: .background).asyncAfter(
            deadline: .now() + 0.5
        ) {
            do {
                let attributes = try FileManager.default.attributesOfItem(
                    atPath: fileURL.path
                )
                if let fileSize = attributes[.size] as? Int {
                    let fileSizeMB = Double(fileSize) / (1024.0 * 1024.0)
                    print(String(format: "File size: %.2f MB", fileSizeMB))
                }
            } catch {
                print("Error retrieving file size: \(error)")
            }
        }

    }

    func loadLayers(from filename: String, completion: @escaping () -> Void) {
        let fileURL = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first!
            .appendingPathComponent(filename)

        DispatchQueue.global(qos: .userInitiated).async {
            DispatchQueue.main.async {
                self.layers = self.storeManager.loadLayers(from: fileURL)
                self.synchronizeLayers()
                completion()  // Notify UI after loading
            }
        }
    }

}
