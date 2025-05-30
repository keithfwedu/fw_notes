//
//  GifAnimtaionController.swift
//  test_note
//
//  Created by Alex Ng on 1/5/2025.
//

import UIKit
import ImageIO

class GifAnimationController {
    var gifWrappers: [String: GifWrapper] = [:]

    func startGIFAnimation(for gifLayer: ImageLayer) {
        guard let wrapper = getWrapper(gifLayer) else { return }
        setupGIFAnimation(wrapper)
    }
    
    func pauseAllGIFAnimations() {
        gifWrappers.forEach { _, wrapper in
            let pausedTime = wrapper.gifLayer.convertTime(CACurrentMediaTime(), from: nil)
            wrapper.gifLayer.speed = 0.0
            wrapper.gifLayer.timeOffset = pausedTime

            wrapper.gifLayer.isHidden = true
           
        }
    }



    func resumeAllGIFAnimations() {
        gifWrappers.forEach { _, wrapper in
            let pausedTime = wrapper.gifLayer.timeOffset
            wrapper.gifLayer.speed = 1.0
            wrapper.gifLayer.timeOffset = 0.0
            wrapper.gifLayer.beginTime = 0.0
            let timeSincePause = wrapper.gifLayer.convertTime(CACurrentMediaTime(), from: nil) - pausedTime
            wrapper.gifLayer.beginTime = timeSincePause
            wrapper.gifLayer.isHidden = false
        }
    }



    func getWrapper(_ gifLayer: ImageLayer) -> GifWrapper? {
        // Ensure gifLayer.name is not nil before proceeding
        guard let name = gifLayer.name else {
            print("gifLayer.name is nil!")
            return nil
        }

        // Check if a wrapper already exists
        if let existingWrapper = gifWrappers[name] {
            return existingWrapper
        }

        // Attempt to create a new wrapper
        guard let wrapper = createWrapper(gifLayer) else {
            print("Failed to create wrapper for \(name)")
            return nil
        }

        // Store and return the new wrapper
        gifWrappers[name] = wrapper
        return wrapper
    }


    func createWrapper(_ gifLayer: ImageLayer) -> GifWrapper? {
        guard let source = loadGIFSource(gifLayer.url) else { return nil }
        let (frames, delays) = extractFramesAndDelays(from: source)
        return GifWrapper(gifLayer: gifLayer, source: source, frameCount: frames.count, delays: delays)
    }

    func setupGIFAnimation(_ wrapper: GifWrapper) {
        var images: [CGImage] = []
        var keyTimes: [NSNumber] = []
        var totalDuration: Double = 0.0

        // **Optimized Frame Storage - Using Thumbnail Generation**
        for index in 0..<wrapper.frameCount {
            autoreleasepool {
                if let frame = CGImageSourceCreateThumbnailAtIndex(wrapper.source, index, [kCGImageSourceCreateThumbnailFromImageIfAbsent: true] as CFDictionary) {
                    images.append(frame)
                    let delay = wrapper.delays[index]
                    keyTimes.append(NSNumber(value: totalDuration / wrapper.totalDuration))
                    totalDuration += delay
                }
            }
        }

        let animation = CAKeyframeAnimation(keyPath: "contents")
        animation.values = images
        animation.keyTimes = keyTimes
        animation.duration = totalDuration
        animation.calculationMode = .discrete
        animation.repeatCount = .infinity

        wrapper.gifLayer.add(animation, forKey: "gifAnimation")

        // **Clear Cached Frames Immediately After Animation Setup**
        wrapper.cachedFrames.removeAll()
    }

    func removeGIFAnimations() {
        gifWrappers.forEach { _, wrapper in
            wrapper.gifLayer.removeAllAnimations()
            wrapper.gifLayer.removeFromSuperlayer()
            wrapper.cachedFrames.removeAll()
        }
        gifWrappers.removeAll()
    }

    func loadGIFSource(_ path: String?) -> CGImageSource? {
        guard let gifPath = path else { return nil }
        let gifFilename = (gifPath as NSString).deletingPathExtension
        guard let gifURL = Bundle.main.url(forResource: gifFilename, withExtension: "gif"),
              let gifData = try? Data(contentsOf: gifURL) else {
            print("Error: GIF '\(gifPath)' not found.")
            return nil
        }
        return CGImageSourceCreateWithData(gifData as CFData, nil)
    }

    func extractFramesAndDelays(from source: CGImageSource) -> ([CGImage], [Double]) {
        let frameCount = CGImageSourceGetCount(source)
        var delays: [Double] = []
        var cachedFrames: [CGImage] = []

        for i in 0..<frameCount {
            autoreleasepool {
                if let frame = CGImageSourceCreateThumbnailAtIndex(source, i, [kCGImageSourceCreateThumbnailFromImageIfAbsent: true] as CFDictionary) {
                    cachedFrames.append(frame)
                }
                if let properties = CGImageSourceCopyPropertiesAtIndex(source, i, nil) as? [String: Any],
                   let gifDict = properties[kCGImagePropertyGIFDictionary as String] as? [String: Any],
                   let delayTime = gifDict[kCGImagePropertyGIFDelayTime as String] as? Double {
                    delays.append(max(delayTime, 0.02))
                } else {
                    delays.append(0.1)
                }
            }
        }
        return (cachedFrames, delays)
    }
}
