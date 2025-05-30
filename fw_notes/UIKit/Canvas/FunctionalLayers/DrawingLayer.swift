//
//  DrawingLayer.swift
//  test_draw
//
//  Created by Fung Wing on 20/5/2025.
//
import UIKit

class DrawingLayer: CAShapeLayer {
    private var holdPositionTimer: Timer?
    private var latestDrawTouchTime: TimeInterval?

    private var tempDrawingPoints: [NotePoint] = []
    private var builPath: Bool = true
    private var isFinished: Bool = false
    
    override init() {
        super.init()
        configureLayer()  // Ensure layer settings are applied
    }

    override init(layer: Any) {
        super.init(layer: layer)
        configureLayer()  // Ensure layer settings are applied
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureLayer() {
        self.strokeColor = UIColor.purple.cgColor
        self.fillColor = UIColor.purple.cgColor
        self.lineCap = .round
        self.lineJoin = .round
        self.fillRule = .nonZero
        self.lineWidth = 1.0
        self.shouldRasterize = true
        self.contentsScale = UIScreen.main.scale
        self.rasterizationScale = UIScreen.main.scale
        self.zPosition = 1

    }

    func adjustBounds(by parentView: UIView) {
        self.frame = parentView.bounds
    }

    func drawPath(
        _ touch: UITouch,
        in parentView: UIView,
        baseWidth: CGFloat,
        color: UIColor,
        opacity: Float = 1.0,
        begin: Bool = false
    ) {
        let movementDistance = touch.movementDistance(in: parentView)
        let notePoint = touch.toNotePoint(
            in: parentView,
            baseWidth: baseWidth,
            previousTouchTime: latestDrawTouchTime
        )

        self.tempDrawingPoints.forEach({ print($0.location) })
        if begin {

            self.tempDrawingPoints = [notePoint]

            self.frame = .zero
            self.strokeColor = color.cgColor
            self.fillColor = color.cgColor
            self.fillMode = .forwards

            self.isOpaque = false
            self.opacity = opacity
            self.isFinished = false
        } else if movementDistance > 1 {

            cancelHoldPositionTimer()
            notePoint.adjustedWidth(by: self.tempDrawingPoints.last)
            self.tempDrawingPoints.append(notePoint)
            DispatchQueue.global(qos: .userInteractive).async {
                let tempDrawingPath = PathHelper.createPath(
                    from: self.tempDrawingPoints
                )

                DispatchQueue.main.async {
                    if self.isFinished == false {
                        self.path = tempDrawingPath.cgPath
                    }
                }
            }

        } else if movementDistance <= 1, tempDrawingPoints.count > 1,
            holdPositionTimer == nil
        {

            holdPositionTimer = Timer.scheduledTimer(
                withTimeInterval: 1.0,
                repeats: false
            ) { [weak self] _ in
                guard let self = self else { return }

                self.replaceWithShape()
            }
        }

        latestDrawTouchTime = touch.timestamp
    }

    func cancelHoldPositionTimer() {
        if let timer = holdPositionTimer {
            print("cancalTimer")
            timer.invalidate()
            holdPositionTimer = nil
        }

    }

    func endPath() -> PathLayer {
        var cgPath = self.path
        if builPath {
            // cgPath from drawPath() is calculated in real-time by another thread
            // to reduce CPU and GPU load. Since endPath() may execute faster
            // than the real-time path generation, we use the latest points
            // to rebuild the path here, preventing incomplete shapes.

            let tempDrawingPath = PathHelper.createPath(
                from: self.tempDrawingPoints
            )
            cgPath = tempDrawingPath.cgPath
        }

        let pathBounding = cgPath!.boundingBox
        let stroke: PathLayer = PathLayer(
            path: cgPath!,
            color: self.fillColor ?? UIColor.black.cgColor,
            opacity: self.opacity,
            position: CGPoint(x: pathBounding.midX, y: pathBounding.midY)
        )

        self.path = nil
        setNeedsDisplay()
        tempDrawingPoints = []
        self.latestDrawTouchTime = nil
        builPath = true
        isFinished = true
        return stroke

    }

    func replaceWithShape() {
        if let shapePath =
            ShapeRecognizeHelper.getRecognizedShape(
                from: tempDrawingPoints.map({
                    $0.location
                })
            )
        {
            let shapeCgPath = shapePath.copy(
                strokingWithWidth: 4.0,
                lineCap: .round,
                lineJoin: .round,
                miterLimit: .pi
            )

            // Prevent rebuild path from points, because path has been refined by shapeCgPath
            self.builPath = false
            self.path = shapeCgPath

        }
    }

}
