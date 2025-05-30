//
//  LaserLayer.swift
//  test_draw
//
//  Created by Fung Wing on 29/5/2025.
//

import UIKit

class LaserLayer: CAShapeLayer {
    private var fadeoutTimer: Timer?
    private var latestDrawTouchTime: TimeInterval?
    private let fadeAnimation = CABasicAnimation(keyPath: "opacity")

    private var tempDrawingPoints: [NotePoint] = []
    private var combinedCGPath: CGPath = CGPath(rect: .zero, transform: nil)
    private var isFinished: Bool = false

    override init() {
        super.init()
        configureLayer()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureLayer() {
        self.fillMode = .forwards
        self.fillColor = UIColor.white.cgColor
        self.strokeColor = UIColor.red.cgColor
        self.shadowColor = UIColor.red.cgColor
        self.shadowOpacity = 1
        self.shadowRadius = 2
        self.shadowOffset = CGSize(width: 0, height: 0)
        self.shouldRasterize = true
        self.contentsScale = UIScreen.main.scale
        self.rasterizationScale = UIScreen.main.scale
        self.zPosition = 2
        self.isOpaque = false

        fadeAnimation.fromValue = self.opacity
        fadeAnimation.toValue = 0
        fadeAnimation.duration = 0.3
        fadeAnimation.fillMode = .forwards
        fadeAnimation.isRemovedOnCompletion = false
    }

    func drawPath(
        _ touch: UITouch,
        in parentView: UIView,
        baseWidth: CGFloat,
        begin: Bool = false,
    ) {
        cancelFadeoutTimer()
        let movementDistance = touch.movementDistance(in: parentView)
        let notePoint = touch.toNotePoint(
            in: parentView,
            baseWidth: baseWidth,
            previousTouchTime: latestDrawTouchTime
        )
        if begin {
            print("begin")
            tempDrawingPoints = [notePoint]
        } else if movementDistance > 1 {
            print("move")
            fadeoutTimer = Timer.scheduledTimer(
                withTimeInterval: 1.5,
                repeats: false
            ) { _ in
                self.isFinished = true
                DispatchQueue.main.async {
                    self.add(self.fadeAnimation, forKey: "fadeOut")

                    // Ensure the layer is removed after animation completes
                    DispatchQueue.main.asyncAfter(
                        deadline: .now() + self.fadeAnimation.duration
                    ) {
                        self.resetPaths()
                    }
                }
            }

            notePoint.adjustedWidth(by: self.tempDrawingPoints.last)
            self.tempDrawingPoints.append(notePoint)
            DispatchQueue.global(qos: .utility).async {

                // Efficient path update
                let tempDrawingPath = PathHelper.createPath(
                    from: self.tempDrawingPoints
                )

                self.combinedCGPath = self.combinedCGPath.union(
                    tempDrawingPath.cgPath
                )
                DispatchQueue.main.async {
                    if self.isFinished == false {
                        print("move2")
                        self.path = self.combinedCGPath
                    }
                }
            }
        }

        self.latestDrawTouchTime = touch.timestamp
    }

    func cancelFadeoutTimer() {
        if let timer = fadeoutTimer {
            //print("cancalTimer")
            timer.invalidate()
            fadeoutTimer = nil
        }

    }

    func endPath() {
        self.tempDrawingPoints = []
    }

    func resetPaths() {
        self.cancelFadeoutTimer()
        self.tempDrawingPoints = []
        self.combinedCGPath = CGPath(rect: self.bounds, transform: nil)
        self.latestDrawTouchTime = nil
        self.path = nil
        self.isFinished = false
        self.removeAnimation(forKey: "fadeOut")  // Remove fade-out animation
    }

}
